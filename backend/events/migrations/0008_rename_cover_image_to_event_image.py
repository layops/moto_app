# Generated manually on 2025-01-27

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('events', '0007_event_approval_system'),
    ]

    operations = [
        migrations.RenameField(
            model_name='event',
            old_name='cover_image',
            new_name='event_image',
        ),
    ]
