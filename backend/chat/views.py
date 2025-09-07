from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from .models import GroupMessage
from .serializers import GroupMessageSerializer
from users.services.supabase_service import SupabaseStorage
import logging

logger = logging.getLogger(__name__)

class GroupMessageViewSet(viewsets.ModelViewSet):
    serializer_class = GroupMessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self):
        group_pk = self.kwargs.get('group_pk')
        if group_pk:
            from groups.models import Group
            group = get_object_or_404(Group, pk=group_pk)
            return GroupMessage.objects.filter(group=group)
        return GroupMessage.objects.none()

    def perform_create(self, serializer):
        group_pk = self.kwargs.get('group_pk')
        from groups.models import Group
        group = get_object_or_404(Group, pk=group_pk)
        
        # Kullanıcının grup üyesi olup olmadığını kontrol et
        if self.request.user not in group.members.all() and self.request.user != group.owner:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Bu grubun üyesi değilsiniz.")
        
        # Medya dosyasını al
        media_file = self.request.FILES.get('media')
        
        # Mesajı oluştur
        message = serializer.save(sender=self.request.user, group=group)
        
        # Eğer medya dosyası varsa Supabase'e yükle
        if media_file:
            try:
                storage = SupabaseStorage()
                file_url = storage.upload_group_message_media(media_file, group.id, message.id)
                message.file_url = file_url
                message.message_type = 'image'  # Şimdilik sadece resim desteği
                message.save()
                logger.info(f"Grup mesaj medyası Supabase'e yüklendi: {file_url}")
            except Exception as e:
                logger.error(f"Grup mesaj medyası Supabase'e yükleme hatası: {str(e)}")
                # Medya yükleme hatası olsa bile mesaj kaydedilir

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Sadece mesaj sahibi düzenleyebilir
        if instance.sender != request.user:
            return Response(
                {'detail': 'Bu mesajı düzenleme yetkiniz yok.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Sadece mesaj sahibi veya grup sahibi silebilir
        if instance.sender != request.user and instance.group.owner != request.user:
            return Response(
                {'detail': 'Bu mesajı silme yetkiniz yok.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        return super().destroy(request, *args, **kwargs)
