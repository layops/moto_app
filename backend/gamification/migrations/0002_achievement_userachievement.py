# Generated manually for Achievement and UserAchievement models

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('gamification', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Achievement',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(help_text='Başarım adı', max_length=100)),
                ('description', models.TextField(help_text='Başarım açıklaması')),
                ('icon', models.CharField(default='emoji_events', help_text='Material icon adı', max_length=50)),
                ('achievement_type', models.CharField(choices=[('ride_count', 'Yolculuk Sayısı'), ('distance', 'Mesafe'), ('speed', 'Hız'), ('streak', 'Seri'), ('time', 'Zaman'), ('special', 'Özel')], help_text='Başarım türü', max_length=20)),
                ('target_value', models.IntegerField(help_text='Hedef değer (örn: 10 yolculuk, 1000 km)')),
                ('points', models.IntegerField(default=0, help_text='Bu başarım için verilecek puan')),
                ('is_active', models.BooleanField(default=True, help_text='Başarım aktif mi?')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'ordering': ['points', 'name'],
            },
        ),
        migrations.CreateModel(
            name='UserAchievement',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('progress', models.IntegerField(default=0, help_text='Mevcut ilerleme')),
                ('is_unlocked', models.BooleanField(default=False, help_text='Başarım kazanıldı mı?')),
                ('unlocked_at', models.DateTimeField(blank=True, help_text='Kazanılma tarihi', null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('achievement', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='user_achievements', to='gamification.achievement')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='user_achievements', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-unlocked_at', '-created_at'],
                'unique_together': {('user', 'achievement')},
            },
        ),
    ]
