# Generated manually for HiddenConversation model

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('chat', '0002_add_groupmessage'),
    ]

    operations = [
        migrations.CreateModel(
            name='HiddenConversation',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('hidden_at', models.DateTimeField(auto_now_add=True, verbose_name='Gizlenme Tarihi')),
                ('other_user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='hidden_by_conversations', to=settings.AUTH_USER_MODEL, verbose_name='Gizlenen Kullanıcı')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='hidden_conversations', to=settings.AUTH_USER_MODEL, verbose_name='Kullanıcı')),
            ],
            options={
                'verbose_name': 'Gizlenen Konuşma',
                'verbose_name_plural': 'Gizlenen Konuşmalar',
            },
        ),
    ]
