from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied
from django.db.models import Q 
from rest_framework.parsers import MultiPartParser, FormParser
from django.utils import timezone

from .models import Group, GroupJoinRequest, GroupMessage
from .serializers import (
    GroupSerializer, GroupMemberSerializer, GroupJoinRequestSerializer,
    GroupJoinRequestCreateSerializer, GroupMessageSerializer, GroupMessageCreateSerializer
)
from users.models import CustomUser
from users.services.supabase_service import SupabaseStorage
from group_posts.models import Post
from group_posts.serializers import PostSerializer

# --- PERMISSIONS ---

class IsGroupOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.owner == request.user


class IsGroupOwnerOrMember(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.user.is_authenticated:
            return request.user == obj.owner or request.user in obj.members.all()
        return False

    def has_permission(self, request, view):
        return request.user.is_authenticated

class IsGroupOwnerOrModerator(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.user.is_authenticated:
            return (request.user == obj.owner or 
                   request.user in obj.moderators.all())
        return False

    def has_permission(self, request, view):
        return request.user.is_authenticated

class IsGroupMember(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.user.is_authenticated:
            return (request.user == obj.owner or 
                   request.user in obj.members.all() or 
                   request.user in obj.moderators.all())
        return False

    def has_permission(self, request, view):
        return request.user.is_authenticated


# --- VIEWS ---

class MyGroupsListView(generics.ListAPIView):
    """
    Kullanıcının üyesi olduğu grupları listeler.
    """
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Kullanıcının üyesi olduğu grupları getir
        return self.request.user.member_of_groups.all()

class GroupCreateView(generics.ListCreateAPIView):
    """
    Grup listesi (GET) ve yeni grup oluşturma (POST).
    """
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)

    def get_queryset(self):
        # Tüm grupları listele (isteğe bağlı olarak filtreleme eklenebilir)
        return Group.objects.all().order_by('-created_at')

    def create(self, request, *args, **kwargs):
        print("Gelen veri:", request.data)
        print("Dosyalar:", request.FILES)
        
        data = request.data.copy()
        profile_file = request.FILES.get('profile_picture')
        
        if profile_file and 'profile_picture' in data:
            del data['profile_picture']
        
        serializer = self.get_serializer(data=data)
        if not serializer.is_valid():
            print("Serializer hataları:", serializer.errors)
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
                print("Profil resmi yükleme hatası:", str(e))
        
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
        # Kullanıcının üyesi olmadığı VE herkese açık olan grupları getir
        return Group.objects.filter(is_public=True).exclude(members=user)


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
                print("Profil resmi güncelleme hatası:", str(e))
        
        return Response(serializer.data)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Grup silinmeden önce profil fotoğrafını da sil
        if instance.profile_picture_url:
            try:
                supabase = SupabaseStorage()
                supabase.delete_group_profile_picture(instance.profile_picture_url)
            except Exception as e:
                print("Profil resmi silme hatası:", str(e))
        
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
        
        # Grup türü kontrolü
        if group.join_type != 'public':
            return Response(
                {'message': 'Bu grup herkese açık değil'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Maksimum üye sayısı kontrolü
        if group.members.count() >= group.max_members:
            return Response(
                {'message': 'Grup maksimum üye sayısına ulaştı'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
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

    def patch(self, request, *args, **kwargs):
        group = self.get_object()
        user = request.user
        action = request.data.get('action')

        if action == 'join':
            if user not in group.members.all():
                group.members.add(user)
                return Response({'detail': 'Gruba başarıyla katıldınız.'}, status=status.HTTP_200_OK)
            return Response({'detail': 'Zaten grubun üyesisiniz.'}, status=status.HTTP_400_BAD_REQUEST)

        elif action == 'leave':
            if user in group.members.all():
                group.members.remove(user)
                return Response({'detail': 'Gruptan başarıyla ayrıldınız.'}, status=status.HTTP_200_OK)
            return Response({'detail': 'Grubun üyesi değilsiniz.'}, status=status.HTTP_400_BAD_REQUEST)

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


# --- GROUP JOIN REQUESTS ---

class GroupJoinRequestViewSet(viewsets.ModelViewSet):
    serializer_class = GroupJoinRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return GroupJoinRequest.objects.filter(
            Q(user=user) | Q(group__owner=user) | Q(group__moderators=user)
        ).distinct()

    def get_serializer_class(self):
        if self.action == 'create':
            return GroupJoinRequestCreateSerializer
        return GroupJoinRequestSerializer

    def perform_create(self, serializer):
        group_id = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_id)
        
        # Kullanıcının zaten üye olup olmadığını kontrol et
        if self.request.user in group.members.all():
            raise PermissionDenied("Zaten grubun üyesisiniz")
        
        # Zaten bekleyen bir talebi var mı kontrol et
        if GroupJoinRequest.objects.filter(
            group=group, user=self.request.user, status='pending'
        ).exists():
            raise PermissionDenied("Zaten bekleyen bir katılım talebiniz var")
        
        serializer.save(user=self.request.user, group=group)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None, group_pk=None):
        join_request = self.get_object()
        group = join_request.group
        
        # Yetki kontrolü
        if not (request.user == group.owner or request.user in group.moderators.all()):
            raise PermissionDenied("Bu işlem için yetkiniz yok")
        
        if join_request.status != 'pending':
            return Response(
                {"error": "Bu talep zaten işlenmiş"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Kullanıcıyı gruba ekle
        group.members.add(join_request.user)
        
        # Talebi onayla
        join_request.status = 'approved'
        join_request.responded_at = timezone.now()
        join_request.responded_by = request.user
        join_request.save()
        
        return Response({"message": "Katılım talebi onaylandı"})

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None, group_pk=None):
        join_request = self.get_object()
        group = join_request.group
        
        # Yetki kontrolü
        if not (request.user == group.owner or request.user in group.moderators.all()):
            raise PermissionDenied("Bu işlem için yetkiniz yok")
        
        if join_request.status != 'pending':
            return Response(
                {"error": "Bu talep zaten işlenmiş"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Talebi reddet
        join_request.status = 'rejected'
        join_request.responded_at = timezone.now()
        join_request.responded_by = request.user
        join_request.save()
        
        return Response({"message": "Katılım talebi reddedildi"})


# --- GROUP MESSAGES ---

class GroupMessageViewSet(viewsets.ModelViewSet):
    serializer_class = GroupMessageSerializer
    permission_classes = [IsGroupMember]

    def get_queryset(self):
        group_id = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_id)
        
        # Grup üyesi kontrolü
        if not (self.request.user == group.owner or 
                self.request.user in group.members.all() or 
                self.request.user in group.moderators.all()):
            raise PermissionDenied("Bu grubun mesajlarını görme yetkiniz yok")
        
        return GroupMessage.objects.filter(group=group)

    def get_serializer_class(self):
        if self.action == 'create':
            return GroupMessageCreateSerializer
        return GroupMessageSerializer

    def perform_create(self, serializer):
        group_id = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_id)
        serializer.save(sender=self.request.user, group=group)

    def perform_update(self, serializer):
        # Sadece mesaj sahibi düzenleyebilir
        if serializer.instance.sender != self.request.user:
            raise PermissionDenied("Sadece kendi mesajlarınızı düzenleyebilirsiniz")
        
        serializer.save(is_edited=True)

    def perform_destroy(self, instance):
        # Sadece mesaj sahibi, grup sahibi veya moderatör silebilir
        group = instance.group
        if not (instance.sender == self.request.user or 
                self.request.user == group.owner or 
                self.request.user in group.moderators.all()):
            raise PermissionDenied("Bu mesajı silme yetkiniz yok")
        
        instance.delete()


# --- GROUP POSTS (using existing group_posts app) ---

class GroupPostViewSet(viewsets.ModelViewSet):
    serializer_class = PostSerializer
    permission_classes = [IsGroupMember]

    def get_queryset(self):
        group_id = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_id)
        
        # Grup üyesi kontrolü
        if not (self.request.user == group.owner or 
                self.request.user in group.members.all() or 
                self.request.user in group.moderators.all()):
            raise PermissionDenied("Bu grubun postlarını görme yetkiniz yok")
        
        return Post.objects.filter(group=group).order_by('-created_at')

    def perform_create(self, serializer):
        group_id = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_id)
        serializer.save(author=self.request.user, group=group)