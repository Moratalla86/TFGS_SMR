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

  /// Rellena la sesión desde el JSON devuelto por /api/auth/login
  void fromJson(Map<String, dynamic> json) {
    userId = json['id'];
    userEmail = json['email'];
    userNombre = json['nombre'];
    userApellido1 = json['apellido1'];
    userRol = json['rol'];
  }

  void clear() {
    userId = null;
    userEmail = null;
    userNombre = null;
    userApellido1 = null;
    userRol = null;
  }

  String get displayName => (userNombre != null && userApellido1 != null)
      ? '$userNombre $userApellido1'
      : userEmail ?? 'Usuario';
}
