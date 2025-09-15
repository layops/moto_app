# users/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from .serializers import (
    UserRegisterSerializer, UserLoginSerializer, UserSerializer,
    FollowSerializer
)
# from rest_framework_simplejwt.tokens import RefreshToken
import json

User = get_user_model()

class UserRegisterView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = UserRegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response({
                'user': UserSerializer(user).data,
                'message': 'Kullanıcı başarıyla oluşturuldu! Email doğrulama linki gönderildi.',
                'email_verification_required': True
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class UserLoginView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = UserLoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            # refresh = RefreshToken.for_user(user)
            return Response({
                'user': UserSerializer(user).data,
                'message': 'Giriş başarılı'
                # 'token': str(refresh.access_token),
                # 'refresh': str(refresh)
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class TokenRefreshView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        # Geçici olarak devre dışı
        pass

class EmailVerificationView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Email doğrulama token ile email'i doğrula"""
        token = request.data.get('token')
        if not token:
            return Response({'error': 'Doğrulama token gereklidir'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            from .services.supabase_auth_service import SupabaseAuthService
            
            supabase_auth = SupabaseAuthService()
            result = supabase_auth.verify_email(token)
            
            if result['success']:
                # Local user'ı da güncelle
                user_email = result['user'].email
                try:
                    user = User.objects.get(email=user_email)
                    user.email_verified = True
                    user.save()
                except User.DoesNotExist:
                    pass
                
                return Response({
                    'message': 'Email başarıyla doğrulandı!',
                    'user': result['user'].__dict__ if hasattr(result['user'], '__dict__') else None
                }, status=status.HTTP_200_OK)
            else:
                return Response({'error': result['error']}, status=status.HTTP_400_BAD_REQUEST)
                
        except ImportError:
            return Response({'error': 'Email doğrulama servisi kullanılamıyor'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception as e:
            return Response({'error': f'Email doğrulama hatası: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class ResendVerificationView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Email doğrulama linkini tekrar gönder"""
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email adresi gereklidir'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            from .services.supabase_auth_service import SupabaseAuthService
            
            supabase_auth = SupabaseAuthService()
            result = supabase_auth.resend_verification(email)
            
            if result['success']:
                return Response({
                    'message': 'Email doğrulama linki tekrar gönderildi!'
                }, status=status.HTTP_200_OK)
            else:
                return Response({'error': result['error']}, status=status.HTTP_400_BAD_REQUEST)
                
        except ImportError:
            return Response({'error': 'Email doğrulama servisi kullanılamıyor'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception as e:
            return Response({'error': f'Email tekrar gönderme hatası: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class PasswordResetView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Şifre sıfırlama linki gönder"""
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email adresi gereklidir'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            from .services.supabase_auth_service import SupabaseAuthService
            
            supabase_auth = SupabaseAuthService()
            result = supabase_auth.reset_password(email)
            
            if result['success']:
                return Response({
                    'message': 'Şifre sıfırlama linki email adresinize gönderildi!'
                }, status=status.HTTP_200_OK)
            else:
                return Response({'error': result['error']}, status=status.HTTP_400_BAD_REQUEST)
                
        except ImportError:
            return Response({'error': 'Şifre sıfırlama servisi kullanılamıyor'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception as e:
            return Response({'error': f'Şifre sıfırlama hatası: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        return Response({'error': 'Token refresh geçici olarak devre dışı'}, status=status.HTTP_501_NOT_IMPLEMENTED)

class ProfileImageUploadView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, username):
        user = get_object_or_404(User, username=username)
        if request.user != user:
            return Response({'error': 'Bu işlem için yetkiniz yok'}, status=status.HTTP_403_FORBIDDEN)
        
        if 'profile_picture' not in request.FILES:
            return Response({'error': 'Dosya bulunamadı'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            from .services.supabase_service import SupabaseStorage
            
            # Eski profil fotoğrafını sil
            if user.profile_picture:
                storage = SupabaseStorage()
                storage.delete_profile_picture(user.profile_picture)
            
            # Yeni fotoğrafı yükle
            storage = SupabaseStorage()
            file_obj = request.FILES['profile_picture']
            image_url = storage.upload_profile_picture(file_obj, user.id)
            
            # Kullanıcı modelini güncelle
            user.profile_picture = image_url
            user.save()
            
            # Güncellenmiş kullanıcı bilgilerini döndür
            serializer = UserSerializer(user, context={'request': request})
            return Response({
                'message': 'Profil fotoğrafı başarıyla güncellendi',
                'user': serializer.data
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({'error': f'Fotoğraf yükleme hatası: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class CoverImageUploadView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, username):
        user = get_object_or_404(User, username=username)
        if request.user != user:
            return Response({'error': 'Bu işlem için yetkiniz yok'}, status=status.HTTP_403_FORBIDDEN)
        
        if 'cover_picture' not in request.FILES:
            return Response({'error': 'Dosya bulunamadı'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            from .services.supabase_service import SupabaseStorage
            
            # Eski kapak fotoğrafını sil
            if user.cover_picture:
                storage = SupabaseStorage()
                storage.delete_cover_picture(user.cover_picture)
            
            # Yeni fotoğrafı yükle
            storage = SupabaseStorage()
            file_obj = request.FILES['cover_picture']
            image_url = storage.upload_cover_picture(file_obj, user.id)
            
            # Kullanıcı modelini güncelle
            user.cover_picture = image_url
            user.save()
            
            # Güncellenmiş kullanıcı bilgilerini döndür
            serializer = UserSerializer(user, context={'request': request})
            return Response({
                'message': 'Kapak fotoğrafı başarıyla güncellendi',
                'user': serializer.data
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({'error': f'Fotoğraf yükleme hatası: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class FollowToggleView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, username=None, user_id=None):
        if username:
            target_user = get_object_or_404(User, username=username)
        elif user_id:
            target_user = get_object_or_404(User, id=user_id)
        else:
            return Response({'error': 'Kullanıcı belirtilmedi'}, status=status.HTTP_400_BAD_REQUEST)
        
        if target_user == request.user:
            return Response({'error': 'Kendinizi takip edemezsiniz'}, status=status.HTTP_400_BAD_REQUEST)
        
        if request.user.following.filter(id=target_user.id).exists():
            request.user.following.remove(target_user)
            return Response({"detail": "Takip bırakıldı"}, status=status.HTTP_200_OK)
        else:
            request.user.following.add(target_user)
            
            # Takip bildirimi gönder (asenkron olarak)
            try:
                from notifications.utils import send_realtime_notification
                message = f"{request.user.get_full_name() or request.user.username} sizi takip etmeye başladı"
                
                # Bildirimi arka planda gönder (asenkron)
                import threading
                def send_notification_async():
                    try:
                        send_realtime_notification(
                            recipient_user=target_user,
                            message=message,
                            notification_type='follow',
                            sender_user=request.user
                        )
                    except Exception as e:
                        import logging
                        logger = logging.getLogger(__name__)
                        logger.error(f"Takip bildirimi gönderilemedi: {e}")
                
                # Arka planda bildirim gönder
                threading.Thread(target=send_notification_async, daemon=True).start()
                
            except Exception as e:
                # Bildirim gönderme hatası kritik değil, sadece logla
                import logging
                logger = logging.getLogger(__name__)
                logger.error(f"Takip bildirimi thread başlatılamadı: {e}")
            
            return Response({"detail": "Takip edildi"}, status=status.HTTP_200_OK)

class FollowersListView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request, username):
        user = get_object_or_404(User, username=username)
        followers = user.followers.all()
        serializer = FollowSerializer(followers, many=True)
        return Response(serializer.data)

class FollowingListView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request, username):
        user = get_object_or_404(User, username=username)
        following = user.following.all()
        serializer = FollowSerializer(following, many=True)
        return Response(serializer.data)

class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request, username):
        user = get_object_or_404(User, username=username)
        serializer = UserSerializer(user, context={'request': request})
        return Response(serializer.data)
    
    def put(self, request, username):
        user = get_object_or_404(User, username=username)
        if request.user != user:
            return Response({'error': 'Bu işlem için yetkiniz yok'}, status=status.HTTP_403_FORBIDDEN)
        
        serializer = UserSerializer(user, data=request.data, partial=True, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class UserPostsView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request, username):
        user = get_object_or_404(User, username=username)
        posts = user.posts.all().order_by('-created_at')
        from posts.serializers import PostSerializer
        serializer = PostSerializer(posts, many=True, context={'request': request})
        return Response(serializer.data)

class UserMediaView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request, username):
        user = get_object_or_404(User, username=username)
        media = user.media.all().order_by('-uploaded_at')
        from media.serializers import MediaSerializer
        serializer = MediaSerializer(media, many=True, context={'request': request})
        return Response(serializer.data)

class UserEventsView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request, username):
        user = get_object_or_404(User, username=username)
        events = user.events.all().order_by('-created_at')
        from events.serializers import EventSerializer
        serializer = EventSerializer(events, many=True, context={'request': request})
        return Response(serializer.data)

class UserLogoutView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            # refresh_token = request.data["refresh"]
            # token = RefreshToken(refresh_token)
            # token.blacklist()
            return Response({'message': 'Başarıyla çıkış yapıldı'}, status=status.HTTP_205_RESET_CONTENT)
        except Exception as e:
            return Response({'error': 'Çıkış yapılamadı'}, status=status.HTTP_400_BAD_REQUEST)

# Geçici test endpoint'i
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny

@api_view(['POST'])
@permission_classes([AllowAny])
def create_test_users(request):
    """Test kullanıcıları oluşturmak için geçici endpoint"""
    test_users = [
        {'username': 'ahmet', 'email': 'ahmet@test.com', 'first_name': 'Ahmet', 'last_name': 'Yılmaz'},
        {'username': 'mehmet', 'email': 'mehmet@test.com', 'first_name': 'Mehmet', 'last_name': 'Kaya'},
        {'username': 'ayse', 'email': 'ayse@test.com', 'first_name': 'Ayşe', 'last_name': 'Demir'},
    ]
    
    created_users = []
    
    for user_data in test_users:
        if not User.objects.filter(username=user_data['username']).exists():
            user = User.objects.create_user(
                username=user_data['username'],
                email=user_data['email'],
                first_name=user_data['first_name'],
                last_name=user_data['last_name'],
                password='test123',
                is_active=True
            )
            created_users.append(user_data['username'])
    
    return Response({
        'message': f'{len(created_users)} test kullanıcısı oluşturuldu',
        'created_users': created_users
    }, status=status.HTTP_201_CREATED)