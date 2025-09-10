from django.db import migrations
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
        TrigramExtension(),
    ]
