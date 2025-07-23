# moto_app/backend/users/serializers.py

from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth import authenticate # Kullanıcı doğrulaması için
from rest_framework.exceptions import ValidationError # Hata fırlatmak için

User = get_user_model() # Django'nun özel User modelini alıyoruz

class UserRegisterSerializer(serializers.ModelSerializer):
    # Kullanıcı kaydı için ikinci bir şifre alanı ekliyoruz
    password2 = serializers.CharField(style={'input_type': 'password'}, write_only=True)

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password2']
        extra_kwargs = {
            'password': {'write_only': True} # Şifrenin sadece yazılabilir olmasını sağlar (API yanıtında görünmez)
        }

    def validate(self, data):
        # Şifrelerin eşleşip eşleşmediğini kontrol et
        if data['password'] != data['password2']:
            raise serializers.ValidationError({"password": "Şifre alanları eşleşmiyor."})
        return data

    def create(self, validated_data):
        # Kullanıcı oluştururken password2 alanını çıkar
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data) # create_user ile güvenli bir şekilde kullanıcı oluştur
        return user


class UserLoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(style={'input_type': 'password'}, write_only=True) # Şifrenin görünmemesi için

    def validate(self, data):
        username = data.get('username')
        password = data.get('password')

        if not username or not password:
            raise ValidationError('Kullanıcı adı ve şifre zorunludur.')

        user = authenticate(username=username, password=password)
        if not user:
            # Kullanıcı bulunamazsa veya şifre yanlışsa hata fırlat
            raise ValidationError('Sağlanan kimlik bilgileriyle giriş yapılamıyor.')

        data['user'] = user # Doğrulanmış kullanıcı nesnesini veri setine ekle
        return data