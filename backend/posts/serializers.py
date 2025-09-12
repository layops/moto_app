# posts/serializers.py

from rest_framework import serializers
from .models import Post, PostLike, PostComment
from users.serializers import UserSerializer
from groups.models import Group

class PostCommentSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)
    
    class Meta:
        model = PostComment
        fields = ['id', 'author', 'content', 'created_at', 'updated_at']
        read_only_fields = ('id', 'author', 'created_at', 'updated_at')

class PostSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)  # Nested serializer ile detaylı user bilgisi
    group = serializers.PrimaryKeyRelatedField(queryset=Group.objects.all(), required=False)
    image = serializers.ImageField(required=False, write_only=True)  # Sadece yazma için, okuma için değil
    content = serializers.CharField(required=True, allow_blank=False)  # Content zorunlu ve boş olamaz
    likes_count = serializers.ReadOnlyField()
    comments_count = serializers.ReadOnlyField()
    is_liked = serializers.SerializerMethodField()
    comments = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'id', 'group', 'author', 'content', 'image', 'image_url', 
            'created_at', 'updated_at', 'likes_count', 'comments_count', 
            'is_liked', 'comments'
        ]
        read_only_fields = ('id', 'author', 'created_at', 'updated_at')

    def get_is_liked(self, obj):
        request = self.context.get('request')
        print(f"PostSerializer - Post {obj.id}: get_is_liked called")
        print(f"  - Request exists: {request is not None}")
        print(f"  - User authenticated: {request and request.user.is_authenticated}")
        print(f"  - User: {request.user.username if request and request.user.is_authenticated else 'None'}")
        
        if request and request.user.is_authenticated:
            try:
                # Önce PostLike tablosunda bu post için kaç beğeni var kontrol et
                total_likes = PostLike.objects.filter(post=obj).count()
                user_like = PostLike.objects.filter(post=obj, user=request.user).exists()
                
                print(f"  - Total likes for post {obj.id}: {total_likes}")
                print(f"  - User {request.user.username} liked: {user_like}")
                
                return user_like
            except Exception as e:
                print(f"PostSerializer - Post {obj.id}: Error checking is_liked: {e}")
                import traceback
                traceback.print_exc()
                return False
        print(f"PostSerializer - Post {obj.id}: User not authenticated, is_liked = False")
        return False

    def get_comments(self, obj):
        try:
            comments = obj.comments.all()[:5]  # Son 5 yorumu al
            return [{
                'id': comment.id,
                'content': comment.content,
                'created_at': comment.created_at,
                'author': {
                    'id': comment.author.id,
                    'username': comment.author.username,
                }
            } for comment in comments]
        except:
            return []

    def create(self, validated_data):
        print(f"PostSerializer.create çağrıldı - validated_data: {validated_data}")
        
        # Author alanını validated_data'dan çıkar (read_only olduğu için)
        author = validated_data.pop('author', None)
        print(f"PostSerializer.create - Author: {author}")
        
        if not author:
            raise serializers.ValidationError("Author bilgisi bulunamadı.")
        
        # Post'u author ile birlikte oluştur
        try:
            post = Post.objects.create(
                content=validated_data.get('content'),
                group=validated_data.get('group'),
                author=author
            )
            print(f"PostSerializer.create - Post başarıyla oluşturuldu: {post.id}, Author ID: {post.author.id}")
        except Exception as e:
            print(f"PostSerializer.create - Post oluşturma hatası: {str(e)}")
            raise serializers.ValidationError(f"Post oluşturulamadı: {str(e)}")
        
        return post

    def to_representation(self, instance):
        """
        Eğer context'te 'only_content' flag'i varsa sadece content dön.
        Aksi halde tüm alanları dön.
        """
        representation = super().to_representation(instance)
        if self.context.get('only_content'):
            return representation.get('content')
        
        # Debug log'ları
        print(f"PostSerializer - Post {instance.id}:")
        print(f"  - Author: {instance.author}")
        print(f"  - Author username: {instance.author.username}")
        print(f"  - Author ID: {instance.author.id}")
        print(f"  - Representation author: {representation.get('author')}")
        if representation.get('author'):
            author_data = representation.get('author')
            print(f"  - Author data type: {type(author_data)}")
            if isinstance(author_data, dict):
                print(f"  - Author username in data: {author_data.get('username')}")
                print(f"  - Author ID in data: {author_data.get('id')}")
        
        # Eğer image_url varsa, image alanını None yap (frontend'de karışıklık olmasın)
        if instance.image_url:
            representation['image'] = None
        
        # Author verisini manuel olarak kontrol et
        if not representation.get('author') or not representation['author'].get('username'):
            print(f"PostSerializer - Author verisi eksik, manuel olarak ekleniyor")
            representation['author'] = {
                'id': instance.author.id,
                'username': instance.author.username,
                'email': instance.author.email,
                'profile_photo_url': None,  # Şimdilik None
            }
            print(f"PostSerializer - Manuel author verisi: {representation['author']}")
        
        return representation
