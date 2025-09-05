from django.contrib import admin
from .models import Group, GroupJoinRequest

@admin.register(Group)
class GroupAdmin(admin.ModelAdmin):
    list_display = ['name', 'owner', 'member_count', 'created_at']
    list_filter = ['created_at', 'updated_at']
    search_fields = ['name', 'description']
    readonly_fields = ['created_at', 'updated_at', 'member_count']
    
    def member_count(self, obj):
        return obj.member_count
    member_count.short_description = 'Üye Sayısı'

@admin.register(GroupJoinRequest)
class GroupJoinRequestAdmin(admin.ModelAdmin):
    list_display = ['user', 'group', 'status', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['user__username', 'group__name', 'message']
    readonly_fields = ['created_at', 'updated_at']
