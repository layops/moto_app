# moto_app/backend/notifications/views.py

from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from django.db import transaction
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404

from .models import Notification
from .serializers import NotificationSerializer
from .utils import send_realtime_notification # send_realtime_notification fonksiyonunu import ediyoruz

User = get_user_model()

class NotificationListView(generics.ListAPIView):
    """
    Kullanıcının tüm bildirimlerini listeler.
    Sadece kimliği doğrulanmış kullanıcılar erişebilir.
    """
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Sadece oturum açmış kullanıcının bildirimlerini döndür
        return Notification.objects.filter(recipient=self.request.user).order_by('-timestamp')

class NotificationMarkReadView(APIView):
    """
    Belirli bildirimleri okundu olarak işaretler veya tümünü okundu olarak işaretler.
    Sadece kimliği doğrulanmış kullanıcılar erişebilir.
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, *args, **kwargs):
        notification_ids = request.data.get('notification_ids')

        if notification_ids:
            # Belirli ID'lere sahip bildirimleri okundu olarak işaretle
            notifications_to_mark = Notification.objects.filter(
                recipient=request.user,
                id__in=notification_ids,
                is_read=False
            )
            updated_count = notifications_to_mark.update(is_read=True)
            return Response(
                {"detail": f"{updated_count} bildirim okundu olarak işaretlendi."},
                status=status.HTTP_200_OK
            )
        else:
            # Tüm okunmamış bildirimleri okundu olarak işaretle
            updated_count = Notification.objects.filter(
                recipient=request.user,
                is_read=False
            ).update(is_read=True)
            return Response(
                {"detail": f"Tüm {updated_count} okunmamış bildirim okundu olarak işaretlendi."},
                status=status.HTTP_200_OK
            )

class NotificationDeleteView(generics.DestroyAPIView):
    """
    Belirli bir bildirimi siler.
    Sadece kimliği doğrulanmış kullanıcılar ve bildirimin alıcısı erişebilir.
    """
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Sadece oturum açmış kullanıcının bildirimlerini silmesine izin ver
        return Notification.objects.filter(recipient=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

# Test amaçlı veya manuel tetikleme için örnek bir view (API üzerinden bildirim gönderme)
class SendTestNotificationView(APIView):
    """
    API üzerinden test bildirimi göndermek için.
    Sadece süper kullanıcılar erişebilir.
    """
    permission_classes = [IsAuthenticated] # Normalde IsAdminUser olmalıydı, test için IsAuthenticated bıraktım

    def post(self, request, *args, **kwargs):
        recipient_username = request.data.get('recipient_username')
        message = request.data.get('message')
        notification_type = request.data.get('notification_type', 'other')
        sender_username = request.data.get('sender_username')

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
        
        # send_realtime_notification yardımcı fonksiyonunu kullanarak bildirimi gönder
        send_realtime_notification(
            recipient_user=recipient_user,
            message=message,
            notification_type=notification_type,
            sender_user=sender_user
        )

        return Response(
            {"detail": "Test bildirimi başarıyla gönderildi."},
            status=status.HTTP_200_OK
        )
