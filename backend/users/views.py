# ... existing code ...

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status

@api_view(['POST'])
@permission_classes([AllowAny])  # Geçici olarak herkese açık
def create_test_users(request):
    """Test kullanıcıları oluşturmak için geçici endpoint"""
    from django.contrib.auth import get_user_model
    User = get_user_model()
    
    test_users = [
        {'username': 'ahmet', 'email': 'ahmet@test.com', 'first_name': 'Ahmet', 'last_name': 'Yılmaz'},
        {'username': 'mehmet', 'email': 'mehmet@test.com', 'first_name': 'Mehmet', 'last_name': 'Kaya'},
        {'username': 'ayse', 'email': 'ayse@test.com', 'first_name': 'Ayşe', 'last_name': 'Demir'},
    ]
    
    created_users = []
    
    for user_data in test_users:
        if not User.objects.filter(username=user_data['username']).exists():
            user = User.objects.create_user(
                username=user_data['username'],
                email=user_data['email'],
                first_name=user_data['first_name'],
                last_name=user_data['last_name'],
                password='test123',
                is_active=True
            )
            created_users.append(user.username)
    
    return Response({
        'message': f'{len(created_users)} test kullanıcısı oluşturuldu',
        'created_users': created_users,
        'total_users': User.objects.count()
    }, status=status.HTTP_201_CREATED)