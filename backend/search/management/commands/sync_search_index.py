"""
Search index'i senkronize etmek için management command
"""
from django.core.management.base import BaseCommand
from search.pg_trgm_search import pg_trgm_search_engine


class Command(BaseCommand):
    help = 'Search index\'i User ve Group modelleri ile senkronize eder'

    def add_arguments(self, parser):
        parser.add_argument(
            '--force',
            action='store_true',
            help='Mevcut index\'i temizleyip yeniden oluştur',
        )

    def handle(self, *args, **options):
        if options['force']:
            self.stdout.write(
                self.style.WARNING('Search index temizleniyor ve yeniden oluşturuluyor...')
            )
            pg_trgm_search_engine.clear_cache()
            self.stdout.write(
                self.style.SUCCESS('Search index başarıyla temizlendi ve yeniden oluşturuldu!')
            )
        else:
            self.stdout.write(
                self.style.WARNING('Search index senkronize ediliyor...')
            )
            pg_trgm_search_engine.force_sync()
            self.stdout.write(
                self.style.SUCCESS('Search index başarıyla senkronize edildi!')
            )
