from django.db import migrations, connection
from django.contrib.postgres.operations import TrigramExtension


class Migration(migrations.Migration):
    """
    PostgreSQL pg_trgm extension'ını etkinleştirir
    Bu extension trigram tabanlı arama için gerekli
    """
    
    initial = True
    
    dependencies = [
    ]

    operations = [
        # PostgreSQL için TrigramExtension, SQLite için boş
        TrigramExtension() if connection.vendor == 'postgresql' else migrations.RunSQL(
            "-- SQLite için boş migration",
            reverse_sql="-- SQLite için boş migration",
            state_operations=[],
        ),
    ]
