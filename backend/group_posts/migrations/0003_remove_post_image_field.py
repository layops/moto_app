# Generated manually for Supabase migration

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('group_posts', '0002_remove_post_creator_post_author_alter_post_group'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='post',
            name='image',
        ),
    ]
