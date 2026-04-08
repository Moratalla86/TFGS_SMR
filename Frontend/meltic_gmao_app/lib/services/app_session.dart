import 'dart:convert';

/// Singleton que guarda la sesión del usuario logueado en memoria.
/// Se rellena al hacer login y se borra al cerrar sesión.
class AppSession {
  AppSession._internal();
  static final AppSession _instance = AppSession._internal();
  static AppSession get instance => _instance;

  int? userId;
  String? userEmail;
  String? userNombre;
  String? userApellido1;
  String? userRol; // ADMIN | JEFE_MANTENIMIENTO | TECNICO
  String? authToken; // UUID token for Authorization header

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

  /// Indica si el usuario actual tiene permisos para Crear, Editar o Eliminar activos PLC.
  /// Según requerimiento, solo el Súper Admin (ADMIN) puede hacerlo.
  bool get canManageAssets {
    final r = userRol?.toUpperCase().trim() ?? '';
    return r == 'ADMIN' || r == 'SUPERADMIN';
  }

  /// Rellena la sesión desde el objeto devuelto por /api/auth/login
  /// La estructura es: { "user": { ... }, "token": "..." }
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
  }

  /// Devuelve los headers necesarios para peticiones autenticadas
  Map<String, String> get authHeaders {
    final headers = {"Content-Type": "application/json"};
    if (authToken != null) {
      headers["Authorization"] = "Bearer $authToken";
    }
    return headers;
  }

  void clear() {
    userId = null;
    userEmail = null;
    userNombre = null;
    userApellido1 = null;
    userRol = null;
    authToken = null;
  }

  String get displayName => (userNombre != null && userApellido1 != null)
      ? '$userNombre $userApellido1'
      : userEmail ?? 'Usuario';
}
