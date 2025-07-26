from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404

from .models import Notification
from .serializers import NotificationSerializer, NotificationMarkReadSerializer

class NotificationListView(generics.ListAPIView):
    """
    Kimliği doğrulanmış kullanıcının bildirimlerini listeler.
    Okunmamış bildirimleri filtrelemek için `?is_read=false` kullanılabilir.
    """
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Sadece kimliği doğrulanmış kullanıcının bildirimlerini getir
        queryset = Notification.objects.filter(recipient=self.request.user)

        # Eğer 'is_read' sorgu parametresi varsa, buna göre filtrele
        is_read_param = self.request.query_params.get('is_read', None)
        if is_read_param is not None:
            if is_read_param.lower() == 'true':
                queryset = queryset.filter(is_read=True)
            elif is_read_param.lower() == 'false':
                queryset = queryset.filter(is_read=False)
        
        return queryset.order_by('-timestamp') # En yeni bildirimler en üstte

class NotificationMarkReadView(APIView):
    """
    Belirli bildirimleri okundu olarak işaretler.
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, *args, **kwargs):
        serializer = NotificationMarkReadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        notification_ids = serializer.validated_data['notification_ids']
        
        # Sadece kullanıcının kendi bildirimlerini güncellemesine izin ver
        notifications_to_update = Notification.objects.filter(
            id__in=notification_ids,
            recipient=request.user
        )
        
        updated_count = notifications_to_update.update(is_read=True)
        
        return Response(
            {"detail": f"{updated_count} bildirim okundu olarak işaretlendi."},
            status=status.HTTP_200_OK
        )

class NotificationDeleteView(generics.DestroyAPIView):
    """
    Belirli bir bildirimi siler.
    Sadece bildirim sahibi silebilir.
    """
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer # Silme işlemi için serializer gerekli değil ama tanımlandı
    permission_classes = [IsAuthenticated]

    def get_object(self):
        # URL'den gelen bildirim ID'sini al
        notification_id = self.kwargs.get('pk')
        # Sadece kimliği doğrulanmış kullanıcının kendi bildirimini silmesine izin ver
        notification = get_object_or_404(
            Notification,
            pk=notification_id,
            recipient=self.request.user
        )
        return notification