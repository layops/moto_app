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
# from users.services.supabase_service import SupabaseStorage  # Removed - Supabase disabled

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
        print(f"🔥🔥🔥 MyGroupsListView çağrıldı - Kullanıcı: {user.username} (ID: {user.id})")
        
        # Tüm grupları listele
        all_groups = Group.objects.all()
        print(f"🔥 Tüm gruplar: {[(g.id, g.name, g.owner.username) for g in all_groups]}")
        
        # Kullanıcının gruplarını filtrele
        groups = Group.objects.filter(
            Q(owner=user) | Q(members=user)
        ).distinct()
        
        print(f"🔥 MyGroupsListView - Bulunan gruplar: {[(g.id, g.name, g.owner.username) for g in groups]}")
        for group in groups:
            members = [m.username for m in group.members.all()]
            print(f"🔥 - {group.name} (ID: {group.id}): Owner={group.owner.username}, Members={members}")
        
        return groups

    def list(self, request, *args, **kwargs):
        print(f"🔥🔥🔥 MyGroupsListView.list() çağrıldı")
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        print(f"🔥 Serializer data: {serializer.data}")
        return Response(serializer.data)


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
        profile_picture_url = data.get('profile_picture_url')  # Yeni güvenli sistemden gelen URL
        
        if profile_file and 'profile_picture' in data:
            del data['profile_picture']
        
        # Eğer URL gelmişse, direkt kullan
        if profile_picture_url:
            data['profile_picture_url'] = profile_picture_url
        
        serializer = self.get_serializer(data=data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        group = serializer.save(owner=request.user)
        # Grup sahibi aynı zamanda grup üyesi olarak eklenir
        group.members.add(request.user)
        
        # Debug log'u ekle
        print(f"🔥 Grup oluşturuldu: {group.name} (ID: {group.id})")
        print(f"🔥 Grup sahibi: {request.user.username} (ID: {request.user.id})")
        print(f"🔥 Grup üyeleri: {[member.username for member in group.members.all()]}")
        
        # Grup üyelik durumunu tekrar kontrol et
        group.refresh_from_db()
        print(f"🔥 Grup refresh sonrası üyeleri: {[member.username for member in group.members.all()]}")
        
        # Profile picture upload temporarily disabled - Supabase removed
        # if profile_file:
        #     try:
        #         supabase = SupabaseStorage()
        #         profile_url = supabase.upload_group_profile_picture(profile_file, str(group.id))
        #         group.profile_picture_url = profile_url
        #         group.save()
        #         serializer = self.get_serializer(group)
        #     except Exception as e:
        #         # Profil resmi yüklenemezse grup oluşturulmaya devam eder
        #         serializer = self.get_serializer(group)
        
        # Final serializer response
        final_serializer = self.get_serializer(group)
        print(f"🔥 Final response data: {final_serializer.data}")
        
        headers = self.get_success_headers(final_serializer.data)
        return Response(final_serializer.data, status=status.HTTP_201_CREATED, headers=headers)


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
        
        # Profile picture upload temporarily disabled - Supabase removed
        # if profile_file:
        #     try:
        #         supabase = SupabaseStorage()
        #         # Eski profil fotoğrafını sil
        #         if group.profile_picture_url:
        #             supabase.delete_group_profile_picture(group.profile_picture_url)
        #         
        #         # Yeni profil fotoğrafını yükle
        #         profile_url = supabase.upload_group_profile_picture(profile_file, str(group.id))
        #         group.profile_picture_url = profile_url
        #         group.save()
        #         serializer = self.get_serializer(group)
        #     except Exception as e:
        #         # Profil resmi yüklenemezse grup güncellemesi devam eder
        #         serializer = self.get_serializer(group)
        
        return Response(serializer.data)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Profile picture deletion temporarily disabled - Supabase removed
        # if instance.profile_picture_url:
        #     try:
        #         supabase = SupabaseStorage()
        #         supabase.delete_group_profile_picture(instance.profile_picture_url)
        #     except Exception as e:
        #         # Profil resmi silinemezse grup silinmeye devam eder
        #         pass
        
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
            
            # Onay sistemi kontrolü
            if group.requires_approval:
                # Onay gerekiyorsa istek oluştur
                message = request.data.get('message', '')
                join_request, created = GroupJoinRequest.objects.get_or_create(
                    group=group,
                    user=user,
                    defaults={'message': message}
                )
                
                if not created:
                    return Response({'detail': 'Bu grup için zaten bir istek gönderdiniz.'}, 
                                    status=status.HTTP_400_BAD_REQUEST)
                
                # Bildirim gönder
                self._send_notification(
                    recipient=group.owner,
                    sender=user,
                    notification_type='group_join_request',
                    message=f"{user.username} {group.name} grubuna katılmak istiyor.",
                    content_object=join_request
                )
                
                return Response({'detail': 'Katılım isteği gönderildi. Onay bekleniyor.'})
            else:
                # Onay gerektirmiyorsa direkt katıl
                group.members.add(user)
                serializer = GroupSerializer(group)
                return Response({
                    'detail': 'Gruba başarıyla katıldınız.',
                    'group': serializer.data
                })

        elif action == 'leave':
            if user not in group.members.all():
                return Response({'detail': 'Grubun üyesi değilsiniz.'}, status=status.HTTP_400_BAD_REQUEST)

            group.members.remove(user)
            return Response({'detail': 'Gruptan başarıyla ayrıldınız.'})

    def _send_notification(self, recipient, sender, notification_type, message, content_object=None):
        """Bildirim gönder"""
        try:
            from notifications.models import Notification
            
            notification = Notification.objects.create(
                recipient=recipient,
                sender=sender,
                notification_type=notification_type,
                message=message,
                content_object=content_object
            )
            print(f"Bildirim gönderildi: {notification}")
        except Exception as e:
            print(f"Bildirim gönderme hatası: {str(e)}")

        return Response({'detail': 'Geçersiz eylem. "join" veya "leave" olmalı.'}, status=status.HTTP_400_BAD_REQUEST)


class GroupRequestViewSet(viewsets.ModelViewSet):
    """Grup katılım istekleri yönetimi"""
    queryset = GroupJoinRequest.objects.all()
    serializer_class = GroupJoinRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def my_requests(self, request):
        """Kullanıcının gönderdiği istekleri getir"""
        requests = GroupJoinRequest.objects.filter(user=request.user)
        serializer = self.get_serializer(requests, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def pending_requests(self, request):
        """Kullanıcının sahip olduğu gruplar için bekleyen istekleri getir"""
        user_groups = Group.objects.filter(owner=request.user)
        requests = GroupJoinRequest.objects.filter(
            group__in=user_groups,
            status='pending'
        )
        serializer = self.get_serializer(requests, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Grup katılım isteğini onayla"""
        try:
            join_request = self.get_object()
            if request.user != join_request.group.owner:
                return Response({'error': 'Bu grubun sahibi değilsiniz.'},
                                status=status.HTTP_403_FORBIDDEN)
            
            if join_request.status != 'pending':
                return Response({'error': 'Bu istek zaten işlenmiş.'},
                                status=status.HTTP_400_BAD_REQUEST)
            
            # Onayla
            join_request.status = 'approved'
            join_request.save()
            
            # Kullanıcıyı gruba ekle
            join_request.group.members.add(join_request.user)
            
            # Bildirim gönder
            self._send_notification(
                recipient=join_request.user,
                sender=request.user,
                notification_type='group_join_approved',
                message=f"{join_request.group.name} grubuna katılımınız onaylandı.",
                content_object=join_request.group
            )
            
            return Response({'message': 'İstek onaylandı.'})
        except Exception as e:
            print(f"Approve request hatası: {str(e)}")
            return Response(
                {'error': 'İstek onaylanırken bir hata oluştu'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Grup katılım isteğini reddet"""
        try:
            join_request = self.get_object()
            if request.user != join_request.group.owner:
                return Response({'error': 'Bu grubun sahibi değilsiniz.'},
                                status=status.HTTP_403_FORBIDDEN)
            
            if join_request.status != 'pending':
                return Response({'error': 'Bu istek zaten işlenmiş.'},
                                status=status.HTTP_400_BAD_REQUEST)
            
            # Reddet
            join_request.status = 'rejected'
            join_request.save()
            
            # Bildirim gönder
            self._send_notification(
                recipient=join_request.user,
                sender=request.user,
                notification_type='group_join_rejected',
                message=f"{join_request.group.name} grubuna katılımınız reddedildi.",
                content_object=join_request.group
            )
            
            return Response({'message': 'İstek reddedildi.'})
        except Exception as e:
            print(f"Reject request hatası: {str(e)}")
            return Response(
                {'error': 'İstek reddedilirken bir hata oluştu'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def _send_notification(self, recipient, sender, notification_type, message, content_object=None):
        """Bildirim gönder"""
        try:
            from notifications.models import Notification
            
            notification = Notification.objects.create(
                recipient=recipient,
                sender=sender,
                notification_type=notification_type,
                message=message,
                content_object=content_object
            )
            print(f"Bildirim gönderildi: {notification}")
        except Exception as e:
            print(f"Bildirim gönderme hatası: {str(e)}")


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