from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from .models import Post
from .serializers import PostSerializer
from users.services.supabase_service import SupabaseStorage
import logging

logger = logging.getLogger(__name__)

class PostViewSet(viewsets.ModelViewSet):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)

    def get_queryset(self):
        group_pk = self.kwargs.get('group_pk')
        if group_pk:
            from groups.models import Group
            group = get_object_or_404(Group, pk=group_pk)
            return Post.objects.filter(group=group)
        return Post.objects.all()

    def perform_create(self, serializer):
        group_pk = self.kwargs.get('group_pk')
        from groups.models import Group
        group = get_object_or_404(Group, pk=group_pk)
        
        # Kullanıcının grup üyesi olup olmadığını kontrol et
        if self.request.user not in group.members.all() and self.request.user != group.owner:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Bu grubun üyesi değilsiniz.")
        
        # Post'u önce oluştur (image_url olmadan)
        post = serializer.save(author=self.request.user, group=group)
        
        # Eğer resim varsa Supabase'e yükle
        image_file = self.request.FILES.get('image')
        if image_file:
            try:
                storage = SupabaseStorage()
                image_url = storage.upload_group_post_image(image_file, group.id, post.id)
                post.image_url = image_url
                post.save()
                logger.info(f"Grup post resmi başarıyla yüklendi: {image_url}")
            except Exception as e:
                logger.error(f"Grup post resmi yükleme hatası: {str(e)}")
                # Post'u sil çünkü resim yüklenemedi
                post.delete()
                raise

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Sadece post sahibi veya grup sahibi düzenleyebilir
        if instance.author != request.user and instance.group.owner != request.user:
            return Response(
                {'detail': 'Bu postu düzenleme yetkiniz yok.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Eğer yeni resim yükleniyorsa
        image_file = request.FILES.get('image')
        if image_file:
            try:
                # Eski resmi sil
                if instance.image_url:
                    storage = SupabaseStorage()
                    storage.delete_group_post_image(instance.image_url)
                
                # Yeni resmi yükle
                storage = SupabaseStorage()
                image_url = storage.upload_group_post_image(image_file, instance.group.id, instance.id)
                
                # Post'u güncelle
                data = request.data.copy()
                data['image_url'] = image_url
                serializer = self.get_serializer(instance, data=data, partial=True)
                if serializer.is_valid():
                    serializer.save()
                    return Response(serializer.data)
                else:
                    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            except Exception as e:
                logger.error(f"Grup post resmi güncelleme hatası: {str(e)}")
                return Response(
                    {'detail': 'Resim güncellenirken hata oluştu.'}, 
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Sadece post sahibi veya grup sahibi silebilir
        if instance.author != request.user and instance.group.owner != request.user:
            return Response(
                {'detail': 'Bu postu silme yetkiniz yok.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Eğer resim varsa Supabase'den sil
        if instance.image_url:
            try:
                storage = SupabaseStorage()
                storage.delete_group_post_image(instance.image_url)
                logger.info(f"Grup post resmi başarıyla silindi: {instance.image_url}")
            except Exception as e:
                logger.warning(f"Grup post resmi silinemedi: {str(e)}")
        
        return super().destroy(request, *args, **kwargs)
