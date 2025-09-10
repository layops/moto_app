from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from groups.models import Group

User = get_user_model()

class Command(BaseCommand):
    help = 'Test arama verilerini temizler'

    def add_arguments(self, parser):
        parser.add_argument(
            '--force',
            action='store_true',
            help='Onay istemeden temizle',
        )

    def handle(self, *args, **options):
        force = options['force']
        
        # Test kullanıcıları listesi
        test_usernames = [
            'ahmet', 'mehmet', 'ayse', 'fatma', 'ali', 'testuser'
        ]
        
        # Test grupları listesi
        test_group_names = [
            'Motosiklet Severler', 'Yol Arkadaşları', 'Test Grubu', 
            'Harley Davidson', 'Yamaha Riders'
        ]
        
        self.stdout.write('🧹 Test verileri temizleniyor...')
        
        # Test kullanıcılarını sil
        deleted_users = 0
        for username in test_usernames:
            try:
                user = User.objects.get(username=username)
                user.delete()
                deleted_users += 1
                self.stdout.write(f'✅ Test kullanıcısı silindi: {username}')
            except User.DoesNotExist:
                self.stdout.write(f'⚠️ Test kullanıcısı bulunamadı: {username}')
        
        # Test gruplarını sil
        deleted_groups = 0
        for group_name in test_group_names:
            try:
                group = Group.objects.get(name=group_name)
                group.delete()
                deleted_groups += 1
                self.stdout.write(f'✅ Test grubu silindi: {group_name}')
            except Group.DoesNotExist:
                self.stdout.write(f'⚠️ Test grubu bulunamadı: {group_name}')
        
        self.stdout.write(f'\n📊 Temizleme Özeti:')
        self.stdout.write(f'   Silinen test kullanıcıları: {deleted_users}')
        self.stdout.write(f'   Silinen test grupları: {deleted_groups}')
        
        # Kalan verileri göster
        remaining_users = User.objects.count()
        remaining_groups = Group.objects.count()
        
        self.stdout.write(f'\n📈 Kalan Veriler:')
        self.stdout.write(f'   Toplam kullanıcı: {remaining_users}')
        self.stdout.write(f'   Toplam grup: {remaining_groups}')
        
        if remaining_users > 0:
            self.stdout.write(f'\n👥 Mevcut Kullanıcılar:')
            for user in User.objects.all()[:5]:
                self.stdout.write(f'   - {user.username} ({user.first_name} {user.last_name})')
        
        if remaining_groups > 0:
            self.stdout.write(f'\n👥 Mevcut Gruplar:')
            for group in Group.objects.all()[:5]:
                self.stdout.write(f'   - {group.name}')
        
        self.stdout.write(f'\n✅ Test verileri temizlendi!')
