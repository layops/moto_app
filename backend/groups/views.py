from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404 # Http404 import edildi
from rest_framework.exceptions import PermissionDenied # PermissionDenied import edildi

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

    # Yeni eklenen filtreleme metodu
    def get_queryset(self):
        # Kullanıcının üyesi olduğu grupları getir
        return self.request.user.member_of_groups.all()
    
    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class GroupDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [IsGroupOwnerOrReadOnly] # Sadece sahibi güncelleyebilir/silebilir


class GroupMembersView(generics.ListAPIView):
    """
    Bir grubun üyelerini listeler. Sadece grup üyeleri veya sahibi görebilir.
    """
    serializer_class = GroupMemberSerializer # Üyelerin CustomUser detaylarını göstermek için
    permission_classes = [permissions.IsAuthenticated, IsGroupOwnerOrMember]

    def get_queryset(self):
        group_pk = self.kwargs['pk']
        group = get_object_or_404(Group, pk=group_pk)
        
        # IsGroupOwnerOrMember permission objenin kendisine uygulanır.
        # Burada sadece queryset'i döndürüyoruz, izin kontrolü has_object_permission'da yapılır.
        # GroupMemberSerializer CustomUser'ı beklediği için, members.all() döndürüyoruz.
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
    Bir grubun belirli bir üyesini yönetir (gruptan çıkarma).
    Sadece grup sahibi bu işlemleri yapabilir.
    Rol güncelleme için ayrı bir API veya daha karmaşık bir yapı gerekebilir,
    çünkü GroupMember modeli yok ve CustomUser'ın rol alanı yok.
    """
    serializer_class = GroupMemberSerializer # CustomUser serileştirmesi için GroupMemberSerializer kullanılıyor
    permission_classes = [permissions.IsAuthenticated, IsGroupOwnerOrReadOnly] # Grup sahibi izni
    queryset = Group.objects.all() # Group objesini almak için

    def get_object(self):
        # URL'den group_pk'yi alıyoruz. user_pk'yi burada kullanmıyoruz,
        # çünkü objeyi Group olarak döndürüyoruz. Üye kontrolü delete/put içinde yapılacak.
        group_pk = self.kwargs['group_pk']
        group = get_object_or_404(Group, pk=group_pk)
        
        # İzin kontrolü için grubu döndür (IsGroupOwnerOrReadOnly objeye uygulanır)
        self.check_object_permissions(self.request, group)
        
        return group # Group objesini döndürüyoruz çünkü permission üzerinde çalışacak

    def delete(self, request, *args, **kwargs):
        # Üyeyi gruptan tamamen çıkarma (DELETE için)
        group = self.get_object() # get_object() Group modelini döndürür ve izin kontrolü yapılır
        user_to_remove = get_object_or_404(CustomUser, pk=self.kwargs['user_pk'])

        # Grup sahibinin kendisini silmesini engelle
        if group.owner == user_to_remove:
            raise PermissionDenied("Grup sahibi kendisini gruptan çıkaramaz.")
            
        if user_to_remove not in group.members.all():
            return Response({'detail': 'Bu kullanıcı grubun üyesi değil.'}, status=status.HTTP_400_BAD_REQUEST)

        group.members.remove(user_to_remove)
        return Response({'detail': f"{user_to_remove.username} gruptan başarıyla çıkarıldı."}, status=status.HTTP_204_NO_CONTENT)

    # Rol güncelleme için PUT/PATCH metodu (şimdilik sadece placeholder)
    # Eğer GroupMember modelinizde bir rol alanı olsaydı, burada güncellerdiniz.
    # Şu anki yapınızda CustomUser modelinde bir rol alanı yok.
    # Eğer rol yönetimi isteniyorsa, GroupMember modeli veya CustomUser modeline rol alanı eklenmeli.
    def put(self, request, *args, **kwargs):
        return Response({'detail': 'Rol güncelleme özelliği henüz mevcut değil.'}, status=status.HTTP_501_NOT_IMPLEMENTED)

    def patch(self, request, *args, **kwargs):
        return self.put(request, *args, **kwargs) # PATCH isteklerini PUT'a yönlendiriyoruz