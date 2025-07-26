from rest_framework import serializers
from .models import Notification
from users.serializers import UserSerializer # Gönderici ve alıcı kullanıcı bilgilerini göstermek için

class NotificationSerializer(serializers.ModelSerializer):
    # Gönderici ve alıcı alanlarını UserSerializer ile serileştiriyoruz
    sender = UserSerializer(read_only=True)
    recipient = UserSerializer(read_only=True)

    # content_object'in detaylarını göstermek için bir alan ekleyebiliriz.
    # Ancak GenericForeignKey'i doğrudan serileştirmek karmaşık olabilir.
    # Şimdilik sadece ilgili nesnenin türünü ve ID'sini göstereceğiz.
    # İleride ihtiyaca göre bu kısmı genişletebiliriz.
    content_object_type = serializers.CharField(source='content_type.model', read_only=True)
    content_object_id = serializers.IntegerField(source='object_id', read_only=True)

    class Meta:
        model = Notification
        fields = [
            'id',
            'recipient',
            'sender',
            'message',
            'notification_type',
            'content_object_type', # İlgili nesnenin model adı
            'content_object_id',   # İlgili nesnenin ID'si
            'is_read',
            'timestamp',
        ]
        read_only_fields = [
            'id',
            'recipient',
            'sender',
            'message',
            'notification_type',
            'content_object_type',
            'content_object_id',
            'timestamp',
        ]

class NotificationMarkReadSerializer(serializers.Serializer):
    """
    Bildirimleri okundu olarak işaretlemek için kullanılan serileştirici.
    """
    notification_ids = serializers.ListField(
        child=serializers.IntegerField(),
        min_length=1,
        write_only=True,
        help_text="Okundu olarak işaretlenecek bildirim ID'lerinin listesi."
    )
