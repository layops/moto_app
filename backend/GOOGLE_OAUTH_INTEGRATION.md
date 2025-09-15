# Google OAuth Entegrasyonu

## Supabase Ayarları

1. **Supabase Dashboard'da Google Provider'ı aktif edin:**
   - Authentication > Providers > Google
   - "Enable Sign in with Google" toggle'ını açın
   - Google Cloud Console'dan Client ID ve Client Secret'i alın
   - Callback URL: `https://mosiqkyyribzlvdvedet.supabase.co/auth/v1/callback`

2. **Google Cloud Console Ayarları:**
   - OAuth 2.0 Client ID oluşturun
   - Authorized redirect URIs'ye Supabase callback URL'ini ekleyin
   - Client ID ve Secret'i Supabase'e girin

## Backend API Endpoints

### 1. Google OAuth URL Alma
```http
GET /api/users/auth/google/
```

**Response:**
```json
{
    "auth_url": "https://mosiqkyyribzlvdvedet.supabase.co/auth/v1/authorize?provider=google&redirect_to=...",
    "message": "Google OAuth URL oluşturuldu"
}
```

### 2. OAuth Callback İşleme
```http
GET /api/users/auth/callback/?code=AUTH_CODE&state=STATE
```

**Response:**
```json
{
    "message": "Google ile giriş başarılı!",
    "user": {
        "id": 1,
        "username": "john_doe",
        "email": "john@gmail.com",
        "email_verified": true,
        "first_name": "John",
        "last_name": "Doe"
    },
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 3. Token Doğrulama
```http
POST /api/users/verify-token/
Content-Type: application/json

{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
    "user": {
        "id": 1,
        "username": "john_doe",
        "email": "john@gmail.com",
        "email_verified": true
    },
    "message": "Token doğrulandı"
}
```

## Frontend Entegrasyonu (Flutter)

### 1. Google OAuth URL'i Al
```dart
Future<String?> getGoogleAuthUrl() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/auth/google/'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['auth_url'];
    }
  } catch (e) {
    print('Google OAuth URL hatası: $e');
  }
  return null;
}
```

### 2. WebView ile Google OAuth
```dart
import 'package:webview_flutter/webview_flutter.dart';

class GoogleAuthWebView extends StatefulWidget {
  @override
  _GoogleAuthWebViewState createState() => _GoogleAuthWebViewState();
}

class _GoogleAuthWebViewState extends State<GoogleAuthWebView> {
  late WebViewController _controller;
  String? authUrl;

  @override
  void initState() {
    super.initState();
    _getAuthUrl();
  }

  Future<void> _getAuthUrl() async {
    final url = await getGoogleAuthUrl();
    if (url != null) {
      setState(() {
        authUrl = url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (authUrl == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Google ile Giriş')),
      body: WebView(
        initialUrl: authUrl,
        onWebViewCreated: (WebViewController controller) {
          _controller = controller;
        },
        navigationDelegate: (NavigationRequest request) {
          // Callback URL'yi yakala
          if (request.url.contains('/api/users/auth/callback/')) {
            _handleCallback(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }

  void _handleCallback(String url) async {
    final uri = Uri.parse(url);
    final code = uri.queryParameters['code'];
    
    if (code != null) {
      // Backend'e callback gönder
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/auth/callback/?code=$code'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Kullanıcı bilgilerini kaydet
        await _saveUserData(data);
        Navigator.pop(context, data['user']);
      }
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> data) async {
    // SharedPreferences veya local storage'a kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token']);
    await prefs.setString('user_data', json.encode(data['user']));
  }
}
```

### 3. Kullanım
```dart
// Google ile giriş butonu
ElevatedButton(
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GoogleAuthWebView()),
    );
    
    if (result != null) {
      // Giriş başarılı, ana sayfaya yönlendir
      Navigator.pushReplacementNamed(context, '/home');
    }
  },
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset('assets/images/google_logo.png', height: 20),
      SizedBox(width: 8),
      Text('Google ile Giriş'),
    ],
  ),
)
```

## Güvenlik Notları

1. **HTTPS Kullanın:** OAuth callback'leri sadece HTTPS üzerinden çalışır
2. **State Parameter:** CSRF saldırılarını önlemek için state parameter kullanın
3. **Token Saklama:** Access token'ları güvenli şekilde saklayın
4. **Token Yenileme:** Refresh token ile access token'ları yenileyin

## Test Etme

1. Supabase'de Google provider'ı aktif edin
2. Google Cloud Console'da OAuth client oluşturun
3. Backend'i çalıştırın
4. Frontend'de Google ile giriş butonunu test edin
5. Callback URL'nin doğru çalıştığını kontrol edin
