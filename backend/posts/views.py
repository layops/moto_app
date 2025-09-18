# moto_app/backend/posts/views.py

from rest_framework import generics, permissions, status, serializers
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Post, PostLike, PostComment
from .serializers import PostSerializer, PostCommentSerializer
from groups.models import Group
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import MultiPartParser, FormParser
# from users.services.supabase_service import SupabaseStorage  # Removed - Supabase disabled
from django.db.models import Q
import logging

logger = logging.getLogger(__name__)

# Genel postları yönetir (grup dışı)
class GeneralPostListCreateView(generics.ListCreateAPIView):
    queryset = Post.objects.filter(group__isnull=True).order_by('-created_at')
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def perform_create(self, serializer):
        # Kullanıcı authentication kontrolü
        logger.info(f"perform_create çağrıldı - User: {self.request.user}")
        logger.info(f"User authenticated: {self.request.user.is_authenticated}")
        logger.info(f"User ID: {getattr(self.request.user, 'id', 'NO_ID')}")
        
        if not self.request.user or not self.request.user.is_authenticated:
            logger.error("Kullanıcı kimlik doğrulaması başarısız")
            raise PermissionDenied("Kullanıcı kimlik doğrulaması gerekli.")
        
        # Resim dosyasını al
        image_file = self.request.FILES.get('image')
        
        # Post'u oluştur (resim olmadan)
        post_data = serializer.validated_data.copy()
        if 'image' in post_data:
            del post_data['image']  # Resmi local media'ya kaydetme
        
        # Content validation
        content = post_data.get('content', '').strip()
        if not content:
            raise serializers.ValidationError("Gönderi içeriği boş olamaz.")
        
        logger.info(f"Genel post oluşturuluyor - User: {self.request.user.username} (ID: {self.request.user.id})")
        logger.info(f"Content: {content[:100]}...")
        logger.info(f"Post data: {post_data}")
        
        try:
            # Author'ı explicit olarak set et
            post = serializer.save(author=self.request.user, group=None)
            logger.info(f"Genel post başarıyla oluşturuldu - ID: {post.id}, Author ID: {post.author.id}")
        except Exception as e:
            logger.error(f"Genel post oluşturma hatası: {str(e)}")
            raise serializers.ValidationError(f"Post oluşturulamadı: {str(e)}")
        
        # Eğer resim varsa sadece Supabase'e yükle
        if image_file:
            try:
                storage = SupabaseStorage()
                image_url = storage.upload_group_post_image(image_file, None, post.id)  # group_id=None for general posts
                post.image_url = image_url
                post.save()
                logger.info(f"Genel post resmi Supabase'e yüklendi: {image_url}")
            except Exception as e:
                logger.error(f"Genel post resmi Supabase'e yükleme hatası: {str(e)}")

# Grup postlarını yönetir
class GroupPostListCreateView(generics.ListCreateAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)

        if self.request.user in group.members.all() or self.request.user == group.owner:
            posts = Post.objects.filter(group=group).order_by('-created_at')
            logger.info(f"Grup {group_pk} için {posts.count()} post bulundu")
            for post in posts:
                logger.info(f"Post {post.id}: Author={post.author.username}, Content={post.content[:50]}...")
            return posts
        raise PermissionDenied("Bu grubun gönderilerini görüntüleme izniniz yok.")

    def perform_create(self, serializer):
        # Kullanıcı authentication kontrolü
        if not self.request.user or not self.request.user.is_authenticated:
            raise PermissionDenied("Kullanıcı kimlik doğrulaması gerekli.")
        
        group_pk = self.kwargs.get('group_pk')
        group = get_object_or_404(Group, pk=group_pk)

        logger.info(f"Post oluşturma isteği - Grup: {group_pk}, Kullanıcı: {self.request.user.username}")
        logger.info(f"Request data: {self.request.data}")
        logger.info(f"Request files: {list(self.request.FILES.keys())}")

        if self.request.user in group.members.all() or self.request.user == group.owner:
            # Resim dosyasını al
            image_file = self.request.FILES.get('image')
            
            # Post'u oluştur (resim olmadan)
            post_data = serializer.validated_data.copy()
            if 'image' in post_data:
                del post_data['image']  # Resmi local media'ya kaydetme
            
            # Content validation
            content = post_data.get('content', '').strip()
            if not content:
                raise serializers.ValidationError("Gönderi içeriği boş olamaz.")
            
            logger.info(f"Post data: {post_data}")
            logger.info(f"Serializer is valid: {serializer.is_valid()}")
            if not serializer.is_valid():
                logger.error(f"Serializer errors: {serializer.errors}")
            
            logger.info(f"Post oluşturuluyor - Author: {self.request.user.username} (ID: {self.request.user.id})")
            try:
                post = serializer.save(author=self.request.user, group=group, **post_data)
                logger.info(f"Post oluşturuldu - ID: {post.id}, Author: {post.author.username}")
            except Exception as e:
                logger.error(f"Grup post oluşturma hatası: {str(e)}")
                raise serializers.ValidationError(f"Post oluşturulamadı: {str(e)}")
            
            # Eğer resim varsa sadece Supabase'e yükle
            if image_file:
                try:
                    logger.info(f"Post resmi alındı: {image_file.name}, boyut: {image_file.size}")
                    logger.info(f"Content type: {image_file.content_type}")
                    
                    # Dosya stream'ini kontrol et
                    image_file.seek(0)
                    file_content = image_file.read()
                    logger.info(f"Post resmi içeriği boyutu: {len(file_content)} bytes")
                    
                    # Dosya stream'ini başa al
                    image_file.seek(0)
                    
                    storage = SupabaseStorage()
                    image_url = storage.upload_group_post_image(image_file, group.id, post.id)
                    post.image_url = image_url
                    post.save()
                    logger.info(f"Grup post resmi Supabase'e yüklendi: {image_url}")
                except Exception as e:
                    logger.error(f"Grup post resmi Supabase'e yükleme hatası: {str(e)}")
        else:
            raise PermissionDenied("Bu gruba gönderi oluşturma izniniz yok.")

# Tekil postlar için görünüm
class PostDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_object(self):
        obj = super().get_object()

        if obj.group:
            if self.request.user not in obj.group.members.all() and self.request.user != obj.group.owner:
                raise PermissionDenied("Bu gönderiyi görüntüleme izniniz yok.")

        return obj

    def perform_update(self, serializer):
        if serializer.instance.author != self.request.user:
            raise PermissionDenied("Bu gönderiyi düzenleme izniniz yok.")
        
        # Eğer yeni resim yükleniyorsa
        image_file = self.request.FILES.get('image')
        if image_file:
            try:
                # Eski resmi sil
                if serializer.instance.image_url:
                    storage = SupabaseStorage()
                    storage.delete_group_post_image(serializer.instance.image_url)
                
                # Yeni resmi yükle
                storage = SupabaseStorage()
                group_id = serializer.instance.group.id if serializer.instance.group else None
                image_url = storage.upload_group_post_image(image_file, group_id, serializer.instance.id)
                
                # Post'u güncelle
                data = self.request.data.copy()
                data['image_url'] = image_url
                serializer = self.get_serializer(serializer.instance, data=data, partial=True)
                if serializer.is_valid():
                    serializer.save()
                    return Response(serializer.data)
                else:
                    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            except Exception as e:
                logger.error(f"Post resmi güncelleme hatası: {str(e)}")
                return Response(
                    {'detail': 'Resim güncellenirken hata oluştu.'}, 
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        serializer.save()

    def perform_destroy(self, instance):
        if instance.author != self.request.user and (not instance.group or instance.group.owner != self.request.user):
            raise PermissionDenied("Bu gönderiyi silme izniniz yok.")
        
        # Eğer resim varsa Supabase'den sil
        if instance.image_url:
            try:
                storage = SupabaseStorage()
                storage.delete_group_post_image(instance.image_url)
                logger.info(f"Post resmi başarıyla silindi: {instance.image_url}")
            except Exception as e:
                logger.warning(f"Post resmi silinemedi: {str(e)}")
        
        instance.delete()


# Like API'leri
class PostLikeToggleView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, post_id):
        post = get_object_or_404(Post, id=post_id)
        
        # Post'a erişim kontrolü
        if post.group:
            if request.user not in post.group.members.all() and request.user != post.group.owner:
                raise PermissionDenied("Bu gönderiyi beğenme izniniz yok.")
        
        # Mevcut beğeni durumunu kontrol et
        existing_like = PostLike.objects.filter(
            post=post,
            user=request.user
        ).first()
        
        print(f"PostLikeToggleView - Post {post_id}, User {request.user.username}")
        print(f"  - Existing like: {existing_like is not None}")
        
        if existing_like:
            # Beğeni varsa sil
            existing_like.delete()
            is_liked = False
            logger.info(f"Beğeni silindi - Post: {post_id}, User: {request.user.username}")
            print(f"  - Beğeni silindi")
        else:
            # Beğeni yoksa ekle
            PostLike.objects.create(
                post=post,
                user=request.user
            )
            is_liked = True
            logger.info(f"Beğeni eklendi - Post: {post_id}, User: {request.user.username}")
            print(f"  - Beğeni eklendi")
            
            # Beğeni bildirimi gönder (sadece post sahibi farklıysa)
            if post.author != request.user:
                try:
                    from notifications.utils import send_notification_with_preferences
                    message_text = f"{request.user.get_full_name() or request.user.username} gönderinizi beğendi"
                    
                    # Bildirimi arka planda gönder (asenkron)
                    import threading
                    def send_like_notification_async():
                        try:
                            send_notification_with_preferences(
                                recipient_user=post.author,
                                message=message_text,
                                notification_type='like',
                                sender_user=request.user,
                                content_object=post,
                                title=f"Gönderiniz Beğenildi - {request.user.get_full_name() or request.user.username}"
                            )
                        except Exception as e:
                            # Logger'ı fonksiyon içinde tanımla
                            import logging
                            async_logger = logging.getLogger(__name__)
                            async_logger.error(f"Beğeni bildirimi gönderilemedi: {e}")
                    
                    # Arka planda bildirim gönder
                    threading.Thread(target=send_like_notification_async, daemon=True).start()
                    
                except Exception as e:
                    # Bildirim gönderme hatası kritik değil, sadece logla
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.error(f"Beğeni bildirimi thread başlatılamadı: {e}")
        
        # Güncel beğeni sayısını al
        likes_count = PostLike.objects.filter(post=post).count()
        
        print(f"  - Final likes_count: {likes_count}")
        print(f"  - Final is_liked: {is_liked}")
        
        logger.info(f"Post {post_id} beğeni sayısı: {likes_count}, is_liked: {is_liked}")
        
        return Response({
            'is_liked': is_liked,
            'likes_count': likes_count
        })


# Comment API'leri
class PostCommentListCreateView(generics.ListCreateAPIView):
    serializer_class = PostCommentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        post_id = self.kwargs['post_id']
        post = get_object_or_404(Post, id=post_id)
        
        # Post'a erişim kontrolü
        if post.group:
            if self.request.user not in post.group.members.all() and self.request.user != post.group.owner:
                raise PermissionDenied("Bu gönderinin yorumlarını görüntüleme izniniz yok.")
        
        return PostComment.objects.filter(post=post).order_by('-created_at')

    def perform_create(self, serializer):
        post_id = self.kwargs['post_id']
        post = get_object_or_404(Post, id=post_id)
        
        # Post'a erişim kontrolü
        if post.group:
            if self.request.user not in post.group.members.all() and self.request.user != post.group.owner:
                raise PermissionDenied("Bu gönderiye yorum yapma izniniz yok.")
        
        serializer.save(author=self.request.user, post=post)


class PostCommentDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = PostCommentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        post_id = self.kwargs['post_id']
        post = get_object_or_404(Post, id=post_id)
        
        # Post'a erişim kontrolü
        if post.group:
            if self.request.user not in post.group.members.all() and self.request.user != post.group.owner:
                raise PermissionDenied("Bu gönderinin yorumlarını görüntüleme izniniz yok.")
        
        return PostComment.objects.filter(post=post)

    def perform_update(self, serializer):
        if serializer.instance.author != self.request.user:
            raise PermissionDenied("Bu yorumu düzenleme izniniz yok.")
        serializer.save()

    def perform_destroy(self, instance):
        if instance.author != self.request.user:
            raise PermissionDenied("Bu yorumu silme izniniz yok.")
        instance.delete()


# Takip edilen kullanıcıların postlarını getir (kendi postları dahil)
class FollowingPostsView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        try:
            user = request.user
            
            # Takip edilen kullanıcıları al
            following_users = user.following.all()
            following_user_ids = list(following_users.values_list('id', flat=True))
            
            # Kendi ID'sini de ekle
            following_user_ids.append(user.id)
            
            logger.info(f"Following posts için kullanıcı ID'leri: {following_user_ids}")
            
            # Takip edilen kullanıcıların postlarını getir (grup postları hariç)
            posts = Post.objects.filter(
                Q(author_id__in=following_user_ids) & Q(group__isnull=True)
            ).order_by('-created_at')
            
            logger.info(f"Following posts: {posts.count()} post bulundu")
            
            # Serialize et
            serializer = PostSerializer(posts, many=True, context={'request': request})
            
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Following posts hatası: {str(e)}")
            return Response(
                {'error': 'Takip edilen postlar alınamadı'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )