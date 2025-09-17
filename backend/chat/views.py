from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.decorators import action
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.db.models import Q, Max
from django.contrib.auth import get_user_model
from .models import GroupMessage, PrivateMessage
from .serializers import GroupMessageSerializer, PrivateMessageSerializer
# from users.services.supabase_service import SupabaseStorage  # Removed - Supabase disabled
import logging

logger = logging.getLogger(__name__)
User = get_user_model()

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
                logger.info(f"Medya dosyası alındı: {media_file.name}, boyut: {media_file.size}")
                logger.info(f"Content type: {media_file.content_type}")
                logger.info(f"Charset: {getattr(media_file, 'charset', 'None')}")
                
                # Dosya stream'ini kontrol et
                media_file.seek(0)
                file_content = media_file.read()
                logger.info(f"Dosya içeriği boyutu: {len(file_content)} bytes")
                
                # Dosya stream'ini başa al
                media_file.seek(0)
                
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
        
        # Eğer medya dosyası varsa Supabase'den sil
        if instance.file_url:
            try:
                storage = SupabaseStorage()
                storage.delete_group_message_media(instance.file_url)
                logger.info(f"Grup mesaj medyası başarıyla silindi: {instance.file_url}")
            except Exception as e:
                logger.warning(f"Grup mesaj medyası silinemedi: {str(e)}")
        
        return super().destroy(request, *args, **kwargs)


class PrivateMessageViewSet(viewsets.ModelViewSet):
    serializer_class = PrivateMessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return PrivateMessage.objects.filter(
            Q(sender=user) | Q(receiver=user)
        ).order_by('-timestamp')

    def perform_create(self, serializer):
        message = serializer.save(sender=self.request.user)
        
        # Mesaj alıcısına bildirim oluştur
        try:
            from notifications.models import Notification
            Notification.objects.create(
                user=message.receiver,
                notification_type='message',
                message=f"{message.sender.first_name or message.sender.username} size mesaj gönderdi",
                data={
                    'message_id': message.id,
                    'sender_id': message.sender.id,
                    'sender_username': message.sender.username,
                }
            )
            logger.info(f"Message notification created for user {message.receiver.id}")
        except Exception as e:
            logger.error(f"Error creating message notification: {e}")

    @action(detail=True, methods=['patch'], url_path='mark-read')
    def mark_read(self, request, pk=None):
        message = self.get_object()
        logger.info(f"Mark read request for message {pk} from user {request.user.id}")
        logger.info(f"Message receiver: {message.receiver.id}, sender: {message.sender.id}")
        
        if message.receiver == request.user:
            message.mark_as_read()
            logger.info(f"Message {pk} marked as read successfully")
            return Response({'status': 'message marked as read'})
        return Response(
            {'detail': 'Bu mesajı okundu olarak işaretleme yetkiniz yok.'},
            status=status.HTTP_403_FORBIDDEN
        )

    def partial_update(self, request, pk=None):
        """PATCH request için özel işlem"""
        message = self.get_object()
        
        # Eğer sadece is_read field'ı güncelleniyorsa
        if 'is_read' in request.data and len(request.data) == 1:
            if message.receiver == request.user and request.data.get('is_read') is True:
                message.mark_as_read()
                return Response({'status': 'message marked as read'})
            else:
                return Response(
                    {'detail': 'Bu mesajı okundu olarak işaretleme yetkiniz yok.'},
                    status=status.HTTP_403_FORBIDDEN
                )
        
        # Normal güncelleme işlemi
        return super().partial_update(request, pk)

    def destroy(self, request, *args, **kwargs):
        """Mesajı sil"""
        message = self.get_object()
        
        # Sadece mesaj sahibi silebilir
        if message.sender != request.user:
            return Response(
                {'detail': 'Bu mesajı silme yetkiniz yok.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        return super().destroy(request, *args, **kwargs)

    @action(detail=False, methods=['get'], url_path='with-user/(?P<user_id>[^/.]+)')
    def with_user(self, request, user_id=None):
        """Belirli bir kullanıcı ile olan konuşmayı getir"""
        try:
            other_user = get_object_or_404(User, id=user_id)
            user = request.user
            
            # İki kullanıcı arasındaki mesajları getir
            messages = PrivateMessage.objects.filter(
                Q(sender=user, receiver=other_user) | 
                Q(sender=other_user, receiver=user)
            ).order_by('timestamp')
            
            serializer = self.get_serializer(messages, many=True)
            return Response(serializer.data)
        except Exception as e:
            return Response(
                {'detail': f'Konuşma alınırken hata: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=False, methods=['get'], url_path='search')
    def search_messages(self, request):
        """Mesajlarda arama yap"""
        query = request.query_params.get('q', '').strip()
        if not query:
            return Response(
                {'detail': 'Arama terimi gerekli'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            user = request.user
            
            # Kullanıcının gönderdiği veya aldığı mesajlarda arama yap
            messages = PrivateMessage.objects.filter(
                Q(sender=user) | Q(receiver=user),
                Q(message__icontains=query)
            ).order_by('-timestamp')
            
            serializer = self.get_serializer(messages, many=True)
            return Response(serializer.data)
        except Exception as e:
            return Response(
                {'detail': f'Arama sırasında hata: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )

    # TODO: HiddenConversation modeli migration sonrası aktif edilecek
    # @action(detail=False, methods=['post'], url_path='conversation/(?P<user_id>[^/.]+)/hide')
    # def hide_conversation(self, request, user_id=None):
    #     """Belirli bir kullanıcı ile olan konuşmayı gizle (mesajları silme)"""
    #     pass


class ConversationViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def list(self, request):
        user = request.user
        
        # Kullanıcının katıldığı konuşmaları getir
        # TODO: HiddenConversation modeli migration sonrası aktif edilecek
        conversations = PrivateMessage.objects.filter(
            Q(sender=user) | Q(receiver=user)
        ).values('sender', 'receiver').distinct()
        
        conversation_list = []
        
        for conv in conversations:
            sender_id = conv['sender']
            receiver_id = conv['receiver']
            
            # Diğer kullanıcıyı belirle
            other_user_id = receiver_id if sender_id == user.id else sender_id
            other_user = get_object_or_404(User, id=other_user_id)
            
            # Son mesajı getir
            last_message = PrivateMessage.objects.filter(
                Q(sender=user, receiver=other_user) | 
                Q(sender=other_user, receiver=user)
            ).order_by('-timestamp').first()
            
            # Okunmamış mesaj sayısını getir
            unread_count = PrivateMessage.objects.filter(
                sender=other_user,
                receiver=user,
                is_read=False
            ).count()
            
            conversation_list.append({
                'other_user': {
                    'id': other_user.id,
                    'username': other_user.username,
                    'first_name': other_user.first_name,
                    'last_name': other_user.last_name,
                    'profile_picture': getattr(other_user, 'profile_picture', None),
                },
                'last_message': PrivateMessageSerializer(last_message).data if last_message else None,
                'unread_count': unread_count,
                'is_online': False,  # TODO: Online durumu için WebSocket implementasyonu
            })
        
        return Response(conversation_list)


class RoomMessagesView(APIView):
    """Frontend'in beklediği room messages endpoint'i"""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request, user1_id, user2_id):
        """İki kullanıcı arasındaki mesajları getir"""
        try:
            user = request.user
            
            # Kullanıcının bu konuşmaya erişim yetkisi var mı kontrol et
            if user.id not in [user1_id, user2_id]:
                return Response(
                    {'detail': 'Bu konuşmaya erişim yetkiniz yok.'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Diğer kullanıcıyı belirle
            other_user_id = user2_id if user.id == user1_id else user1_id
            other_user = get_object_or_404(User, id=other_user_id)
            
            # İki kullanıcı arasındaki mesajları getir
            messages = PrivateMessage.objects.filter(
                Q(sender=user, receiver=other_user) | 
                Q(sender=other_user, receiver=user)
            ).order_by('timestamp')
            
            serializer = PrivateMessageSerializer(messages, many=True)
            return Response(serializer.data)
            
        except Exception as e:
            logger.error(f"Room messages error: {e}")
            return Response(
                {'detail': f'Mesajlar alınırken hata: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    def post(self, request, user1_id, user2_id):
        """Yeni mesaj gönder"""
        try:
            user = request.user
            
            # Kullanıcının bu konuşmaya erişim yetkisi var mı kontrol et
            if user.id not in [user1_id, user2_id]:
                return Response(
                    {'detail': 'Bu konuşmaya erişim yetkiniz yok.'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Diğer kullanıcıyı belirle
            other_user_id = user2_id if user.id == user1_id else user1_id
            other_user = get_object_or_404(User, id=other_user_id)
            
            # Mesajı oluştur
            serializer = PrivateMessageSerializer(data=request.data)
            if serializer.is_valid():
                message = serializer.save(sender=user, receiver=other_user)
                
                # Mesaj alıcısına bildirim oluştur
                try:
                    from notifications.utils import send_notification_with_preferences
                    send_notification_with_preferences(
                        recipient_user=other_user,
                        message=f"{user.first_name or user.username} size mesaj gönderdi: {message.message[:50]}...",
                        notification_type='message',
                        sender_user=user,
                        title=f"Yeni Mesaj - {user.first_name or user.username}"
                    )
                    logger.info(f"Message notification sent to user {other_user.id}")
                except Exception as e:
                    logger.error(f"Error sending message notification: {e}")
                
                return Response(PrivateMessageSerializer(message).data, status=status.HTTP_201_CREATED)
            else:
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            logger.error(f"Send message error: {e}")
            return Response(
                {'detail': f'Mesaj gönderilirken hata: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )
