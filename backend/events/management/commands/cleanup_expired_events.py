from django.core.management.base import BaseCommand
from django.utils import timezone
from django.db import models
from events.models import Event
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Süresi geçmiş event\'leri temizler'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Sadece hangi event\'lerin silineceğini göster, gerçekten silme',
        )
        parser.add_argument(
            '--days-after',
            type=int,
            default=7,
            help='Event bitiş tarihinden kaç gün sonra silinsin (varsayılan: 7)',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        days_after = options['days_after']
        
        # Şu anki zaman
        now = timezone.now()
        
        # Silme tarihi: end_time + days_after gün
        # Eğer end_time yoksa start_time + days_after gün
        cutoff_date = now - timezone.timedelta(days=days_after)
        
        self.stdout.write(f"Süresi geçmiş event'ler temizleniyor...")
        self.stdout.write(f"Şu anki zaman: {now}")
        self.stdout.write(f"Silme tarihi: {cutoff_date} (Event bitiş tarihi + {days_after} gün)")
        
        # Silinecek event'leri bul
        expired_events = Event.get_expired_events(days_after)
        
        count = expired_events.count()
        
        if count == 0:
            self.stdout.write(
                self.style.SUCCESS('Silinecek süresi geçmiş event bulunamadı.')
            )
            return
        
        self.stdout.write(f"Silinecek event sayısı: {count}")
        
        # Event detaylarını göster
        for event in expired_events:
            end_time_str = event.end_time.strftime('%Y-%m-%d %H:%M') if event.end_time else 'Yok'
            start_time_str = event.start_time.strftime('%Y-%m-%d %H:%M')
            
            self.stdout.write(
                f"- ID: {event.id}, Başlık: {event.title}, "
                f"Başlangıç: {start_time_str}, Bitiş: {end_time_str}, "
                f"Organizatör: {event.organizer.username}"
            )
        
        if dry_run:
            self.stdout.write(
                self.style.WARNING(f'DRY RUN: {count} event silinecekti ama silinmedi.')
            )
            return
        
        # Onay iste
        confirm = input(f"\n{count} adet süresi geçmiş event silinecek. Devam etmek istiyor musunuz? (y/N): ")
        
        if confirm.lower() != 'y':
            self.stdout.write(self.style.WARNING('İşlem iptal edildi.'))
            return
        
        # Event'leri sil
        deleted_count = 0
        for event in expired_events:
            try:
                event_title = event.title
                event_id = event.id
                event.delete()
                deleted_count += 1
                logger.info(f"Expired event deleted: ID={event_id}, Title={event_title}")
            except Exception as e:
                logger.error(f"Event silme hatası - ID: {event.id}, Hata: {str(e)}")
                self.stdout.write(
                    self.style.ERROR(f"Event silme hatası - ID: {event.id}, Hata: {str(e)}")
                )
        
        self.stdout.write(
            self.style.SUCCESS(f'{deleted_count} adet süresi geçmiş event başarıyla silindi.')
        )
        
        # İstatistikler
        remaining_events = Event.objects.count()
        self.stdout.write(f"Kalan event sayısı: {remaining_events}")
