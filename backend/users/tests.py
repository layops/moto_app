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
            'email': 'newuser@gmail.com',  # Geçerli email domain'i
            'password': 'SecurePass123',  # Güçlü şifre
            'password2': 'SecurePass123'
        }
        # POST isteği ile kayıt endpoint'ine veri gönder
        response = self.client.post(self.register_url, data, format='json')

        # Yanıt durum kodunu kontrol et (Başarılı kayıt için 201 Created beklenir)
        self.assertEqual(response.status_code, 201)
        # Kullanıcının veritabanına kaydedilip kaydedilmediğini kontrol et
        self.assertTrue(User.objects.filter(username='testuser_new').exists())
        # Yanıt içinde user bilgisi döndürülüyor mu kontrol et
        self.assertIn('user', response.data)
        self.assertIn('message', response.data)

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

    def test_user_registration_with_invalid_email(self):
        """
        Geçersiz email adresiyle kayıt olmaya çalışıldığında hata verilip verilmediğini test eder.
        """
        data = {
            'username': 'testuser_invalid_email',
            'email': 'invalid-email',  # Geçersiz email formatı
            'password': 'SecurePass123',
            'password2': 'SecurePass123'
        }
        response = self.client.post(self.register_url, data, format='json')

        # Yanıt durum kodunu kontrol et (400 Bad Request beklenir)
        self.assertEqual(response.status_code, 400)
        # Hata mesajında 'email' ile ilgili bir hata olduğunu kontrol et
        self.assertIn('email', response.data)

    def test_user_registration_with_fake_domain(self):
        """
        Sahte domain ile kayıt olmaya çalışıldığında hata verilip verilmediğini test eder.
        """
        data = {
            'username': 'testuser_fake_domain',
            'email': 'user@fake.com',  # Sahte domain
            'password': 'SecurePass123',
            'password2': 'SecurePass123'
        }
        response = self.client.post(self.register_url, data, format='json')

        # Yanıt durum kodunu kontrol et (400 Bad Request beklenir)
        self.assertEqual(response.status_code, 400)
        # Hata mesajında 'email' ile ilgili bir hata olduğunu kontrol et
        self.assertIn('email', response.data)

    def test_user_registration_with_weak_password(self):
        """
        Zayıf şifre ile kayıt olmaya çalışıldığında hata verilip verilmediğini test eder.
        """
        data = {
            'username': 'testuser_weak_pass',
            'email': 'user@gmail.com',
            'password': '123',  # Zayıf şifre
            'password2': '123'
        }
        response = self.client.post(self.register_url, data, format='json')

        # Yanıt durum kodunu kontrol et (400 Bad Request beklenir)
        self.assertEqual(response.status_code, 400)
        # Hata mesajında 'password' ile ilgili bir hata olduğunu kontrol et
        self.assertIn('password', response.data)

    def test_user_registration_with_existing_email(self):
        """
        Mevcut email adresiyle kayıt olmaya çalışıldığında hata verilip verilmediğini test eder.
        """
        # Test için önceden bir kullanıcı oluştur
        User.objects.create_user(
            username='existinguser_email', 
            email='existing@gmail.com', 
            password='password123'
        )

        data = {
            'username': 'newuser_email',
            'email': 'existing@gmail.com',  # Mevcut email
            'password': 'SecurePass123',
            'password2': 'SecurePass123'
        }
        response = self.client.post(self.register_url, data, format='json')

        # Yanıt durum kodunu kontrol et (400 Bad Request beklenir)
        self.assertEqual(response.status_code, 400)
        # Hata mesajında 'email' ile ilgili bir hata olduğunu kontrol et
        self.assertIn('email', response.data)