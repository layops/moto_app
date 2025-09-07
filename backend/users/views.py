# users/views.py
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import get_object_or_404
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model, authenticate
from django.conf import settings
import logging
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
from .services.supabase_service import SupabaseStorage

User = get_user_model()
logger = logging.getLogger(__name__)

# -------------------------------
# REGISTER & LOGIN
# -------------------------------
@method_decorator(csrf_exempt, name='dispatch')
class UserRegisterView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request, *args, **kwargs):
        try:
            serializer = UserRegisterSerializer(data=request.data)
            if serializer.is_valid():
                user = serializer.save()
                token, created = Token.objects.get_or_create(user=user)
                response_data = serializer.data
                response_data['token'] = token.key
                return Response(response_data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Register error: {str(e)}", exc_info=True)
            return Response(
                {'error': 'Kayıt sırasında bir hata oluştu'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

@method_decorator(csrf_exempt, name='dispatch')
class UserLoginView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request, *args, **kwargs):
        try:
            username = request.data.get('username')
            password = request.data.get('password')
            
            if not username or not password:
                return Response(
                    {'error': 'Kullanıcı adı ve şifre gereklidir'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            user = authenticate(username=username, password=password)
            
            if user is not None:
                if user.is_active:
                    token, created = Token.objects.get_or_create(user=user)
                    return Response({
                        'token': token.key, 
                        'username': user.username,
                        'user_id': user.id,
                        'email': user.email
                    }, status=status.HTTP_200_OK)
                else:
                    return Response(
                        {'error': 'Hesap devre dışı bırakılmış'}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
            else:
                return Response(
                    {'error': 'Geçersiz kullanıcı adı veya şifre'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
        except Exception as e:
            logger.error(f"Login error: {str(e)}", exc_info=True)
            if settings.DEBUG:
                return Response(
                    {'error': f'Login hatası: {str(e)}'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
            return Response(
                {'error': 'Giriş sırasında bir hata oluştu'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

# -------------------------------
# PROFILE IMAGE UPLOAD 
# -------------------------------
class ProfileImageUploadView(APIView):
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [IsAuthenticated]

    def post(self, request, username, *args, **kwargs):
        if request.user.username != username:
            return Response(
                {"error": "Bu işlem için yetkiniz yok"}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        user = request.user
        file_obj = request.FILES.get('profile_picture')

        if not file_obj:
            return Response(
                {"error": "Profil fotoğrafı yüklenmedi"}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        if file_obj.content_type not in allowed_types:
            return Response(
                {"error": "Geçersiz dosya formatı. Sadece JPEG, PNG, GIF veya WebP yükleyebilirsiniz."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if file_obj.size > 5 * 1024 * 1024:
            return Response(
                {"error": "Dosya boyutu 5MB'ı aşamaz"},
                status=status.HTTP_400_BAD_REQUEST
            )

        storage = SupabaseStorage()

        if user.profile_picture:
            try:
                storage.delete_profile_picture(user.profile_picture)
            except Exception as e:
                logger.warning(f"Eski profil resmi silinemedi: {str(e)}")

        try:
            image_url = storage.upload_profile_picture(file_obj, user.id)
            user.profile_picture = image_url
            user.save()
            serializer = UserSerializer(user, context={'request': request})
            return Response({
                "message": "Profil fotoğrafı başarıyla güncellendi",
                "user": serializer.data
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Profil resmi yükleme hatası: {str(e)}", exc_info=True)
            return Response(
                {"error": f"Dosya yüklenirken bir hata oluştu: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

# -------------------------------
# COVER IMAGE UPLOAD (YENİ EKLENEN)
# -------------------------------
class CoverImageUploadView(APIView):
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [IsAuthenticated]

    def post(self, request, username, *args, **kwargs):
        if request.user.username != username:
            return Response(
                {"error": "Bu işlem için yetkiniz yok"}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        user = request.user
        file_obj = request.FILES.get('cover_picture')
        
        if not file_obj:
            return Response(
                {"error": "Kapak fotoğrafı yüklenmedi"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        if file_obj.content_type not in allowed_types:
            return Response(
                {"error": "Geçersiz dosya formatı. Sadece JPEG, PNG, GIF veya WebP yükleyebilirsiniz."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if file_obj.size > 10 * 1024 * 1024:
            return Response(
                {"error": "Dosya boyutu 10MB'ı aşamaz"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        storage = SupabaseStorage()
        
        if user.cover_picture:
            try:
                storage.delete_cover_picture(user.cover_picture)
            except Exception as e:
                logger.warning(f"Eski kapak resmi silinemedi: {str(e)}")

        try:
            image_url = storage.upload_cover_picture(file_obj, user.id)
            user.cover_picture = image_url
            user.save()
            serializer = UserSerializer(user, context={'request': request})
            return Response({
                "message": "Kapak fotoğrafı başarıyla güncellendi",
                "user": serializer.data
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Kapak resmi yükleme hatası: {str(e)}", exc_info=True)
            return Response(
                {"error": f"Dosya yüklenirken bir hata oluştu: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

# -------------------------------
# FOLLOW / FOLLOWERS / FOLLOWING
# -------------------------------
class FollowToggleView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, username=None, user_id=None):
        if username:
            target_user = get_object_or_404(User, username=username)
        elif user_id:
            target_user = get_object_or_404(User, id=user_id)
        else:
            return Response({"detail": "Kullanıcı belirtilmedi"}, status=status.HTTP_400_BAD_REQUEST)

        if target_user == request.user:
            return Response({"detail": "Kendini takip edemezsin"}, status=status.HTTP_400_BAD_REQUEST)

        if request.user.following.filter(id=target_user.id).exists():
            request.user.following.remove(target_user)
            return Response({"detail": "Takipten çıkıldı"}, status=status.HTTP_200_OK)
        else:
            request.user.following.add(target_user)
            return Response({"detail": "Takip edildi"}, status=status.HTTP_200_OK)

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
        if 'email' in data:
            del data['email']

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

        # Sadece genel post'ları getir (grup post'ları hariç)
        posts = Post.objects.filter(author=user, group__isnull=True)
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

# -------------------------------
# FOLLOWERS / FOLLOWING LIST
# -------------------------------
class FollowersListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, username):
        user = get_object_or_404(User, username=username)
        followers = user.followers.all()  # Assuming related_name='followers' on User.following
        serializer = UserSerializer(followers, many=True, context={'request': request})
        return Response(serializer.data)

class FollowingListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, username):
        user = get_object_or_404(User, username=username)
        following = user.following.all()  # Assuming related_name='following' on User model
        serializer = UserSerializer(following, many=True, context={'request': request})
        return Response(serializer.data)
    


# -------------------------------
# Logout
# -------------------------------

class UserLogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        # Eğer token kullanıyorsan burada token'ı blacklist'e ekleyebilirsin
        # Basit kullanım için sadece frontend tarafında logout yapılacak
        return Response({"detail": "Başarıyla çıkış yapıldı"}, status=200)