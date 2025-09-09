from django.contrib import admin
from .models import Post, PostLike, PostComment

@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ['id', 'author', 'content', 'group', 'created_at', 'likes_count', 'comments_count']
    list_filter = ['created_at', 'group', 'author']
    search_fields = ['content', 'author__username', 'group__name']
    readonly_fields = ['created_at', 'updated_at', 'likes_count', 'comments_count']
    ordering = ['-created_at']

@admin.register(PostLike)
class PostLikeAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'post', 'created_at']
    list_filter = ['created_at']
    search_fields = ['user__username', 'post__content']
    readonly_fields = ['created_at']
    ordering = ['-created_at']

@admin.register(PostComment)
class PostCommentAdmin(admin.ModelAdmin):
    list_display = ['id', 'author', 'post', 'content', 'created_at']
    list_filter = ['created_at', 'author']
    search_fields = ['content', 'author__username', 'post__content']
    readonly_fields = ['created_at', 'updated_at']
    ordering = ['-created_at']
