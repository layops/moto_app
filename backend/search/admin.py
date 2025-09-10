from django.contrib import admin
from .models import SearchIndex


@admin.register(SearchIndex)
class SearchIndexAdmin(admin.ModelAdmin):
    """
    SearchIndex modeli için admin interface
    """
    list_display = [
        'id', 'user_id', 'username', 'first_name', 'last_name', 
        'group_id', 'group_name', 'created_at', 'updated_at'
    ]
    list_filter = ['created_at', 'updated_at']
    search_fields = ['username', 'first_name', 'last_name', 'email', 'group_name']
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = (
        ('Kullanıcı Bilgileri', {
            'fields': ('user_id', 'username', 'first_name', 'last_name', 'email', 'full_name', 'search_vector')
        }),
        ('Grup Bilgileri', {
            'fields': ('group_id', 'group_name', 'group_description', 'group_search_vector')
        }),
        ('Sistem Bilgileri', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related()
