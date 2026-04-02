import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const String hotspotIp = "192.168.137.1";
    if (kIsWeb) return "http://$hotspotIp:8080"; 
    return (defaultTargetPlatform == TargetPlatform.windows) 
        ? "http://localhost:8080" 
        : "http://$hotspotIp:8080";
  }
}
