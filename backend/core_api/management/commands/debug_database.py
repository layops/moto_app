"""
Management command to debug database status
"""
from django.core.management.base import BaseCommand
from core_api.database_debug import debug_database

class Command(BaseCommand):
    help = 'Debug database status and create test data'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Starting database debug...'))
        debug_database()
        self.stdout.write(self.style.SUCCESS('Database debug completed!'))
