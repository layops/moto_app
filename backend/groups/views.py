# groups/views.py
from rest_framework.views import APIView
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from django.shortcuts import get_object_or_404
from .models import Group
from .serializers import GroupSerializer, GroupMemberSerializer
from django.contrib.auth import get_user_model # Kullanıcı modeline erişim için

User = get_user_model()

class GroupListCreateView(generics.ListCreateAPIView):
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [IsAuthenticated] # Sadece kimliği doğrulanmış kullanıcılar

    def perform_create(self, serializer):
        # Grup oluşturulurken, oluşturan kullanıcıyı (request.user) sahibi olarak ayarla
        serializer.save(owner=self.request.user, members=[self.request.user]) # Oluşturanı otomatik üye yap

class GroupDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    # Sadece grubun sahibi veya süper kullanıcı grubu düzenleyebilir/silebilir
    permission_classes = [IsAuthenticated] # Örnek olarak burada daha gelişmiş bir permission yazılabilir

    def get_queryset(self):
        # Kullanıcının sadece sahibi olduğu veya üyesi olduğu grupları görmesini sağlayabiliriz
        if self.request.user.is_staff: # Adminler tüm grupları görsün
            return Group.objects.all()
        return Group.objects.filter(models.Q(owner=self.request.user) | models.Q(members=self.request.user)).distinct()

class GroupAddRemoveMemberView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk, *args, **kwargs):
        group = get_object_or_404(Group, pk=pk)
        # Sadece grup sahibi üye ekleyebilir/çıkarabilir
        if group.owner != request.user:
            return Response({'detail': 'You are not the owner of this group.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = GroupMemberSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        username = serializer.validated_data['username']
        member_user = get_object_or_404(User, username=username)

        if member_user in group.members.all():
            return Response({'detail': f'{username} is already a member of this group.'}, status=status.HTTP_400_BAD_REQUEST)

        group.members.add(member_user)
        return Response({'detail': f'{username} added to group {group.name}.'}, status=status.HTTP_200_OK)

    def delete(self, request, pk, *args, **kwargs):
        group = get_object_or_404(Group, pk=pk)
        # Sadece grup sahibi üye ekleyebilir/çıkarabilir
        if group.owner != request.user:
            return Response({'detail': 'You are not the owner of this group.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = GroupMemberSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        username = serializer.validated_data['username']
        member_user = get_object_or_404(User, username=username)

        if member_user not in group.members.all():
            return Response({'detail': f'{username} is not a member of this group.'}, status=status.HTTP_400_BAD_REQUEST)

        group.members.remove(member_user)
        return Response({'detail': f'{username} removed from group {group.name}.'}, status=status.HTTP_200_OK)