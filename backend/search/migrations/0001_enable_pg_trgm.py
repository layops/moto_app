from django.db import migrations


class Migration(migrations.Migration):
    """
    PostgreSQL pg_trgm extension'ını etkinleştirir
    Bu extension trigram tabanlı arama için gerekli
    SQLite için boş migration
    """
    
    initial = True
    
    dependencies = [
    ]

    operations = [
        # SQLite için boş migration - PostgreSQL'de çalışmayacak ama SQLite'da çalışacak
        migrations.RunSQL(
            "-- SQLite için boş migration",
            reverse_sql="-- SQLite için boş migration",
            state_operations=[],
        ),
    ]
