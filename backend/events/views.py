# events/views.py
from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from .models import Event, EventRequest
from .serializers import EventSerializer, EventRequestSerializer
from groups.models import Group
try:
    from users.services.supabase_service import SupabaseStorage
    supabase = SupabaseStorage()
    print("SupabaseStorage başarıyla yüklendi")
except Exception as e:
    print(f"SupabaseStorage yükleme hatası: {str(e)}")
    import traceback
    traceback.print_exc()
    supabase = None

from users.serializers import UserSerializer  # Yeni import

class EventViewSet(viewsets.ModelViewSet):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (JSONParser, MultiPartParser, FormParser)

    def get_queryset(self):
        user = self.request.user
        print(f"get_queryset çağrıldı, kullanıcı: {user.username}")
        
        try:
            # En basit sorgu ile başlayalım
            print("En basit sorgu başlatılıyor...")
            
            # Sadece tüm etkinlikleri getir
            all_events = Event.objects.all().order_by('start_time')
            print(f"Tüm etkinlikler: {all_events.count()}")
            
            return all_events
            
        except Exception as e:
            print(f"get_queryset hatası: {str(e)}")
            print(f"Hata türü: {type(e)}")
            import traceback
            traceback.print_exc()
            
            # Hata durumunda boş queryset döndür
            return Event.objects.none()

    def create(self, request, *args, **kwargs):
        print("Gelen veri:", request.data)
        print("Dosyalar:", request.FILES)
        
        try:
            data = request.data.copy()
            cover_file = request.FILES.get('cover_image')
            
            # Cover image'ı data'dan çıkar çünkü Supabase'e yükleyeceğiz
            if cover_file and 'cover_image' in data:
                del data['cover_image']
            
            serializer = self.get_serializer(data=data)
            if not serializer.is_valid():
                print("Serializer hataları:", serializer.errors)
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
            # Etkinliği oluştur
            event = serializer.save(organizer=request.user)
            
            # Organizatörü katılımcı olarak ekle
            try:
                if request.user not in event.participants.all():
                    event.participants.add(request.user)
            except Exception as e:
                print(f"Organizatör ekleme hatası: {str(e)}")
                # Bu hata etkinlik oluşturmayı engellemez
                pass
            
            # Kapak resmi varsa Supabase'e yükle
            if cover_file and supabase is not None:
                try:
                    print(f"Resim yükleniyor: {cover_file.name}, boyut: {cover_file.size}")
                    cover_url = supabase.upload_event_picture(cover_file, str(event.id))
                    print(f"Resim URL'i alındı: {cover_url}")
                    event.cover_image = cover_url
                    event.save()
                    print("Event cover_image güncellendi")
                    serializer = self.get_serializer(event)
                except Exception as e:
                    print("Resim yükleme hatası:", str(e))
                    import traceback
                    traceback.print_exc()
                    # Resim yükleme hatası etkinlik oluşturmayı engellemez
                    pass
            elif cover_file and supabase is None:
                print("Supabase mevcut değil, resim yüklenemiyor")
                pass
            elif cover_file:
                print("Cover file var ama supabase None")
            else:
                print("Cover file yok")
            
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
            
        except Exception as e:
            print("Etkinlik oluşturma hatası:", str(e))
            return Response(
                {"error": "Etkinlik oluşturulurken bir hata oluştu"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def perform_create(self, serializer):
        # perform_create artık create metodunda yapılıyor, bu metod boş bırakıldı
        pass

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def join(self, request, pk=None):
        try:
            event = self.get_object()
            user = request.user

            # Kontenjan kontrolü
            if event.is_full():
                return Response({
                    "error": "Etkinlik kontenjanı dolmuştur.",
                    "error_type": "event_full",
                    "participant_count": event.current_participant_count,
                    "guest_limit": event.guest_limit
                }, status=status.HTTP_400_BAD_REQUEST)

            # Zaten katılıyor mu kontrolü
            if user in event.participants.all():
                return Response({
                    "error": "Zaten bu etkinliğe katılıyorsunuz.",
                    "error_type": "already_joined"
                }, status=status.HTTP_400_BAD_REQUEST)

            # Onay sistemi kontrolü
            if event.requires_approval:
                # Onay gerekiyorsa istek oluştur
                message = ''
                try:
                    # Form data veya JSON data'yı parse et
                    if hasattr(request, 'data'):
                        message = request.data.get('message', '')
                    else:
                        # POST data'yı da kontrol et
                        message = request.POST.get('message', '')
                except Exception as e:
                    print(f"Message parse hatası: {str(e)}")
                    message = ''
                
                try:
                    event_request, created = EventRequest.objects.get_or_create(
                        event=event,
                        user=user,
                        defaults={'message': message}
                    )
                except Exception as e:
                    print(f"EventRequest oluşturma hatası: {str(e)}")
                    raise e
                
                if not created:
                    # İstek durumunu kontrol et
                    request_status = event_request.status
                    status_message = {
                        'pending': 'Bu etkinlik için zaten bir katılım isteği gönderdiniz. Onay bekleniyor.',
                        'approved': 'Bu etkinliğe zaten katılıyorsunuz.',
                        'rejected': 'Bu etkinlik için gönderdiğiniz istek reddedilmiş. Yeni bir istek gönderebilirsiniz.'
                    }
                    
                    return Response({
                        "error": status_message.get(request_status, "Bu etkinlik için zaten bir istek gönderdiniz."),
                        "error_type": "request_exists",
                        "request_status": request_status
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                # Bildirim gönder
                try:
                    self._send_notification(
                        recipient=event.organizer,
                        sender=user,
                        notification_type='event_join_request',
                        message=f"{user.username} {event.title} etkinliğine katılmak istiyor.",
                        content_object=event_request
                    )
                except Exception as e:
                    print(f"Bildirim gönderme hatası: {str(e)}")
                    # Bildirim hatası etkinlik katılımını engellemez
                
                return Response({
                    "message": "Katılım isteği gönderildi. Onay bekleniyor.",
                    "request_created": True,
                    "event": self.get_serializer(event).data
                }, status=status.HTTP_200_OK)
            else:
                # Onay gerektirmiyorsa direkt katıl
                event.participants.add(user)
                serializer = self.get_serializer(event)
                return Response({
                    "message": "Etkinliğe başarıyla katıldınız.",
                    "event": serializer.data
                }, status=status.HTTP_200_OK)
                
        except Exception as e:
            print(f"Join event hatası: {str(e)}")
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
            print(f"Leave event hatası: {str(e)}")
            return Response(
                {"error": "Etkinlikten ayrılırken bir hata oluştu"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['get'])
    def requests(self, request, pk=None):
        """Etkinlik katılım isteklerini getir"""
        try:
            print(f"DEBUG: Event requests endpoint çağrıldı - Event ID: {pk}, User: {request.user.username}")
            event = self.get_object()
            print(f"DEBUG: Event bulundu: {event.title}")
            
            if request.user != event.organizer:
                print(f"DEBUG: Kullanıcı organizatör değil: {request.user.username} != {event.organizer.username}")
                return Response({"error": "Bu etkinliğin organizatörü değilsiniz."},
                                status=status.HTTP_403_FORBIDDEN)
            
            requests = EventRequest.objects.filter(event=event, status='pending')
            print(f"DEBUG: {requests.count()} adet pending request bulundu")
            
            serializer = EventRequestSerializer(requests, many=True)
            print(f"DEBUG: Serializer başarılı, {len(serializer.data)} item döndürülüyor")
            
            return Response(serializer.data)
        except Exception as e:
            print(f"Event requests hatası: {str(e)}")
            import traceback
            traceback.print_exc()
            return Response(
                {"error": "İstekler getirilirken bir hata oluştu"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def approve_request(self, request, pk=None):
        """Etkinlik katılım isteğini onayla"""
        try:
            event = self.get_object()
            if request.user != event.organizer:
                return Response({"error": "Bu etkinliğin organizatörü değilsiniz."},
                                status=status.HTTP_403_FORBIDDEN)
            
            request_id = request.data.get('request_id')
            if not request_id:
                return Response({"error": "İstek ID gerekli."},
                                status=status.HTTP_400_BAD_REQUEST)
            
            event_request = get_object_or_404(EventRequest, id=request_id, event=event)
            
            if event_request.status != 'pending':
                return Response({"error": "Bu istek zaten işlenmiş."},
                                status=status.HTTP_400_BAD_REQUEST)
            
            # Onayla
            event_request.status = 'approved'
            event_request.save()
            
            # Kullanıcıyı etkinliğe ekle
            event.participants.add(event_request.user)
            
            # Bildirim gönder
            self._send_notification(
                recipient=event_request.user,
                sender=request.user,
                notification_type='event_join_approved',
                message=f"{event.title} etkinliğine katılımınız onaylandı.",
                content_object=event
            )
            
            return Response({"message": "İstek onaylandı."})
        except Exception as e:
            print(f"Approve request hatası: {str(e)}")
            return Response(
                {"error": "İstek onaylanırken bir hata oluştu"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def reject_request(self, request, pk=None):
        """Etkinlik katılım isteğini reddet"""
        try:
            event = self.get_object()
            if request.user != event.organizer:
                return Response({"error": "Bu etkinliğin organizatörü değilsiniz."},
                                status=status.HTTP_403_FORBIDDEN)
            
            request_id = request.data.get('request_id')
            if not request_id:
                return Response({"error": "İstek ID gerekli."},
                                status=status.HTTP_400_BAD_REQUEST)
            
            event_request = get_object_or_404(EventRequest, id=request_id, event=event)
            
            if event_request.status != 'pending':
                return Response({"error": "Bu istek zaten işlenmiş."},
                                status=status.HTTP_400_BAD_REQUEST)
            
            # Reddet
            event_request.status = 'rejected'
            event_request.save()
            
            # Bildirim gönder
            self._send_notification(
                recipient=event_request.user,
                sender=request.user,
                notification_type='event_join_rejected',
                message=f"{event.title} etkinliğine katılımınız reddedildi.",
                content_object=event
            )
            
            return Response({"message": "İstek reddedildi."})
        except Exception as e:
            print(f"Reject request hatası: {str(e)}")
            return Response(
                {"error": "İstek reddedilirken bir hata oluştu"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def _send_notification(self, recipient, sender, notification_type, message, content_object=None):
        """Bildirim gönder"""
        try:
            from notifications.models import Notification
            from django.contrib.contenttypes.models import ContentType
            
            print(f"Bildirim gönderiliyor - Recipient: {recipient.username}, Sender: {sender.username}, Type: {notification_type}")
            
            # ContentType'ı manuel olarak ayarla
            content_type = None
            object_id = None
            if content_object:
                content_type = ContentType.objects.get_for_model(content_object)
                object_id = content_object.id
                print(f"ContentType: {content_type}, Object ID: {object_id}")
            
            notification = Notification.objects.create(
                recipient=recipient,
                sender=sender,
                notification_type=notification_type,
                message=message,
                content_type=content_type,
                object_id=object_id
            )
            print(f"Bildirim gönderildi: {notification}")
        except Exception as e:
            print(f"Bildirim gönderme hatası: {str(e)}")
            import traceback
            traceback.print_exc()

    # Yeni eklenen action - Katılımcıları getir
    @action(detail=True, methods=['get'])
    def participants(self, request, pk=None):
        try:
            event = self.get_object()
            participants = event.participants.all()
            serializer = UserSerializer(participants, many=True)
            return Response(serializer.data)
        except Exception as e:
            print(f"Participants getirme hatası: {str(e)}")
            return Response(
                {"error": "Katılımcılar getirilirken bir hata oluştu"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )