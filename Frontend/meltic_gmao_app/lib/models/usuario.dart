class Usuario {
  final int? id;
  final String nombre;
  final String apellido1;
  final String? apellido2;
  final String? telefonoPersonal;
  final String? telefonoProfesional;
  final String? emailPersonal;
  final String? email; // corporativo (generado automáticamente)
  final String? username;
  final String? password;
  final String rol;
  final bool activo;
  final String? rfidTag;

  Usuario({
    this.id,
    required this.nombre,
    required this.apellido1,
    this.apellido2,
    this.telefonoPersonal,
    this.telefonoProfesional,
    this.emailPersonal,
    this.email,
    this.username,
    this.password,
    required this.rol,
    this.activo = true,
    this.rfidTag,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      apellido1: json['apellido1'] ?? '',
      apellido2: json['apellido2'],
      telefonoPersonal: json['telefonoPersonal'],
      telefonoProfesional: json['telefonoProfesional'],
      emailPersonal: json['emailPersonal'],
      email: json['email'],
      username: json['username'],
      rol: json['rol'] ?? 'TECNICO',
      activo: json['activo'] ?? true,
      rfidTag: json['rfidTag'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'apellido1': apellido1,
      if (apellido2 != null) 'apellido2': apellido2,
      if (telefonoPersonal != null) 'telefonoPersonal': telefonoPersonal,
      if (telefonoProfesional != null)
        'telefonoProfesional': telefonoProfesional,
      if (emailPersonal != null) 'emailPersonal': emailPersonal,
      if (password != null) 'password': password,
      'rol': rol,
      'activo': activo,
      if (rfidTag != null) 'rfidTag': rfidTag,
    };
  }

  /// Preview del email corporativo calculado en cliente (el real lo genera el backend)
  String get emailCorporativoPreview {
    if (nombre.isEmpty || apellido1.isEmpty) return '';
    return '${nombre[0].toLowerCase()}${apellido1.toLowerCase()}@meltic.com';
  }

  String get nombreCompleto =>
      '$nombre $apellido1${apellido2 != null ? ' $apellido2' : ''}';
}
