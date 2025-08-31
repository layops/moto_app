from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
import logging

logger = logging.getLogger(__name__)

def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    
    if response is None:
        logger.error(f"Unhandled exception: {exc}", exc_info=True)
        response = Response(
            {'error': 'Sunucu hatası oluştu'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
    return response