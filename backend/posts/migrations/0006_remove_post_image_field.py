# Generated manually for Supabase migration

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('posts', '0005_postlike_postcomment'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='post',
            name='image',
        ),
    ]
