# Generated manually for Render.com deployment
# Migration to add GroupMessage model

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('chat', '0001_initial'),
        ('groups', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='GroupMessage',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('content', models.TextField(verbose_name='Mesaj İçeriği')),
                ('message_type', models.CharField(choices=[('text', 'Metin'), ('image', 'Resim'), ('file', 'Dosya')], default='text', max_length=20, verbose_name='Mesaj Türü')),
                ('file_url', models.URLField(blank=True, null=True, verbose_name='Dosya URL')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Oluşturulma Tarihi')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Güncellenme Tarihi')),
                ('group', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='messages', to='groups.group', verbose_name='Grup')),
                ('reply_to', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='replies', to='chat.groupmessage', verbose_name='Yanıtlanan Mesaj')),
                ('sender', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='sent_group_messages', to=settings.AUTH_USER_MODEL, verbose_name='Gönderen')),
            ],
            options={
                'verbose_name': 'Grup Mesajı',
                'verbose_name_plural': 'Grup Mesajları',
                'ordering': ['-created_at'],
            },
        ),
    ]
