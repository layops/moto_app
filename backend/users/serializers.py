# users/serializers.py
from rest_framework import serializers
from django.contrib.auth import get_user_model, authenticate
from posts.models import Post
from events.models import Event
from media.models import Media  

User = get_user_model()


# -------------------------------
# Kullanıcı Kayıt ve Login
# -------------------------------
class UserRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    password2 = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password', 'password2']

    def validate(self, data):
        if data['password'] != data['password2']:
            raise serializers.ValidationError("Şifreler eşleşmiyor")
        return data

    def create(self, validated_data):
        validated_data.pop('password2')
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email'),
            password=validated_data['password']
        )
        return user


class UserLoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        username = data.get('username')
        password = data.get('password')
        
        if username and password:
            user = authenticate(username=username, password=password)
            if user:
                if user.is_active:
                    data['user'] = user
                    return data
                raise serializers.ValidationError("Kullanıcı hesabı devre dışı")
            raise serializers.ValidationError("Geçersiz kullanıcı adı veya şifre")
        raise serializers.ValidationError("Kullanıcı adı ve şifre gereklidir")


# -------------------------------
# Kullanıcı Profili
# -------------------------------
class UserSerializer(serializers.ModelSerializer):
    followers_count = serializers.SerializerMethodField()
    following_count = serializers.SerializerMethodField()
    display_name = serializers.CharField(source='first_name', required=False, allow_blank=True)

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'profile_picture', 
            'followers_count', 'following_count', 'display_name',
            'bio', 'motorcycle_model', 'location', 'website',
            'phone_number', 'address'
        ]
        extra_kwargs = {
            'username': {'read_only': True},
            'email': {'read_only': True}
        }

    def get_followers_count(self, obj):
        return obj.followers.count()

    def get_following_count(self, obj):
        return obj.following.count()

    def validate_website(self, value):
        if value and value.strip():
            import re
            url_pattern = re.compile(
                r'^(https?://)?'
                r'(([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})'
                r'(:[0-9]{1,5})?'
                r'(/.*)?$'
            )
            if not url_pattern.match(value):
                if not value.startswith(('http://', 'https://')):
                    value = 'https://' + value
                    if not url_pattern.match(value):
                        raise serializers.ValidationError("Geçerli bir URL girin")
                else:
                    raise serializers.ValidationError("Geçerli bir URL girin")
        return value


# -------------------------------
# Follow Serializer
# -------------------------------
class FollowSerializer(serializers.ModelSerializer):
    followers_count = serializers.SerializerMethodField()
    following_count = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'profile_picture', 'followers_count', 'following_count']

    def get_followers_count(self, obj):
        return obj.followers.count()

    def get_following_count(self, obj):
        return obj.following.count()


# -------------------------------
# Post Serializer
# -------------------------------
class PostSerializer(serializers.ModelSerializer):
    class Meta:
        model = Post
        fields = ['id', 'title', 'content', 'created_at']


# -------------------------------
# Media Serializer
# -------------------------------
class MediaSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = Media 
        fields = ['id', 'file_url', 'description', 'uploaded_by', 'uploaded_at', 'group']

    def get_file_url(self, obj):
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(obj.file.url)
        return obj.file.url


# -------------------------------
# Event Serializer
# -------------------------------
class EventSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = ['id', 'title', 'description', 'date']