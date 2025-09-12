# moto_app/backend/media/serializers.py

from rest_framework import serializers
from .models import Media

class MediaSerializer(serializers.ModelSerializer):
    uploaded_by = serializers.ReadOnlyField(source='uploaded_by.username')
    group_name = serializers.ReadOnlyField(source='group.name')

    class Meta:
        model = Media
        fields = ['id', 'group', 'group_name', 'file_url', 'description', 'uploaded_by', 'uploaded_at']
        read_only_fields = ['uploaded_by', 'uploaded_at', 'group'] # Group alanı URL'den geldiği için read_only olabilir