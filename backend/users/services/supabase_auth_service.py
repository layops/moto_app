# users/services/supabase_auth_service.py
import logging
from django.conf import settings
try:
    from supabase import create_client
    SUPABASE_AVAILABLE = True
except ImportError:
    create_client = None
    SUPABASE_AVAILABLE = False
import os
import uuid
import base64
import hashlib
import secrets
import json
from django.core.cache import cache

logger = logging.getLogger(__name__)

class SupabaseAuthService:
    def __init__(self):
        self.supabase_url = settings.SUPABASE_URL
        self.supabase_anon_key = getattr(settings, 'SUPABASE_ANON_KEY', None)
        self.supabase_service_key = settings.SUPABASE_SERVICE_KEY
        
        self.client = None
        self.is_available = False
        
        try:
            if not SUPABASE_AVAILABLE:
                logger.warning("Supabase modülü bulunamadı, auth servisi oluşturulamadı")
                return
                
            if not self.supabase_anon_key:
                logger.warning("SUPABASE_ANON_KEY bulunamadı, auth servisi devre dışı")
                return
            
            # Supabase client oluştur (anon key ile) - CLIENT_CLASS parametresi olmadan
            self.client = create_client(self.supabase_url, self.supabase_anon_key)
            logger.info("Supabase Auth istemcisi başarıyla oluşturuldu")
            self.is_available = True

        except Exception as e:
            logger.error(f"Supabase Auth istemcisi oluşturulamadı: {str(e)}")
            self.client = None
            self.is_available = False

    def _is_available(self):
        """Supabase Auth'un kullanılabilir olup olmadığını kontrol et"""
        return self.is_available and self.client is not None

    def sign_up(self, email, password, user_metadata=None):
        """Kullanıcı kaydı - Supabase Auth ile"""
        try:
            if not self._is_available():
                raise Exception("Supabase Auth servisi kullanılamıyor")
            
            # Supabase Auth ile kayıt
            response = self.client.auth.sign_up({
                "email": email,
                "password": password,
                "options": {
                    "data": user_metadata or {}
                }
            })
            
            if response.user:
                logger.info(f"Kullanıcı başarıyla kaydedildi: {email}")
                return {
                    'success': True,
                    'user': response.user,
                    'session': response.session,
                    'message': 'Kayıt başarılı! Email doğrulama linki gönderildi.'
                }
            else:
                logger.error(f"Kullanıcı kaydı başarısız: {email}")
                return {
                    'success': False,
                    'error': 'Kullanıcı kaydı başarısız'
                }
                
        except Exception as e:
            logger.error(f"Supabase Auth kayıt hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def sign_in(self, email, password):
        """Kullanıcı girişi - Supabase Auth ile"""
        try:
            if not self._is_available():
                raise Exception("Supabase Auth servisi kullanılamıyor")
            
            # Supabase Auth ile giriş
            response = self.client.auth.sign_in_with_password({
                "email": email,
                "password": password
            })
            
            if response.user:
                logger.info(f"Kullanıcı başarıyla giriş yaptı: {email}")
                return {
                    'success': True,
                    'user': response.user,
                    'session': response.session,
                    'access_token': response.session.access_token if response.session else None,
                    'refresh_token': response.session.refresh_token if response.session else None
                }
            else:
                logger.error(f"Kullanıcı girişi başarısız: {email}")
                return {
                    'success': False,
                    'error': 'Geçersiz email veya şifre'
                }
                
        except Exception as e:
            logger.error(f"Supabase Auth giriş hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def verify_email(self, token):
        """Email doğrulama - Supabase Auth ile"""
        try:
            if not self._is_available():
                raise Exception("Supabase Auth servisi kullanılamıyor")
            
            # Email verification token ile doğrulama
            response = self.client.auth.verify_otp({
                "token": token,
                "type": "email"
            })
            
            if response.user:
                logger.info(f"Email başarıyla doğrulandı: {response.user.email}")
                return {
                    'success': True,
                    'user': response.user,
                    'session': response.session,
                    'message': 'Email başarıyla doğrulandı'
                }
            else:
                logger.error("Email doğrulama başarısız")
                return {
                    'success': False,
                    'error': 'Geçersiz doğrulama token'
                }
                
        except Exception as e:
            logger.error(f"Supabase Auth email doğrulama hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def resend_verification(self, email):
        """Email doğrulama linkini tekrar gönder"""
        try:
            if not self._is_available():
                raise Exception("Supabase Auth servisi kullanılamıyor")
            
            # Email verification resend
            response = self.client.auth.resend({
                "type": "signup",
                "email": email
            })
            
            logger.info(f"Email doğrulama linki tekrar gönderildi: {email}")
            return {
                'success': True,
                'message': 'Email doğrulama linki tekrar gönderildi'
            }
                
        except Exception as e:
            logger.error(f"Supabase Auth email tekrar gönderme hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def reset_password(self, email):
        """Şifre sıfırlama linki gönder"""
        try:
            if not self._is_available():
                raise Exception("Supabase Auth servisi kullanılamıyor")
            
            # Password reset
            response = self.client.auth.reset_password_email(email)
            
            logger.info(f"Şifre sıfırlama linki gönderildi: {email}")
            return {
                'success': True,
                'message': 'Şifre sıfırlama linki email adresinize gönderildi'
            }
                
        except Exception as e:
            logger.error(f"Supabase Auth şifre sıfırlama hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def update_password(self, access_token, new_password):
        """Şifre güncelleme"""
        try:
            if not self._is_available():
                raise Exception("Supabase Auth servisi kullanılamıyor")
            
            # Set session with access token
            self.client.auth.set_session(access_token, "")
            
            # Update password
            response = self.client.auth.update_user({
                "password": new_password
            })
            
            if response.user:
                logger.info("Şifre başarıyla güncellendi")
                return {
                    'success': True,
                    'message': 'Şifre başarıyla güncellendi'
                }
            else:
                return {
                    'success': False,
                    'error': 'Şifre güncellenemedi'
                }
                
        except Exception as e:
            logger.error(f"Supabase Auth şifre güncelleme hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def get_user(self, access_token):
        """Access token ile kullanıcı bilgisi al"""
        try:
            if not self._is_available():
                raise Exception("Supabase Auth servisi kullanılamıyor")
            
            # Set session with access token
            self.client.auth.set_session(access_token, "")
            
            # Get user
            user = self.client.auth.get_user()
            
            if user:
                return {
                    'success': True,
                    'user': user
                }
            else:
                return {
                    'success': False,
                    'error': 'Kullanıcı bulunamadı'
                }
                
        except Exception as e:
            logger.error(f"Supabase Auth kullanıcı alma hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def sign_out(self, access_token):
        """Kullanıcı çıkışı"""
        try:
            if not self._is_available():
                raise Exception("Supabase Auth servisi kullanılamıyor")
            
            # Set session with access token
            self.client.auth.set_session(access_token, "")
            
            # Sign out
            self.client.auth.sign_out()
            
            logger.info("Kullanıcı başarıyla çıkış yaptı")
            return {
                'success': True,
                'message': 'Başarıyla çıkış yapıldı'
            }
                
        except Exception as e:
            logger.error(f"Supabase Auth çıkış hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def _generate_pkce_challenge(self, code_verifier):
        """PKCE code challenge oluştur"""
        code_challenge = hashlib.sha256(code_verifier.encode('utf-8')).digest()
        code_challenge = base64.urlsafe_b64encode(code_challenge).decode('utf-8').rstrip('=')
        return code_challenge

    def _generate_pkce_pair(self):
        """PKCE code verifier ve challenge çifti oluştur"""
        code_verifier = base64.urlsafe_b64encode(secrets.token_bytes(32)).decode('utf-8').rstrip('=')
        code_challenge = self._generate_pkce_challenge(code_verifier)
        return code_verifier, code_challenge

    def get_google_auth_url(self, redirect_to=None):
        """Google OAuth URL'i oluştur (PKCE ile)"""
        try:
            if not self._is_available():
                raise Exception("Supabase Auth servisi kullanılamıyor")
            
            # PKCE parametrelerini oluştur
            code_verifier, code_challenge = self._generate_pkce_pair()
            
            # State parametresi oluştur (code_verifier'ı saklamak için)
            state = base64.urlsafe_b64encode(secrets.token_bytes(16)).decode('utf-8').rstrip('=')
            
            # Code verifier'ı cache'de sakla (5 dakika)
            cache.set(f"pkce_verifier_{state}", code_verifier, 300)
            
            # Google OAuth URL oluştur
            response = self.client.auth.sign_in_with_oauth({
                "provider": "google",
                "options": {
                    "redirect_to": redirect_to or settings.GOOGLE_CALLBACK_URL,
                    "query_params": {
                        "code_challenge": code_challenge,
                        "code_challenge_method": "S256",
                        "state": state
                    }
                }
            })
            
            logger.info("Google OAuth URL oluşturuldu (PKCE ile)")
            return {
                'success': True,
                'auth_url': response.url if hasattr(response, 'url') else str(response),
                'state': state,  # Frontend'e gönderilecek
                'message': 'Google OAuth URL oluşturuldu'
            }
                
        except Exception as e:
            logger.error(f"Google OAuth URL oluşturma hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def handle_oauth_callback(self, code, state=None):
        """OAuth callback'i işle (PKCE ile)"""
        try:
            if not self._is_available():
                raise Exception("Supabase Auth servisi kullanılamıyor")
            
            # State'den code_verifier'ı al
            code_verifier = None
            if state:
                code_verifier = cache.get(f"pkce_verifier_{state}")
                if code_verifier:
                    # Cache'den sil
                    cache.delete(f"pkce_verifier_{state}")
            
            # OAuth callback'i işle (PKCE ile)
            if code_verifier:
                response = self.client.auth.exchange_code_for_session({
                    "auth_code": code,
                    "code_verifier": code_verifier
                })
            else:
                # Fallback: PKCE olmadan
                response = self.client.auth.exchange_code_for_session({
                    "auth_code": code
                })
            
            if response.user and response.session:
                logger.info(f"OAuth başarılı: {response.user.email}")
                return {
                    'success': True,
                    'user': response.user,
                    'session': response.session,
                    'access_token': response.session.access_token,
                    'refresh_token': response.session.refresh_token,
                    'message': 'OAuth giriş başarılı'
                }
            else:
                logger.error("OAuth callback başarısız")
                return {
                    'success': False,
                    'error': 'OAuth callback başarısız'
                }
                
        except Exception as e:
            logger.error(f"OAuth callback hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def get_user_from_token(self, access_token):
        """Access token'dan kullanıcı bilgisi al"""
        try:
            if not self._is_available():
                raise Exception("Supabase Auth servisi kullanılamıyor")
            
            # Set session with access token
            self.client.auth.set_session(access_token, "")
            
            # Get user
            user = self.client.auth.get_user()
            
            if user:
                return {
                    'success': True,
                    'user': user,
                    'message': 'Kullanıcı bilgisi alındı'
                }
            else:
                return {
                    'success': False,
                    'error': 'Kullanıcı bulunamadı'
                }
                
        except Exception as e:
            logger.error(f"Token'dan kullanıcı alma hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
