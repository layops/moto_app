from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()

class Command(BaseCommand):
    help = 'Emre kullanıcısını aktif hale getir ve bilgilerini göster'

    def handle(self, *args, **options):
        try:
            # Emre kullanıcısını bul
            emre_user = User.objects.get(username='emre')
            
            self.stdout.write(f"Emre kullanıcısı bulundu:")
            self.stdout.write(f"  - ID: {emre_user.id}")
            self.stdout.write(f"  - Username: {emre_user.username}")
            self.stdout.write(f"  - Email: {emre_user.email}")
            self.stdout.write(f"  - Active: {emre_user.is_active}")
            self.stdout.write(f"  - Superuser: {emre_user.is_superuser}")
            self.stdout.write(f"  - First Name: {emre_user.first_name}")
            self.stdout.write(f"  - Last Name: {emre_user.last_name}")
            
            # Eğer aktif değilse aktif hale getir
            if not emre_user.is_active:
                emre_user.is_active = True
                emre_user.save()
                self.stdout.write(self.style.SUCCESS("✅ Emre kullanıcısı aktif hale getirildi!"))
            else:
                self.stdout.write(self.style.SUCCESS("✅ Emre kullanıcısı zaten aktif!"))
                
        except User.DoesNotExist:
            self.stdout.write(self.style.ERROR("❌ Emre kullanıcısı bulunamadı!"))
            
            # Tüm kullanıcıları listele
            self.stdout.write("\nMevcut kullanıcılar:")
            for user in User.objects.all():
                self.stdout.write(f"  - {user.username} (ID: {user.id}, Active: {user.is_active})")
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"❌ Hata: {e}"))
