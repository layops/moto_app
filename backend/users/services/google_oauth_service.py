# users/services/google_oauth_service.py
import os
import secrets
import base64
import hashlib
import requests
import logging
from urllib.parse import unquote
from django.conf import settings
from django.core.cache import cache
from django.contrib.auth import get_user_model

User = get_user_model()
logger = logging.getLogger(__name__)

class GoogleOAuthService:
    def __init__(self):
        self.client_id = settings.GOOGLE_CLIENT_ID
        self.client_secret = settings.GOOGLE_CLIENT_SECRET
        self.redirect_uri = settings.GOOGLE_REDIRECT_URI
        
        # Google OAuth endpoints
        self.auth_url = 'https://accounts.google.com/o/oauth2/v2/auth'
        self.token_url = 'https://oauth2.googleapis.com/token'
        self.user_info_url = 'https://www.googleapis.com/oauth2/v2/userinfo'
        
        self.is_available = bool(self.client_id and self.client_secret)
        
        if not self.is_available:
            logger.warning("Google OAuth credentials not found - service disabled")
        else:
            logger.info("Google OAuth service initialized successfully")

    def _generate_pkce_pair(self):
        """PKCE code verifier ve challenge çifti oluştur"""
        code_verifier = base64.urlsafe_b64encode(secrets.token_bytes(32)).decode('utf-8').rstrip('=')
        code_challenge = hashlib.sha256(code_verifier.encode('utf-8')).digest()
        code_challenge = base64.urlsafe_b64encode(code_challenge).decode('utf-8').rstrip('=')
        return code_verifier, code_challenge

    def get_auth_url(self, redirect_to=None):
        """Google OAuth URL'i oluştur"""
        try:
            if not self.is_available:
                raise Exception("Google OAuth servisi kullanılamıyor - credentials eksik")
            
            # PKCE parametrelerini oluştur
            code_verifier, code_challenge = self._generate_pkce_pair()
            
            # State parametresi oluştur
            state = base64.urlsafe_b64encode(secrets.token_bytes(16)).decode('utf-8').rstrip('=')
            
            # Code verifier'ı cache'de sakla (5 dakika) - Redis bağlantı sorunları için try-catch
            try:
                cache.set(f"google_pkce_verifier_{state}", code_verifier, 300)
                logger.info(f"Code verifier cached successfully: {code_verifier[:10]}...")
            except Exception as cache_error:
                logger.warning(f"Cache set error (non-critical): {cache_error}")
                # Cache hatası kritik değil, devam et
            
            # OAuth parametreleri
            params = {
                'client_id': self.client_id,
                'redirect_uri': self.redirect_uri,
                'scope': 'openid email profile',
                'response_type': 'code',
                'state': state,
                'code_challenge': code_challenge,
                'code_challenge_method': 'S256',
                'access_type': 'offline',
                'prompt': 'consent'
            }
            
            # URL oluştur
            auth_url = f"{self.auth_url}?" + "&".join([f"{k}={v}" for k, v in params.items()])
            
            logger.info("Google OAuth URL oluşturuldu")
            return {
                'success': True,
                'auth_url': auth_url,
                'state': state,
                'message': 'Google OAuth URL oluşturuldu'
            }
            
        except Exception as e:
            logger.error(f"Google OAuth URL oluşturma hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def get_google_auth_url(self, redirect_to=None):
        """Google OAuth URL'i oluştur - Views ile uyumlu metod"""
        return self.get_auth_url(redirect_to)

    def handle_callback(self, code, state=None):
        """OAuth callback'i işle"""
        try:
            if not self.is_available:
                raise Exception("Google OAuth servisi kullanılamıyor - credentials eksik")
            
            # State'den code_verifier'ı al - Redis bağlantı sorunları için try-catch
            code_verifier = None
            if state:
                try:
                    code_verifier = cache.get(f"google_pkce_verifier_{state}")
                    if code_verifier:
                        logger.info(f"Code verifier retrieved successfully: {code_verifier[:10]}...")
                        cache.delete(f"google_pkce_verifier_{state}")
                    else:
                        logger.warning(f"Code verifier not found for state: {state}")
                except Exception as cache_error:
                    logger.warning(f"Cache get/delete error (non-critical): {cache_error}")
                    # Cache hatası kritik değil, devam et
            
            # Access token al - code'u URL decode et
            decoded_code = unquote(code)
            logger.info(f"Original code: {code}")
            logger.info(f"Decoded code: {decoded_code}")
            
            token_data = {
                'client_id': self.client_id,
                'client_secret': self.client_secret,
                'code': decoded_code,
                'grant_type': 'authorization_code',
                'redirect_uri': self.redirect_uri,
            }
            
            if code_verifier:
                token_data['code_verifier'] = code_verifier
            
            # Token request
            logger.info(f"Token request data: {token_data}")
            token_response = requests.post(self.token_url, data=token_data, timeout=30)
            
            if token_response.status_code != 200:
                logger.error(f"Token request failed: {token_response.status_code}")
                logger.error(f"Response text: {token_response.text}")
                token_response.raise_for_status()
            
            token_info = token_response.json()
            
            access_token = token_info.get('access_token')
            refresh_token = token_info.get('refresh_token')
            
            if not access_token:
                raise Exception("Access token alınamadı")
            
            # User info al
            user_info_response = requests.get(
                self.user_info_url,
                headers={'Authorization': f'Bearer {access_token}'},
                timeout=30
            )
            user_info_response.raise_for_status()
            user_info = user_info_response.json()
            
            # User bilgilerini al
            email = user_info.get('email')
            name = user_info.get('name', '')
            first_name = user_info.get('given_name', '')
            last_name = user_info.get('family_name', '')
            picture = user_info.get('picture', '')
            
            if not email:
                raise Exception("Email bilgisi alınamadı")
            
            # Local user'ı oluştur veya güncelle
            try:
                user = User.objects.get(email=email)
                user.email_verified = True
                if picture and not user.profile_picture:
                    user.profile_picture = picture
                user.save()
            except User.DoesNotExist:
                # Yeni kullanıcı oluştur
                username = email.split('@')[0]
                counter = 1
                original_username = username
                while User.objects.filter(username=username).exists():
                    username = f"{original_username}_{counter}"
                    counter += 1
                
                user = User.objects.create_user(
                    username=username,
                    email=email,
                    email_verified=True,
                    first_name=first_name,
                    last_name=last_name,
                    profile_picture=picture
                )
            
            logger.info(f"Google OAuth başarılı: {email}")
            return {
                'success': True,
                'user': user,
                'access_token': access_token,
                'refresh_token': refresh_token,
                'message': 'Google OAuth giriş başarılı'
            }
            
        except Exception as e:
            logger.error(f"Google OAuth callback hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def handle_oauth_callback(self, code, state=None):
        """OAuth callback'i işle - Views ile uyumlu metod"""
        return self.handle_callback(code, state)

    def verify_token(self, access_token):
        """Access token'ı doğrula"""
        try:
            if not self.is_available:
                raise Exception("Google OAuth servisi kullanılamıyor")
            
            # User info al
            user_info_response = requests.get(
                self.user_info_url,
                headers={'Authorization': f'Bearer {access_token}'},
                timeout=30
            )
            user_info_response.raise_for_status()
            user_info = user_info_response.json()
            
            email = user_info.get('email')
            if not email:
                raise Exception("Email bilgisi alınamadı")
            
            # Local user'ı bul
            try:
                user = User.objects.get(email=email)
                return {
                    'success': True,
                    'user': user,
                    'message': 'Token doğrulandı'
                }
            except User.DoesNotExist:
                return {
                    'success': False,
                    'error': 'Kullanıcı bulunamadı'
                }
                
        except Exception as e:
            logger.error(f"Token doğrulama hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def get_user_from_token(self, access_token):
        """Access token'dan kullanıcı bilgisi al - Views ile uyumlu metod"""
        return self.verify_token(access_token)
