from django.http import JsonResponse
from django.urls import reverse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.middleware.csrf import get_token

@api_view(['GET'])
@permission_classes([AllowAny])
def api_root(request):
    """
    Motosiklet Bilgi Platformu API Root
    Tüm mevcut endpoint'leri listeler
    """
    base_url = request.build_absolute_uri('/')
    
    api_endpoints = {
        "message": "Motosiklet Bilgi Platformu API'sine hoş geldiniz!",
        "version": "v1",
        "documentation": {
            "swagger": f"{base_url}swagger/",
            "redoc": f"{base_url}redoc/"
        },
        "endpoints": {
            "users": {
                "url": f"{base_url}api/users/",
                "description": "Kullanıcı kayıt, giriş, profil yönetimi",
                "endpoints": [
                    "POST /api/users/register/ - Kullanıcı kaydı",
                    "POST /api/users/login/ - Kullanıcı girişi",
                    "POST /api/users/logout/ - Kullanıcı çıkışı",
                    "GET /api/users/{username}/profile/ - Kullanıcı profili",
                    "POST /api/users/{username}/upload-photo/ - Profil fotoğrafı yükleme",
                    "POST /api/users/{username}/upload-cover/ - Kapak fotoğrafı yükleme",
                    "POST /api/users/{username}/follow-toggle/ - Takip etme/bırakma",
                    "GET /api/users/{username}/followers/ - Takipçiler",
                    "GET /api/users/{username}/following/ - Takip edilenler",
                    "GET /api/users/{username}/posts/ - Kullanıcı gönderileri",
                    "GET /api/users/{username}/media/ - Kullanıcı medyaları",
                    "GET /api/users/{username}/events/ - Kullanıcı etkinlikleri"
                ]
            },
            "bikes": {
                "url": f"{base_url}api/bikes/",
                "description": "Motosiklet yönetimi",
                "endpoints": [
                    "GET /api/bikes/ - Motosiklet listesi",
                    "POST /api/bikes/ - Yeni motosiklet ekleme",
                    "GET /api/bikes/{id}/ - Motosiklet detayı",
                    "PUT /api/bikes/{id}/ - Motosiklet güncelleme",
                    "DELETE /api/bikes/{id}/ - Motosiklet silme"
                ]
            },
            "rides": {
                "url": f"{base_url}api/rides/",
                "description": "Yolculuk yönetimi",
                "endpoints": [
                    "GET /api/rides/ - Yolculuk listesi",
                    "POST /api/rides/ - Yeni yolculuk oluşturma",
                    "GET /api/rides/{id}/ - Yolculuk detayı",
                    "PUT /api/rides/{id}/ - Yolculuk güncelleme",
                    "DELETE /api/rides/{id}/ - Yolculuk silme"
                ]
            },
            "groups": {
                "url": f"{base_url}api/groups/",
                "description": "Grup yönetimi ve sosyal özellikler",
                "endpoints": [
                    "GET /api/groups/my_groups/ - Kullanıcının grupları",
                    "GET /api/groups/discover/ - Keşfet grupları",
                    "POST /api/groups/ - Yeni grup oluşturma",
                    "GET /api/groups/{id}/ - Grup detayı",
                    "PUT /api/groups/{id}/ - Grup güncelleme",
                    "DELETE /api/groups/{id}/ - Grup silme",
                    "GET /api/groups/{id}/members/ - Grup üyeleri",
                    "POST /api/groups/{id}/join-leave/ - Gruba katılma/ayrılma",
                    "GET /api/groups/{id}/posts/ - Grup gönderileri",
                    "POST /api/groups/{id}/posts/ - Grup gönderisi oluşturma",
                    "GET /api/groups/{id}/messages/ - Grup mesajları",
                    "POST /api/groups/{id}/messages/ - Grup mesajı gönderme"
                ]
            },
            "events": {
                "url": f"{base_url}api/events/",
                "description": "Etkinlik yönetimi",
                "endpoints": [
                    "GET /api/events/ - Etkinlik listesi",
                    "POST /api/events/ - Yeni etkinlik oluşturma",
                    "GET /api/events/{id}/ - Etkinlik detayı",
                    "PUT /api/events/{id}/ - Etkinlik güncelleme",
                    "DELETE /api/events/{id}/ - Etkinlik silme"
                ]
            },
            "posts": {
                "url": f"{base_url}api/posts/",
                "description": "Genel gönderi yönetimi",
                "endpoints": [
                    "GET /api/posts/ - Genel gönderi listesi",
                    "POST /api/posts/ - Yeni gönderi oluşturma",
                    "GET /api/posts/{id}/ - Gönderi detayı",
                    "PUT /api/posts/{id}/ - Gönderi güncelleme",
                    "DELETE /api/posts/{id}/ - Gönderi silme",
                    "GET /api/posts/groups/{group_id}/posts/ - Grup gönderileri"
                ]
            },
            "notifications": {
                "url": f"{base_url}api/notifications/",
                "description": "Bildirim yönetimi",
                "endpoints": [
                    "GET /api/notifications/ - Bildirim listesi",
                    "POST /api/notifications/mark-read/ - Bildirimleri okundu olarak işaretle",
                    "DELETE /api/notifications/{id}/ - Bildirim silme"
                ]
            },
            "gamification": {
                "url": f"{base_url}api/gamification/",
                "description": "Oyunlaştırma ve liderlik tablosu",
                "endpoints": [
                    "GET /api/gamification/leaderboard/users/ - Kullanıcı liderlik tablosu"
                ]
            }
        },
        "authentication": {
            "type": "Token Authentication",
            "header": "Authorization: Token <your_token>",
            "login_url": f"{base_url}api/users/login/",
            "register_url": f"{base_url}api/users/register/"
        },
        "features": [
            "Kullanıcı kayıt ve giriş sistemi",
            "Motosiklet profili yönetimi",
            "Yolculuk planlama ve takibi",
            "Grup oluşturma ve yönetimi",
            "Etkinlik organizasyonu",
            "Sosyal medya benzeri gönderi sistemi",
            "Gerçek zamanlı mesajlaşma",
            "Bildirim sistemi",
            "Oyunlaştırma ve puanlama",
            "Medya yükleme (Supabase entegrasyonu)"
        ],
        "contact": {
            "email": "contact@yourdomain.com",
            "documentation": f"{base_url}swagger/"
        }
    }
    
    return Response(api_endpoints)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_csrf_token(request):
    """
    CSRF token'ı almak için endpoint
    """
    csrf_token = get_token(request)
    return Response({'csrfToken': csrf_token})
