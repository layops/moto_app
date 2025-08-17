# moto_app/backend/posts/views.py

from rest_framework import generics, permissions
from rest_framework.response import Response
from .models import Post
from .serializers import PostSerializer
from groups.models import Group
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import MultiPartParser, FormParser

# Genel postları yönetir (grup dışı)
class GeneralPostListCreateView(generics.ListCreateAPIView):
    queryset = Post.objects.filter(group__isnull=True).order_by('-created_at')
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def perform_create(self, serializer):
        serializer.save(author=self.request.user, group=None)

# Grup postlarını yönetir
class GroupPostListCreateView(generics.ListCreateAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self):
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)

        if self.request.user in group.members.all() or self.request.user == group.owner:
            return Post.objects.filter(group=group).order_by('-created_at')
        raise PermissionDenied("Bu grubun gönderilerini görüntüleme izniniz yok.")

    def perform_create(self, serializer):
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)

        if self.request.user in group.members.all() or self.request.user == group.owner:
            serializer.save(author=self.request.user, group=group)
        else:
            raise PermissionDenied("Bu gruba gönderi oluşturma izniniz yok.")

# Tekil postlar için görünüm
class PostDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        obj = super().get_object()

        if obj.group:
            if self.request.user not in obj.group.members.all() and self.request.user != obj.group.owner:
                raise PermissionDenied("Bu gönderiyi görüntüleme izniniz yok.")

        return obj

    def perform_update(self, serializer):
        if serializer.instance.author != self.request.user:
            raise PermissionDenied("Bu gönderiyi düzenleme izniniz yok.")
        serializer.save()

    def perform_destroy(self, instance):
        if instance.author != self.request.user and (not instance.group or instance.group.owner != self.request.user):
            raise PermissionDenied("Bu gönderiyi silme izniniz yok.")
        instance.delete()