# Generated manually for Supabase migration

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bikes', '0001_initial'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='bike',
            name='main_image',
        ),
        migrations.AddField(
            model_name='bike',
            name='main_image_url',
            field=models.URLField(blank=True, null=True, verbose_name='Ana Resim URL'),
        ),
    ]
