# moto_app/backend/posts/views.py

from rest_framework import generics, permissions, status
from rest_framework.response import Response # Response import edildiğinden emin olun
from .models import Post
from .serializers import PostSerializer
from groups.models import Group
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied

# Group'a ait gönderileri listelemek ve yeni gönderi oluşturmak için
class PostListCreateView(generics.ListCreateAPIView):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)
        if self.request.user in group.members.all() or self.request.user == group.owner:
            return Post.objects.filter(group=group).order_by('-created_at')
        else:
            raise PermissionDenied("Bu grubun gönderilerini görüntüleme izniniz yok.")

    def perform_create(self, serializer):
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)
        if self.request.user in group.members.all() or self.request.user == group.owner:
            serializer.save(author=self.request.user, group=group)
        else:
            raise PermissionDenied("Bu gruba gönderi oluşturma izniniz yok.")

    # BURAYI EKLEYİN: get_serializer_context ve list metotlarını override etme
    def get_serializer_context(self):
        # Varsayılan bağlamı al
        context = super().get_serializer_context()
        # Eğer URL'de ?only_content=true varsa, bağlama ekle
        if self.request.query_params.get('only_content') == 'true':
            context['only_content'] = True
        return context
    
    # Listeleme yanıtını değiştirmek istersen:
    # def list(self, request, *args, **kwargs):
    #     queryset = self.filter_queryset(self.get_queryset())
    #     serializer = self.get_serializer(queryset, many=True)
        
    #     if self.request.query_params.get('only_content') == 'true':
    #         # Eğer sadece content isteniyorsa, her bir objeden sadece content'i al
    #         content_list = [item.get('content') for item in serializer.data]
    #         return Response(content_list)
    #     return Response(serializer.data)


class PostDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        obj = super().get_object()
        group_pk = self.kwargs.get('group_pk')
        if obj.group.pk != int(group_pk):
            raise PermissionDenied("Bu gruba ait olmayan bir gönderiye erişmeye çalışıyorsunuz.")

        group = obj.group
        if self.request.user not in group.members.all() and self.request.user != group.owner:
            raise PermissionDenied("Bu grubun gönderisini görüntüleme izniniz yok.")
            
        return obj

    def perform_update(self, serializer):
        if serializer.instance.author != self.request.user:
            raise PermissionDenied("Bu gönderiyi düzenleme izniniz yok.")
        serializer.save()

    def perform_destroy(self, instance):
        if instance.author != self.request.user and instance.group.owner != self.request.user:
            raise PermissionDenied("Bu gönderiyi silme izniniz yok.")
        instance.delete()