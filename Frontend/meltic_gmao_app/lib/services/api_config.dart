import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _defaultHotspotIp = "192.168.137.1";
  static const String _prefsKey = "custom_backend_ip";

  /// IP configurada por el usuario (null = usar default)
  static String? _customIp;

  /// Carga la IP guardada desde SharedPreferences (llamar en main antes de runApp)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customIp = prefs.getString(_prefsKey);
  }

  /// Guarda una IP personalizada para Android
  static Future<void> setCustomIp(String ip) async {
    _customIp = ip.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _customIp!);
  }

  static String get baseUrl {
    // Flutter Web: detectar host desde la URL del navegador
    if (kIsWeb) {
      final String host = Uri.base.host.isEmpty ? "localhost" : Uri.base.host;
      return "http://$host:8080";
    }

    // Windows nativo
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return "http://localhost:8080";
    }

    // Android: usar IP configurada por el usuario, o el default del hotspot
    final String ip = _customIp?.isNotEmpty == true ? _customIp! : _defaultHotspotIp;
    return "http://$ip:8080";
  }
}
