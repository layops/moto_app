from rest_framework import serializers
from .models import Event
from groups.models import Group
from users.serializers import UserSerializer
from django.contrib.auth import get_user_model

User = get_user_model()

class EventSerializer(serializers.ModelSerializer):
    organizer = UserSerializer(read_only=True)
    participants = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(),
        many=True,
        required=False
    )
    group = serializers.PrimaryKeyRelatedField(
        queryset=Group.objects.all(),
        required=False
    )

    class Meta:
        model = Event
        fields = [
            'id', 'group', 'organizer', 'title', 'description', 
            'location', 'start_time', 'end_time', 'participants', 
            'created_at', 'updated_at'
        ]
        read_only_fields = ('id', 'organizer', 'created_at', 'updated_at')

    def create(self, validated_data):
        participants_data = validated_data.pop('participants', [])
        event = super().create(validated_data)
        event.participants.set(participants_data)
        return event

    def update(self, instance, validated_data):
        participants_data = validated_data.pop('participants', None)
        instance = super().update(instance, validated_data)
        if participants_data is not None:
            instance.participants.set(participants_data)
        return instance
