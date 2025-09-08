from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.http import Http404
import logging
import traceback

logger = logging.getLogger(__name__)

class APIError(Exception):
    """Custom API exception class"""
    def __init__(self, message, status_code=status.HTTP_400_BAD_REQUEST, details=None):
        self.message = message
        self.status_code = status_code
        self.details = details
        super().__init__(self.message)

def custom_exception_handler(exc, context):
    """
    Custom exception handler for better error responses
    """
    # Get the standard error response first
    response = exception_handler(exc, context)
    
    # Custom error response structure
    custom_response_data = {
        'success': False,
        'error': {
            'message': '',
            'code': '',
            'details': None,
            'timestamp': None
        }
    }
    
    # Handle different types of exceptions
    if isinstance(exc, APIError):
        custom_response_data['error']['message'] = exc.message
        custom_response_data['error']['code'] = 'CUSTOM_ERROR'
        custom_response_data['error']['details'] = exc.details
        response = Response(custom_response_data, status=exc.status_code)
        
    elif isinstance(exc, ValidationError):
        custom_response_data['error']['message'] = 'Veri doğrulama hatası'
        custom_response_data['error']['code'] = 'VALIDATION_ERROR'
        custom_response_data['error']['details'] = exc.message_dict if hasattr(exc, 'message_dict') else str(exc)
        response = Response(custom_response_data, status=status.HTTP_400_BAD_REQUEST)
        
    elif isinstance(exc, IntegrityError):
        custom_response_data['error']['message'] = 'Veritabanı bütünlük hatası'
        custom_response_data['error']['code'] = 'INTEGRITY_ERROR'
        custom_response_data['error']['details'] = 'Bu işlem veritabanı kurallarını ihlal ediyor'
        response = Response(custom_response_data, status=status.HTTP_400_BAD_REQUEST)
        
    elif isinstance(exc, Http404):
        custom_response_data['error']['message'] = 'Kaynak bulunamadı'
        custom_response_data['error']['code'] = 'NOT_FOUND'
        response = Response(custom_response_data, status=status.HTTP_404_NOT_FOUND)
        
    elif response is not None:
        # Handle DRF exceptions
        if hasattr(exc, 'detail'):
            if isinstance(exc.detail, dict):
                custom_response_data['error']['message'] = 'İstek doğrulama hatası'
                custom_response_data['error']['code'] = 'VALIDATION_ERROR'
                custom_response_data['error']['details'] = exc.detail
            else:
                custom_response_data['error']['message'] = str(exc.detail)
                custom_response_data['error']['code'] = 'DRF_ERROR'
        else:
            custom_response_data['error']['message'] = 'API hatası'
            custom_response_data['error']['code'] = 'API_ERROR'
            
        response = Response(custom_response_data, status=response.status_code)
        
    else:
        # Handle unhandled exceptions
        logger.error(f"Unhandled exception: {exc}", exc_info=True)
        custom_response_data['error']['message'] = 'Sunucu hatası oluştu'
        custom_response_data['error']['code'] = 'INTERNAL_ERROR'
        custom_response_data['error']['details'] = str(exc) if hasattr(exc, '__str__') else 'Bilinmeyen hata'
        response = Response(custom_response_data, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    # Add timestamp
    from django.utils import timezone
    custom_response_data['error']['timestamp'] = timezone.now().isoformat()
    
    return response