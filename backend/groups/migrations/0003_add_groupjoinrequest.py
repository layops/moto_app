# Generated manually for Render.com deployment
# Migration to add GroupJoinRequest model

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('groups', '0002_add_profile_picture_url'),
    ]

    operations = [
        migrations.CreateModel(
            name='GroupJoinRequest',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('message', models.TextField(blank=True, verbose_name='Mesaj')),
                ('status', models.CharField(choices=[('pending', 'Beklemede'), ('approved', 'Onaylandı'), ('rejected', 'Reddedildi')], default='pending', max_length=20, verbose_name='Durum')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Oluşturulma Tarihi')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Güncellenme Tarihi')),
                ('group', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='join_requests', to='groups.group', verbose_name='Grup')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='group_join_requests', to=settings.AUTH_USER_MODEL, verbose_name='Kullanıcı')),
            ],
            options={
                'verbose_name': 'Grup Katılım Talebi',
                'verbose_name_plural': 'Grup Katılım Talepleri',
                'unique_together': {('group', 'user')},
                'ordering': ['-created_at'],
            },
        ),
    ]
