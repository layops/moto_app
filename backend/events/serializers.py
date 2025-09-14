from rest_framework import serializers
from .models import Event, EventRequest
from groups.models import Group
from groups.serializers import GroupSerializer
from users.serializers import UserSerializer
from django.contrib.auth import get_user_model

User = get_user_model()

class EventSerializer(serializers.ModelSerializer):
    organizer = UserSerializer(read_only=True)
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
    user = UserSerializer(read_only=True)
    event = EventSerializer(read_only=True)
    
    class Meta:
        model = EventRequest
        fields = ['id', 'user', 'event', 'status', 'message', 'created_at', 'updated_at']
        read_only_fields = ['id', 'user', 'event', 'created_at', 'updated_at']