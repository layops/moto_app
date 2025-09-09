from django.core.management.base import BaseCommand
from gamification.models import Achievement

class Command(BaseCommand):
    help = 'Yolculuk bazlı başarımları oluştur'

    def handle(self, *args, **options):
        try:
            achievements_data = [
            {
                'name': 'İlk Yolculuk',
                'description': 'İlk motosiklet yolculuğunuzu tamamladınız',
                'icon': 'two_wheeler',
                'achievement_type': 'ride_count',
                'target_value': 1,
                'points': 10,
            },
            {
                'name': 'Yolcu',
                'description': '10 yolculuk tamamladınız',
                'icon': 'directions_bike',
                'achievement_type': 'ride_count',
                'target_value': 10,
                'points': 25,
            },
            {
                'name': 'Deneyimli Sürücü',
                'description': '50 yolculuk tamamladınız',
                'icon': 'motorcycle',
                'achievement_type': 'ride_count',
                'target_value': 50,
                'points': 50,
            },
            {
                'name': 'Usta Sürücü',
                'description': '100 yolculuk tamamladınız',
                'icon': 'speed',
                'achievement_type': 'ride_count',
                'target_value': 100,
                'points': 100,
            },
            {
                'name': 'Mesafe Avcısı',
                'description': '1000 km yol katettiniz',
                'icon': 'straighten',
                'achievement_type': 'distance',
                'target_value': 1000,
                'points': 75,
            },
            {
                'name': 'Hız Tutkunu',
                'description': '120 km/h hıza ulaştınız',
                'icon': 'flash_on',
                'achievement_type': 'speed',
                'target_value': 120,
                'points': 60,
            },
            {
                'name': 'Günlük Sürücü',
                'description': '7 gün üst üste yolculuk yaptınız',
                'icon': 'calendar_today',
                'achievement_type': 'streak',
                'target_value': 7,
                'points': 40,
            },
            {
                'name': 'Gece Sürücüsü',
                'description': '10 gece yolculuğu tamamladınız',
                'icon': 'nightlight_round',
                'achievement_type': 'special',
                'target_value': 10,
                'points': 35,
            },
        ]

        created_count = 0
        for achievement_data in achievements_data:
            achievement, created = Achievement.objects.get_or_create(
                name=achievement_data['name'],
                defaults=achievement_data
            )
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'Başarım oluşturuldu: {achievement.name}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'Başarım zaten mevcut: {achievement.name}')
                )

            self.stdout.write(
                self.style.SUCCESS(f'Toplam {created_count} yeni başarım oluşturuldu.')
            )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Başarımlar oluşturulurken hata: {e}')
            )
            # Hata durumunda da devam et, crash etmesin
