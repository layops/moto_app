# Generated manually for HiddenConversation model

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models, connection


def create_hiddenconversation_table(apps, schema_editor):
    """Create HiddenConversation table if it doesn't exist"""
    with connection.cursor() as cursor:
        # Check if table exists
        cursor.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'chat_hiddenconversation'
            );
        """)
        table_exists = cursor.fetchone()[0]
        
        if table_exists:
            # Table already exists, skip creation
            print("✅ chat_hiddenconversation table already exists, skipping creation")
            return
        
        # Create table manually
        cursor.execute("""
            CREATE TABLE chat_hiddenconversation (
                id BIGSERIAL PRIMARY KEY,
                hidden_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                other_user_id BIGINT NOT NULL,
                user_id BIGINT NOT NULL,
                CONSTRAINT chat_hiddenconversation_user_id_fkey 
                    FOREIGN KEY (user_id) REFERENCES auth_user (id) ON DELETE CASCADE,
                CONSTRAINT chat_hiddenconversation_other_user_id_fkey 
                    FOREIGN KEY (other_user_id) REFERENCES auth_user (id) ON DELETE CASCADE,
                CONSTRAINT unique_hidden_conversation UNIQUE (user_id, other_user_id)
            );
        """)
        
        # Create indexes
        cursor.execute("CREATE INDEX chat_hiddenconversation_user_id_idx ON chat_hiddenconversation (user_id);")
        cursor.execute("CREATE INDEX chat_hiddenconversation_other_user_id_idx ON chat_hiddenconversation (other_user_id);")
        print("✅ chat_hiddenconversation table created successfully")


def reverse_create_hiddenconversation_table(apps, schema_editor):
    """Drop HiddenConversation table if it exists"""
    with connection.cursor() as cursor:
        cursor.execute("DROP TABLE IF EXISTS chat_hiddenconversation CASCADE;")


class Migration(migrations.Migration):

    dependencies = [
        ('chat', '0002_add_groupmessage'),
    ]

    operations = [
        migrations.RunPython(
            create_hiddenconversation_table,
            reverse_create_hiddenconversation_table,
        ),
    ]
