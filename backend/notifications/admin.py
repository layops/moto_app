# moto_app/backend/notifications/admin.py

from django.contrib import admin
from .models import Notification

# Notification modelini Django Admin paneline kaydediyoruz
@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    # Admin listesinde gösterilecek alanlar
    # content_object_type ve object_id doğrudan model alanları olmadığı için kaldırıldı.
    # content_type ve object_id modelde olduğu için kullanılabilir.
    list_display = (
        'recipient',
        'message',
        'notification_type',
        'is_read',
        'timestamp',
        'content_type', # İlgili nesnenin ContentType'ını gösterir
        # 'object_id',  # object_id'yi burada göstermek isterseniz ekleyebilirsiniz
    )
    # Filtreleme seçenekleri
    list_filter = (
        'notification_type',
        'is_read',
        'timestamp',
    )
    # Arama çubuğunda arama yapılabilecek alanlar
    search_fields = (
        'recipient__username', # Alıcı kullanıcı adına göre arama
        'sender__username',    # Gönderici kullanıcı adına göre arama
        'message',             # Mesaj içeriğine göre arama
    )
    # Düzenleme sayfasında sadece okunur alanlar
    readonly_fields = (
        'timestamp',
        'content_object', # content_object doğrudan düzenlenemez
    )
    # content_type ve object_id alanlarını bir arada göstermek için
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

