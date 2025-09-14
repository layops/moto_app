from rest_framework import serializers
from .models import Event, EventRequest
from groups.models import Group
from groups.serializers import GroupSerializer
from django.contrib.auth import get_user_model

User = get_user_model()

# Circular import'u önlemek için UserSerializer'ı lazy import edelim
def get_user_serializer():
    from users.serializers import UserSerializer
    return UserSerializer

class EventSerializer(serializers.ModelSerializer):
    organizer = serializers.SerializerMethodField()
    # participants field'ını geçici olarak kaldırıyoruz
    # participants = serializers.PrimaryKeyRelatedField(
    #     queryset=User.objects.all(),
    #     many=True,
    #     required=False
    # )
    group = GroupSerializer(read_only=True)
    group_id = serializers.PrimaryKeyRelatedField(
        queryset=Group.objects.all(),
        source='group',
        write_only=True,
        required=False,
        allow_null=True
    )
    current_participant_count = serializers.ReadOnlyField()
    is_full = serializers.ReadOnlyField()
    is_joined = serializers.SerializerMethodField()
    request_status = serializers.SerializerMethodField()
    cover_image = serializers.URLField(required=False, allow_blank=True, allow_null=True)

    class Meta:
        model = Event
        fields = [
            'id', 'group', 'group_id', 'organizer', 'title', 'description',
            'location', 'start_time', 'end_time', 'is_public', 'guest_limit',
            'requires_approval', 'cover_image', 'current_participant_count', 'is_full', 'is_joined', 'request_status',
            'created_at', 'updated_at'
        ]
        read_only_fields = (
            'id', 'organizer', 'created_at', 'updated_at',
            'current_participant_count', 'is_full', 'is_joined', 'request_status'
        )
        extra_kwargs = {
            'title': {'required': True},
            'start_time': {'required': True},
            'is_public': {'required': True},
        }

    def get_is_joined(self, obj):
        try:
            request = self.context.get('request')
            if request and request.user.is_authenticated:
                # ManyToMany field için doğru kontrol
                return request.user in obj.participants.all()
            return False
        except Exception as e:
            print(f"get_is_joined hatası: {str(e)}")
            return False
    
    def get_request_status(self, obj):
        try:
            request = self.context.get('request')
            if request and request.user.is_authenticated:
                return obj.get_user_request_status(request.user)
            return None
        except Exception as e:
            print(f"get_request_status hatası: {str(e)}")
            return None
    
    def get_organizer(self, obj):
        try:
            UserSerializer = get_user_serializer()
            return UserSerializer(obj.organizer).data
        except Exception as e:
            print(f"get_organizer hatası: {str(e)}")
            return {
                'id': obj.organizer.id,
                'username': obj.organizer.username,
                'email': obj.organizer.email
            }

    def create(self, validated_data):
        participants_data = validated_data.pop('participants', [])
        event = super().create(validated_data)
        if participants_data:
            event.participants.set(participants_data)
        return event

    def update(self, instance, validated_data):
        participants_data = validated_data.pop('participants', None)
        instance = super().update(instance, validated_data)
        if participants_data is not None:
            instance.participants.set(participants_data)
        return instance


class EventRequestSerializer(serializers.ModelSerializer):
    user = serializers.SerializerMethodField()
    # Circular reference'ı önlemek için sadece event ID'sini döndür
    event_id = serializers.IntegerField(source='event.id', read_only=True)
    event_title = serializers.CharField(source='event.title', read_only=True)
    
    class Meta:
        model = EventRequest
        fields = ['id', 'user', 'event_id', 'event_title', 'status', 'message', 'created_at', 'updated_at']
        read_only_fields = ['id', 'user', 'event_id', 'event_title', 'created_at', 'updated_at']
    
    def get_user(self, obj):
        try:
            UserSerializer = get_user_serializer()
            return UserSerializer(obj.user).data
        except Exception as e:
            print(f"get_user hatası: {str(e)}")
            return {
                'id': obj.user.id,
                'username': obj.user.username,
                'email': obj.user.email
            }