# moto_app/backend/bikes/tests.py

from rest_framework.test import APITestCase
from django.urls import reverse
from django.contrib.auth import get_user_model
from .models import Bike
from rest_framework import status

User = get_user_model()

class BikeTest(APITestCase):
    def setUp(self):
        """
        Her test metodundan önce çalışacak kurulum işlemleri.
        Test kullanıcıları oluşturma ve URL'leri tanımlama.
        """
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpassword'
        )
        self.admin_user = User.objects.create_superuser(
            username='adminuser',
            email='admin@example.com',
            password='adminpassword'
        )

        self.bike_list_url = reverse('bike-list')

        self.bike_data = {
            "brand": "Honda",
            "model": "CBR1000RR",
            "year": 2023,
            "engine_size": 1000,
            "color": "Red",
            "description": "Sport bike for track and road."
        }

    def test_authenticated_user_can_create_bike(self):
        """
        Kimliği doğrulanmış bir kullanıcının başarılı bir şekilde motosiklet oluşturup oluşturmadığını test eder.
        """
        self.client.force_authenticate(user=self.user)
        response = self.client.post(self.bike_list_url, self.bike_data, format='json')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Bike.objects.filter(brand="Honda", model="CBR1000RR", owner=self.user).exists())
        self.assertEqual(response.data['owner'], self.user.username)


    def test_unauthenticated_user_cannot_create_bike(self):
        """
        Kimliği doğrulanmamış bir kullanıcının motosiklet oluşturup oluşturmadığını test eder.
        """
        self.client.force_authenticate(user=None)
        response = self.client.post(self.bike_list_url, self.bike_data, format='json')

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertFalse(Bike.objects.filter(brand="Honda", model="CBR1000RR").exists())

    def test_authenticated_user_can_list_bikes(self):
        """
        Kimliği doğrulanmış bir kullanıcının tüm motosikletleri listeleyebildiğini test eder.
        """
        self.client.force_authenticate(user=self.user)

        Bike.objects.create(owner=self.user, brand="Kawasaki", model="Ninja 400")
        Bike.objects.create(owner=self.admin_user, brand="Ducati", model="Panigale V4")

        response = self.client.get(self.bike_list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)

        owners_in_response = [item.get('owner') for item in response.data] # .get() kullanıldı
        brands_in_response = [item['brand'] for item in response.data]

        self.assertIn(self.user.username, owners_in_response)
        self.assertIn(self.admin_user.username, owners_in_response)
        self.assertIn("Kawasaki", brands_in_response)
        self.assertIn("Ducati", brands_in_response)

    def test_unauthenticated_user_can_list_bikes(self):
        """
        Kimliği doğrulanmamış bir kullanıcının motosikletleri listeleyebildiğini test eder (AllowAny izni nedeniyle).
        """
        # owner'ı olmayan bir motosiklet de ekleyelim
        Bike.objects.create(owner=None, brand="Suzuki", model="GSX-R600")
        Bike.objects.create(owner=self.user, brand="Yamaha", model="MT-07")

        self.client.force_authenticate(user=None) # Kimlik doğrulamayı kaldır
        response = self.client.get(self.bike_list_url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)
        # Gelen verideki owner'ların ve markaların doğru olduğunu kontrol et
        owners_in_response = [item.get('owner') for item in response.data] # .get() kullanıldı
        brands_in_response = [item['brand'] for item in response.data]

        self.assertIn(None, owners_in_response) # owner=None olan motosiklet için
        self.assertIn(self.user.username, owners_in_response)
        self.assertIn("Suzuki", brands_in_response)
        self.assertIn("Yamaha", brands_in_response)


    def test_authenticated_user_can_retrieve_bike_detail(self):
        """
        Kimliği doğrulanmış bir kullanıcının belirli bir motosikletin detayını görüntüleyebildiğini test eder.
        """
        self.client.force_authenticate(user=self.user)

        # Bir motosiklet oluştur
        bike = Bike.objects.create(owner=self.user, **self.bike_data)

        # Detay URL'sini al
        bike_detail_url = reverse('bike-detail', kwargs={'pk': bike.pk})

        response = self.client.get(bike_detail_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['brand'], self.bike_data['brand'])
        self.assertEqual(response.data['owner'], self.user.username)
        self.assertIn('id', response.data)
        self.assertEqual(response.data['id'], bike.pk)

    def test_unauthenticated_user_can_retrieve_bike_detail(self):
        """
        Kimliği doğrulanmamış bir kullanıcının belirli bir motosikletin detayını görüntüleyebildiğini test eder.
        """
        # Bir motosiklet oluştur (sahibi olsun veya olmasın fark etmez)
        bike = Bike.objects.create(owner=self.user, **self.bike_data)

        # Detay URL'sini al
        bike_detail_url = reverse('bike-detail', kwargs={'pk': bike.pk})

        self.client.force_authenticate(user=None) # Kimlik doğrulamayı kaldır
        response = self.client.get(bike_detail_url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['brand'], self.bike_data['brand'])
        self.assertEqual(response.data['owner'], self.user.username) # Hata vermemesi için owner'ı kontrol et
        self.assertIn('id', response.data)
        self.assertEqual(response.data['id'], bike.pk)

    def test_authenticated_user_can_update_own_bike(self):
        """
        Kimliği doğrulanmış bir kullanıcının kendi oluşturduğu motosikleti güncelleyebildiğini test eder.
        """
        self.client.force_authenticate(user=self.user)
        bike = Bike.objects.create(owner=self.user, **self.bike_data)
        bike_detail_url = reverse('bike-detail', kwargs={'pk': bike.pk})

        updated_data = {
            "brand": "Honda",
            "model": "CBR600RR", # Model güncellendi
            "year": 2024,
            "color": "Blue",
        }

        response = self.client.patch(bike_detail_url, updated_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        bike.refresh_from_db() # Veritabanından güncel verileri çek
        self.assertEqual(bike.model, updated_data['model'])
        self.assertEqual(bike.year, updated_data['year'])
        self.assertEqual(bike.color, updated_data['color'])

    def test_authenticated_user_cannot_update_others_bike(self):
        """
        Kimliği doğrulanmış bir kullanıcının başka birine ait motosikleti güncelleyemediğini test eder.
        """
        self.client.force_authenticate(user=self.user) # testuser olarak giriş yap
        other_bike = Bike.objects.create(owner=self.admin_user, **self.bike_data) # admin_user'a ait bir motosiklet oluştur
        bike_detail_url = reverse('bike-detail', kwargs={'pk': other_bike.pk})

        updated_data = {
            "model": "Başkasına Ait Model Güncelleme Denemesi",
        }

        response = self.client.patch(bike_detail_url, updated_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN) # İzin hatası beklenir

        # Motosikletin modelinin değişmediğini kontrol et
        other_bike.refresh_from_db()
        self.assertNotEqual(other_bike.model, updated_data['model'])

    def test_authenticated_admin_can_update_any_bike(self):
        """
        Admin kullanıcının herhangi bir motosikleti güncelleyebildiğini test eder.
        """
        self.client.force_authenticate(user=self.admin_user) # admin_user olarak giriş yap
        bike = Bike.objects.create(owner=self.user, **self.bike_data) # testuser'a ait bir motosiklet oluştur
        bike_detail_url = reverse('bike-detail', kwargs={'pk': bike.pk})

        updated_data = {
            "model": "Admin Tarafından Güncellendi",
        }

        response = self.client.patch(bike_detail_url, updated_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK) # Başarılı güncelleme beklenir

        bike.refresh_from_db()
        self.assertEqual(bike.model, updated_data['model'])


    def test_unauthenticated_user_cannot_update_bike(self):
        """
        Kimliği doğrulanmamış bir kullanıcının motosiklet güncelleyemediğini test eder.
        """
        bike = Bike.objects.create(owner=self.user, **self.bike_data)
        bike_detail_url = reverse('bike-detail', kwargs={'pk': bike.pk})

        updated_data = {"model": "Anonim Güncelleme"}
        self.client.force_authenticate(user=None) # Kimlik doğrulamayı kaldır

        response = self.client.patch(bike_detail_url, updated_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED) # Yetkilendirme hatası beklenir
        bike.refresh_from_db()
        self.assertNotEqual(bike.model, updated_data['model'])


    def test_authenticated_user_can_delete_own_bike(self):
        """
        Kimliği doğrulanmış bir kullanıcının kendi oluşturduğu motosikleti silebildiğini test eder.
        """
        self.client.force_authenticate(user=self.user)
        bike = Bike.objects.create(owner=self.user, **self.bike_data)
        bike_detail_url = reverse('bike-detail', kwargs={'pk': bike.pk})

        response = self.client.delete(bike_detail_url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT) # Başarılı silme için 204 No Content beklenir

        # Veritabanında motosikletin silindiğini kontrol et
        self.assertFalse(Bike.objects.filter(pk=bike.pk).exists())

    def test_authenticated_user_cannot_delete_others_bike(self):
        """
        Kimliği doğrulanmış bir kullanıcının başka birine ait motosikleti silemediğini test eder.
        """
        self.client.force_authenticate(user=self.user) # testuser olarak giriş yap
        other_bike = Bike.objects.create(owner=self.admin_user, **self.bike_data) # admin_user'a ait bir motosiklet oluştur
        bike_detail_url = reverse('bike-detail', kwargs={'pk': other_bike.pk})

        response = self.client.delete(bike_detail_url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN) # İzin hatası beklenir

        # Motosikletin hala veritabanında olduğunu kontrol et
        self.assertTrue(Bike.objects.filter(pk=other_bike.pk).exists())

    def test_authenticated_admin_can_delete_any_bike(self):
        """
        Admin kullanıcının herhangi bir motosikleti silebildiğini test eder.
        """
        self.client.force_authenticate(user=self.admin_user) # admin_user olarak giriş yap
        bike = Bike.objects.create(owner=self.user, **self.bike_data) # testuser'a ait bir motosiklet oluştur
        bike_detail_url = reverse('bike-detail', kwargs={'pk': bike.pk})

        response = self.client.delete(bike_detail_url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT) # Başarılı silme beklenir

        # Veritabanında motosikletin silindiğini kontrol et
        self.assertFalse(Bike.objects.filter(pk=bike.pk).exists())


    def test_unauthenticated_user_cannot_delete_bike(self):
        """
        Kimliği doğrulanmamış bir kullanıcının motosiklet silip silemediğini test eder.
        """
        bike = Bike.objects.create(owner=self.user, **self.bike_data)
        bike_detail_url = reverse('bike-detail', kwargs={'pk': bike.pk})

        self.client.force_authenticate(user=None) # Kimlik doğrulamayı kaldır

        response = self.client.delete(bike_detail_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED) # Yetkilendirme hatası beklenir
        self.assertTrue(Bike.objects.filter(pk=bike.pk).exists())