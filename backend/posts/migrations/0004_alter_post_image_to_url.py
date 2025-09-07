# Generated manually

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('posts', '0003_alter_post_group'),
    ]

    operations = [
        migrations.AddField(
            model_name='post',
            name='image_url',
            field=models.URLField(blank=True, null=True, verbose_name='Görsel URL (Supabase)'),
        ),
    ]