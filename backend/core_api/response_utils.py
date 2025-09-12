"""
Standardized API response utilities
"""
from rest_framework.response import Response
from rest_framework import status
from typing import Any, Dict, Optional, List
import logging

logger = logging.getLogger(__name__)

class APIResponse:
    """Standardized API response class"""
    
    @staticmethod
    def success(
        data: Any = None,
        message: str = "İşlem başarılı",
        status_code: int = status.HTTP_200_OK,
        meta: Optional[Dict] = None
    ) -> Response:
        """Create a standardized success response"""
        response_data = {
            'success': True,
            'message': message,
            'data': data,
        }
        
        if meta:
            response_data['meta'] = meta
            
        return Response(response_data, status=status_code)
    
    @staticmethod
    def error(
        message: str = "Bir hata oluştu",
        status_code: int = status.HTTP_400_BAD_REQUEST,
        error_code: str = "GENERIC_ERROR",
        details: Optional[Dict] = None,
        field_errors: Optional[Dict] = None
    ) -> Response:
        """Create a standardized error response"""
        response_data = {
            'success': False,
            'error': {
                'message': message,
                'code': error_code,
                'details': details,
                'field_errors': field_errors
            }
        }
        
        logger.error(f"API Error: {message} (Code: {error_code})")
        return Response(response_data, status=status_code)
    
    @staticmethod
    def created(
        data: Any = None,
        message: str = "Kayıt başarıyla oluşturuldu"
    ) -> Response:
        """Create a standardized created response"""
        return APIResponse.success(
            data=data,
            message=message,
            status_code=status.HTTP_201_CREATED
        )
    
    @staticmethod
    def not_found(
        message: str = "Kaynak bulunamadı",
        resource: str = "Resource"
    ) -> Response:
        """Create a standardized not found response"""
        return APIResponse.error(
            message=message,
            status_code=status.HTTP_404_NOT_FOUND,
            error_code="NOT_FOUND"
        )
    
    @staticmethod
    def forbidden(
        message: str = "Bu işlem için yetkiniz yok"
    ) -> Response:
        """Create a standardized forbidden response"""
        return APIResponse.error(
            message=message,
            status_code=status.HTTP_403_FORBIDDEN,
            error_code="FORBIDDEN"
        )
    
    @staticmethod
    def validation_error(
        field_errors: Dict,
        message: str = "Doğrulama hatası"
    ) -> Response:
        """Create a standardized validation error response"""
        return APIResponse.error(
            message=message,
            status_code=status.HTTP_400_BAD_REQUEST,
            error_code="VALIDATION_ERROR",
            field_errors=field_errors
        )
    
    @staticmethod
    def paginated(
        data: List,
        page: int,
        page_size: int,
        total_count: int,
        message: str = "Veriler başarıyla getirildi"
    ) -> Response:
        """Create a standardized paginated response"""
        total_pages = (total_count + page_size - 1) // page_size
        
        meta = {
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_count': total_count,
                'total_pages': total_pages,
                'has_next': page < total_pages,
                'has_previous': page > 1
            }
        }
        
        return APIResponse.success(
            data=data,
            message=message,
            meta=meta
        )

class ResponseMixin:
    """Mixin class for standardized responses in views"""
    
    def success_response(self, data=None, message="İşlem başarılı", status_code=200, meta=None):
        """Return success response"""
        return APIResponse.success(data, message, status_code, meta)
    
    def error_response(self, message="Bir hata oluştu", status_code=400, error_code="GENERIC_ERROR", details=None, field_errors=None):
        """Return error response"""
        return APIResponse.error(message, status_code, error_code, details, field_errors)
    
    def created_response(self, data=None, message="Kayıt başarıyla oluşturuldu"):
        """Return created response"""
        return APIResponse.created(data, message)
    
    def not_found_response(self, message="Kaynak bulunamadı"):
        """Return not found response"""
        return APIResponse.not_found(message)
    
    def forbidden_response(self, message="Bu işlem için yetkiniz yok"):
        """Return forbidden response"""
        return APIResponse.forbidden(message)
    
    def validation_error_response(self, field_errors, message="Doğrulama hatası"):
        """Return validation error response"""
        return APIResponse.validation_error(field_errors, message)
    
    def paginated_response(self, data, page, page_size, total_count, message="Veriler başarıyla getirildi"):
        """Return paginated response"""
        return APIResponse.paginated(data, page, page_size, total_count, message)
