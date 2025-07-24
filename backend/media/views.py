# moto_app/backend/media/views.py

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Media
from groups.models import Group
from .serializers import MediaSerializer
from users.models import CustomUser

from rest_framework.parsers import MultiPartParser, FormParser 


class IsGroupMemberOrOwner(permissions.BasePermission):
    """
    Sadece grubun üyeleri veya sahibi medya dosyalarına erişebilir ve yükleyebilir.
    """
    def has_permission(self, request, view):
        group_pk = view.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)
        return request.user.is_authenticated and (request.user == group.owner or request.user in group.members.all())

    def has_object_permission(self, request, view, obj):
        # Medya dosyasının sahibi veya grup sahibi düzenleme/silme yapabilir.
        if request.method in permissions.SAFE_METHODS:
            return True # Okuma herkes için (grup üyesi/sahibi)
        return obj.uploaded_by == request.user or obj.group.owner == request.user


class MediaListCreateView(generics.ListCreateAPIView):
    serializer_class = MediaSerializer
    permission_classes = [permissions.IsAuthenticated, IsGroupMemberOrOwner]

    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self):
        group_pk = self.kwargs['group_pk']
        group = get_object_or_404(Group, pk=group_pk)
        return Media.objects.filter(group=group).order_by('-uploaded_at')

    def perform_create(self, serializer):
        group_pk = self.kwargs['group_pk']
        group = get_object_or_404(Group, pk=group_pk)
        serializer.save(uploaded_by=self.request.user, group=group)


class MediaDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Media.objects.all()
    serializer_class = MediaSerializer
    permission_classes = [permissions.IsAuthenticated, IsGroupMemberOrOwner]

    def get_object(self):
        group_pk = self.kwargs['group_pk']
        media_pk = self.kwargs['pk']
        group = get_object_or_404(Group, pk=group_pk)
        obj = get_object_or_404(Media, pk=media_pk, group=group)
        self.check_object_permissions(self.request, obj)
        return obj