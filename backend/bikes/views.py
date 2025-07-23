from rest_framework import viewsets, permissions # DRF'in viewsets ve permissions modüllerini içe aktarır
from .models import Bike # Kendi Bike modelimizi içe aktarırız
from .serializers import BikeSerializer # Oluşturduğumuz BikeSerializer'ı içe aktarırız

# *** ÖNEMLİ: IsOwnerOrAdmin Sınıfını da Buraya Ekle ***
# Bu izin sınıfı, bir objenin (motosikletin) sahibi veya süper kullanıcı (admin) ise izin verir.
class IsOwnerOrAdmin(permissions.BasePermission):
    """
    Custom permission to only allow owners of an object or an admin to edit/delete it.
    """
    # Obje bazında izin kontrolü yapar (yani belirli bir motosiklet üzerinde)
    def has_object_permission(self, request, view, obj):
        # GET, HEAD veya OPTIONS gibi güvenli (veri değiştirmeyen) istekler her zaman izinlidir.
        if request.method in permissions.SAFE_METHODS:
            return True

        # Yazma (POST, PUT, DELETE) izinleri sadece objenin sahibine veya adminlere verilir.
        # obj.owner: Motosikletin sahibi (Bike modelindeki owner alanı)
        # request.user: İsteği yapan kullanıcı
        # request.user.is_superuser: İsteği yapan kullanıcının admin olup olmadığı
        return obj.owner == request.user or request.user.is_superuser


class BikeViewSet(viewsets.ModelViewSet): # ModelViewSet, CRUD işlemleri için hazır metotlar sunar
    queryset = Bike.objects.all().order_by('-created_at') # API'nin hangi veriyi sunacağını ve sıralamasını belirler
    serializer_class = BikeSerializer # Hangi serileştiricinin kullanılacağını belirtir

    # Bu metot, her bir API eylemi (GET, POST, PUT vb.) için hangi izinlerin geçerli olacağını belirler
    def get_permissions(self):
        if self.action in ['list', 'retrieve']: # Motosikletleri listeleme veya tek bir tanesini görme
            permission_classes = [permissions.AllowAny] # Herkese izin ver (giriş yapmamış kullanıcılar da görebilir)
        elif self.action in ['create']: # Yeni motosiklet oluşturma
            permission_classes = [permissions.IsAuthenticated] # Sadece giriş yapmış kullanıcılara izin ver
        elif self.action in ['update', 'partial_update', 'destroy']: # Motosikleti güncelleme veya silme
            # Sadece giriş yapmış VE motosikletin sahibi veya admin olan kullanıcılara izin ver
            permission_classes = [permissions.IsAuthenticated, IsOwnerOrAdmin]
        else:
            permission_classes = [permissions.IsAdminUser] # Diğer (nadiren kullanılan) eylemler sadece adminlere

        return [permission() for permission in permission_classes] # İzin sınıflarını döndürür

    # Bu metot, yeni bir motosiklet oluşturulurken otomatik olarak çağrılır
    def perform_create(self, serializer):
        """
        Yeni bir motosiklet oluşturulduğunda, owner alanını otomatik olarak isteği yapan kullanıcıya atar.
        """
        # Eğer isteği yapan kullanıcı giriş yapmışsa (kimliği doğrulanmışsa)
        if self.request.user.is_authenticated:
            serializer.save(owner=self.request.user) # Serileştiriciyi kaydederken owner'ı set et
        else:
            # Normalde buraya gelinmemesi lazım çünkü 'create' eylemi için IsAuthenticated izni var.
            # Ama bir şekilde gelinirse, sahibi olmayan bir motosiklet kaydına izin verir (modelde null=True olduğu için)
            serializer.save()