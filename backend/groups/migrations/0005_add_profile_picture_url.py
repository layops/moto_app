# Generated manually for Render.com deployment
# Migration number 0005 to avoid conflicts with existing migrations

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('groups', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='group',
            name='profile_picture_url',
            field=models.URLField(blank=True, null=True, verbose_name='Profil Fotoğrafı URL'),
        ),
    ]
