from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token

from django.db.models.functions import Lower
from django.db.models import Q

from unidecode import unidecode  # <-- unidecode import ettik
from core_api.unaccent import Unaccent  # Senin Unaccent fonksiyonun

from .serializers import UserRegisterSerializer, UserLoginSerializer, UserSerializer
from django.contrib.auth import get_user_model
User = get_user_model()

from groups.models import Group
from groups.serializers import GroupSerializer


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


@method_decorator(csrf_exempt, name='dispatch')
class UserLoginView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request, *args, **kwargs):
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
    Türkçe karakter uyumluluğu için unidecode ve Unaccent kullanılır.
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        query = self.request.query_params.get('q', None)

        if query:
            # Arama terimini küçük harfe çevirip, Türkçe karakterlerden arındırıyoruz
            normalized_query = unidecode(query.lower())

            # Veritabanında username alanını da benzer şekilde normalize ediyoruz
            annotated = queryset.annotate(
                norm_username=Unaccent(Lower('username'))
            )

            filtered = annotated.filter(norm_username__icontains=normalized_query)
            return filtered

        return queryset


class GroupSearchView(generics.ListAPIView):
    """
    Grupları adına veya açıklamasına göre arar.
    Sadece kimliği doğrulanmış kullanıcılar arama yapabilir.
    Türkçe karakter uyumluluğu için unidecode ve Unaccent kullanılır.
    """
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        query = self.request.query_params.get('q', None)

        if query:
            normalized_query = unidecode(query.lower())
            annotated = queryset.annotate(
                norm_name=Unaccent(Lower('name')),
                norm_desc=Unaccent(Lower('description'))
            )

            filtered = annotated.filter(
                Q(norm_name__icontains=normalized_query) |
                Q(norm_desc__icontains=normalized_query)
            )
            return filtered

        return queryset
