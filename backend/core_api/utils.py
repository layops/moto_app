"""
Core API utilities and helper functions
"""
import logging
from typing import Any, Dict, Optional
from django.core.paginator import Paginator
from django.db.models import QuerySet
from rest_framework.response import Response
from rest_framework import status

logger = logging.getLogger(__name__)

class APIResponse:
    """Standardized API response helper"""
    
    @staticmethod
    def success(data: Any = None, message: str = "İşlem başarılı", status_code: int = status.HTTP_200_OK) -> Response:
        """Create a successful API response"""
        response_data = {
            'success': True,
            'message': message,
            'data': data,
        }
        return Response(response_data, status=status_code)
    
    @staticmethod
    def error(message: str = "Bir hata oluştu", details: Any = None, status_code: int = status.HTTP_400_BAD_REQUEST) -> Response:
        """Create an error API response"""
        response_data = {
            'success': False,
            'message': message,
            'details': details,
        }
        return Response(response_data, status=status_code)
    
    @staticmethod
    def paginated(queryset: QuerySet, page: int = 1, page_size: int = 20, serializer_class=None) -> Response:
        """Create a paginated response"""
        paginator = Paginator(queryset, page_size)
        page_obj = paginator.get_page(page)
        
        data = {
            'results': serializer_class(page_obj.object_list, many=True).data if serializer_class else list(page_obj.object_list),
            'pagination': {
                'current_page': page_obj.number,
                'total_pages': paginator.num_pages,
                'total_count': paginator.count,
                'has_next': page_obj.has_next(),
                'has_previous': page_obj.has_previous(),
                'next_page': page_obj.next_page_number() if page_obj.has_next() else None,
                'previous_page': page_obj.previous_page_number() if page_obj.has_previous() else None,
            }
        }
        
        return APIResponse.success(data=data, message="Veriler başarıyla getirildi")

def validate_required_fields(data: Dict, required_fields: list) -> Optional[str]:
    """
    Validate that all required fields are present in the data
    Returns error message if validation fails, None if successful
    """
    missing_fields = [field for field in required_fields if field not in data or not data[field]]
    
    if missing_fields:
        return f"Eksik alanlar: {', '.join(missing_fields)}"
    
    return None

def safe_get_user_from_request(request) -> Optional[Any]:
    """
    Safely get user from request, handle authentication errors
    """
    try:
        if hasattr(request, 'user') and request.user.is_authenticated:
            return request.user
        return None
    except Exception as e:
        logger.warning(f"Error getting user from request: {e}")
        return None

def log_api_call(request, response_status: int, extra_data: Dict = None):
    """
    Log API calls for monitoring and debugging
    """
    user_info = ""
    if hasattr(request, 'user') and request.user.is_authenticated:
        user_info = f"User: {request.user.username}"
    
    log_data = {
        'method': request.method,
        'path': request.path,
        'status': response_status,
        'user': user_info,
        'ip': request.META.get('REMOTE_ADDR', 'Unknown'),
    }
    
    if extra_data:
        log_data.update(extra_data)
    
    logger.info(f"API Call: {log_data}")

class CacheKeys:
    """Centralized cache key management"""
    
    @staticmethod
    def user_profile(user_id: int) -> str:
        return f"user_profile_{user_id}"
    
    @staticmethod
    def user_posts(user_id: int, page: int = 1) -> str:
        return f"user_posts_{user_id}_page_{page}"
    
    @staticmethod
    def group_posts(group_id: int, page: int = 1) -> str:
        return f"group_posts_{group_id}_page_{page}"
    
    @staticmethod
    def notifications(user_id: int) -> str:
        return f"notifications_{user_id}"
    
    @staticmethod
    def events_list(page: int = 1) -> str:
        return f"events_list_page_{page}"

def clean_phone_number(phone: str) -> str:
    """
    Clean and format phone number
    """
    if not phone:
        return ""
    
    # Remove all non-digit characters
    cleaned = ''.join(filter(str.isdigit, phone))
    
    # Add Turkish country code if not present
    if cleaned.startswith('0'):
        cleaned = '90' + cleaned[1:]
    elif not cleaned.startswith('90'):
        cleaned = '90' + cleaned
    
    return cleaned

def format_file_size(size_bytes: int) -> str:
    """
    Format file size in human readable format
    """
    if size_bytes == 0:
        return "0 B"
    
    size_names = ["B", "KB", "MB", "GB", "TB"]
    i = 0
    while size_bytes >= 1024 and i < len(size_names) - 1:
        size_bytes /= 1024.0
        i += 1
    
    return f"{size_bytes:.1f} {size_names[i]}"
