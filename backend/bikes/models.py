from django.db import models
from django.conf import settings # Ayarlar dosyasından AUTH_USER_MODEL'ı çekmek için

class Bike(models.Model):
    # Bu motosikleti ekleyen kullanıcı. Zorunlu olmasın demiştik,
    # bu yüzden null=True, blank=True ekliyoruz.
    # Eğer bir motosikletin sahibi yoksa bu alan boş kalabilir.
    # Eğer her motosikletin bir kullanıcısı olması zorunlu olsaydı, null=False ve blank=False olurdu.
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                              related_name='bikes', null=True, blank=True)

    # Temel Tanımlayıcı Bilgiler (Zorunlu Alanlar)
    brand = models.CharField(max_length=100) # Marka (örn: Honda)
    model = models.CharField(max_length=100) # Model (örn: CBR600RR)

    # Opsiyonel Bilgiler (null=True ve blank=True ile boş bırakılabilirler)
    year = models.IntegerField(null=True, blank=True) # Yıl (örn: 2023)
    engine_size = models.IntegerField(null=True, blank=True) # Motor Hacmi (örn: 600cc)
    color = models.CharField(max_length=50, null=True, blank=True) # Renk (örn: Kırmızı)
    description = models.TextField(null=True, blank=True) # Detaylı açıklama

    # Resim Alanı (İsteğe bağlı) - Supabase Storage URL
    # Resimler Supabase Storage'da saklanıyor
    main_image_url = models.URLField(blank=True, null=True, verbose_name="Ana Resim URL")

    # Oluşturulma ve Güncellenme Tarihleri (Otomatik olarak atanır)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Motosiklet" # Admin panelinde daha güzel görünmesi için
        verbose_name_plural = "Motosikletler" # Admin panelinde çoğul hali

    def __str__(self):
        return f"{self.brand} {self.model} ({self.year if self.year else 'N/A'})"