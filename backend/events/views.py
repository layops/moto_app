from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied
from .models import Event
from .serializers import EventSerializer
from groups.models import Group
from users.services.supabase_service import SupabaseStorage

supabase = SupabaseStorage()


class AllEventListCreateView(generics.ListCreateAPIView):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        user = self.request.user
        user_groups = Group.objects.filter(Q(members=user) | Q(owner=user))
        return Event.objects.filter(
            Q(group__in=user_groups) | Q(group__isnull=True, organizer=user) |
            Q(is_public=True)
        ).distinct().order_by('start_time')

    def perform_create(self, serializer):
        user = self.request.user
        group = serializer.validated_data.get('group')
        cover_file = self.request.FILES.get('cover_image')

        if cover_file:
            cover_url = supabase.upload_event_picture(cover_file, user.id)
            serializer.validated_data['cover_image'] = cover_url

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

        cover_file = self.request.FILES.get('cover_image')
        if cover_file:
            cover_url = supabase.upload_event_picture(cover_file, user.id)
            serializer.validated_data['cover_image'] = cover_url

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
        user = self.request.user
        event = serializer.instance

        cover_file = self.request.FILES.get('cover_image')
        if cover_file:
            if event.cover_image:
                supabase.delete_event_picture(event.cover_image)
            cover_url = supabase.upload_event_picture(cover_file, user.id)
            serializer.validated_data['cover_image'] = cover_url

        if event.organizer != user and event.group.owner != user:
            raise PermissionDenied("Bu etkinliği düzenleme yetkiniz yok.")
        serializer.save()

    def perform_destroy(self, instance):
        user = self.request.user
        if instance.organizer != user and instance.group.owner != user:
            raise PermissionDenied("Bu etkinliği silme yetkiniz yok.")
        if instance.cover_image:
            supabase.delete_event_picture(instance.cover_image)
        instance.delete()


class EventJoinView(generics.UpdateAPIView):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Event.objects.all()

    def update(self, request, *args, **kwargs):
        event = self.get_object()
        user = request.user

        if event.is_full():
            return Response(
                {"error": "Etkinlik kontenjanı dolmuştur."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if user in event.participants.all():
            return Response(
                {"error": "Zaten bu etkinliğe katılıyorsunuz."},
                status=status.HTTP_400_BAD_REQUEST
            )

        event.participants.add(user)
        return Response(
            {"message": "Etkinliğe başarıyla katıldınız."},
            status=status.HTTP_200_OK
        )


class EventLeaveView(generics.UpdateAPIView):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Event.objects.all()

    def update(self, request, *args, **kwargs):
        event = self.get_object()
        user = request.user

        if user not in event.participants.all():
            return Response(
                {"error": "Bu etkinliğe zaten katılmıyorsunuz."},
                status=status.HTTP_400_BAD_REQUEST
            )

        event.participants.remove(user)
        return Response(
            {"message": "Etkinlikten ayrıldınız."},
            status=status.HTTP_200_OK
        )


class EventViewSet(viewsets.ModelViewSet):
    queryset = Event.objects.all()
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=True, methods=['post'])
    def join(self, request, pk=None):
        event = self.get_object()
        user = request.user

        if event.is_full():
            return Response(
                {"error": "Etkinlik kontenjanı dolmuştur."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if user in event.participants.all():
            return Response(
                {"error": "Zaten bu etkinliğe katılıyorsunuz."},
                status=status.HTTP_400_BAD_REQUEST
            )

        event.participants.add(user)
        return Response(
            {"message": "Etkinliğe başarıyla katıldınız."},
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=['post'])
    def leave(self, request, pk=None):
        event = self.get_object()
        user = request.user

        if user not in event.participants.all():
            return Response(
                {"error": "Bu etkinliğe zaten katılmıyorsunuz."},
                status=status.HTTP_400_BAD_REQUEST
            )

        event.participants.remove(user)
        return Response(
            {"message": "Etkinlikten ayrıldınız."},
            status=status.HTTP_200_OK
        )
