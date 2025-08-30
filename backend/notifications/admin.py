from django.contrib import admin
from .models import Notification

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = (
        'recipient',
        'message',
        'notification_type',
        'is_read',
        'timestamp',
        'content_type',
    )
    list_filter = ('notification_type', 'is_read', 'timestamp')
    search_fields = ('recipient__username', 'sender__username', 'message')
    readonly_fields = ('timestamp', 'content_object')
    fieldsets = (
        (None, {
            'fields': ('recipient', 'sender', 'message', 'notification_type', 'is_read')
        }),
        ('İlgili Nesne', {
            'fields': ('content_type', 'object_id', 'content_object')
        }),
        ('Zaman Bilgisi', {
            'fields': ('timestamp',)
        }),
    )
