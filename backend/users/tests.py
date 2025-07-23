# moto_app/backend/users/tests.py

from rest_framework.test import APITestCase
from django.urls import reverse
from django.contrib.auth import get_user_model

# Django'nun varsayılan User modelini alıyoruz.
# Kendi özel User modeliniz varsa, Django onu get_user_model() ile otomatik olarak bulur.
User = get_user_model()

class UserRegistrationTest(APITestCase):
    def setUp(self):
        """
        Her test metodundan önce çalışacak kurulum işlemleri.
        Burada API endpoint'inin URL'sini belirliyoruz.
        """
        # Kullanıcı kayıt URL'sini alıyoruz.
        # users/urls.py dosyanızdaki 'register' adlı URL'yi kullanıyoruz.
        self.register_url = reverse('register')

    def test_user_can_register(self):
        """
        Yeni bir kullanıcının başarılı bir şekilde kaydedilip kaydedilmediğini test eder.
        """
        data = {
            'username': 'testuser_new',
            'email': 'newuser@example.com',
            'password': 'securepassword123',
            'password2': 'securepassword123' # Eğer serializer'ınızda password2 alanı varsa
        }
        # POST isteği ile kayıt endpoint'ine veri gönder
        response = self.client.post(self.register_url, data, format='json')

        # Yanıt durum kodunu kontrol et (Başarılı kayıt için 201 Created beklenir)
        self.assertEqual(response.status_code, 201)
        # Kullanıcının veritabanına kaydedilip kaydedilmediğini kontrol et
        self.assertTrue(User.objects.filter(username='testuser_new').exists())
        # Yanıt içinde token döndürülüyor mu kontrol et (eğer UserRegisterView token döndürüyorsa)
        self.assertIn('token', response.data)
        self.assertIsNotNone(response.data['token'])

    def test_user_registration_with_existing_username(self):
        """
        Mevcut bir kullanıcı adıyla kayıt olmaya çalışıldığında hata verilip verilmediğini test eder.
        """
        # Test için önceden bir kullanıcı oluştur
        User.objects.create_user(username='existinguser', email='existing@example.com', password='password123')

        data = {
            'username': 'existinguser', # Mevcut kullanıcı adı
            'email': 'another@example.com',
            'password': 'newpassword',
            'password2': 'newpassword'
        }
        response = self.client.post(self.register_url, data, format='json')

        # Yanıt durum kodunu kontrol et (400 Bad Request beklenir)
        self.assertEqual(response.status_code, 400)
        # Hata mesajında 'username' ile ilgili bir hata olduğunu kontrol et
        self.assertIn('username', response.data)
        # Tam hata mesajını kontrol et (Django'nun varsayı