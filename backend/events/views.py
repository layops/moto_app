# events/views.py
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
try:
    from users.services.supabase_service import SupabaseStorage
    supabase = SupabaseStorage()
except Exception as e:
    supabase = None

from users.serializers import UserSerializer  # Yeni import

class EventViewSet(viewsets.ModelViewSet):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)

    def get_queryset(self):
        user = self.request.user
        
        try:
            # En basit sorgu ile başlayalım
            
            # Sadece tüm etkinlikleri getir
            return Event.objects.select_related('organizer').prefetch_related('participants').order_by('start_time')
            
        except Exception as e:
            import traceback
            traceback.print_exc()
            
            # Hata durumunda boş queryset döndür
            return Event.objects.none()

    def create(self, request, *args, **kwargs):
        
        try:
            data = request.data.copy()
            cover_file = request.FILES.get('cover_image')
            
            if cover_file and 'cover_image' in data:
                del data['cover_image']
            
            serializer = self.get_serializer(data=data)
            if not serializer.is_valid():
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
            # Etkinliği oluştur
            event = serializer.save(organizer=request.user)
            
            # Organizatörü katılımcı olarak ekle
            try:
                if request.user not in event.participants.all():
                    event.participants.add(request.user)
            except Exception as e:
                # Bu hata etkinlik oluşturmayı engellemez
            
            # Kapak resmi varsa yükle
            if cover_file and supabase is not None:
                try:
                    cover_url = supabase.upload_event_picture(cover_file, str(event.id))
                    event.cover_image = cover_url
                    event.save()
                    serializer = self.get_serializer(event)
                except Exception as e:
                    # Resim yükleme hatası etkinlik oluşturmayı engellemez
            elif cover_file and supabase is None:
            
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
            
        except Exception as e:
            return Response(
                {"error": "Etkinlik oluşturulurken bir hata oluştu"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def perform_create(self, serializer):
        # perform_create artık create metodunda yapılıyor, bu metod boş bırakıldı
        pass

    @action(detail=True, methods=['post'])
    def join(self, request, pk=None):
        try:
            event = self.get_object()
            user = request.user

            # Geçici olarak kaldırıldı - is_full metodu
            # if event.is_full():
            #     return Response({"error": "Etkinlik kontenjanı dolmuştur."},
            #                     status=status.HTTP_400_BAD_REQUEST)

            if user in event.participants.all():
                return Response({"error": "Zaten bu etkinliğe katılıyorsunuz."},
                                status=status.HTTP_400_BAD_REQUEST)

            event.participants.add(user)
            serializer = self.get_serializer(event)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            return Response(
                {"error": "Etkinliğe katılırken bir hata oluştu"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def leave(self, request, pk=None):
        try:
            event = self.get_object()
            user = request.user

            if user not in event.participants.all():
                return Response({"error": "Bu etkinliğe zaten katılmıyorsunuz."},
                                status=status.HTTP_400_BAD_REQUEST)

            event.participants.remove(user)
            serializer = self.get_serializer(event)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            return Response(
                {"error": "Etkinlikten ayrılırken bir hata oluştu"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    # Yeni eklenen action - Katılımcıları getir
    @action(detail=True, methods=['get'])
    def participants(self, request, pk=None):
        try:
            event = self.get_object()
            participants = event.participants.all()
            serializer = UserSerializer(participants, many=True)
            return Response(serializer.data)
        except Exception as e:
            return Response(
                {"error": "Katılımcılar getirilirken bir hata oluştu"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )