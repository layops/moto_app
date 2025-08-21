from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from django.db.models.functions import Lower
from unidecode import unidecode
from core_api.unaccent import Unaccent

from django.contrib.auth import get_user_model
from groups.models import Group
from groups.serializers import GroupSerializer
from users.serializers import UserSerializer

User = get_user_model()


class UserSearchView(generics.ListAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        query = self.request.query_params.get('q', None)
        if query:
            normalized_query = unidecode(query.lower())
            annotated = queryset.annotate(norm_username=Unaccent(Lower('username')))
            return annotated.filter(norm_username__icontains=normalized_query)
        return queryset


class GroupSearchView(generics.ListAPIView):
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
            return annotated.filter(
                Q(norm_name__icontains=normalized_query) |
                Q(norm_desc__icontains=normalized_query)
            )
        return queryset
