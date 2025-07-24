# moto_app/backend/groups/views.py

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from .models import Group
from .serializers import GroupSerializer, GroupMemberSerializer # GroupMemberSerializer'ı import etmeyi unutmayın
from users.models import CustomUser # CustomUser modelini import etmeyi unutmayın


class IsGroupOwnerOrReadOnly(permissions.BasePermission):
    """
    Sadece grup sahibinin objeyi düzenlemesine/silmesine izin verir.
    Diğerleri sadece okuyabilir.
    """
    def has_object_permission(self, request, view, obj):
        # Okuma izinleri tüm kimliği doğrulanmış isteklere verilir.
        if request.method in permissions.SAFE_METHODS:
            return True
        # Yazma izinleri sadece grup sahibine verilir.
        return obj.owner == request.user


class IsGroupOwnerOrMember(permissions.BasePermission):
    """
    Sadece grup sahibi veya üyelerin erişmesine izin verir.
    """
    def has_object_permission(self, request, view, obj):
        if request.user.is_authenticated:
            return request.user == obj.owner or request.user in obj.members.all()
        return False

    def has_permission(self, request, view):
        # Listeleme veya oluşturma durumunda, sadece kimliği doğrulanmış kullanıcılar erişebilir.
        return request.user.is_authenticated


class GroupListCreateView(generics.ListCreateAPIView):
    queryset = Group.objects.all().order_by('-created_at')
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        # Grubu oluşturan kullanıcıyı otomatik olarak owner olarak ayarla
        serializer.save(owner=self.request.user)


class GroupDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [IsGroupOwnerOrReadOnly] # Sadece sahibi güncelleyebilir/silebilir


class GroupMembersView(generics.ListAPIView):
    """
    Bir grubun üyelerini listeler. Sadece grup üyeleri veya sahibi görebilir.
    """
    serializer_class = CustomUser # Üyelerin CustomUser detaylarını göstermek için
    permission_classes = [permissions.IsAuthenticated, IsGroupOwnerOrMember]

    def get_queryset(self):
        group_pk = self.kwargs['pk']
        group = get_object_or_404(Group, pk=group_pk)
        
        # IsGroupOwnerOrMember permission objenin kendisine uygulanır.
        # Burada sadece queryset'i döndürüyoruz, izin kontrolü has_object_permission'da yapılır.
        return group.members.all()


class GroupJoinLeaveView(generics.UpdateAPIView):
    """
    Kullanıcının bir gruba katılmasını veya ayrılmasını sağlar.
    """
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, *args, **kwargs):
        group = self.get_object()
        user = request.user

        action = request.data.get('action') # 'join' veya 'leave'
        
        if action == 'join':
            if user not in group.members.all():
                group.members.add(user)
                return Response({'detail': 'Gruba başarıyla katıldınız.'}, status=status.HTTP_200_OK)
            else:
                return Response({'detail': 'Zaten grubun üyesisiniz.'}, status=status.HTTP_400_BAD_REQUEST)
        elif action == 'leave':
            if user in group.members.all():
                group.members.remove(user)
                return Response({'detail': 'Gruptan başarıyla ayrıldınız.'}, status=status.HTTP_200_OK)
            else:
                return Response({'detail': 'Grubun üyesi değilsiniz.'}, status=status.HTTP_400_BAD_REQUEST)
        else:
            return Response({'detail': 'Geçersiz eylem. "join" veya "leave" olmalı.'}, status=status.HTTP_400_BAD_REQUEST)


class GroupMemberDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Bir grubun belirli bir üyesini yönetir (rolünü güncelleme, gruptan çıkarma).
    Sadece grup sahibi bu işlemleri yapabilir.
    """
    serializer_class = GroupMemberSerializer # Sadece üyenin bilgilerini değil, GroupMember modelini serialize edecek bir serializer olmalı
    permission_classes = [permissions.IsAuthenticated, IsGroupOwnerOrReadOnly] # Grup sahibi izni
    queryset = Group.objects.all() # Group objesini almak için

    def get_object(self):
        # URL'den group_pk ve user_pk'yi al
        group_pk = self.kwargs['group_pk']
        user_pk = self.kwargs['user_pk']
        
        group = get_object_or_404(Group, pk=group_pk)
        member = get_object_or_404(CustomUser, pk=user_pk) # Üye CustomUser modelinden alınır

        # Üyenin gerçekten grubun bir üyesi olup olmadığını kontrol et
        if not group.members.filter(pk=user_pk).exists():
            raise Http404("Belirtilen kullanıcı bu grubun bir üyesi değil.")
            
        # Grup sahibinin kendisini silmesini engelle
        if group.owner == member:
            raise PermissionDenied("Grup sahibi kendisini gruptan çıkaramaz.")

        # İzin kontrolü için grubu döndür (IsGroupOwnerOrReadOnly objeye uygulanır)
        self.check_object_permissions(self.request, group)
        
        return group # Group objesini döndürüyoruz çünkü permission üzerinde çalışacak

    def get_serializer_context(self):
        # Serializer'a grubun ve üyenin bilgisini gönder
        context = super().get_serializer_context()
        context['group_pk'] = self.kwargs['group_pk']
        context['user_pk'] = self.kwargs['user_pk']
        return context

    def put(self, request, *args, **kwargs):
        # Üyenin rolünü güncelleme veya gruptan çıkarma (PUT/PATCH için)
        group = self.get_object() # get_object() Group modelini döndürür
        user_to_manage = get_object_or_404(CustomUser, pk=self.kwargs['user_pk'])

        # Sadece sahibi işlemi yapabilir
        if group.owner != request.user:
            raise PermissionDenied("Sadece grup sahibi bu üyenin rolünü güncelleyebilir veya çıkarabilir.")

        # Bu kısımda GroupMemberSerializer'ı kullanmanız gerekecek.
        # Eğer rol güncellemesi yapacaksanız, GroupMember modeli üzerinden yapmalısınız.
        # Şu anki serializer yapınız GroupMember objesi için değil CustomUser için.
        # Eğer GroupMember modelinizde rol alanı varsa, onun üzerinden ilerlemeniz gerekir.
        # Basitçe gruptan çıkarmak için:
        action_type = request.data.get('action')
        if action_type == 'remove':
            group.members.remove(user_to_manage)
            return Response({'detail': f"{user_to_manage.username} gruptan çıkarıldı."}, status=status.HTTP_200_OK)
        
        # Rol güncelleme mantığı buraya eklenebilir. Örneğin:
        # if action_type == 'update_role' and 'role' in request.data:
        #     group_member_instance = GroupMember.objects.get(group=group, user=user_to_manage)
        #     group_member_instance.role = request.data['role']
        #     group_member_instance.save()
        #     return Response(GroupMemberSerializer(group_member_instance).data, status=status.HTTP_200_OK)
            
        return Response({'detail': 'Geçersiz istek.'}, status=status.HTTP_400_BAD_REQUEST)


    def delete(self, request, *args, **kwargs):
        # Üyeyi gruptan tamamen çıkarma (DELETE için)
        group = self.get_object() # get_object() Group modelini döndürür
        user_to_remove = get_object_or_404(CustomUser, pk=self.kwargs['user_pk'])

        # Sadece sahibi işlemi yapabilir
        if group.owner != request.user:
            raise PermissionDenied("Sadece grup sahibi bu üyeyi gruptan silebilir.")
            
        group.members.remove(user_to_remove)
        return Response({'detail': f"{user_to_remove.username} gruptan başarıyla çıkarıldı."}, status=status.HTTP_204_NO_CONTENT)