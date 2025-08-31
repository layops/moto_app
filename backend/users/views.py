from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.authtoken.models import Token

from django.contrib.auth import get_user_model
from .serializers import (
    UserRegisterSerializer,
    UserLoginSerializer,
    UserSerializer,
    FollowSerializer,
    PostSerializer,
    MediaSerializer,
    EventSerializer
)
from posts.models import Post
from media.models import Media
from events.models import Event

User = get_user_model()

# -------------------------------
# REGISTER & LOGIN
# -------------------------------
@method_decorator(csrf_exempt, name='dispatch')
class UserRegisterView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request, *args, **kwargs):
        serializer = UserRegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token, created = Token.objects.get_or_create(user=user)
            response_data = serializer.data
            response_data['token'] = token.key
            return Response(response_data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@method_decorator(csrf_exempt, name='dispatch')
class UserLoginView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request, *args, **kwargs):
        serializer = UserLoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            token, created = Token.objects.get_or_create(user=user)
            return Response({'token': token.key, 'username': user.username}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# -------------------------------
# PROFILE IMAGE UPLOAD
# -------------------------------
class ProfileImageUploadView(APIView):
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        user = request.user
        file_obj = request.FILES.get('profile_picture')  # 👈 Model alan adı ile aynı olmalı

        if not file_obj:
            return Response({"error": "Profil fotoğrafı yüklenmedi"}, status=status.HTTP_400_BAD_REQUEST)

        # Eski fotoğraf varsa sil
        if user.profile_picture:
            user.profile_picture.delete(save=False)

        # Dosyayı kaydet
        user.profile_picture = file_obj
        user.save()

        # Güncel kullanıcı verilerini dön
        serializer = UserSerializer(user, context={'request': request})
        return Response({
            "message": "Profil fotoğrafı başarıyla güncellendi",
            "user": serializer.data
        }, status=status.HTTP_200_OK)


# -------------------------------
# FOLLOW / FOLLOWERS / FOLLOWING
# -------------------------------
class FollowToggleView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, username):
        try:
            target_user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'error': 'Kullanıcı bulunamadı'}, status=status.HTTP_404_NOT_FOUND)

        user = request.user
        if target_user in user.following.all():
            user.following.remove(target_user)
            action = 'unfollowed'
        else:
            user.following.add(target_user)
            action = 'followed'

        return Response({'status': action}, status=status.HTTP_200_OK)


class FollowersListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, username):
        try:
            target_user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'error': 'Kullanıcı bulunamadı'}, status=status.HTTP_404_NOT_FOUND)

        followers = target_user.followers.all()
        serializer = FollowSerializer(followers, many=True, context={'request': request})
        return Response(serializer.data)


class FollowingListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, username):
        try:
            target_user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'error': 'Kullanıcı bulunamadı'}, status=status.HTTP_404_NOT_FOUND)

        following = target_user.following.all()
        serializer = FollowSerializer(following, many=True, context={'request': request})
        return Response(serializer.data)


# -------------------------------
# USER PROFILE
# -------------------------------
class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, username):
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'error': 'Kullanıcı bulunamadı'}, status=status.HTTP_404_NOT_FOUND)

        serializer = UserSerializer(user, context={'request': request})
        return Response(serializer.data)

    def put(self, request, username):
        return self.update_profile(request, username)

    def patch(self, request, username):
        return self.update_profile(request, username, partial=True)

    def update_profile(self, request, username, partial=False):
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'error': 'Kullanıcı bulunamadı'}, status=status.HTTP_404_NOT_FOUND)

        if user != request.user:
            return Response({'error': 'Bu işlem için yetkiniz yok'}, status=status.HTTP_403_FORBIDDEN)

        data = request.data.copy()
        if 'username' in data:
            del data['username']

        serializer = UserSerializer(user, data=data, partial=partial, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# -------------------------------
# USER POSTS
# -------------------------------
class UserPostsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, username):
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'error': 'Kullanıcı bulunamadı'}, status=status.HTTP_404_NOT_FOUND)

        posts = Post.objects.filter(author=user)
        serializer = PostSerializer(posts, many=True, context={'request': request})
        return Response(serializer.data)


# -------------------------------
# USER MEDIA
# -------------------------------
class UserMediaView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, username):
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'error': 'Kullanıcı bulunamadı'}, status=status.HTTP_404_NOT_FOUND)

        media_files = Media.objects.filter(uploaded_by=user)
        serializer = MediaSerializer(media_files, many=True, context={'request': request})
        return Response(serializer.data)


# -------------------------------
# USER EVENTS
# -------------------------------
class UserEventsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, username):
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'error': 'Kullanıcı bulunamadı'}, status=status.HTTP_404_NOT_FOUND)

        organized_events = Event.objects.filter(organizer=user)
        participated_events = Event.objects.filter(participants=user)
        events = organized_events | participated_events
        events = events.distinct().order_by('start_time')

        serializer = EventSerializer(events, many=True, context={'request': request})
        return Response(serializer.data)
