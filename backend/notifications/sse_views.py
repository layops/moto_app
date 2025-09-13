from django.http import StreamingHttpResponse
from django.contrib.auth import get_user_model
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from django.utils import timezone
import json
import time
from .models import Notification

User = get_user_model()

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def notification_stream(request):
    """
    Server-Sent Events ile gerçek zamanlı bildirim akışı
    """
    def event_stream():
        last_check = timezone.now()
        
        while True:
            try:
                # Son kontrol zamanından sonraki yeni bildirimleri al
                new_notifications = Notification.objects.filter(
                    recipient=request.user,
                    timestamp__gt=last_check,
                    is_read=False
                ).order_by('timestamp')
                
                for notification in new_notifications:
                    # SSE formatında bildirim gönder
                    data = {
                        'id': notification.id,
                        'message': notification.message,
                        'notification_type': notification.notification_type,
                        'sender': {
                            'id': notification.sender.id if notification.sender else None,
                            'username': notification.sender.username if notification.sender else None,
                        } if notification.sender else None,
                        'timestamp': notification.timestamp.isoformat(),
                        'is_read': notification.is_read,
                    }
                    
                    yield f"data: {json.dumps(data)}\n\n"
                
                last_check = timezone.now()
                
                # 2 saniye bekle
                time.sleep(2)
                
            except Exception as e:
                # Hata durumunda error event gönder
                error_data = {'error': str(e)}
                yield f"data: {json.dumps(error_data)}\n\n"
                time.sleep(5)  # Hata durumunda daha uzun bekle
    
    response = StreamingHttpResponse(
        event_stream(),
        content_type='text/event-stream'
    )
    response['Cache-Control'] = 'no-cache'
    response['Connection'] = 'keep-alive'
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Headers'] = 'Cache-Control'
    
    return response
