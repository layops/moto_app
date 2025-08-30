from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from django.contrib.auth import get_user_model
from .models import Notification
from .serializers import NotificationSerializer
from .utils import send_realtime_notification

User = get_user_model()

class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(recipient=self.request.user).order_by('-timestamp')

class NotificationMarkReadView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, *args, **kwargs):
        notification_ids = request.data.get('notification_ids')
        if notification_ids:
            notifications_to_mark = Notification.objects.filter(
                recipient=request.user,
                id__in=notification_ids,
                is_read=False
            )
            updated_count = notifications_to_mark.update(is_read=True)
            return Response({"detail": f"{updated_count} bildirim okundu olarak işaretlendi."})
        else:
            updated_count = Notification.objects.filter(
                recipient=request.user,
                is_read=False
            ).update(is_read=True)
            return Response({"detail": f"Tüm {updated_count} okunmamış bildirim okundu olarak işaretlendi."})

class NotificationDeleteView(generics.DestroyAPIView):
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(recipient=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

class SendTestNotificationView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        recipient_username = request.data.get('recipient_username')
        message = request.data.get('message')
        notification_type = request.data.get('notification_type', 'other')
        sender_username = request.data.get('sender_username')

        if not recipient_username or not message:
            return Response({"detail": "Alıcı kullanıcı adı ve mesaj gereklidir."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            recipient_user = User.objects.get(username=recipient_username)
        except User.DoesNotExist:
            return Response({"detail": f"Alıcı kullanıcı '{recipient_username}' bulunamadı."}, status=status.HTTP_404_NOT_FOUND)

        sender_user = None
        if sender_username:
            try:
                sender_user = User.objects.get(username=sender_username)
            except User.DoesNotExist:
                return Response({"detail": f"Gönderen kullanıcı '{sender_username}' bulunamadı."}, status=status.HTTP_404_NOT_FOUND)

        send_realtime_notification(
            recipient_user=recipient_user,
            message=message,
            notification_type=notification_type,
            sender_user=sender_user
        )
        return Response({"detail": "Test bildirimi başarıyla gönderildi."}, status=status.HTTP_200_OK)
