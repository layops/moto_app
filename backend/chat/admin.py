from django.contrib import admin
from .models import PrivateMessage, GroupMessage, HiddenConversation

@admin.register(PrivateMessage)
class PrivateMessageAdmin(admin.ModelAdmin):
    list_display = ['sender', 'receiver', 'message', 'timestamp', 'is_read']
    list_filter = ['timestamp', 'is_read']
    search_fields = ['sender__username', 'receiver__username', 'message']

@admin.register(GroupMessage)
class GroupMessageAdmin(admin.ModelAdmin):
    list_display = ['sender', 'group', 'content', 'message_type', 'created_at']
    list_filter = ['message_type', 'created_at']
    search_fields = ['sender__username', 'group__name', 'content']

@admin.register(HiddenConversation)
class HiddenConversationAdmin(admin.ModelAdmin):
    list_display = ['user', 'other_user', 'hidden_at']
    list_filter = ['hidden_at']
    search_fields = ['user__username', 'other_user__username']
