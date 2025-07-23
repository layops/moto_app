# moto_app/backend/rides/tests.py

from rest_framework.test import APITestCase
from django.urls import reverse
from django.contrib.auth import get_user_model
from .models import Ride # Ride modelini import et
from rest_framework import status # HTTP durum kodları için

User = get_user_model() # Django'nun özel User modelini al

class RideTest(APITestCase):
    def setUp(self):
        """
        Her test metodundan önce çalışacak kurulum işlemleri.
        Test kullanıcıları oluşturma ve URL'leri tanımlama.
        """
        # Test kullanıcıları oluştur
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpassword'
        )
        self.another_user = User.objects.create_user(
            username='anotheruser',
            email='another@example.com',
            password='anotherpassword'
        )

        # Ride oluşturma ve listeleme URL'sini al
        # 'ride-list' ifadesi rides/urls.py dosyasındaki router.register'daki basename='ride' ile uyumlu
        self.ride_list_url = reverse('ride-list')

        # Oluşturulacak yolculuk için örnek veri
        self.ride_data = {
            "title": "İlk Motosiklet Yolculuğu",
            "description": "Harika bir hafta sonu gezisi!",
            "start_location": "Gebze, Kocaeli",
            "end_location": "İstanbul, Kadıköy",
            "start_time": "2025-07-25T10:00:00Z", # ISO 8601 formatında tarih ve saat
            "end_time": "2025-07-25T14:00:00Z",
            "max_participants": 10,
            "is_active": True
        }

    def test_authenticated_user_can_create_ride(self):
        """
        Kimliği doğrulanmış bir kullanıcının başarılı bir şekilde yolculuk oluşturup oluşturmadığını test eder.
        """
        # Kullanıcıyı doğrula (giriş yapmasını sağla)
        self.client.force_authenticate(user=self.user)

        # POST isteği ile yolculuk oluşturma endpoint'ine veri gönder
        response = self.client.post(self.ride_list_url, self.ride_data, format='json')

        # Yanıt durum kodunu kontrol et (Başarılı oluşturma için 201 Created beklenir)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        # Veritabanında yolculuğun oluşturulup oluşturulmadığını kontrol et
        self.assertTrue(Ride.objects.filter(title="İlk Motosiklet Yolculuğu", owner=self.user).exists())

        # Yanıttaki owner alanının doğru kullanıcı adını döndürdüğünü kontrol et
        self.assertEqual(response.data['owner'], self.user.username)

        # Yanıtta diğer beklenen alanların olduğunu kontrol et
        self.assertIn('id', response.data)
        self.assertEqual(response.data['title'], self.ride_data['title'])
        self.assertEqual(response.data['start_location'], self.ride_data['start_location'])


    def test_unauthenticated_user_cannot_create_ride(self):
        """
        Kimliği doğrulanmamış bir kullanıcının yolculuk oluşturup oluşturmadığını test eder.
        """
        # API'ye kimliği doğrulanmamış olarak istek gönder
        self.client.force_authenticate(user=None) # Kimlik doğrulamayı kaldır

        response = self.client.post(self.ride_list_url, self.ride_data, format='json')

        # Yetkilendirme hatası (401 Unauthorized) beklenir
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

        # Veritabanında yolculuğun oluşturulmadığını kontrol et
        self.assertFalse(Ride.objects.filter(title="İlk Motosiklet Yolculuğu").exists())

    def test_authenticated_user_can_list_rides(self):
        """
        Kimliği doğrulanmış bir kullanıcının tüm yolculukları listeleyebildiğini test eder.
        """
        self.client.force_authenticate(user=self.user)

        # Başka bir kullanıcı ve kendi kullanıcımız için iki yolculuk oluşturalım
        ride1 = Ride.objects.create(owner=self.user,
                                    title="Test Kullanıcısı Yolculuğu",
                                    start_location="A", end_location="B",
                                    start_time="2025-07-25T10:00:00Z")
        ride2 = Ride.objects.create(owner=self.another_user,
                                    title="Başka Kullanıcı Yolculuğu",
                                    start_location="C", end_location="D",
                                    start_time="2025-08-01T09:00:00Z") # Daha yeni bir tarih

        response = self.client.get(self.ride_list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2) # İki yolculuk beklentisi

        # Gelen veriyi kontrol edelim, hangi sırada geldiklerini varsaymadan
        owners_in_response = [item['owner'] for item in response.data]
        self.assertIn(self.user.username, owners_in_response)
        self.assertIn(self.another_user.username, owners_in_response)

        # Gelen verideki yolculuk başlıklarını da kontrol edebiliriz
        titles_in_response = [item['title'] for item in response.data]
        self.assertIn("Test Kullanıcısı Yolculuğu", titles_in_response)
        self.assertIn("Başka Kullanıcı Yolculuğu", titles_in_response)


    def test_authenticated_user_can_retrieve_ride_detail(self):
        """
        Kimliği doğrulanmış bir kullanıcının belirli bir yolculuğun detayını görüntüleyebildiğini test eder.
        """
        self.client.force_authenticate(user=self.user)

        # Bir yolculuk oluştur
        ride = Ride.objects.create(owner=self.user, **self.ride_data)

        # Detay URL'sini al
        ride_detail_url = reverse('ride-detail', kwargs={'pk': ride.pk})

        response = self.client.get(ride_detail_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['title'], self.ride_data['title'])
        self.assertEqual(response.data['owner'], self.user.username)
        self.assertIn('id', response.data)
        self.assertEqual(response.data['id'], ride.pk)

    def test_authenticated_user_can_update_own_ride(self):
        """
        Kimliği doğrulanmış bir kullanıcının kendi oluşturduğu yolculuğu güncelleyebildiğini test eder.
        """
        self.client.force_authenticate(user=self.user)
        ride = Ride.objects.create(owner=self.user, **self.ride_data)
        ride_detail_url = reverse('ride-detail', kwargs={'pk': ride.pk})

        updated_data = {
            "title": "Güncellenmiş Motosiklet Yolculuğu",
            "description": "Güncellenmiş açıklama.",
            "start_location": "İstanbul, Kadıköy",
            "end_location": "Bursa",
            "start_time": "2025-07-26T10:00:00Z",
            "end_time": "2025-07-26T14:00:00Z",
            "max_participants": 15,
            "is_active": True
        }

        response = self.client.put(ride_detail_url, updated_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        ride.refresh_from_db() # Veritabanından güncel verileri çek
        self.assertEqual(ride.title, updated_data['title'])
        self.assertEqual(ride.end_location, updated_data['end_location'])
        self.assertEqual(ride.max_participants, updated_data['max_participants'])

    def test_authenticated_user_cannot_update_others_ride(self):
        """
        Kimliği doğrulanmış bir kullanıcının başka birine ait yolculuğu güncelleyemediğini test eder.
        """
        self.client.force_authenticate(user=self.user) # testuser olarak giriş yap
        other_ride = Ride.objects.create(owner=self.another_user, **self.ride_data) # another_user'a ait bir yolculuk oluştur
        ride_detail_url = reverse('ride-detail', kwargs={'pk': other_ride.pk})

        updated_data = {
            "title": "Başkasına Ait Yolculuk Güncelleme Denemesi",
        }

        response = self.client.put(ride_detail_url, updated_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN) # İzin hatası beklenir

        # Yolculuğun başlığının değişmediğini kontrol et
        other_ride.refresh_from_db()
        self.assertNotEqual(other_ride.title, updated_data['title'])


    def test_authenticated_user_can_delete_own_ride(self):
        """
        Kimliği doğrulanmış bir kullanıcının kendi oluşturduğu yolculuğu silebildiğini test eder.
        """
        self.client.force_authenticate(user=self.user)
        ride = Ride.objects.create(owner=self.user, **self.ride_data)
        ride_detail_url = reverse('ride-detail', kwargs={'pk': ride.pk})

        response = self.client.delete(ride_detail_url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT) # Başarılı silme için 204 No Content beklenir

        # Veritabanında yolculuğun silindiğini kontrol et
        self.assertFalse(Ride.objects.filter(pk=ride.pk).exists())

    def test_authenticated_user_cannot_delete_others_ride(self):
        """
        Kimliği doğrulanmış bir kullanıcının başka birine ait yolculuğu silemediğini test eder.
        """
        self.client.force_authenticate(user=self.user) # testuser olarak giriş yap
        other_ride = Ride.objects.create(owner=self.another_user, **self.ride_data) # another_user'a ait bir yolculuk oluştur
        ride_detail_url = reverse('ride-detail', kwargs={'pk': other_ride.pk})

        response = self.client.delete(ride_detail_url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN) # İzin hatası beklenir

        # Yolculuğun hala veritabanında olduğunu kontrol et
        self.assertTrue(Ride.objects.filter(pk=other_ride.pk).exists())

    def test_unauthenticated_user_cannot_update_ride(self):
        """
        Kimliği doğrulanmamış bir kullanıcının yolculuk güncelleyip güncelleyemediğini test eder.
        """
        ride = Ride.objects.create(owner=self.user, **self.ride_data)
        ride_detail_url = reverse('ride-detail', kwargs={'pk': ride.pk})

        updated_data = {"title": "Anonim Güncelleme"}
        self.client.force_authenticate(user=None) # Kimlik doğrulamayı kaldır

        response = self.client.put(ride_detail_url, updated_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED) # Yetkilendirme hatası beklenir
        ride.refresh_from_db()
        self.assertNotEqual(ride.title, updated_data['title'])

    def test_unauthenticated_user_cannot_delete_ride(self):
        """
        Kimliği doğrulanmamış bir kullanıcının yolculuk silip silemediğini test eder.
        """
        ride = Ride.objects.create(owner=self.user, **self.ride_data)
        ride_detail_url = reverse('ride-detail', kwargs={'pk': ride.pk})

        self.client.force_authenticate(user=None) # Kimlik doğrulamayı kaldır

        response = self.client.delete(ride_detail_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED) # Yetkilendirme hatası beklenir
        self.assertTrue(Ride.objects.filter(pk=ride.pk).exists())