from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied
from django.db.models import Q 
from rest_framework.parsers import MultiPartParser, FormParser
from django.utils import timezone

from .models import Group, GroupJoinRequest
from .serializers import (
    GroupSerializer, GroupMemberSerializer, GroupJoinRequestSerializer
)
from users.models import CustomUser
from users.services.supabase_service import SupabaseStorage

# --- PERMISSIONS ---

class IsGroupOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        # Okuma izni herkese açık
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Yazma izni sadece grup sahibine
        return obj.owner == request.user


class IsGroupOwnerOrMember(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        # Grup sahibi veya üye ise erişim izni var
        return (obj.owner == request.user or 
                request.user in obj.members.all())


class IsGroupOwnerOrModerator(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        # Grup sahibi ise erişim izni var (moderatör alanı kaldırıldı)
        return obj.owner == request.user


class IsGroupMember(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        # Grup sahibi veya üye ise erişim izni var
        return (obj.owner == request.user or 
                request.user in obj.members.all())


# --- VIEWS ---

class MyGroupsListView(generics.ListAPIView):
    """
    Kullanıcının üyesi olduğu grupları listeler.
    """
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Group.objects.filter(
            Q(owner=user) | Q(members=user)
        ).distinct()


class GroupCreateView(generics.ListCreateAPIView):
    """
    Grup listesi ve oluşturma işlemleri.
    """
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)

    def get_queryset(self):
        if self.request.method == 'GET':
            # GET isteği için tüm grupları listele
            return Group.objects.all()
        return Group.objects.none()

    def create(self, request, *args, **kwargs):
        data = request.data.copy()
        profile_file = request.FILES.get('profile_picture')
        
        if profile_file and 'profile_picture' in data:
            del data['profile_picture']
        
        serializer = self.get_serializer(data=data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        group = serializer.save(owner=request.user)
        # Grup sahibi aynı zamanda grup üyesi olarak eklenir
        group.members.add(request.user)
        
        if profile_file:
            try:
                supabase = SupabaseStorage()
                profile_url = supabase.upload_group_profile_picture(profile_file, str(group.id))
                group.profile_picture_url = profile_url
                group.save()
                serializer = self.get_serializer(group)
            except Exception as e:
                # Profil resmi yüklenemezse grup oluşturulmaya devam eder
                serializer = self.get_serializer(group)
        
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)


class DiscoverGroupsView(generics.ListAPIView):
    """
    Kullanıcının henüz üyesi olmadığı, herkese açık grupları listeler.
    """
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Kullanıcının üyesi olmadığı grupları getir (geçici olarak tüm gruplar)
        return Group.objects.exclude(members=user)


class GroupDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [IsGroupOwnerOrReadOnly]
    parser_classes = (MultiPartParser, FormParser)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        data = request.data.copy()
        profile_file = request.FILES.get('profile_picture')
        
        if profile_file and 'profile_picture' in data:
            del data['profile_picture']
        
        serializer = self.get_serializer(instance, data=data, partial=partial)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        group = serializer.save()
        
        if profile_file:
            try:
                supabase = SupabaseStorage()
                # Eski profil fotoğrafını sil
                if group.profile_picture_url:
                    supabase.delete_group_profile_picture(group.profile_picture_url)
                
                # Yeni profil fotoğrafını yükle
                profile_url = supabase.upload_group_profile_picture(profile_file, str(group.id))
                group.profile_picture_url = profile_url
                group.save()
                serializer = self.get_serializer(group)
            except Exception as e:
                # Profil resmi yüklenemezse grup güncellemesi devam eder
                serializer = self.get_serializer(group)
        
        return Response(serializer.data)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Grup silinmeden önce profil fotoğrafını da sil
        if instance.profile_picture_url:
            try:
                supabase = SupabaseStorage()
                supabase.delete_group_profile_picture(instance.profile_picture_url)
            except Exception as e:
                # Profil resmi silinemezse grup silinmeye devam eder
                pass
        
        self.perform_destroy(instance)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def join(self, request, pk=None):
        """Gruba katıl (public gruplar için)"""
        group = self.get_object()
        user = request.user
        
        # Zaten üye mi kontrol et
        if user in group.members.all():
            return Response(
                {'message': 'Zaten bu grubun üyesisiniz'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Geçici olarak grup türü ve maksimum üye kontrolü devre dışı
        # if group.join_type != 'public':
        #     return Response(
        #         {'message': 'Bu grup herkese açık değil'}, 
        #         status=status.HTTP_400_BAD_REQUEST
        #     )
        
        # if group.members.count() >= group.max_members:
        #     return Response(
        #         {'message': 'Grup maksimum üye sayısına ulaştı'}, 
        #         status=status.HTTP_400_BAD_REQUEST
        #     )
        
        # Gruba katıl
        group.members.add(user)
        
        return Response(
            {'message': 'Gruba başarıyla katıldınız'}, 
            status=status.HTTP_200_OK
        )


class GroupMembersView(generics.ListAPIView):
    serializer_class = GroupMemberSerializer
    permission_classes = [permissions.IsAuthenticated, IsGroupOwnerOrMember]

    def get_queryset(self):
        group_pk = self.kwargs['pk']
        group = get_object_or_404(Group, pk=group_pk)
        return group.members.all()


class GroupJoinLeaveView(generics.UpdateAPIView):
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]

    def update(self, request, *args, **kwargs):
        group = self.get_object()
        user = request.user
        action = request.data.get('action')

        if action == 'join':
            if user in group.members.all():
                return Response({'detail': 'Zaten grubun üyesisiniz.'}, status=status.HTTP_400_BAD_REQUEST)
            
            group.members.add(user)
            return Response({'detail': 'Gruba başarıyla katıldınız.'})

        elif action == 'leave':
            if user not in group.members.all():
                return Response({'detail': 'Grubun üyesi değilsiniz.'}, status=status.HTTP_400_BAD_REQUEST)

            group.members.remove(user)
            return Response({'detail': 'Gruptan başarıyla ayrıldınız.'})

        return Response({'detail': 'Geçersiz eylem. "join" veya "leave" olmalı.'}, status=status.HTTP_400_BAD_REQUEST)


class GroupMemberDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = GroupMemberSerializer
    permission_classes = [permissions.IsAuthenticated, IsGroupOwnerOrReadOnly]
    queryset = Group.objects.all()

    def get_object(self):
        group_pk = self.kwargs['group_pk']
        group = get_object_or_404(Group, pk=group_pk)
        self.check_object_permissions(self.request, group)
        return group

    def delete(self, request, *args, **kwargs):
        group = self.get_object()
        user_to_remove = get_object_or_404(CustomUser, pk=self.kwargs['user_pk'])

        if group.owner == user_to_remove:
            raise PermissionDenied("Grup sahibi kendisini gruptan çıkaramaz.")

        if user_to_remove not in group.members.all():
            return Response({'detail': 'Bu kullanıcı grubun üyesi değil.'}, status=status.HTTP_400_BAD_REQUEST)

        group.members.remove(user_to_remove)
        return Response({'detail': f"{user_to_remove.username} gruptan başarıyla çıkarıldı."}, status=status.HTTP_204_NO_CONTENT)

    def put(self, request, *args, **kwargs):
        return Response({'detail': 'Rol güncelleme özelliği henüz mevcut değil.'}, status=status.HTTP_501_NOT_IMPLEMENTED)

    def patch(self, request, *args, **kwargs):
        return self.put(request, *args, **kwargs)


# --- GRUP KATILIM TALEPLERİ ---

class GroupJoinRequestViewSet(viewsets.ModelViewSet):
    """
    Grup katılım talepleri için ViewSet
    """
    serializer_class = GroupJoinRequestSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)
        
        # Sadece grup sahibi katılım taleplerini görebilir
        if group.owner == self.request.user:
            return GroupJoinRequest.objects.filter(group=group)
        
        # Diğer kullanıcılar sadece kendi taleplerini görebilir
        return GroupJoinRequest.objects.filter(group=group, user=self.request.user)
    
    def perform_create(self, serializer):
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)
        
        # Zaten üye mi kontrol et
        if self.request.user in group.members.all():
            raise PermissionDenied("Zaten bu grubun üyesisiniz.")
        
        # Zaten bekleyen bir talep var mı kontrol et
        if GroupJoinRequest.objects.filter(group=group, user=self.request.user, status='pending').exists():
            raise PermissionDenied("Bu grup için zaten bekleyen bir katılım talebiniz var.")
        
        serializer.save(group=group, user=self.request.user)
    
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def approve(self, request, group_pk=None, pk=None):
        """Katılım talebini onayla"""
        join_request = self.get_object()
        group = join_request.group
        
        # Sadece grup sahibi onaylayabilir
        if group.owner != request.user:
            raise PermissionDenied("Sadece grup sahibi katılım taleplerini onaylayabilir.")
        
        if join_request.status != 'pending':
            return Response(
                {'detail': 'Bu talep zaten işlenmiş.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Talebi onayla
        join_request.status = 'approved'
        join_request.save()
        
        # Kullanıcıyı gruba ekle
        group.members.add(join_request.user)
        
        return Response(
            {'detail': 'Katılım talebi onaylandı ve kullanıcı gruba eklendi.'}, 
            status=status.HTTP_200_OK
        )
    
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def reject(self, request, group_pk=None, pk=None):
        """Katılım talebini reddet"""
        join_request = self.get_object()
        group = join_request.group
        
        # Sadece grup sahibi reddedebilir
        if group.owner != request.user:
            raise PermissionDenied("Sadece grup sahibi katılım taleplerini reddedebilir.")
        
        if join_request.status != 'pending':
            return Response(
                {'detail': 'Bu talep zaten işlenmiş.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Talebi reddet
        join_request.status = 'rejected'
        join_request.save()
        
        return Response(
            {'detail': 'Katılım talebi reddedildi.'}, 
            status=status.HTTP_200_OK
        )