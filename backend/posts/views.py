# moto_app/backend/posts/views.py

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from .models import Post
from .serializers import PostSerializer
from groups.models import Group
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import MultiPartParser, FormParser
from users.services.supabase_service import SupabaseStorage
import logging

logger = logging.getLogger(__name__)

# Genel postları yönetir (grup dışı)
class GeneralPostListCreateView(generics.ListCreateAPIView):
    queryset = Post.objects.filter(group__isnull=True).order_by('-created_at')
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def perform_create(self, serializer):
        # Post'u önce oluştur (image_url olmadan)
        post = serializer.save(author=self.request.user, group=None)
        
        # Eğer resim varsa Supabase'e yükle
        image_file = self.request.FILES.get('image')
        if image_file:
            try:
                storage = SupabaseStorage()
                image_url = storage.upload_group_post_image(image_file, None, post.id)  # group_id=None for general posts
                post.image_url = image_url
                post.save()
                logger.info(f"Genel post resmi başarıyla yüklendi: {image_url}")
            except Exception as e:
                logger.error(f"Genel post resmi yükleme hatası: {str(e)}")
                # Post'u sil çünkü resim yüklenemedi
                post.delete()
                raise

# Grup postlarını yönetir
class GroupPostListCreateView(generics.ListCreateAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)

        if self.request.user in group.members.all() or self.request.user == group.owner:
            return Post.objects.filter(group=group).order_by('-created_at')
        raise PermissionDenied("Bu grubun gönderilerini görüntüleme izniniz yok.")

    def perform_create(self, serializer):
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)

        if self.request.user in group.members.all() or self.request.user == group.owner:
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
        else:
            raise PermissionDenied("Bu gruba gönderi oluşturma izniniz yok.")

# Tekil postlar için görünüm
class PostDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_object(self):
        obj = super().get_object()

        if obj.group:
            if self.request.user not in obj.group.members.all() and self.request.user != obj.group.owner:
                raise PermissionDenied("Bu gönderiyi görüntüleme izniniz yok.")

        return obj

    def perform_update(self, serializer):
        if serializer.instance.author != self.request.user:
            raise PermissionDenied("Bu gönderiyi düzenleme izniniz yok.")
        
        # Eğer yeni resim yükleniyorsa
        image_file = self.request.FILES.get('image')
        if image_file:
            try:
                # Eski resmi sil
                if serializer.instance.image_url:
                    storage = SupabaseStorage()
                    storage.delete_group_post_image(serializer.instance.image_url)
                
                # Yeni resmi yükle
                storage = SupabaseStorage()
                group_id = serializer.instance.group.id if serializer.instance.group else None
                image_url = storage.upload_group_post_image(image_file, group_id, serializer.instance.id)
                
                # Post'u güncelle
                data = self.request.data.copy()
                data['image_url'] = image_url
                serializer = self.get_serializer(serializer.instance, data=data, partial=True)
                if serializer.is_valid():
                    serializer.save()
                    return Response(serializer.data)
                else:
                    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            except Exception as e:
                logger.error(f"Post resmi güncelleme hatası: {str(e)}")
                return Response(
                    {'detail': 'Resim güncellenirken hata oluştu.'}, 
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        serializer.save()

    def perform_destroy(self, instance):
        if instance.author != self.request.user and (not instance.group or instance.group.owner != self.request.user):
            raise PermissionDenied("Bu gönderiyi silme izniniz yok.")
        
        # Eğer resim varsa Supabase'den sil
        if instance.image_url:
            try:
                storage = SupabaseStorage()
                storage.delete_group_post_image(instance.image_url)
                logger.info(f"Post resmi başarıyla silindi: {instance.image_url}")
            except Exception as e:
                logger.warning(f"Post resmi silinemedi: {str(e)}")
        
        instance.delete()