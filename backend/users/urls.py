# users/urls.py
from django.urls import path
from .views import (
    UserRegisterView,
    UserLoginView,
    TokenRefreshView,
    EmailVerificationView,
    ResendVerificationView,
    PasswordResetView,
    GoogleAuthView,
    GoogleCallbackView,
    VerifyTokenView,
    GoogleAuthTestView,
    # ProfileImageUploadView,  # Kaldırıldı - Yeni güvenli sistem kullanılıyor
    # CoverImageUploadView,    # Kaldırıldı - Yeni güvenli sistem kullanılıyor
    SupabaseStorageTestView,  # Supabase test endpoint'i
    UploadTestView,  # Upload test endpoint'i
    FollowToggleView,
    FollowersListView,
    FollowingListView,
    UserProfileView,
    UserPostsView,
    UserMediaView,
    UserEventsView,
    UserLogoutView,
    ChangePasswordView,  # Yeni eklendi
    create_test_users,  # Geçici test endpoint'i
    request_upload_permission,  # Upload permission endpoint'i
    confirm_upload  # Upload confirmation endpoint'i
)

urlpatterns = [
    # Register / Login
    path('register/', UserRegisterView.as_view(), name='user-register'),
    path('login/', UserLoginView.as_view(), name='user-login'),
    path('refresh-token/', TokenRefreshView.as_view(), name='token-refresh'),
    
    # Email Verification
    path('verify-email/', EmailVerificationView.as_view(), name='verify-email'),
    path('resend-verification/', ResendVerificationView.as_view(), name='resend-verification'),
    path('reset-password/', PasswordResetView.as_view(), name='reset-password'),
    
    # Google OAuth
    path('auth/google/', GoogleAuthView.as_view(), name='google-auth'),
    path('auth/callback/', GoogleCallbackView.as_view(), name='google-callback'),
    path('verify-token/', VerifyTokenView.as_view(), name='verify-token'),
    path('auth/test/', GoogleAuthTestView.as_view(), name='google-auth-test'),

    # Eski Profile Image Upload URL'leri kaldırıldı - Yeni güvenli sistem kullanılıyor
    # path('<str:username>/upload-photo/', ProfileImageUploadView.as_view(), name='profile-upload-photo'),
    # path('<str:username>/upload-cover/', CoverImageUploadView.as_view(), name='profile-upload-cover'),
    
    # Supabase Storage Test
    path('test-supabase-storage/', SupabaseStorageTestView.as_view(), name='test-supabase-storage'),
    path('test-upload/', UploadTestView.as_view(), name='test-upload'),

    # Follow / Followers / Following
    path('<str:username>/follow-toggle/', FollowToggleView.as_view(), name='follow-toggle-by-username'),
    path('<int:user_id>/follow-toggle/', FollowToggleView.as_view(), name='follow-toggle-by-id'),
    path('<str:username>/followers/', FollowersListView.as_view(), name='followers-list'),
    path('<str:username>/following/', FollowingListView.as_view(), name='following-list'),

    # User Profile
    path('<str:username>/profile/', UserProfileView.as_view(), name='user-profile'),

    # User Posts
    path('<str:username>/posts/', UserPostsView.as_view(), name='user-posts'),

    # User Media
    path('<str:username>/media/', UserMediaView.as_view(), name='user-media'),

    # User Events
    path('<str:username>/events/', UserEventsView.as_view(), name='user-events'),
    
    #Users Logout
    path('logout/', UserLogoutView.as_view(), name='user-logout'),
    
    # Change Password
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    
    # Geçici test endpoint'i
    path('create-test-users/', create_test_users, name='create-test-users'),
    
    # Upload Permission Endpoints
    path('upload-permission/', request_upload_permission, name='request-upload-permission'),
    path('confirm-upload/', confirm_upload, name='confirm-upload'),
]