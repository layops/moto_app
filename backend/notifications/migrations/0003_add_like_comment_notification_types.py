# Generated manually to add new notification types

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('notifications', '0002_add_likes_comments_follows'),
    ]

    operations = [
        migrations.AlterField(
            model_name='notification',
            name='notification_type',
            field=models.CharField(
                choices=[
                    ('message', 'Yeni Mesaj'),
                    ('group_invite', 'Grup Daveti'),
                    ('group_join_request', 'Grup Katılım İsteği'),
                    ('group_join_approved', 'Grup Katılım Onaylandı'),
                    ('group_join_rejected', 'Grup Katılım Reddedildi'),
                    ('event_join_request', 'Etkinlik Katılım İsteği'),
                    ('event_join_approved', 'Etkinlik Katılım Onaylandı'),
                    ('event_join_rejected', 'Etkinlik Katılım Reddedildi'),
                    ('ride_request', 'Yolculuk Katılım İsteği'),
                    ('ride_update', 'Yolculuk Güncellemesi'),
                    ('group_update', 'Grup Güncellemesi'),
                    ('friend_request', 'Arkadaşlık İsteği'),
                    ('follow', 'Takip Bildirimi'),
                    ('like', 'Beğeni Bildirimi'),
                    ('comment', 'Yorum Bildirimi'),
                    ('other', 'Diğer'),
                ],
                default='other',
                max_length=50,
                verbose_name='Bildirim Türü'
            ),
        ),
    ]
