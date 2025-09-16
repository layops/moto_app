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
        
        # Email verification temporarily disabled - Supabase removed
        return Response({
            'error': 'Email doğrulama servisi geçici olarak devre dışı',
            'message': 'Supabase kaldırıldı, email doğrulama servisi güncelleniyor'
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

class ResendVerificationView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Email doğrulama linkini tekrar gönder"""
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email adresi gereklidir'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Resend verification temporarily disabled - Supabase removed
        return Response({
            'error': 'Email tekrar gönderme servisi geçici olarak devre dışı',
            'message': 'Supabase kaldırıldı, email servisi güncelleniyor'
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

class PasswordResetView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Şifre sıfırlama linki gönder"""
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email adresi gereklidir'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Password reset temporarily disabled - Supabase removed
        return Response({
            'error': 'Şifre sıfırlama servisi geçici olarak devre dışı',
            'message': 'Supabase kaldırıldı, şifre sıfırlama servisi güncelleniyor'
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

class GoogleAuthView(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request):
        """Google OAuth URL'i döndür (PKCE ile)"""
        try:
            from .services.google_oauth_service import GoogleOAuthService
            
            google_auth = GoogleOAuthService()
            redirect_to = request.query_params.get('redirect_to')
            
            result = google_auth.get_auth_url(redirect_to)
            
            if result['success']:
                return Response({
                    'auth_url': result['auth_url'],
                    'state': result['state'],  # Frontend'e gönder
                    'message': 'Google OAuth URL oluşturuldu'
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'error': 'Google OAuth URL alınırken hata: Lütfen normal email/şifre ile giriş yapın',
                    'message': 'Lütfen normal email/şifre ile giriş yapın'
                }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
                
        except Exception as e:
            return Response({
                'error': 'Google OAuth URL alınırken hata: Lütfen normal email/şifre ile giriş yapın',
                'message': 'Lütfen normal email/şifre ile giriş yapın'
            }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

class GoogleCallbackView(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request):
        """Google OAuth callback'i işle (PKCE ile)"""
        code = request.query_params.get('code')
        state = request.query_params.get('state')
        
        if not code:
            return Response({'error': 'Authorization code bulunamadı'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            from .services.google_oauth_service import GoogleOAuthService
            
            google_auth = GoogleOAuthService()
            result = google_auth.handle_callback(code, state)
            
            if result['success']:
                user = result['user']
                
                return Response({
                    'message': 'Google ile giriş başarılı!',
                    'user': UserSerializer(user).data,
                    'access_token': result['access_token'],
                    'refresh_token': result['refresh_token']
                }, status=status.HTTP_200_OK)
            else:
                return Response({'error': result['error']}, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            return Response({
                'error': f'Google OAuth callback hatası: {str(e)}',
                'message': 'Google OAuth servisi aktif değil'
            }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

class VerifyTokenView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Access token'ı doğrula ve kullanıcı bilgisi döndür"""
        access_token = request.data.get('access_token')
        if not access_token:
            return Response({'error': 'Access token gereklidir'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            from .services.google_oauth_service import GoogleOAuthService
            
            google_auth = GoogleOAuthService()
            result = google_auth.verify_token(access_token)
            
            if result['success']:
                user = result['user']
                return Response({
                    'user': UserSerializer(user).data,
                    'message': 'Token doğrulandı'
                }, status=status.HTTP_200_OK)
            else:
                return Response({'error': result['error']}, status=status.HTTP_401_UNAUTHORIZED)
                
        except Exception as e:
            return Response({'error': f'Token doğrulama hatası: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class GoogleAuthTestView(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request):
        """Google OAuth test endpoint'i"""
        try:
            from .services.google_oauth_service import GoogleOAuthService
            
            google_auth = GoogleOAuthService()
            
            # Google OAuth servisini test et
            if not google_auth.is_available:
                return Response({
                    'status': 'error',
                    'message': 'Google OAuth servisi kullanılamıyor',
                    'environment_check': {
                        'GOOGLE_CLIENT_ID': bool(google_auth.client_id),
                        'GOOGLE_CLIENT_SECRET': bool(google_auth.client_secret),
                        'GOOGLE_REDIRECT_URI': bool(google_auth.redirect_uri),
                    }
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
            # Google OAuth URL'i oluştur
            result = google_auth.get_auth_url()
            
            if result['success']:
                return Response({
                    'status': 'success',
                    'message': 'Google OAuth entegrasyonu hazır!',
                    'auth_url': result['auth_url'],
                    'test_endpoints': {
                        'google_auth': '/api/users/auth/google/',
                        'callback': '/api/users/auth/callback/',
                        'verify_token': '/api/users/verify-token/'
                    }
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'status': 'error',
                    'message': result['error']
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            return Response({
                'status': 'error',
                'message': f'Test hatası: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class ProfileImageUploadView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, username):
        user = get_object_or_404(User, username=username)
        if request.user != user:
            return Response({'error': 'Bu işlem için yetkiniz yok'}, status=status.HTTP_403_FORBIDDEN)
        
        if 'profile_picture' not in request.FILES:
            return Response({'error': 'Dosya bulunamadı'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Profile image upload temporarily disabled - Supabase removed
        return Response({
            'error': 'Profil fotoğrafı yükleme servisi geçici olarak devre dışı',
            'message': 'Supabase kaldırıldı, dosya yükleme servisi güncelleniyor'
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

class CoverImageUploadView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, username):
        user = get_object_or_404(User, username=username)
        if request.user != user:
            return Response({'error': 'Bu işlem için yetkiniz yok'}, status=status.HTTP_403_FORBIDDEN)
        
        if 'cover_picture' not in request.FILES:
            return Response({'error': 'Dosya bulunamadı'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Cover image upload temporarily disabled - Supabase removed
        return Response({
            'error': 'Kapak fotoğrafı yükleme servisi geçici olarak devre dışı',
            'message': 'Supabase kaldırıldı, dosya yükleme servisi güncelleniyor'
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

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