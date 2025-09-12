# moto_app/backend/media/views.py

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Media
from groups.models import Group
from .serializers import MediaSerializer
from users.models import CustomUser

from rest_framework.parsers import MultiPartParser, FormParser 

try:
    from users.services.supabase_service import SupabaseStorage
    supabase = SupabaseStorage()
    print("SupabaseStorage başarıyla yüklendi (Media)")
except Exception as e:
    print(f"SupabaseStorage yükleme hatası (Media): {str(e)}")
    import traceback
    traceback.print_exc()
    supabase = None


class IsGroupMemberOrOwner(permissions.BasePermission):
    """
    Sadece grubun üyeleri veya sahibi medya dosyalarına erişebilir ve yükleyebilir.
    """
    def has_permission(self, request, view):
        group_pk = view.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)
        return request.user.is_authenticated and (request.user == group.owner or request.user in group.members.all())

    def has_object_permission(self, request, view, obj):
        # Medya dosyasının sahibi veya grup sahibi düzenleme/silme yapabilir.
        if request.method in permissions.SAFE_METHODS:
            return True # Okuma herkes için (grup üyesi/sahibi)
        return obj.uploaded_by == request.user or obj.group.owner == request.user


class MediaListCreateView(generics.ListCreateAPIView):
    serializer_class = MediaSerializer
    permission_classes = [permissions.IsAuthenticated, IsGroupMemberOrOwner]

    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self):
        group_pk = self.kwargs['group_pk']
        group = get_object_or_404(Group, pk=group_pk)
        return Media.objects.filter(group=group).order_by('-uploaded_at')

    def create(self, request, *args, **kwargs):
        print("Media yükleme başladı:", request.data)
        print("Media dosyalar:", request.FILES)
        
        try:
            data = request.data.copy()
            media_file = request.FILES.get('file')
            
            # Media file'ı data'dan çıkar çünkü Supabase'e yükleyeceğiz
            if media_file and 'file' in data:
                del data['file']
            
            serializer = self.get_serializer(data=data)
            if not serializer.is_valid():
                print("Media serializer hataları:", serializer.errors)
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
            # Media'yı oluştur
            group_pk = self.kwargs['group_pk']
            group = get_object_or_404(Group, pk=group_pk)
            media = serializer.save(uploaded_by=request.user, group=group)
            
            # Media dosyası varsa Supabase'e yükle
            if media_file and supabase is not None:
                try:
                    print(f"Media dosyası yükleniyor: {media_file.name}, boyut: {media_file.size}")
                    # Grup medyası için Supabase bucket'ını kullan
                    file_url = supabase._upload_file(media_file, supabase.groups_bucket, f"groups/{group_pk}/media/{media.id}/")
                    print(f"Media URL'i alındı: {file_url}")
                    media.file_url = file_url
                    media.save()
                    print("Media file_url güncellendi")
                    serializer = self.get_serializer(media)
                except Exception as e:
                    print("Media yükleme hatası:", str(e))
                    import traceback
                    traceback.print_exc()
                    # Dosya yükleme hatası media oluşturmayı engellemez
                    pass
            elif media_file and supabase is None:
                print("Supabase mevcut değil, media yüklenemiyor")
                pass
            elif media_file:
                print("Media file var ama supabase None")
            else:
                print("Media file yok")
            
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
            
        except Exception as e:
            print("Media oluşturma hatası:", str(e))
            return Response(
                {"error": "Media oluşturulurken bir hata oluştu"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class MediaDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Media.objects.all()
    serializer_class = MediaSerializer
    permission_classes = [permissions.IsAuthenticated, IsGroupMemberOrOwner]

    def get_object(self):
        group_pk = self.kwargs['group_pk']
        media_pk = self.kwargs['pk']
        group = get_object_or_404(Group, pk=group_pk)
        obj = get_object_or_404(Media, pk=media_pk, group=group)
        self.check_object_permissions(self.request, obj)
        return obj