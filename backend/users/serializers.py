from rest_framework import serializers
from django.contrib.auth import get_user_model
from posts.models import Post
from events.models import Event
from media.models import Media  # <-- Burada MediaFile yerine Media kullanıyoruz

User = get_user_model()


# -------------------------------
# Kullanıcı Kayıt ve Login
# -------------------------------
class UserRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password']

    def create(self, validated_data):
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
        from django.contrib.auth import authenticate
        user = authenticate(username=data['username'], password=data['password'])
        if user and user.is_active:
            data['user'] = user
            return data
        raise serializers.ValidationError("Geçersiz kullanıcı adı veya şifre")


# -------------------------------
# Kullanıcı Profili
# -------------------------------
class UserSerializer(serializers.ModelSerializer):
    followers_count = serializers.SerializerMethodField()
    following_count = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'profile_picture', 'followers_count', 'following_count']

    def get_followers_count(self, obj):
        return obj.followers.count() if hasattr(obj, 'followers') else 0

    def get_following_count(self, obj):
        return obj.following.count() if hasattr(obj, 'following') else 0


# -------------------------------
# Follow Serializer
# -------------------------------
class FollowSerializer(serializers.ModelSerializer):
    followers_count = serializers.SerializerMethodField()
    following_count = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'followers_count', 'following_count']

    def get_followers_count(self, obj):
        return obj.followers.count() if hasattr(obj, 'followers') else 0

    def get_following_count(self, obj):
        return obj.following.count() if hasattr(obj, 'following') else 0


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
        model = Media  # MediaFile değil Media
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
