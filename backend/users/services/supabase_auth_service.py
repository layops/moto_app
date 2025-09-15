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
            
            # Supabase client oluştur (anon key ile)
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

    def get_google_auth_url(self, redirect_to=None):
        """Google OAuth URL'i oluştur"""
        try:
            if not self._is_available():
                raise Exception("Supabase Auth servisi kullanılamıyor")
            
            # Google OAuth URL oluştur
            response = self.client.auth.sign_in_with_oauth({
                "provider": "google",
                "options": {
                    "redirect_to": redirect_to or settings.GOOGLE_CALLBACK_URL
                }
            })
            
            logger.info("Google OAuth URL oluşturuldu")
            return {
                'success': True,
                'auth_url': response.url if hasattr(response, 'url') else str(response),
                'message': 'Google OAuth URL oluşturuldu'
            }
                
        except Exception as e:
            logger.error(f"Google OAuth URL oluşturma hatası: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def handle_oauth_callback(self, code, state=None):
        """OAuth callback'i işle"""
        try:
            if not self._is_available():
                raise Exception("Supabase Auth servisi kullanılamıyor")
            
            # OAuth callback'i işle
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
