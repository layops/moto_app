# users/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from django.http import HttpResponse
from .serializers import (
    UserRegisterSerializer, UserLoginSerializer, UserSerializer,
    FollowSerializer, ChangePasswordSerializer
)
from rest_framework_simplejwt.tokens import RefreshToken
import json
import os

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
            refresh = RefreshToken.for_user(user)
            return Response({
                'user': UserSerializer(user).data,
                'message': 'Giriş başarılı',
                'access': str(refresh.access_token),
                'refresh': str(refresh)
            }, status=status.HTTP_200_OK)
        
        print(f"DEBUG: Serializer errors: {serializer.errors}")
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
        import logging
        logger = logging.getLogger(__name__)
        
        try:
            logger.info("Google OAuth URL isteği alındı")
            from .services.google_oauth_service import GoogleOAuthService
            
            google_auth = GoogleOAuthService()
            logger.info(f"Google OAuth servisi oluşturuldu. Available: {google_auth.is_available}")
            
            if not google_auth.is_available:
                logger.error("Google OAuth servisi kullanılamıyor - credentials eksik")
                logger.error(f"Environment variables:")
                logger.error(f"  GOOGLE_CLIENT_ID: {os.environ.get('GOOGLE_CLIENT_ID', 'NOT_SET')}")
                logger.error(f"  GOOGLE_CLIENT_SECRET: {'SET' if os.environ.get('GOOGLE_CLIENT_SECRET') else 'NOT_SET'}")
                logger.error(f"  GOOGLE_REDIRECT_URI: {os.environ.get('GOOGLE_REDIRECT_URI', 'NOT_SET')}")
                
                return Response({
                    'error': 'Google OAuth servisi kullanılamıyor',
                    'message': 'Google OAuth credentials eksik. Lütfen normal email/şifre ile giriş yapın',
                    'debug': {
                        'client_id': bool(google_auth.client_id),
                        'client_secret': bool(google_auth.client_secret),
                        'redirect_uri': google_auth.redirect_uri,
                        'env_client_id': bool(os.environ.get('GOOGLE_CLIENT_ID')),
                        'env_client_secret': bool(os.environ.get('GOOGLE_CLIENT_SECRET')),
                        'env_redirect_uri': bool(os.environ.get('GOOGLE_REDIRECT_URI'))
                    }
                }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
            
            redirect_to = request.query_params.get('redirect_to')
            logger.info(f"Redirect_to parametresi: {redirect_to}")
            
            result = google_auth.get_google_auth_url(redirect_to)
            logger.info(f"Google OAuth URL sonucu: {result}")
            
            if result['success']:
                logger.info("Google OAuth URL başarıyla oluşturuldu")
                return Response({
                    'auth_url': result['auth_url'],
                    'state': result['state'],  # Frontend'e gönder
                    'message': 'Google OAuth URL oluşturuldu'
                }, status=status.HTTP_200_OK)
            else:
                logger.error(f"Google OAuth URL oluşturulamadı: {result.get('error')}")
                return Response({
                    'error': result.get('error', 'Google OAuth URL oluşturulamadı'),
                    'message': 'Lütfen normal email/şifre ile giriş yapın'
                }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
                
        except Exception as e:
            logger.error(f"Google OAuth URL hatası: {str(e)}", exc_info=True)
            return Response({
                'error': f'Google OAuth URL hatası: {str(e)}',
                'message': 'Lütfen normal email/şifre ile giriş yapın'
            }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

class GoogleCallbackView(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request):
        """Google OAuth callback'i işle - JSON API response ve HTML sayfası döndür"""
        code = request.query_params.get('code')
        state = request.query_params.get('state')
        
        # User-Agent kontrolü - API çağrısı mı yoksa tarayıcı mı?
        user_agent = request.META.get('HTTP_USER_AGENT', '').lower()
        is_api_call = 'dart' in user_agent or 'flutter' in user_agent or request.META.get('HTTP_ACCEPT', '').startswith('application/json')
        
        if not code:
            if is_api_call:
                return Response({
                    'success': False,
                    'error': 'Authorization code bulunamadı',
                    'message': 'Geçersiz callback URL'
                }, status=status.HTTP_400_BAD_REQUEST)
            else:
                # Tarayıcı için HTML sayfası
                error_html = """
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Google OAuth Hatası</title>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <style>
                        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
                        .error { color: #d32f2f; }
                        .url-box { background: #f5f5f5; padding: 20px; margin: 20px 0; border-radius: 8px; word-break: break-all; }
                    </style>
                </head>
                <body>
                    <h1 class="error">Google OAuth Hatası</h1>
                    <p>Authorization code bulunamadı.</p>
                    <div class="url-box">
                        <strong>Mevcut URL:</strong><br>
                        <span id="currentUrl"></span>
                    </div>
                    <p>Lütfen Flutter uygulamasında bu URL'yi girin.</p>
                    <script>
                        document.getElementById('currentUrl').textContent = window.location.href;
                    </script>
                </body>
                </html>
                """
                return HttpResponse(error_html, content_type='text/html')
        
        try:
            from .services.google_oauth_service import GoogleOAuthService
            
            google_auth = GoogleOAuthService()
            result = google_auth.handle_oauth_callback(code, state)
            
            if result['success']:
                user = result['user']
                
                # User data'yı JSON'a çevir
                user_data = {
                    'id': user.id,
                    'username': user.username,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name,
                    'profile_picture': user.profile_picture,
                    'email_verified': user.email_verified,
                }
                
                if is_api_call:
                    # API çağrısı için JSON response
                    return Response({
                        'success': True,
                        'message': 'Google OAuth giriş başarılı',
                        'user': user_data,
                        'access_token': result.get('access_token'),
                        'refresh_token': result.get('refresh_token'),
                    }, status=status.HTTP_200_OK)
                else:
                    # Tarayıcı için HTML sayfası + Deep Link
                    import json
                    import base64
                    
                    # User data ve token'ları base64 encode et
                    user_data_json = json.dumps(user_data)
                    user_data_encoded = base64.b64encode(user_data_json.encode()).decode()
                    
                    # Token'ları da encode et
                    token_data = {
                        'access_token': result.get('access_token'),
                        'refresh_token': result.get('refresh_token'),
                    }
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.info(f"Token data before encode: {token_data}")
                    token_data_json = json.dumps(token_data)
                    token_data_encoded = base64.b64encode(token_data_json.encode()).decode()
                    logger.info(f"Token data encoded length: {len(token_data_encoded)}")
                    
                    success_html = f"""
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <title>Google OAuth Başarılı</title>
                        <meta charset="utf-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1">
                        <style>
                            body {{ font-family: Arial, sans-serif; text-align: center; padding: 50px; }}
                            .success {{ color: #2e7d32; }}
                            .url-box {{ background: #f5f5f5; padding: 20px; margin: 20px 0; border-radius: 8px; word-break: break-all; }}
                            .user-info {{ background: #e8f5e8; padding: 15px; margin: 20px 0; border-radius: 8px; }}
                            .copy-btn {{ background: #1976d2; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; }}
                            .copy-btn:hover {{ background: #1565c0; }}
                        </style>
                    </head>
                    <body>
                        <h1 class="success">✅ Google ile Giriş Başarılı!</h1>
                        <div class="user-info">
                            <h3>Hoş geldiniz, {user.get_full_name() or user.username}!</h3>
                            <p><strong>Email:</strong> {user.email}</p>
                            <p><strong>Kullanıcı Adı:</strong> {user.username}</p>
                        </div>
                        
                        <h3>Flutter Uygulamasına Otomatik Yönlendirme:</h3>
                        <p>Flutter uygulamanıza otomatik olarak yönlendiriliyorsunuz...</p>
                        <div class="url-box">
                            <span id="callbackUrl"></span>
                            <br><br>
                            <button class="copy-btn" onclick="openFlutterApp()">Flutter Uygulamasını Aç</button>
                            <br><br>
                            <button class="copy-btn" onclick="copyUrl()" style="background-color: #6c757d;">URL'yi Kopyala</button>
                        </div>
                        
                        <p><strong>Not:</strong> Eğer otomatik yönlendirme çalışmazsa:</p>
                        <ol>
                            <li>Yukarıdaki "Flutter Uygulamasını Aç" butonuna tıklayın</li>
                            <li>Hala çalışmazsa "URL'yi Kopyala" butonuna tıklayın</li>
                            <li>Kopyalanan URL'yi Flutter uygulamasına yapıştırın</li>
                        </ol>
                        
                        <script>
                            document.getElementById('callbackUrl').textContent = window.location.href;
                            
                            // Otomatik Flutter uygulamasına yönlendirme
                            function openFlutterApp() {{
                                const currentUrl = window.location.href;
                                const flutterUrl = 'motoapp://oauth/success?user_data=' + encodeURIComponent('{user_data_encoded}') + '&token_data=' + encodeURIComponent('{token_data_encoded}');
                                
                                console.log('Attempting to open Flutter app with URL:', flutterUrl);
                                
                                // Flutter uygulamasını açmayı dene
                                const link = document.createElement('a');
                                link.href = flutterUrl;
                                link.style.display = 'none';
                                document.body.appendChild(link);
                                link.click();
                                document.body.removeChild(link);
                                
                                // Fallback: 3 saniye sonra kullanıcıyı bilgilendir
                                setTimeout(function() {{
                                    alert('Flutter uygulaması açılmadı. Lütfen uygulamayı manuel olarak açın.');
                                }}, 3000);
                            }}
                            
                            // URL'yi kopyalama fonksiyonu
                            function copyUrl() {{
                                const url = window.location.href;
                                navigator.clipboard.writeText(url).then(function() {{
                                    alert('URL panoya kopyalandı! Flutter uygulamasına yapıştırabilirsiniz.');
                                }}).catch(function(err) {{
                                    console.error('URL kopyalama hatası:', err);
                                    // Fallback: textarea kullanarak kopyala
                                    const textArea = document.createElement('textarea');
                                    textArea.value = url;
                                    document.body.appendChild(textArea);
                                    textArea.select();
                                    document.execCommand('copy');
                                    document.body.removeChild(textArea);
                                    alert('URL panoya kopyalandı! Flutter uygulamasına yapıştırabilirsiniz.');
                                }});
                            }}
                            
                            // Sayfa yüklendiğinde otomatik yönlendirme
                            window.onload = function() {{
                                // Hemen dene
                                openFlutterApp();
                                
                                // 1 saniye sonra tekrar dene
                                setTimeout(openFlutterApp, 1000);
                                
                                // 2 saniye sonra son kez dene
                                setTimeout(openFlutterApp, 2000);
                            }};
                            
                            // Sayfa görünür olduğunda da dene (visibility API)
                            document.addEventListener('visibilitychange', function() {{
                                if (!document.hidden) {{
                                    openFlutterApp();
                                }}
                            }});
                        </script>
                    </body>
                    </html>
                    """
                    return HttpResponse(success_html, content_type='text/html')
            else:
                if is_api_call:
                    # Hata durumu için JSON response
                    return Response({
                        'success': False,
                        'error': result.get('error', 'Google OAuth callback hatası'),
                        'message': 'Google ile giriş başarısız'
                    }, status=status.HTTP_400_BAD_REQUEST)
                else:
                    # Tarayıcı için HTML sayfası
                    error_html = f"""
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <title>Google OAuth Hatası</title>
                        <meta charset="utf-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1">
                        <style>
                            body {{ font-family: Arial, sans-serif; text-align: center; padding: 50px; }}
                            .error {{ color: #d32f2f; }}
                            .url-box {{ background: #f5f5f5; padding: 20px; margin: 20px 0; border-radius: 8px; word-break: break-all; }}
                        </style>
                    </head>
                    <body>
                        <h1 class="error">Google OAuth Hatası</h1>
                        <p><strong>Hata:</strong> {result.get('error', 'Google OAuth callback hatası')}</p>
                        <div class="url-box">
                            <strong>Mevcut URL:</strong><br>
                            <span id="currentUrl"></span>
                        </div>
                        <p>Lütfen Flutter uygulamasında bu URL'yi girin.</p>
                        <script>
                            document.getElementById('currentUrl').textContent = window.location.href;
                        </script>
                    </body>
                    </html>
                    """
                    return HttpResponse(error_html, content_type='text/html')
                
        except Exception as e:
            if is_api_call:
                # Exception durumu için JSON response
                return Response({
                    'success': False,
                    'error': f'Google OAuth callback hatası: {str(e)}',
                    'message': 'Google ile giriş sırasında beklenmeyen hata oluştu'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            else:
                # Tarayıcı için HTML sayfası
                error_html = f"""
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Google OAuth Hatası</title>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <style>
                        body {{ font-family: Arial, sans-serif; text-align: center; padding: 50px; }}
                        .error {{ color: #d32f2f; }}
                        .url-box {{ background: #f5f5f5; padding: 20px; margin: 20px 0; border-radius: 8px; word-break: break-all; }}
                    </style>
                </head>
                <body>
                    <h1 class="error">Google OAuth Hatası</h1>
                    <p><strong>Hata:</strong> {str(e)}</p>
                    <div class="url-box">
                        <strong>Mevcut URL:</strong><br>
                        <span id="currentUrl"></span>
                    </div>
                    <p>Lütfen Flutter uygulamasında bu URL'yi girin.</p>
                    <script>
                        document.getElementById('currentUrl').textContent = window.location.href;
                    </script>
                </body>
                </html>
                """
                return HttpResponse(error_html, content_type='text/html')

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
            result = google_auth.get_user_from_token(access_token)
            
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
            # Environment variables'ları direkt kontrol et
            env_debug = {
                'GOOGLE_CLIENT_ID': os.environ.get('GOOGLE_CLIENT_ID', 'NOT_SET'),
                'GOOGLE_CLIENT_SECRET': 'SET' if os.environ.get('GOOGLE_CLIENT_SECRET') else 'NOT_SET',
                'GOOGLE_REDIRECT_URI': os.environ.get('GOOGLE_REDIRECT_URI', 'NOT_SET'),
                'GOOGLE_CALLBACK_URL': os.environ.get('GOOGLE_CALLBACK_URL', 'NOT_SET'),
            }
            
            # Settings'den de kontrol et
            from django.conf import settings
            settings_debug = {
                'GOOGLE_CLIENT_ID': settings.GOOGLE_CLIENT_ID[:20] + '...' if settings.GOOGLE_CLIENT_ID else 'None',
                'GOOGLE_CLIENT_SECRET': 'SET' if settings.GOOGLE_CLIENT_SECRET else 'None',
                'GOOGLE_REDIRECT_URI': settings.GOOGLE_REDIRECT_URI,
            }
            
            from .services.google_oauth_service import GoogleOAuthService
            google_auth = GoogleOAuthService()
            
            # Google OAuth servisini test et
            if not google_auth.is_available:
                return Response({
                    'status': 'error',
                    'message': 'Google OAuth servisi kullanılamıyor',
                    'environment_variables': env_debug,
                    'settings_variables': settings_debug,
                    'service_check': {
                        'GOOGLE_CLIENT_ID': bool(google_auth.client_id),
                        'GOOGLE_CLIENT_SECRET': bool(google_auth.client_secret),
                        'GOOGLE_REDIRECT_URI': bool(google_auth.redirect_uri),
                    },
                    'debug_info': {
                        'client_id_value': google_auth.client_id[:20] + '...' if google_auth.client_id else None,
                        'redirect_uri_value': google_auth.redirect_uri,
                    }
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
            # Google OAuth URL'i oluştur
            result = google_auth.get_google_auth_url()
            
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
        
        try:
            # Dosya boyutu kontrolü (5MB limit)
            profile_picture = request.FILES['profile_picture']
            if profile_picture.size > 5 * 1024 * 1024:  # 5MB
                return Response({'error': 'Dosya boyutu çok büyük. Maksimum 5MB olmalı.'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Dosya formatı kontrolü
            allowed_formats = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
            if profile_picture.content_type not in allowed_formats:
                return Response({'error': 'Geçersiz dosya formatı. JPEG, PNG, GIF veya WebP kullanın.'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Supabase Storage'a yükle
            from .services.supabase_storage_service import SupabaseStorageService
            storage_service = SupabaseStorageService()
            
            if not storage_service.is_available:
                return Response({
                    'error': 'Dosya yükleme servisi kullanılamıyor',
                    'message': 'Supabase Storage servisi yapılandırılmamış'
                }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
            
            # Dosyayı Supabase'e yükle
            upload_result = storage_service.upload_profile_picture(profile_picture, username)
            
            if not upload_result['success']:
                return Response({
                    'error': upload_result['error']
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
            # Eski profil fotoğrafını sil (Supabase'den)
            if user.profile_picture and 'supabase.co' in user.profile_picture:
                try:
                    # URL'den dosya adını çıkar
                    old_file_name = user.profile_picture.split('/')[-1]
                    storage_service.delete_file(storage_service.profile_bucket, f"{username}/{old_file_name}")
                except:
                    pass  # Silinemezse devam et
            
            # Yeni profil fotoğrafı URL'ini kaydet
            user.profile_picture = upload_result['url']
            user.save()
            
            # Kullanıcı bilgilerini döndür
            serializer = UserSerializer(user, context={'request': request})
            return Response({
                'user': serializer.data,
                'message': 'Profil fotoğrafı başarıyla güncellendi'
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'error': f'Profil fotoğrafı yükleme hatası: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class CoverImageUploadView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, username):
        user = get_object_or_404(User, username=username)
        if request.user != user:
            return Response({'error': 'Bu işlem için yetkiniz yok'}, status=status.HTTP_403_FORBIDDEN)
        
        if 'cover_picture' not in request.FILES:
            return Response({'error': 'Dosya bulunamadı'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Dosya boyutu kontrolü (10MB limit - kapak fotoğrafı daha büyük olabilir)
            cover_picture = request.FILES['cover_picture']
            if cover_picture.size > 10 * 1024 * 1024:  # 10MB
                return Response({'error': 'Dosya boyutu çok büyük. Maksimum 10MB olmalı.'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Dosya formatı kontrolü
            allowed_formats = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
            if cover_picture.content_type not in allowed_formats:
                return Response({'error': 'Geçersiz dosya formatı. JPEG, PNG, GIF veya WebP kullanın.'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Supabase Storage'a yükle
            from .services.supabase_storage_service import SupabaseStorageService
            storage_service = SupabaseStorageService()
            
            if not storage_service.is_available:
                return Response({
                    'error': 'Dosya yükleme servisi kullanılamıyor',
                    'message': 'Supabase Storage servisi yapılandırılmamış'
                }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
            
            # Dosyayı Supabase'e yükle
            upload_result = storage_service.upload_cover_picture(cover_picture, username)
            
            if not upload_result['success']:
                return Response({
                    'error': upload_result['error']
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
            # Eski kapak fotoğrafını sil (Supabase'den)
            if user.cover_picture and 'supabase.co' in user.cover_picture:
                try:
                    # URL'den dosya adını çıkar
                    old_file_name = user.cover_picture.split('/')[-1]
                    storage_service.delete_file(storage_service.cover_bucket, f"{username}/{old_file_name}")
                except:
                    pass  # Silinemezse devam et
            
            # Yeni kapak fotoğrafı URL'ini kaydet
            user.cover_picture = upload_result['url']
            user.save()
            
            # Kullanıcı bilgilerini döndür
            serializer = UserSerializer(user, context={'request': request})
            return Response({
                'user': serializer.data,
                'message': 'Kapak fotoğrafı başarıyla güncellendi'
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'error': f'Kapak fotoğrafı yükleme hatası: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

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
                from notifications.utils import send_follow_notification
                
                # Bildirimi arka planda gönder (asenkron)
                import threading
                def send_notification_async():
                    try:
                        send_follow_notification(
                            follower_user=request.user,
                            followed_user=target_user
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

class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        """Kullanıcının şifresini değiştir"""
        serializer = ChangePasswordSerializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            try:
                user = serializer.save()
                return Response({
                    'message': 'Şifre başarıyla değiştirildi',
                    'user': UserSerializer(user).data
                }, status=status.HTTP_200_OK)
            except Exception as e:
                return Response({
                    'error': 'Şifre değiştirilemedi',
                    'detail': str(e)
                }, status=status.HTTP_400_BAD_REQUEST)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

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