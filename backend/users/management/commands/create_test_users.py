from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()

class Command(BaseCommand):
    help = 'Test kullanıcıları oluştur'

    def handle(self, *args, **options):
        # Test kullanıcıları
        test_users = [
            {
                'username': 'ahmet_yilmaz',
                'email': 'ahmet@example.com',
                'first_name': 'Ahmet',
                'last_name': 'Yılmaz',
                'password': 'test123'
            },
            {
                'username': 'mehmet_kaya',
                'email': 'mehmet@example.com',
                'first_name': 'Mehmet',
                'last_name': 'Kaya',
                'password': 'test123'
            },
            {
                'username': 'ayse_demir',
                'email': 'ayse@example.com',
                'first_name': 'Ayşe',
                'last_name': 'Demir',
                'password': 'test123'
            },
            {
                'username': 'fatma_ozkan',
                'email': 'fatma@example.com',
                'first_name': 'Fatma',
                'last_name': 'Özkan',
                'password': 'test123'
            },
            {
                'username': 'ali_celik',
                'email': 'ali@example.com',
                'first_name': 'Ali',
                'last_name': 'Çelik',
                'password': 'test123'
            }
        ]
        
        created_count = 0
        
        self.stdout.write("Test kullanıcıları oluşturuluyor...")
        
        for user_data in test_users:
            username = user_data['username']
            
            # Kullanıcı zaten var mı kontrol et
            if User.objects.filter(username=username).exists():
                self.stdout.write(f"⚠️  Kullanıcı zaten mevcut: {username}")
                continue
                
            try:
                user = User.objects.create_user(
                    username=user_data['username'],
                    email=user_data['email'],
                    first_name=user_data['first_name'],
                    last_name=user_data['last_name'],
                    password=user_data['password'],
                    is_active=True  # Aktif olarak oluştur
                )
                self.stdout.write(f"✅ Kullanıcı oluşturuldu: {username} ({user.first_name} {user.last_name})")
                created_count += 1
                
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"❌ Kullanıcı oluşturulamadı {username}: {e}"))
        
        self.stdout.write(f"\n📊 Toplam {created_count} yeni kullanıcı oluşturuldu")
        self.stdout.write(f"📊 Toplam kullanıcı sayısı: {User.objects.count()}")
        self.stdout.write(f"📊 Aktif kullanıcı sayısı: {User.objects.filter(is_active=True).count()}")
        
        # Tüm kullanıcıları listele
        self.stdout.write("\n=== TÜM KULLANICILAR ===")
        for user in User.objects.all():
            self.stdout.write(f"- {user.username} (ID: {user.id}, Active: {user.is_active}, Superuser: {user.is_superuser})")
