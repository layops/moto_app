from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied
from django.db.models import Q 
from rest_framework.parsers import MultiPartParser, FormParser

from .models import Group
from .serializers import GroupSerializer, GroupMemberSerializer
from users.models import CustomUser
from users.services.supabase_service import SupabaseStorage

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

class GroupCreateView(generics.CreateAPIView):
    """
    Yeni grup oluşturur.
    """
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)

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