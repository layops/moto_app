from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import MultiPartParser, FormParser

from .models import Event
from .serializers import EventSerializer
from groups.models import Group
from users.services.supabase_service import SupabaseStorage

supabase = SupabaseStorage()

class EventViewSet(viewsets.ModelViewSet):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)

    def get_queryset(self):
        user = self.request.user
        user_groups = Group.objects.filter(Q(members=user) | Q(owner=user))
        return Event.objects.filter(
            Q(group__in=user_groups) | Q(group__isnull=True, organizer=user) |
            Q(is_public=True)
        ).distinct().order_by('start_time')

    def create(self, request, *args, **kwargs):
        print("Gelen veri:", request.data)
        print("Dosyalar:", request.FILES)
        
        data = request.data.copy()
        cover_file = request.FILES.get('cover_image')
        
        # Cover image dosyası varsa, veriden kaldır
        if cover_file and 'cover_image' in data:
            del data['cover_image']
        
        serializer = self.get_serializer(data=data)
        if not serializer.is_valid():
            print("Serializer hataları:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        # Önce event'i oluştur
        event = serializer.save(organizer=request.user)
        
        # Cover image yükleme işlemi
        if cover_file:
            try:
                cover_url = supabase.upload_event_picture(cover_file, str(event.id))
                event.cover_image = cover_url
                event.save()
                
                # Serializer'ı güncelle
                serializer = self.get_serializer(event)
            except Exception as e:
                print("Resim yükleme hatası:", str(e))
                # Hata durumunda event'i silebilir veya olduğu gibi bırakabilirsiniz
                # event.delete()
                # return Response({"error": "Resim yüklenemedi"}, status=status.HTTP_400_BAD_REQUEST)
        
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

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

    @action(detail=True, methods=['post'])
    def join(self, request, pk=None):
        event = self.get_object()
        user = request.user

        if event.is_full():
            return Response({"error": "Etkinlik kontenjanı dolmuştur."},
                            status=status.HTTP_400_BAD_REQUEST)

        if user in event.participants.all():
            return Response({"error": "Zaten bu etkinliğe katılıyorsunuz."},
                            status=status.HTTP_400_BAD_REQUEST)

        event.participants.add(user)
        
        # Güncellenmiş event verisi ile response döndür
        serializer = self.get_serializer(event)
        return Response({
            "message": "Etkinliğe başarıyla katıldınız.",
            "event": serializer.data
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def leave(self, request, pk=None):
        event = self.get_object()
        user = request.user

        if user not in event.participants.all():
            return Response({"error": "Bu etkinliğe zaten katılmıyorsunuz."},
                            status=status.HTTP_400_BAD_REQUEST)

        event.participants.remove(user)
        
        # Güncellenmiş event verisi ile response döndür
        serializer = self.get_serializer(event)
        return Response({
            "message": "Etkinlikten ayrıldınız.",
            "event": serializer.data
        }, status=status.HTTP_200_OK)