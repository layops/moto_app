# moto_app/backend/rides/permissions.py

from rest_framework import permissions

class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Sadece nesnenin sahibinin onu düzenlemesine/silmesine izin ver.
    Okuma izinleri herkese açık olsun.
    """

    def has_permission(self, request, view):
        # Listeleme ve oluşturma işlemleri için izinleri kontrol et.
        # Kimliği doğrulanmış kullanıcılar oluşturabilir.
        # Herkes listeleyebilir (okuma izni).
        if request.method in permissions.SAFE_METHODS:
            return True # GET, HEAD, OPTIONS istekleri her zaman izinlidir.
        
        # POST (Oluşturma) istekleri için kullanıcının kimliği doğrulanmış olması gerekir.
        return request.user and request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        # Okuma izinleri (GET, HEAD, OPTIONS) nesne bazında herkese verilir.
        if request.method in permissions.SAFE_METHODS:
            return True

        # Yazma izinleri (PUT, PATCH, DELETE) sadece nesnenin sahibine verilir.
        return obj.owner == request.user