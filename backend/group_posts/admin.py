from django.contrib import admin
from .models import Post

@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ['author', 'group', 'content', 'created_at']
    list_filter = ['created_at', 'group']
    search_fields = ['author__username', 'group__name', 'content']
