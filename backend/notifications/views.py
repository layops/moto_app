from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import Notification, NotificationPreferences
from .serializers import NotificationSerializer, NotificationPreferencesSerializer, FCMTokenSerializer
from .utils import send_realtime_notification

User = get_user_model()

class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(
            recipient=self.request.user
        ).select_related('sender', 'recipient').order_by('-timestamp')
    
    def list(self, request, *args, **kwargs):
        try:
            return super().list(request, *args, **kwargs)
        except Exception as e:
            return Response(
                {"detail": f"Bildirimler yüklenirken hata oluştu: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class NotificationMarkReadView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, *args, **kwargs):
        try:
            notification_ids = request.data.get('notification_ids')
            if notification_ids:
                if not isinstance(notification_ids, list):
                    return Response(
                        {"detail": "notification_ids bir liste olmalıdır."},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                notifications_to_mark = Notification.objects.filter(
                    recipient=request.user,
                    id__in=notification_ids,
                    is_read=False
                )
                updated_count = notifications_to_mark.update(is_read=True)
                return Response({
                    "detail": f"{updated_count} bildirim okundu olarak işaretlendi.",
                    "updated_count": updated_count
                })
            else:
                updated_count = Notification.objects.filter(
                    recipient=request.user,
                    is_read=False
                ).update(is_read=True)
                return Response({
                    "detail": f"Tüm {updated_count} okunmamış bildirim okundu olarak işaretlendi.",
                    "updated_count": updated_count
                })
        except Exception as e:
            return Response(
                {"detail": f"Bildirimler işaretlenirken hata oluştu: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class NotificationDeleteView(generics.DestroyAPIView):
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(recipient=self.request.user)

    def perform_destroy(self, instance):
        try:
            instance.delete()
        except Exception as e:
            from rest_framework.exceptions import APIException
            raise APIException(f"Bildirim silinirken hata oluştu: {str(e)}")

class SendTestNotificationView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        try:
            recipient_username = request.data.get('recipient_username')
            message = request.data.get('message')
            notification_type = request.data.get('notification_type', 'other')
            sender_username = request.data.get('sender_username')
            send_push = request.data.get('send_push', True)  # Push notification gönderilsin mi?

            if not recipient_username or not message:
                return Response(
                    {"detail": "Alıcı kullanıcı adı ve mesaj gereklidir."}, 
                    status=status.HTTP_400_BAD_REQUEST
                )

            try:
                recipient_user = User.objects.get(username=recipient_username)
            except User.DoesNotExist:
                return Response(
                    {"detail": f"Alıcı kullanıcı '{recipient_username}' bulunamadı."}, 
                    status=status.HTTP_404_NOT_FOUND
                )

            sender_user = None
            if sender_username:
                try:
                    sender_user = User.objects.get(username=sender_username)
                except User.DoesNotExist:
                    return Response(
                        {"detail": f"Gönderen kullanıcı '{sender_username}' bulunamadı."}, 
                        status=status.HTTP_404_NOT_FOUND
                    )

            # Push notification ile birlikte gönder
            if send_push:
                from .utils import send_notification_with_preferences
                notification = send_notification_with_preferences(
                    recipient_user=recipient_user,
                    message=message,
                    notification_type=notification_type,
                    sender_user=sender_user,
                    title=f"Test Bildirimi - {notification_type.replace('_', ' ').title()}"
                )
                if notification:
                    return Response(
                        {"detail": "Test bildirimi (push notification ile) başarıyla gönderildi.", "notification_id": notification.id}, 
                        status=status.HTTP_200_OK
                    )
                else:
                    return Response(
                        {"detail": "Test bildirimi gönderildi ancak push notification gönderilemedi (kullanıcı tercihleri kapalı olabilir)."}, 
                        status=status.HTTP_200_OK
                    )
            else:
                # Sadece WebSocket bildirimi gönder
                send_realtime_notification(
                    recipient_user=recipient_user,
                    message=message,
                    notification_type=notification_type,
                    sender_user=sender_user
                )
                return Response(
                    {"detail": "Test bildirimi (sadece WebSocket) başarıyla gönderildi."}, 
                    status=status.HTTP_200_OK
                )
        except Exception as e:
            return Response(
                {"detail": f"Test bildirimi gönderilirken hata oluştu: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def get(self, request, *args, **kwargs):
        """Test bildirimi gönderme endpoint'i için basit test"""
        try:
            # Kendine test bildirimi gönder
            from .utils import send_realtime_notification
            
            send_realtime_notification(
                recipient_user=request.user,
                message="Bu bir test bildirimidir!",
                notification_type='other',
                sender_user=request.user
            )
            
            return Response({
                "detail": f"Test bildirimi '{request.user.username}' kullanıcısına gönderildi.",
                "user": request.user.username,
                "message": "Bu bir test bildirimidir!"
            })
        except Exception as e:
            return Response(
                {"detail": f"Test bildirimi gönderilirken hata oluştu: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class NotificationPreferencesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Kullanıcının bildirim tercihlerini getir"""
        try:
            preferences, created = NotificationPreferences.objects.get_or_create(
                user=request.user
            )
            serializer = NotificationPreferencesSerializer(preferences)
            return Response(serializer.data)
        except Exception as e:
            return Response(
                {"detail": f"Bildirim tercihleri alınırken hata oluştu: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def patch(self, request):
        """Kullanıcının bildirim tercihlerini güncelle"""
        try:
            preferences, created = NotificationPreferences.objects.get_or_create(
                user=request.user
            )
            serializer = NotificationPreferencesSerializer(
                preferences, 
                data=request.data, 
                partial=True
            )
            
            if serializer.is_valid():
                serializer.save()
                return Response({
                    "detail": "Bildirim tercihleri başarıyla güncellendi.",
                    "preferences": serializer.data
                })
            else:
                return Response(
                    {"detail": "Geçersiz veri", "errors": serializer.errors},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except Exception as e:
            return Response(
                {"detail": f"Bildirim tercihleri güncellenirken hata oluştu: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class FCMTokenView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """FCM token'ı kaydet"""
        try:
            serializer = FCMTokenSerializer(data=request.data)
            if serializer.is_valid():
                fcm_token = serializer.validated_data['fcm_token']
                
                preferences, created = NotificationPreferences.objects.get_or_create(
                    user=request.user
                )
                preferences.fcm_token = fcm_token
                preferences.save()
                
                return Response({
                    "detail": "FCM token başarıyla kaydedildi."
                })
            else:
                return Response(
                    {"detail": "Geçersiz token", "errors": serializer.errors},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except Exception as e:
            return Response(
                {"detail": f"FCM token kaydedilirken hata oluştu: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SupabaseTestView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """Supabase realtime notification test endpoint'i"""
        try:
            from .utils import send_notification_with_preferences
            
            # Test bildirimi gönder
            title = "MotoApp Test Bildirimi"
            body = f"Merhaba {request.user.username}! Bu bir Supabase test bildirimidir."
            
            notification = send_notification_with_preferences(
                recipient_user=request.user,
                message=body,
                notification_type='test',
                sender_user=request.user,
                title=title
            )
            
            if notification:
                return Response({
                    "detail": "Supabase test bildirimi başarıyla gönderildi!",
                    "title": title,
                    "body": body,
                    "notification_id": notification.id
                })
            else:
                return Response(
                    {"detail": "Supabase test bildirimi gönderilemedi. Supabase konfigürasyonunu kontrol edin."},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
                
        except Exception as e:
            return Response(
                {"detail": f"Supabase test hatası: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )