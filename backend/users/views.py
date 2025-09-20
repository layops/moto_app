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
import uuid
from datetime import datetime, timedelta

User = get_user_model()

def get_storage_service():
    """Supabase Storage servisini güvenli şekilde al"""
    try:
        from .services.supabase_storage_service import SupabaseStorageService
        storage_service = SupabaseStorageService()
        
        if not storage_service.is_available:
            # Supabase konfigürasyonunu kontrol et
            import os
            from django.conf import settings
            
            supabase_url = os.getenv('SUPABASE_URL') or getattr(settings, 'SUPABASE_URL', None)
            supabase_key = (os.getenv('SUPABASE_SERVICE_ROLE_KEY') or 
                           getattr(settings, 'SUPABASE_SERVICE_ROLE_KEY', None) or
                           os.getenv('SUPABASE_ANON_KEY') or 
                           getattr(settings, 'SUPABASE_ANON_KEY', None))
            
            return None, {
                'error': 'Dosya yükleme servisi kullanılamıyor',
                'message': 'Supabase Storage servisi yapılandırılmamış',
                'debug_info': {
                    'supabase_url_set': bool(supabase_url),
                    'supabase_key_set': bool(supabase_key),
                    'service_available': storage_service.is_available
                },
                'solution': 'SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY environment variables\'larını ayarlayın'
            }
        
        return storage_service, None
        
    except ImportError as import_error:
        return None, {
            'error': 'Supabase modülü bulunamadı',
            'message': 'Supabase Python paketi yüklü değil',
            'debug_info': f'ImportError: {str(import_error)}',
            'solution': 'pip install supabase'
        }
    except Exception as service_error:
        return None, {
            'error': 'Supabase Storage servisi başlatılamadı',
            'message': 'Supabase konfigürasyon hatası',
            'debug_info': f'ServiceError: {str(service_error)}'
        }

def validate_image_file(file, max_size_mb=5):
    """Resim dosyasını validate et"""
    # Dosya boyutu kontrolü
    max_size_bytes = max_size_mb * 1024 * 1024
    if file.size > max_size_bytes:
        return False, f'Dosya boyutu çok büyük. Maksimum {max_size_mb}MB olmalı.'
    
    # Dosya formatı kontrolü
    from .services.supabase_storage_service import get_safe_content_type
    allowed_formats = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
    content_type = get_safe_content_type(file)
    
    if content_type not in allowed_formats:
        return False, 'Geçersiz dosya formatı. JPEG, PNG, GIF veya WebP kullanın.'
    
    return True, None

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
                    # Auto redirect kontrolü
                    auto_redirect = request.GET.get('auto_redirect', 'false').lower() == 'true'
                    
                    if auto_redirect:
                        # Token data'yı hazırla
                        import json
                        import base64
                        token_data = {
                            'access_token': result.get('access_token'),
                            'refresh_token': result.get('refresh_token'),
                        }
                        # Doğrudan Flutter uygulamasına yönlendir
                        flutter_url = f'motoapp://oauth/success?user_data={base64.b64encode(json.dumps(user_data).encode()).decode()}&token_data={base64.b64encode(json.dumps(token_data).encode()).decode()}'
                        return HttpResponse(f'''
                        <!DOCTYPE html>
                        <html>
                        <head>
                            <meta charset="UTF-8">
                            <meta name="viewport" content="width=device-width, initial-scale=1.0">
                            <title>Flutter Uygulamasına Yönlendiriliyor</title>
                        </head>
                        <body>
                            <script>
                                window.location.href = '{flutter_url}';
                            </script>
                            <p>Flutter uygulamasına yönlendiriliyorsunuz...</p>
                        </body>
                        </html>
                        ''', content_type='text/html')
                    
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
                        
                        <div id="loadingIndicator" style="display: block;">
                            <p>🔄 Flutter uygulaması açılmaya çalışılıyor...</p>
                        </div>
                        
                        <div id="manualActions" style="display: none;">
                            <div class="url-box">
                                <span id="callbackUrl"></span>
                                <br><br>
                                <button class="copy-btn" onclick="openFlutterApp()">Flutter Uygulamasını Aç</button>
                                <br><br>
                                <button class="copy-btn" onclick="copyUrl()" style="background-color: #6c757d;">URL'yi Kopyala</button>
                            </div>
                        </div>
                        
                        <div id="instructions" style="display: block;">
                            <div style="background-color: #d1ecf1; border: 1px solid #bee5eb; border-radius: 8px; padding: 16px; margin: 16px 0;">
                                <h4 style="color: #0c5460; margin: 0 0 12px 0;">📱 Flutter Uygulamasına Yönlendirme</h4>
                                <p style="color: #0c5460; margin: 0 0 12px 0;"><strong>Otomatik yönlendirme denendi, manuel yöntem:</strong></p>
                                <ol style="color: #0c5460; margin: 0; padding-left: 20px;">
                                    <li><strong>URL'yi Kopyala</strong> butonuna tıklayın</li>
                                    <li>Flutter uygulamasını açın</li>
                                    <li>Google giriş sayfasında "URL'yi Yapıştır" seçeneğini kullanın</li>
                                    <li>Kopyalanan URL'yi yapıştırın ve "Devam Et" butonuna tıklayın</li>
                                </ol>
                            </div>
                        </div>
                        
                        <script>
                            document.getElementById('callbackUrl').textContent = window.location.href;
                            
                            // Otomatik Flutter uygulamasına yönlendirme
                            function openFlutterApp() {{
                                console.log('Attempting to open Flutter app...');
                                
                                // Custom scheme URL'i oluştur - daha basit format
                                const userData = '{user_data_encoded}';
                                const tokenData = '{token_data_encoded}';
                                const flutterUrl = 'motoapp://?user_data=' + encodeURIComponent(userData) + '&token_data=' + encodeURIComponent(tokenData);
                                
                                console.log('Flutter URL:', flutterUrl);
                                
                                // Try multiple methods
                                let success = false;
                                
                                // Method 1: Direct location change
                                try {{
                                    window.location.href = flutterUrl;
                                    success = true;
                                    console.log('Method 1: Direct location change');
                                }} catch(e) {{
                                    console.log('Method 1 failed:', e);
                                }}
                                
                                // Method 2: Hidden iframe (most reliable)
                                if (!success) {{
                                    try {{
                                        const iframe = document.createElement('iframe');
                                        iframe.style.display = 'none';
                                        iframe.style.width = '0';
                                        iframe.style.height = '0';
                                        iframe.src = flutterUrl;
                                        document.body.appendChild(iframe);
                                        
                                        setTimeout(function() {{
                                            if (iframe.parentNode) {{
                                                document.body.removeChild(iframe);
                                            }}
                                        }}, 2000);
                                        
                                        console.log('Method 2: Hidden iframe');
                                        success = true;
                                    }} catch(e) {{
                                        console.log('Method 2 failed:', e);
                                    }}
                                }}
                                
                                // Method 3: Create and click link
                                if (!success) {{
                                    try {{
                                        const link = document.createElement('a');
                                        link.href = flutterUrl;
                                        link.style.display = 'none';
                                        document.body.appendChild(link);
                                        link.click();
                                        document.body.removeChild(link);
                                        console.log('Method 3: Programmatic link click');
                                        success = true;
                                    }} catch(e) {{
                                        console.log('Method 3 failed:', e);
                                    }}
                                }}
                                
                                return success;
                            }}
                            
                            // URL'yi kopyalama fonksiyonu
                            function copyUrl() {{
                                const url = window.location.href;
                                console.log('Copying URL:', url);
                                
                                if (navigator.clipboard && window.isSecureContext) {{
                                    navigator.clipboard.writeText(url).then(function() {{
                                        alert('✅ URL panoya kopyalandı!\\n\\nŞimdi:\\n1. Flutter uygulamasını açın\\n2. Google giriş sayfasında URL\'yi yapıştırın');
                                    }}).catch(function(err) {{
                                        console.error('Clipboard API error:', err);
                                        fallbackCopy(url);
                                    }});
                                }} else {{
                                    fallbackCopy(url);
                                }}
                            }}
                            
                            function fallbackCopy(url) {{
                                const textArea = document.createElement('textarea');
                                textArea.value = url;
                                textArea.style.position = 'fixed';
                                textArea.style.left = '-999999px';
                                textArea.style.top = '-999999px';
                                document.body.appendChild(textArea);
                                textArea.focus();
                                textArea.select();
                                
                                try {{
                                    const successful = document.execCommand('copy');
                                    if (successful) {{
                                        alert('✅ URL panoya kopyalandı!\\n\\nŞimdi:\\n1. Flutter uygulamasını açın\\n2. Google giriş sayfasında URL\'yi yapıştırın');
                                    }} else {{
                                        alert('❌ URL kopyalanamadı. Lütfen URL\'yi manuel olarak kopyalayın:\\n\\n' + url);
                                    }}
                                }} catch (err) {{
                                    console.error('Fallback copy error:', err);
                                    alert('❌ URL kopyalanamadı. Lütfen URL\'yi manuel olarak kopyalayın:\\n\\n' + url);
                                }}
                                
                                document.body.removeChild(textArea);
                            }}
                            
                            // Sayfa yüklendiğinde otomatik yönlendirme
                            window.onload = function() {{
                                // Hemen dene
                                const success = openFlutterApp();
                                
                                // 2 saniye sonra tekrar dene
                                setTimeout(function() {{
                                    openFlutterApp();
                                }}, 2000);
                                
                                // 4 saniye sonra manuel seçenekleri göster
                                setTimeout(function() {{
                                    document.getElementById('loadingIndicator').style.display = 'none';
                                    document.getElementById('manualActions').style.display = 'block';
                                    document.getElementById('instructions').style.display = 'block';
                                }}, 4000);
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

# Eski ProfileImageUploadView kaldırıldı - Yeni güvenli upload sistemi kullanılıyor

# Eski CoverImageUploadView kaldırıldı - Yeni güvenli upload sistemi kullanılıyor

class SupabaseStorageTestView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Supabase Storage bağlantısını test eder"""
        try:
            # Storage servisini al
            storage_service, error_response = get_storage_service()
            if error_response:
                return Response({
                    'success': False,
                    'error': error_response['error'],
                    'message': error_response['message']
                }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
            
            # Bucket test
            bucket_test = storage_service.test_connection()
            
            if bucket_test['success']:
                return Response({
                    'success': True,
                    'message': 'Supabase Storage bağlantısı başarılı',
                    'buckets': bucket_test['buckets'],
                    'bucket_status': {
                        'profile_bucket_exists': bucket_test['profile_bucket_exists'],
                        'events_bucket_exists': bucket_test['events_bucket_exists'],
                        'cover_bucket_exists': bucket_test['cover_bucket_exists'],
                        'groups_bucket_exists': bucket_test['groups_bucket_exists'],
                        'posts_bucket_exists': bucket_test['posts_bucket_exists'],
                        'bikes_bucket_exists': bucket_test['bikes_bucket_exists']
                    },
                    'upload_endpoints': {
                        'profile_upload': f'/api/users/{request.user.username}/upload-photo/',
                        'cover_upload': f'/api/users/{request.user.username}/upload-cover/',
                        'test_storage': '/api/users/test-supabase-storage/'
                    }
                })
            else:
                return Response({
                    'success': False,
                    'error': bucket_test['error']
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
                
        except Exception as e:
            return Response({
                'success': False,
                'error': f'Supabase Storage test hatası: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class UploadTestView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Upload işlemlerinin durumunu test eder"""
        try:
            # Storage servisini al
            storage_service, error_response = get_storage_service()
            if error_response:
                return Response({
                    'success': False,
                    'error': error_response['error'],
                    'message': 'Upload işlemleri kullanılamıyor - Supabase Storage servisi yapılandırılmamış'
                }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
            
            # Upload endpoint'lerini test et
            upload_info = {
                'success': True,
                'message': 'Upload işlemleri hazır',
                'available_endpoints': {
                    'profile_upload': {
                        'url': f'/api/users/{request.user.username}/upload-photo/',
                        'method': 'POST',
                        'field_name': 'profile_picture',
                        'max_size': '5MB',
                        'allowed_formats': ['JPEG', 'PNG', 'GIF', 'WebP']
                    },
                    'cover_upload': {
                        'url': f'/api/users/{request.user.username}/upload-cover/',
                        'method': 'POST',
                        'field_name': 'cover_picture',
                        'max_size': '10MB',
                        'allowed_formats': ['JPEG', 'PNG', 'GIF', 'WebP']
                    }
                },
                'storage_service': {
                    'available': storage_service.is_available,
                    'buckets': list(storage_service.buckets.keys())
                }
            }
            
            return Response(upload_info, status=status.HTTP_200_OK)
                
        except Exception as e:
            return Response({
                'success': False,
                'error': f'Upload test hatası: {str(e)}'
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

# Upload Permission Endpoints
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def request_upload_permission(request):
    """Frontend'den güvenli dosya yükleme izni almak için endpoint"""
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        logger.info(f"Upload permission isteği - User: {request.user.username}, Data: {request.data}")
        
        user = request.user
        file_type = request.data.get('file_type')  # 'profile', 'cover', 'post', 'event', 'group', 'bike'
        file_size = request.data.get('file_size', 0)  # bytes
        
        # Dosya tipi kontrolü
        allowed_types = ['profile', 'cover', 'post', 'event', 'group', 'bike']
        if file_type not in allowed_types:
            return Response({
                'error': 'Geçersiz dosya tipi',
                'allowed_types': allowed_types
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Dosya boyutu kontrolü (5MB limit)
        max_size = 5 * 1024 * 1024  # 5MB
        if file_size > max_size:
            return Response({
                'error': 'Dosya çok büyük',
                'max_size_mb': 5,
                'current_size_mb': round(file_size / (1024 * 1024), 2)
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Supabase Storage servisini al
        logger.info("Supabase Storage servisi alınıyor...")
        storage_service, error = get_storage_service()
        if error:
            logger.error(f"Storage servisi hatası: {error}")
            return Response(error, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        logger.info(f"Storage servisi başarıyla alındı - Available: {storage_service.is_available}")
        
        # Güvenli dosya yolu oluştur
        file_extension = request.data.get('file_extension', 'jpg')
        upload_id = str(uuid.uuid4())
        timestamp = int(datetime.now().timestamp() * 1000)
        
        if file_type == 'profile':
            file_path = f"{user.username}/profile_{user.username}_{timestamp}.{file_extension}"
            bucket = storage_service.profile_bucket
        elif file_type == 'cover':
            file_path = f"{user.username}/cover_{user.username}_{timestamp}.{file_extension}"
            bucket = storage_service.cover_bucket
        elif file_type == 'post':
            post_id = request.data.get('post_id', upload_id)
            file_path = f"posts/{post_id}/image_{post_id}_{timestamp}.{file_extension}"
            bucket = storage_service.posts_bucket
        elif file_type == 'event':
            event_id = request.data.get('event_id', upload_id)
            file_path = f"events/{event_id}/cover_{event_id}_{timestamp}.{file_extension}"
            bucket = storage_service.events_bucket
        elif file_type == 'group':
            group_id = request.data.get('group_id', upload_id)
            file_path = f"groups/{group_id}/profile_{group_id}_{timestamp}.{file_extension}"
            bucket = storage_service.groups_bucket
        elif file_type == 'bike':
            bike_id = request.data.get('bike_id', upload_id)
            file_path = f"bikes/{bike_id}/image_{bike_id}_{timestamp}.{file_extension}"
            bucket = storage_service.bikes_bucket
        
        # Supabase'den signed URL al (10 dakika geçerli)
        try:
            logger.info(f"Signed URL oluşturuluyor - Bucket: {bucket}, Path: {file_path}")
            
            # Supabase'den signed upload URL al
            storage_bucket = storage_service.client.storage.from_(bucket)
            signed_url_response = storage_bucket.create_signed_upload_url(file_path)
            logger.info(f"Signed URL response: {signed_url_response}")
            
            if signed_url_response.get('error'):
                return Response({
                    'error': 'Signed URL oluşturulamadı',
                    'detail': signed_url_response['error']
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
            # Supabase response formatını kontrol et
            signed_url = signed_url_response.get('signed_url') or signed_url_response.get('signedURL')
            if not signed_url:
                logger.error(f"Signed URL bulunamadı. Response keys: {list(signed_url_response.keys())}")
                return Response({
                    'error': 'Signed URL alınamadı',
                    'response_keys': list(signed_url_response.keys())
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
            # Upload permission'ı döndür
            return Response({
                'success': True,
                'upload_permission': {
                    'upload_id': upload_id,
                    'upload_url': signed_url,
                    'file_path': file_path,
                    'bucket': bucket,
                    'expires_at': (datetime.now() + timedelta(minutes=10)).isoformat(),
                    'file_type': file_type,
                    'user_id': user.id,
                    'username': user.username
                }
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Supabase signed URL hatası: {str(e)}")
            return Response({
                'error': 'Supabase bağlantı hatası',
                'detail': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    except Exception as e:
        logger.error(f"Upload permission genel hatası: {str(e)}")
        return Response({
            'error': 'Upload permission alınamadı',
            'detail': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def confirm_upload(request):
    """Frontend'den yükleme tamamlandığında çağrılır"""
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        logger.info(f"Confirm upload isteği - User: {request.user.username}, Data: {request.data}")
        
        upload_id = request.data.get('upload_id')
        file_path = request.data.get('file_path')
        bucket = request.data.get('bucket')
        file_type = request.data.get('file_type')
        
        if not all([upload_id, file_path, bucket, file_type]):
            return Response({
                'error': 'Eksik parametreler',
                'required': ['upload_id', 'file_path', 'bucket', 'file_type']
            }, status=status.HTTP_400_BAD_REQUEST)
        
        user = request.user
        
        # Dosyanın gerçekten yüklendiğini kontrol et
        storage_service, error = get_storage_service()
        if error:
            return Response(error, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        try:
            logger.info(f"Dosya varlığı kontrol ediliyor - Bucket: {bucket}, Path: {file_path}")
            # Dosyanın varlığını kontrol et
            file_info = storage_service.client.storage.from_(bucket).get_public_url(file_path)
            logger.info(f"Public URL alındı: {file_info}")
            if not file_info:
                return Response({
                    'error': 'Dosya bulunamadı'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Public URL'i al (get_public_url zaten string döndürüyor)
            public_url = file_info
            
            # Kullanıcı profilini güncelle (sadece profile ve cover için)
            if file_type in ['profile', 'cover']:
                if file_type == 'profile':
                    user.profile_picture = public_url
                elif file_type == 'cover':
                    user.cover_picture = public_url
                user.save()
            
            return Response({
                'success': True,
                'message': 'Upload başarıyla tamamlandı',
                'file_url': public_url,
                'file_path': file_path,
                'upload_id': upload_id
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Dosya doğrulama hatası: {str(e)}")
            return Response({
                'error': 'Dosya doğrulama hatası',
                'detail': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    except Exception as e:
        logger.error(f"Upload confirmation genel hatası: {str(e)}")
        return Response({
            'error': 'Upload confirmation hatası',
            'detail': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)