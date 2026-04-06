import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const String hotspotIp = "192.168.137.1";
    
    // Si estamos en la WEB
    if (kIsWeb) {
      // Intentamos detectar la IP desde la que se carga la página
      // Si estamos en local, Uri.base.host será 'localhost'
      final String host = Uri.base.host.isEmpty ? "localhost" : Uri.base.host;
      return "http://$host:8080";
    }
    
    // Si estamos en WINDOWS (Nativo)
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return "http://localhost:8080";
    }

    // Para ANDROID (Nativo), usamos la IP fija del Hotspot industrial
    return "http://$hotspotIp:8080";
  }
}
