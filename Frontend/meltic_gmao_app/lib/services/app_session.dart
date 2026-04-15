import 'package:shared_preferences/shared_preferences.dart';

/// Singleton que guarda la sesión del usuario logueado.
/// Se rellena al hacer login y se borra al cerrar sesión.
/// La sesión se persiste en SharedPreferences para sobrevivir recargas (Flutter Web).
class AppSession {
  AppSession._internal();
  static final AppSession _instance = AppSession._internal();
  static AppSession get instance => _instance;

  int? userId;
  String? userEmail;
  String? userNombre;
  String? userApellido1;
  String? userRol; // ADMIN | JEFE_MANTENIMIENTO | TECNICO
  String? authToken;

  bool get isJefe {
    final r = userRol?.toUpperCase().trim() ?? '';
    return r == 'ADMIN' ||
           r == 'JEFE_MANTENIMIENTO' ||
           r == 'JEFE DE MANTENIMIENTO';
  }

  bool get isTecnico {
    final r = userRol?.toUpperCase().trim() ?? '';
    return r == 'TECNICO' || r == 'TÉCNICO';
  }

  bool get canManageAssets {
    final r = userRol?.toUpperCase().trim() ?? '';
    return r == 'ADMIN' || r == 'SUPERADMIN';
  }

  /// Rellena la sesión desde el objeto devuelto por /api/auth/login
  void fromJson(Map<String, dynamic> responseData) {
    if (responseData.containsKey('user')) {
      final user = responseData['user'];
      userId = user['id'];
      userEmail = user['email'];
      userNombre = user['nombre'];
      userApellido1 = user['apellido1'];
      userRol = user['rol'];
    }
    if (responseData.containsKey('token')) {
      authToken = responseData['token'];
    }
    _persist();
  }

  /// Persiste la sesión en SharedPreferences
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('session_userId', userId ?? -1);
    await prefs.setString('session_email', userEmail ?? '');
    await prefs.setString('session_nombre', userNombre ?? '');
    await prefs.setString('session_apellido1', userApellido1 ?? '');
    await prefs.setString('session_rol', userRol ?? '');
    await prefs.setString('session_token', authToken ?? '');
  }

  /// Intenta restaurar la sesión desde SharedPreferences al arrancar la app
  Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('session_token') ?? '';
    if (token.isEmpty) return false;
    authToken = token;
    final id = prefs.getInt('session_userId') ?? -1;
    userId = id < 0 ? null : id;
    userEmail = prefs.getString('session_email')?.nullIfEmpty;
    userNombre = prefs.getString('session_nombre')?.nullIfEmpty;
    userApellido1 = prefs.getString('session_apellido1')?.nullIfEmpty;
    userRol = prefs.getString('session_rol')?.nullIfEmpty;
    return authToken != null && authToken!.isNotEmpty;
  }

  Map<String, String> get authHeaders {
    final headers = {"Content-Type": "application/json"};
    if (authToken != null) {
      headers["Authorization"] = "Bearer $authToken";
    }
    return headers;
  }

  Future<void> clear() async {
    userId = null;
    userEmail = null;
    userNombre = null;
    userApellido1 = null;
    userRol = null;
    authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_userId');
    await prefs.remove('session_email');
    await prefs.remove('session_nombre');
    await prefs.remove('session_apellido1');
    await prefs.remove('session_rol');
    await prefs.remove('session_token');
  }

  String get displayName => (userNombre != null && userApellido1 != null)
      ? '$userNombre $userApellido1'
      : userEmail ?? 'Usuario';
}

extension _NullIfEmpty on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
