# Generated manually to fix PostLike constraint

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('posts', '0007_fix_constraint_issue'),
    ]

    operations = [
        # unique_together'ı kaldır ve constraints ile değiştir
        migrations.AlterUniqueTogether(
            name='postlike',
            unique_together=set(),
        ),
        migrations.AddConstraint(
            model_name='postlike',
            constraint=models.UniqueConstraint(fields=['post', 'user'], name='unique_post_user_like'),
        ),
    ]

