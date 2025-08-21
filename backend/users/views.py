from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from rest_framework.parsers import MultiPartParser, FormParser

from django.db.models.functions import Lower
from django.db.models import Q
from unidecode import unidecode
from core_api.unaccent import Unaccent

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

from groups.models import Group
from groups.serializers import GroupSerializer
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
# USER SEARCH
# -------------------------------
class UserSearchView(generics.ListAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        query = self.request.query_params.get('q', None)
        if query:
            normalized_query = unidecode(query.lower())
            annotated = queryset.annotate(norm_username=Unaccent(Lower('username')))
            return annotated.filter(norm_username__icontains=normalized_query)
        return queryset


# -------------------------------
# GROUP SEARCH
# -------------------------------
class GroupSearchView(generics.ListAPIView):
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        query = self.request.query_params.get('q', None)
        if query:
            normalized_query = unidecode(query.lower())
            annotated = queryset.annotate(
                norm_name=Unaccent(Lower('name')),
                norm_desc=Unaccent(Lower('description'))
            )
            return annotated.filter(
                Q(norm_name__icontains=normalized_query) |
                Q(norm_desc__icontains=normalized_query)
            )
        return queryset


# -------------------------------
# PROFILE IMAGE UPLOAD
# -------------------------------
class ProfileImageUploadView(APIView):
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        user = request.user
        file_obj = request.data.get('profile_picture')

        if not file_obj:
            return Response({"error": "No image provided."}, status=status.HTTP_400_BAD_REQUEST)

        user.profile_picture = file_obj
        user.save()

        return Response({"message": "Profile image updated successfully."}, status=status.HTTP_200_OK)


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

        media_files = MediaFile.objects.filter(user=user)
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

        events = Event.objects.filter(user=user)
        serializer = EventSerializer(events, many=True, context={'request': request})
        return Response(serializer.data)
