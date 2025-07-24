from rest_framework import generics, permissions
from .models import Event
from .serializers import EventSerializer
from groups.models import Group # Grubu kontrol etmek için
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied


# Gruba ait etkinlikleri listelemek ve yeni etkinlik oluşturmak için
class EventListCreateView(generics.ListCreateAPIView):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated] # Sadece giriş yapmış kullanıcılar etkinlik oluşturabilir ve görebilir

    def get_queryset(self):
        # URL'den gelen group_pk (grup ID'si) ile ilgili etkinlikleri filtrele
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)
        
        # Sadece grubun üyeleri etkinlikleri görebilir
        if self.request.user in group.members.all() or self.request.user == group.owner:
            return Event.objects.filter(group=group).order_by('start_time') # Başlangıç zamanına göre sırala
        else:
            raise PermissionDenied("Bu grubun etkinliklerini görüntüleme izniniz yok.")

    def perform_create(self, serializer):
        # Etkinliği oluşturan kullanıcıyı (organizer) ve grubu otomatik olarak ata
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)

        # Sadece grubun üyeleri etkinlik oluşturabilir
        if self.request.user in group.members.all() or self.request.user == group.owner:
            # group alanı serializer'da required=False olduğu için, burada atanması gerekiyor.
            # validated_data'dan participants çıkarıldıktan sonra save yapıyoruz.
            participants_data = serializer.validated_data.pop('participants', [])
            event = serializer.save(organizer=self.request.user, group=group)
            event.participants.set(participants_data) # Katılımcıları set et
        else:
            raise PermissionDenied("Bu gruba etkinlik oluşturma izniniz yok.")

# Tek bir etkinliği görmek, güncellemek veya silmek için
class EventDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Event.objects.all()
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated] # Sadece giriş yapmış kullanıcılar görebilir

    def get_object(self):
        # Etkinlik ID'si ile birlikte grup ID'sini de kontrol et
        obj = super().get_object()
        group_pk = self.kwargs.get('group_pk')
        
        if obj.group.pk != int(group_pk):
            raise PermissionDenied("Bu gruba ait olmayan bir etkinliğe erişmeye çalışıyorsunuz.")

        # Sadece grubun üyeleri etkinliği görebilir
        group = obj.group
        if self.request.user not in group.members.all() and self.request.user != group.owner:
            raise PermissionDenied("Bu grubun etkinliğini görüntüleme izniniz yok.")
            
        return obj

    def perform_update(self, serializer):
        # Sadece etkinliğin organizatörü veya grubun sahibi etkinliği güncelleyebilir
        if serializer.instance.organizer != self.request.user and serializer.instance.group.owner != self.request.user:
            raise PermissionDenied("Bu etkinliği düzenleme izniniz yok.")
        
        # Katılımcıları güncelleme sırasında ayır ve manuel olarak set et
        participants_data = serializer.validated_data.pop('participants', None)
        event = serializer.save()
        if participants_data is not None:
            event.participants.set(participants_data)

    def perform_destroy(self, instance):
        # Sadece etkinliğin organizatörü veya grubun sahibi etkinliği silebilir
        if instance.organizer != self.request.user and instance.group.owner != self.request.user:
            raise PermissionDenied("Bu etkinliği silme izniniz yok.")
        instance.delete()