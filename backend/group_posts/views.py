from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from .models import Post
from .serializers import PostSerializer
from groups.models import Group

class PostViewSet(viewsets.ModelViewSet):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)

    def get_queryset(self):
        group_pk = self.kwargs.get('group_pk')
        if group_pk:
            group = get_object_or_404(Group, pk=group_pk)
            return Post.objects.filter(group=group)
        return Post.objects.all()

    def perform_create(self, serializer):
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)
        
        # Kullanıcının grup üyesi olup olmadığını kontrol et
        if self.request.user not in group.members.all() and self.request.user != group.owner:
            return Response(
                {'detail': 'Bu grubun üyesi değilsiniz.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer.save(author=self.request.user, group=group)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Sadece post sahibi veya grup sahibi düzenleyebilir
        if instance.author != request.user and instance.group.owner != request.user:
            return Response(
                {'detail': 'Bu postu düzenleme yetkiniz yok.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Sadece post sahibi veya grup sahibi silebilir
        if instance.author != request.user and instance.group.owner != request.user:
            return Response(
                {'detail': 'Bu postu silme yetkiniz yok.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        return super().destroy(request, *args, **kwargs)
