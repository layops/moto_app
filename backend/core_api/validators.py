"""
Custom validators for API input validation
"""
import re
from django.core.exceptions import ValidationError
from django.core.validators import EmailValidator
from django.utils.translation import gettext_lazy as _
import logging

logger = logging.getLogger(__name__)

class CustomValidators:
    """Custom validation utilities"""
    
    @staticmethod
    def validate_username(value):
        """Validate username format"""
        if not re.match(r'^[a-zA-Z0-9_]{3,30}$', value):
            raise ValidationError(
                _('Kullanıcı adı 3-30 karakter arası olmalı ve sadece harf, rakam ve alt çizgi içermelidir.')
            )
        
        # Check for reserved usernames
        reserved_usernames = [
            'admin', 'administrator', 'root', 'api', 'www', 'mail', 'ftp',
            'support', 'help', 'info', 'contact', 'about', 'terms', 'privacy'
        ]
        if value.lower() in reserved_usernames:
            raise ValidationError(_('Bu kullanıcı adı rezerve edilmiştir.'))
    
    @staticmethod
    def validate_password_strength(value):
        """Validate password strength"""
        if len(value) < 8:
            raise ValidationError(_('Şifre en az 8 karakter olmalıdır.'))
        
        if not re.search(r'[A-Z]', value):
            raise ValidationError(_('Şifre en az bir büyük harf içermelidir.'))
        
        if not re.search(r'[a-z]', value):
            raise ValidationError(_('Şifre en az bir küçük harf içermelidir.'))
        
        if not re.search(r'\d', value):
            raise ValidationError(_('Şifre en az bir rakam içermelidir.'))
        
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', value):
            raise ValidationError(_('Şifre en az bir özel karakter içermelidir.'))
    
    @staticmethod
    def validate_phone_number(value):
        """Validate Turkish phone number format"""
        if not re.match(r'^(\+90|0)?[5][0-9]{9}$', value):
            raise ValidationError(_('Geçerli bir Türkiye telefon numarası giriniz.'))
    
    @staticmethod
    def validate_file_size(file, max_size_mb=5):
        """Validate file size"""
        max_size_bytes = max_size_mb * 1024 * 1024
        if file.size > max_size_bytes:
            raise ValidationError(
                _('Dosya boyutu {max_size}MB\'dan büyük olamaz.').format(max_size=max_size_mb)
            )
    
    @staticmethod
    def validate_image_format(file):
        """Validate image file format"""
        allowed_formats = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        if file.content_type not in allowed_formats:
            raise ValidationError(_('Sadece JPEG, PNG, GIF ve WebP formatları desteklenir.'))
    
    @staticmethod
    def validate_coordinates(lat, lng):
        """Validate GPS coordinates"""
        if not (-90 <= lat <= 90):
            raise ValidationError(_('Geçersiz enlem değeri.'))
        
        if not (-180 <= lng <= 180):
            raise ValidationError(_('Geçersiz boylam değeri.'))
    
    @staticmethod
    def validate_ride_date(start_time, end_time=None):
        """Validate ride date logic"""
        from django.utils import timezone
        
        if start_time < timezone.now():
            raise ValidationError(_('Yolculuk tarihi geçmişte olamaz.'))
        
        if end_time and end_time <= start_time:
            raise ValidationError(_('Bitiş tarihi başlangıç tarihinden sonra olmalıdır.'))
    
    @staticmethod
    def sanitize_html(value):
        """Sanitize HTML content"""
        import bleach
        
        allowed_tags = ['p', 'br', 'strong', 'em', 'u', 'ol', 'ul', 'li']
        allowed_attributes = {}
        
        return bleach.clean(value, tags=allowed_tags, attributes=allowed_attributes)

class SecurityValidators:
    """Security-focused validators"""
    
    @staticmethod
    def validate_sql_injection(value):
        """Basic SQL injection prevention"""
        dangerous_patterns = [
            r'(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b)',
            r'(\b(OR|AND)\s+\d+\s*=\s*\d+)',
            r'(\b(OR|AND)\s+\w+\s*=\s*\w+)',
            r'(--|\#|\/\*|\*\/)',
            r'(\b(WAITFOR|DELAY)\b)',
        ]
        
        for pattern in dangerous_patterns:
            if re.search(pattern, value, re.IGNORECASE):
                logger.warning(f"Potential SQL injection attempt detected: {value}")
                raise ValidationError(_('Geçersiz karakterler tespit edildi.'))
    
    @staticmethod
    def validate_xss(value):
        """Basic XSS prevention"""
        dangerous_patterns = [
            r'<script[^>]*>.*?</script>',
            r'javascript:',
            r'on\w+\s*=',
            r'<iframe[^>]*>',
            r'<object[^>]*>',
            r'<embed[^>]*>',
        ]
        
        for pattern in dangerous_patterns:
            if re.search(pattern, value, re.IGNORECASE):
                logger.warning(f"Potential XSS attempt detected: {value}")
                raise ValidationError(_('Geçersiz içerik tespit edildi.'))
    
    @staticmethod
    def validate_path_traversal(value):
        """Prevent path traversal attacks"""
        dangerous_patterns = [
            r'\.\./',
            r'\.\.\\',
            r'%2e%2e%2f',
            r'%2e%2e%5c',
        ]
        
        for pattern in dangerous_patterns:
            if re.search(pattern, value, re.IGNORECASE):
                logger.warning(f"Potential path traversal attempt detected: {value}")
                raise ValidationError(_('Geçersiz dosya yolu tespit edildi.'))
