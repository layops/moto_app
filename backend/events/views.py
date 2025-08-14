from rest_framework import generics, permissions
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied
from .models import Event
from .serializers import EventSerializer
from groups.models import Group

class EventListCreateView(generics.ListCreateAPIView):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        group_pk = self.kwargs['group_pk']
        group = get_object_or_404(Group, pk=group_pk)
        if self.request.user in group.members.all() or self.request.user == group.owner:
            return Event.objects.filter(group=group).order_by('start_time')
        raise PermissionDenied("Bu grubun etkinliklerini görme yetkiniz yok.")

    def perform_create(self, serializer):
        group_pk = self.kwargs['group_pk']
        group = get_object_or_404(Group, pk=group_pk)
        if self.request.user in group.members.all() or self.request.user == group.owner:
            serializer.save(organizer=self.request.user, group=group)
        else:
            raise PermissionDenied("Bu gruba etkinlik ekleme yetkiniz yok.")

class EventDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        group_pk = self.kwargs['group_pk']
        group = get_object_or_404(Group, pk=group_pk)
        if self.request.user in group.members.all() or self.request.user == group.owner:
            return Event.objects.filter(group=group)
        raise PermissionDenied("Bu grubun etkinliklerini görme yetkiniz yok.")

    def perform_update(self, serializer):
        if serializer.instance.organizer != self.request.user and serializer.instance.group.owner != self.request.user:
            raise PermissionDenied("Bu etkinliği düzenleme yetkiniz yok.")
        serializer.save()

    def perform_destroy(self, instance):
        if instance.organizer != self.request.user and instance.group.owner != self.request.user:
            raise PermissionDenied("Bu etkinliği silme yetkiniz yok.")
        instance.delete()
