import 'package:flutter/foundation.dart'; // Para usar kIsWeb

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Para Flutter Web
      return "http://localhost:8080";
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Para el Emulador de Android
      return "http://10.0.2.2:8080";
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      // Para la aplicación de Windows Escritorio
      return "http://localhost:8080";
    } else {
      // móvil real por WiFi
      return "http://192.168.1.69:8080";
    }
  }
}
