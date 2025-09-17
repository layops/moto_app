# Generated manually to fix constraint issue

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('posts', '0006_remove_post_image_field'),
    ]

    operations = [
        # Constraint'i güvenli şekilde kaldır
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM information_schema.table_constraints 
                    WHERE constraint_name = 'unique_post_user_like' 
                    AND table_name = 'posts_postlike'
                ) THEN
                    ALTER TABLE posts_postlike DROP CONSTRAINT unique_post_user_like;
                END IF;
            END $$;
            """,
            reverse_sql="-- No reverse operation needed",
        ),
    ]
