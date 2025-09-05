from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import GroupMessage
from .serializers import GroupMessageSerializer
from groups.models import Group

class GroupMessageViewSet(viewsets.ModelViewSet):
    serializer_class = GroupMessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        group_pk = self.kwargs.get('group_pk')
        if group_pk:
            group = get_object_or_404(Group, pk=group_pk)
            return GroupMessage.objects.filter(group=group)
        return GroupMessage.objects.none()

    def perform_create(self, serializer):
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)
        
        # Kullanıcının grup üyesi olup olmadığını kontrol et
        if self.request.user not in group.members.all() and self.request.user != group.owner:
            return Response(
                {'detail': 'Bu grubun üyesi değilsiniz.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer.save(sender=self.request.user, group=group)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Sadece mesaj sahibi düzenleyebilir
        if instance.sender != request.user:
            return Response(
                {'detail': 'Bu mesajı düzenleme yetkiniz yok.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Sadece mesaj sahibi veya grup sahibi silebilir
        if instance.sender != request.user and instance.group.owner != request.user:
            return Response(
                {'detail': 'Bu mesajı silme yetkiniz yok.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        return super().destroy(request, *args, **kwargs)
