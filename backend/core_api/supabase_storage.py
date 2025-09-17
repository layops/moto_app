"""
Supabase Storage utility for file uploads
"""
import os
import requests
from typing import Optional, Dict, Any
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

class SupabaseStorageClient:
    """Supabase Storage client for file uploads"""
    
    def __init__(self):
        self.supabase_url = getattr(settings, 'SUPABASE_URL', None)
        self.supabase_key = getattr(settings, 'SUPABASE_ANON_KEY', None)
        self.service_role_key = getattr(settings, 'SUPABASE_SERVICE_ROLE_KEY', None)
        
        if not self.supabase_url or not self.supabase_key:
            logger.warning("Supabase credentials not configured")
    
    def upload_file(self, file, bucket: str, file_path: str, 
                   content_type: Optional[str] = None) -> Dict[str, Any]:
        """
        Upload a file to Supabase Storage
        
        Args:
            file: Django UploadedFile object
            bucket: Storage bucket name
            file_path: Path within the bucket
            content_type: MIME type of the file
            
        Returns:
            Dict with success status and file URL or error message
        """
        if not self.supabase_url or not self.supabase_key:
            return {
                'success': False,
                'error': 'Supabase not configured'
            }
        
        try:
            # Prepare headers
            headers = {
                'Authorization': f'Bearer {self.supabase_key}',
                'Content-Type': content_type or 'application/octet-stream'
            }
            
            # Construct upload URL
            upload_url = f"{self.supabase_url}/storage/v1/object/{bucket}/{file_path}"
            
            # Read file content
            file.seek(0)  # Reset file pointer
            file_content = file.read()
            
            # Upload file
            response = requests.post(
                upload_url,
                headers=headers,
                data=file_content
            )
            
            if response.status_code == 200:
                # Get public URL
                public_url = f"{self.supabase_url}/storage/v1/object/public/{bucket}/{file_path}"
                
                return {
                    'success': True,
                    'url': public_url,
                    'path': file_path
                }
            else:
                logger.error(f"Supabase upload failed: {response.status_code} - {response.text}")
                return {
                    'success': False,
                    'error': f'Upload failed: {response.status_code}',
                    'details': response.text
                }
                
        except Exception as e:
            logger.error(f"Supabase upload error: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def delete_file(self, bucket: str, file_path: str) -> Dict[str, Any]:
        """
        Delete a file from Supabase Storage
        
        Args:
            bucket: Storage bucket name
            file_path: Path within the bucket
            
        Returns:
            Dict with success status
        """
        if not self.supabase_url or not self.supabase_key:
            return {
                'success': False,
                'error': 'Supabase not configured'
            }
        
        try:
            # Prepare headers
            headers = {
                'Authorization': f'Bearer {self.supabase_key}'
            }
            
            # Construct delete URL
            delete_url = f"{self.supabase_url}/storage/v1/object/{bucket}/{file_path}"
            
            # Delete file
            response = requests.delete(delete_url, headers=headers)
            
            if response.status_code in [200, 204]:
                return {
                    'success': True,
                    'message': 'File deleted successfully'
                }
            else:
                logger.error(f"Supabase delete failed: {response.status_code} - {response.text}")
                return {
                    'success': False,
                    'error': f'Delete failed: {response.status_code}',
                    'details': response.text
                }
                
        except Exception as e:
            logger.error(f"Supabase delete error: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def generate_file_path(self, user_id: int, file_name: str, 
                          folder: str = 'uploads') -> str:
        """
        Generate a unique file path for upload
        
        Args:
            user_id: User ID
            file_name: Original file name
            folder: Folder name
            
        Returns:
            Generated file path
        """
        import uuid
        import os
        
        # Get file extension
        _, ext = os.path.splitext(file_name)
        
        # Generate unique filename
        unique_name = f"{uuid.uuid4()}{ext}"
        
        return f"{folder}/{user_id}/{unique_name}"

# Global instance
supabase_storage = SupabaseStorageClient()
