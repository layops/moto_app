from rest_framework import serializers
from .models import Event
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

    cover_image = serializers.URLField(required=False, allow_blank=True, allow_null=True)

    class Meta:
        model = Event
        fields = [
            'id', 'group', 'group_id', 'organizer', 'title', 'description',
            'location', 'start_time', 'end_time',
            'created_at', 'updated_at', 'is_public', 'guest_limit',
            'cover_image', 'current_participant_count', 'is_full', 'is_joined'
        ]
        read_only_fields = (
            'id', 'organizer', 'created_at', 'updated_at', 
            'current_participant_count', 'is_full', 'is_joined'
        )
        extra_kwargs = {
            'title': {'required': True},
            'start_time': {'required': True},
            'is_public': {'required': True},
        }

    def get_is_joined(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.participants.filter(id=request.user.id).exists()
        return False

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