# Generated manually to add new notification preference fields

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('notifications', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='notificationpreferences',
            name='likes_comments',
            field=models.BooleanField(default=True, verbose_name='Beğeni ve Yorumlar'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='follows',
            field=models.BooleanField(default=True, verbose_name='Takip Bildirimleri'),
        ),
    ]
