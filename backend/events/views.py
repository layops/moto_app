from rest_framework import generics, permissions
from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied
from .models import Event
from .serializers import EventSerializer
from groups.models import Group

class AllEventListCreateView(generics.ListCreateAPIView):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        user = self.request.user
        user_groups = Group.objects.filter(Q(members=user) | Q(owner=user))
        return Event.objects.filter(
            Q(group__in=user_groups) | Q(group__isnull=True, organizer=user)
        ).order_by('start_time')

    def perform_create(self, serializer):
        user = self.request.user
        group = serializer.validated_data.get('group')
        if group:
            if (user in group.members.all()) or (group.owner == user):
                serializer.save(organizer=user, group=group)
            else:
                raise PermissionDenied("Bu gruba etkinlik ekleme yetkiniz yok.")
        else:
            serializer.save(organizer=user, group=None)

class EventListCreateView(generics.ListCreateAPIView):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        group_pk = self.kwargs['group_pk']
        group = get_object_or_404(Group, pk=group_pk)
        user = self.request.user
        if (user in group.members.all()) or (user == group.owner):
            return Event.objects.filter(group=group).order_by('start_time')
        raise PermissionDenied("Bu grubun etkinliklerini görme yetkiniz yok.")

    def perform_create(self, serializer):
        group_pk = self.kwargs['group_pk']
        group = get_object_or_404(Group, pk=group_pk)
        user = self.request.user
        if (user in group.members.all()) or (user == group.owner):
            serializer.save(organizer=user, group=group)
        else:
            raise PermissionDenied("Bu gruba etkinlik ekleme yetkiniz yok.")

class EventDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        group_pk = self.kwargs['group_pk']
        group = get_object_or_404(Group, pk=group_pk)
        user = self.request.user
        if (user in group.members.all()) or (user == group.owner):
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
