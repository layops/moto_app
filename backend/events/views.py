# events/views.py
from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.http import Http404
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from .models import Event, EventRequest
from .serializers import EventSerializer, EventRequestSerializer
from groups.models import Group
# Supabase integration removed - using direct Google OAuth
# supabase = None

# UserSerializer'ı lazy import edelim - circular import'u önlemek için
def get_user_serializer():
    from users.serializers import UserSerializer
    return UserSerializer

class EventViewSet(viewsets.ModelViewSet):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (JSONParser, MultiPartParser, FormParser)
    
    def get_permissions(self):
        """
        Event silme işlemi için sadece organizatör izni
        """
        if self.action == 'destroy':
            return [permissions.IsAuthenticated()]
        return super().get_permissions()
    
    def destroy(self, request, *args, **kwargs):
        """
        Event silme - sadece organizatör silebilir
        """
        try:
            event = self.get_object()
            if request.user != event.organizer:
                return Response(
                    {"error": "Bu etkinliği sadece organizatör silebilir."},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            print(f"DEBUG: Event siliniyor - ID: {event.id}, Title: {event.title}, Organizer: {event.organizer.username}")
            
            # Event'i sil
            event.delete()
            
            return Response(
                {"message": "Etkinlik başarıyla silindi."},
                status=status.HTTP_200_OK
            )
        except Exception as e:
            print(f"Event silme hatası: {str(e)}")
            import traceback
            traceback.print_exc()
            return Response(
                {"error": "Etkinlik silinirken bir hata oluştu"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def get_queryset(self):
        user = self.request.user
        print(f"get_queryset çağrıldı, kullanıcı: {user.username}")
        
        try:
            # En basit sorgu ile başlayalım
            print("En basit sorgu başlatılıyor...")
            
            # Sadece tüm etkinlikleri getir
            all_events = Event.objects.all().order_by('start_time')
            print(f"Tüm etkinlikler: {all_events.count()}")
            
            # Mevcut Event ID'lerini log'la
            event_ids = list(all_events.values_list('id', flat=True))
            print(f"Mevcut Event ID'leri: {event_ids}")
            
            # Her event'in detaylarını log'la
            for event in all_events:
                print(f"Event ID: {event.id}, Title: {event.title}, Start: {event.start_time}, End: {event.end_time}")
            
            return all_events
            
        except Exception as e:
            print(f"get_queryset hatası: {str(e)}")
            print(f"Hata türü: {type(e)}")
            import traceback
            traceback.print_exc()
            
            # Hata durumunda boş queryset döndür
            return Event.objects.none()

    def create(self, request, *args, **kwargs):
        print("=== EVENT OLUŞTURMA BAŞLADI ===")
        print("Gelen veri:", request.data)
        print("Dosyalar:", request.FILES)
        print("Content-Type:", request.content_type)
        print("FILES keys:", list(request.FILES.keys()))
        print("FILES values:", list(request.FILES.values()))
        
        try:
            data = request.data.copy()
            event_image_file = request.FILES.get('event_image')
            
            # Event image'ı data'dan çıkar çünkü Supabase'e yükleyeceğiz
            if event_image_file and 'event_image' in data:
                del data['event_image']
            
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
            
            # Event image upload to Supabase
            print(f"=== EVENT IMAGE UPLOAD KONTROL ===")
            print(f"event_image_file var mı: {event_image_file is not None}")
            
            upload_warnings = []
            
            if event_image_file:
                print(f"Event image file detayları:")
                print(f"  - Name: {event_image_file.name}")
                print(f"  - Size: {event_image_file.size}")
                print(f"  - Content-Type: {event_image_file.content_type}")
            
                # Dosya boyutu kontrolü (10MB limit)
                if event_image_file.size > 10 * 1024 * 1024:  # 10MB
                    print("❌ Dosya boyutu çok büyük. Maksimum 10MB olmalı.")
                    return Response({
                        'error': 'Dosya boyutu çok büyük. Maksimum 10MB olmalı.'
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                # Dosya formatı kontrolü
                allowed_formats = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
                if event_image_file.content_type not in allowed_formats:
                    print(f"❌ Geçersiz dosya formatı: {event_image_file.content_type}")
                    return Response({
                        'error': 'Geçersiz dosya formatı. JPEG, PNG, GIF veya WebP kullanın.'
                    }, status=status.HTTP_400_BAD_REQUEST)
            
                try:
                    from users.services.supabase_storage_service import SupabaseStorageService
                    print("SupabaseStorageService import edildi")
                    storage_service = SupabaseStorageService()
                    print(f"Storage service oluşturuldu, is_available: {storage_service.is_available}")
                    
                    if storage_service.is_available:
                        print(f"Event resmi yükleniyor: {event_image_file.name}, boyut: {event_image_file.size}")
                        upload_result = storage_service.upload_event_picture(event_image_file, str(event.id))
                        print(f"Upload sonucu: {upload_result}")
                        
                        if upload_result.get('success'):
                            event_image_url = upload_result.get('url')
                            print(f"Event resmi URL'i alındı: {event_image_url}")
                            
                            if event_image_url:
                                event.event_image = event_image_url
                                event.save()
                                print("✅ Event event_image güncellendi")
                            else:
                                warning_msg = upload_result.get('warning', 'URL oluşturulamadı')
                                print(f"⚠️ Event resmi yüklendi ama URL oluşturulamadı: {warning_msg}")
                                upload_warnings.append(f"Resim yüklendi ancak URL oluşturulamadı: {warning_msg}")
                        else:
                            error_msg = upload_result.get('error', 'Bilinmeyen hata')
                            print(f"❌ Event resmi yükleme başarısız: {error_msg}")
                            upload_warnings.append(f"Resim yüklenemedi: {error_msg}")
                    else:
                        print("❌ Supabase Storage servisi kullanılamıyor")
                        upload_warnings.append("Resim yükleme servisi kullanılamıyor")
                        
                except Exception as e:
                    print("❌ Event resmi yükleme hatası:", str(e))
                    import traceback
                    traceback.print_exc()
                    upload_warnings.append(f"Resim yükleme hatası: {str(e)}")
            else:
                print("❌ Event image file yok - FILES dict'inde event_image bulunamadı")
                print("Mevcut FILES keys:", list(request.FILES.keys()))
            
            # Event'i güncel haliyle serialize et
            final_serializer = self.get_serializer(event)
            response_data = final_serializer.data
            
            # Uyarılar varsa response'a ekle
            if upload_warnings:
                response_data['warnings'] = upload_warnings
            
            headers = self.get_success_headers(final_serializer.data)
            return Response(response_data, status=status.HTTP_201_CREATED, headers=headers)
            
        except Exception as e:
            print("Etkinlik oluşturma hatası:", str(e))
            import traceback
            traceback.print_exc()
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
                    print(f"DEBUG: EventRequest oluşturuluyor - Event: {event.id}, User: {user.username}, Message: {message}")
                    event_request, created = EventRequest.objects.get_or_create(
                        event=event,
                        user=user,
                        defaults={'message': message}
                    )
                    print(f"DEBUG: EventRequest {'oluşturuldu' if created else 'bulundu'} - ID: {event_request.id}, Status: {event_request.status}")
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
                
                # Bildirim gönder - Event ID'sini gönder (EventRequest ID'si yerine)
                try:
                    self._send_notification(
                        recipient=event.organizer,
                        sender=user,
                        notification_type='event_join_request',
                        message=f"{user.username} {event.title} etkinliğine katılmak istiyor.",
                        content_object=event  # EventRequest yerine Event gönder
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
            
            # Event'i bul
            try:
                event = self.get_object()
                print(f"DEBUG: Event bulundu: {event.title}")
            except Exception as e:
                print(f"DEBUG: Event bulunamadı - ID: {pk}, Hata: {str(e)}")
                return Response(
                    {"error": f"Event ID {pk} bulunamadı. Etkinlik mevcut değil veya silinmiş olabilir."},
                    status=status.HTTP_404_NOT_FOUND
                )
            
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

    # Yeni eklenen action - Katılımcıları getir
    @action(detail=True, methods=['get'])
    def participants(self, request, pk=None):
        try:
            print(f"DEBUG: Participants action çağrıldı - Event ID: {pk}, User: {request.user.username}")
            print(f"DEBUG: Request method: {request.method}")
            print(f"DEBUG: Request path: {request.path}")
            
            # Event ID'yi kwargs'dan al
            event_id = pk or request.kwargs.get('event_id')
            print(f"DEBUG: Event ID from kwargs: {event_id}")
            
            if not event_id:
                return Response(
                    {"error": "Event ID bulunamadı"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Event'i bul
            try:
                event = Event.objects.get(id=event_id)
                print(f"DEBUG: Event bulundu: {event.title}")
            except Event.DoesNotExist:
                print(f"DEBUG: Event bulunamadı - ID: {event_id}")
                # Mevcut Event ID'lerini de log'la
                existing_ids = list(Event.objects.values_list('id', flat=True))
                print(f"DEBUG: Mevcut Event ID'leri: {existing_ids}")
                return Response(
                    {"error": f"Event ID {event_id} bulunamadı. Mevcut Event ID'leri: {existing_ids}"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            participants = event.participants.all()
            print(f"DEBUG: {participants.count()} adet katılımcı bulundu")
            
            # UserSerializer'ı lazy import et
            UserSerializer = get_user_serializer()
            serializer = UserSerializer(participants, many=True)
            print(f"DEBUG: Serializer başarılı, {len(serializer.data)} item döndürülüyor")
            return Response(serializer.data)
        except Exception as e:
            print(f"Participants getirme hatası: {str(e)}")
            import traceback
            traceback.print_exc()
            return Response(
                {"error": "Katılımcılar getirilirken bir hata oluştu"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def approve_request(self, request, pk=None):
        """Etkinlik katılım isteğini onayla"""
        try:
            print(f"DEBUG: Approve request çağrıldı - Event ID: {pk}, User: {request.user.username}")
            print(f"DEBUG: Request data: {request.data}")
            print(f"DEBUG: Request method: {request.method}")
            
            event = self.get_object()
            print(f"DEBUG: Event bulundu: {event.title}")
            
            if request.user != event.organizer:
                print(f"DEBUG: Yetki hatası - User: {request.user.username}, Organizer: {event.organizer.username}")
                return Response({"error": "Bu etkinliğin organizatörü değilsiniz."},
                                status=status.HTTP_403_FORBIDDEN)
            
            request_id = request.data.get('request_id')
            print(f"DEBUG: Request ID: {request_id}")
            
            if not request_id:
                print("DEBUG: Request ID bulunamadı")
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
            print(f"DEBUG: Reject request çağrıldı - Event ID: {pk}, User: {request.user.username}")
            print(f"DEBUG: Request data: {request.data}")
            print(f"DEBUG: Request method: {request.method}")
            
            event = self.get_object()
            print(f"DEBUG: Event bulundu: {event.title}")
            
            if request.user != event.organizer:
                print(f"DEBUG: Yetki hatası - User: {request.user.username}, Organizer: {event.organizer.username}")
                return Response({"error": "Bu etkinliğin organizatörü değilsiniz."},
                                status=status.HTTP_403_FORBIDDEN)
            
            request_id = request.data.get('request_id')
            print(f"DEBUG: Request ID: {request_id}")
            
            if not request_id:
                print("DEBUG: Request ID bulunamadı")
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
            print(f"Bildirim oluşturuldu - ID: {notification.id}")
        except Exception as e:
            print(f"Bildirim gönderme hatası: {str(e)}")
            import traceback
            traceback.print_exc()


class EventRequestDetailView(generics.RetrieveAPIView):
    """EventRequest detay bilgilerini getir"""
    serializer_class = EventRequestSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return EventRequest.objects.all()
    
    def get_object(self):
        request_id = self.kwargs['pk']
        print(f"DEBUG: EventRequestDetailView çağrıldı - Request ID: {request_id}, User: {self.request.user.username}")
        
        # Mevcut EventRequest ID'lerini log'la
        existing_request_ids = list(EventRequest.objects.values_list('id', flat=True))
        print(f"DEBUG: Mevcut EventRequest ID'leri: {existing_request_ids}")
        
        try:
            event_request = EventRequest.objects.get(pk=request_id)
            print(f"DEBUG: EventRequest bulundu - ID: {event_request.id}, Event: {event_request.event.title}, User: {event_request.user.username}")
            
            # Sadece event organizatörü veya istek sahibi görebilir
            if (self.request.user != event_request.event.organizer and 
                self.request.user != event_request.user):
                print(f"DEBUG: Yetki hatası - User: {self.request.user.username}, Organizer: {event_request.event.organizer.username}, Request User: {event_request.user.username}")
                raise PermissionDenied("Bu isteği görme yetkiniz yok.")
            
            return event_request
        except EventRequest.DoesNotExist:
            print(f"DEBUG: EventRequest bulunamadı - ID: {request_id}")
            raise Http404(f"EventRequest ID {request_id} bulunamadı. Mevcut EventRequest ID'leri: {existing_request_ids}")