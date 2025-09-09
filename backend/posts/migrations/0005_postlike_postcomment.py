# Generated manually

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('posts', '0004_alter_post_image_to_url'),
        ('users', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='PostLike',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Oluşturulma Tarihi')),
                ('post', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='likes', to='posts.post', verbose_name='Gönderi')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='post_likes', to='users.customuser', verbose_name='Kullanıcı')),
            ],
            options={
                'verbose_name': 'Gönderi Beğenisi',
                'verbose_name_plural': 'Gönderi Beğenileri',
            },
        ),
        migrations.CreateModel(
            name='PostComment',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('content', models.TextField(verbose_name='Yorum İçeriği')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Oluşturulma Tarihi')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Güncellenme Tarihi')),
                ('author', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='post_comments', to='users.customuser', verbose_name='Yazar')),
                ('post', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='comments', to='posts.post', verbose_name='Gönderi')),
            ],
            options={
                'verbose_name': 'Gönderi Yorumu',
                'verbose_name_plural': 'Gönderi Yorumları',
                'ordering': ['-created_at'],
            },
        ),
        migrations.AddConstraint(
            model_name='postlike',
            constraint=models.UniqueConstraint(fields=('post', 'user'), name='unique_post_user_like'),
        ),
    ]
