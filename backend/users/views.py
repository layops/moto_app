from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics, permissions # generics ve permissions eklendi
from rest_framework.authtoken.models import Token 
from rest_framework.permissions import AllowAny, IsAuthenticated # IsAuthenticated eklendi

# Kendi oluşturduğumuz serileştiricileri import ediyoruz
from .serializers import UserRegisterSerializer, UserLoginSerializer, UserSerializer # UserSerializer eklendi
from django.contrib.auth import get_user_model
User = get_user_model()

# Grupları aramak için Group modelini import ediyoruz
from groups.models import Group # Group modeli import edildi
from groups.serializers import GroupSerializer # GroupSerializer import edildi


# UserRegisterView'e csrf_exempt dekoratörünü ekle
@method_decorator(csrf_exempt, name='dispatch') 
class UserRegisterView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request, *args, **kwargs):
        serializer = UserRegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save() 

            token, created = Token.objects.get_or_create(user=user)

            response_data = serializer.data
            response_data['token'] = token.key

            return Response(response_data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# UserLoginView'e csrf_exempt dekoratörünü ekle
@method_decorator(csrf_exempt, name='dispatch') 
class UserLoginView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request, *args, **kwargs):
        print("DEBUG: userLoginView post metotu... ")
        serializer = UserLoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            
            token, created = Token.objects.get_or_create(user=user)
            
            return Response({'token': token.key, 'username': user.username}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UserSearchView(generics.ListAPIView):
    """
    Kullanıcıları kullanıcı adına göre arar.
    Sadece kimliği doğrulanmış kullanıcılar arama yapabilir.
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        query = self.request.query_params.get('q', None) # 'q' parametresi ile arama sorgusu alınır

        if query:
            # Kullanıcı adında arama sorgusunu içeren kullanıcıları filtrele
            queryset = queryset.filter(username__icontains=query)
        return queryset


class GroupSearchView(generics.ListAPIView):
    """
    Grupları adına veya açıklamasına göre arar.
    Sadece kimliği doğrulanmış kullanıcılar arama yapabilir.
    """
    queryset = Group.objects.all()
    serializer_class = GroupSerializer # groups uygulamasından GroupSerializer kullanılıyor
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        query = self.request.query_params.get('q', None) # 'q' parametresi ile arama sorgusu alınır

        if query:
            # Grup adında veya açıklamasında arama sorgusunu içeren grupları filtrele
            queryset = queryset.filter(name__icontains=query) | \
                       queryset.filter(description__icontains=query)
        return queryset