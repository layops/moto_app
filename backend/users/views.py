# moto_app/backend/users/views.py

# Yeni import'ları ekle:
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.authtoken.models import Token # Token modelini kullanmak için
from rest_framework.permissions import AllowAny # Kayıt ve giriş için kimlik doğrulama gerektirmemek adına

# Kendi oluşturduğumuz serileştiricileri import ediyoruz
from .serializers import UserRegisterSerializer, UserLoginSerializer
# from django.contrib.auth import get_user_model # Eğer views içinde User modelini doğrudan kullanacaksanız uncomment edebilirsiniz
# User = get_user_model()


# UserRegisterView'e csrf_exempt dekoratörünü ekle
@method_decorator(csrf_exempt, name='dispatch') # <-- Bu satırı ekle
class UserRegisterView(APIView):
    # Kayıt endpoint'inin herkes tarafından erişilebilir olması için
    permission_classes = (AllowAny,)

    def post(self, request, *args, **kwargs):
        serializer = UserRegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save() # Kullanıcıyı kaydet

            # Kullanıcı kaydedildikten sonra bir token oluştur ve yanıta ekle
            token, created = Token.objects.get_or_create(user=user)

            # Serileştiricinin döndürdüğü veriyi al ve token'ı ekle
            response_data = serializer.data
            response_data['token'] = token.key

            return Response(response_data, status=status.HTTP_201_CREATED)
        # Eğer serileştirici geçerli değilse, hata mesajlarını döndür
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# UserLoginView'e csrf_exempt dekoratörünü ekle
@method_decorator(csrf_exempt, name='dispatch') # <-- Bu satırı ekle
class UserLoginView(APIView):
    # Giriş endpoint'inin de herkes tarafından erişilebilir olması için
    permission_classes = (AllowAny,)

    def post(self, request, *args, **kwargs):
        print("DEBUG: userLoginView post metotu... ")
        serializer = UserLoginSerializer(data=request.data)
        if serializer.is_valid():
            # Serileştirici içindeki validate metodu kullanıcıyı döndürecek
            user = serializer.validated_data['user']
            
            # Kullanıcı için mevcut token'ı al veya yeni bir tane oluştur
            token, created = Token.objects.get_or_create(user=user)
            
            # Başarılı giriş yanıtına token ve kullanıcı adını ekle
            return Response({'token': token.key, 'username': user.username}, status=status.HTTP_200_OK)
        # Eğer serileştirici geçerli değilse, hata mesajlarını döndür
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)