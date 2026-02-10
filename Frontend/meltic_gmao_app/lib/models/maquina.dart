class Maquina {
  final int id;
  final String nombre;
  final String modelo;
  final String estado;

  Maquina({
    required this.id,
    required this.nombre,
    required this.modelo,
    required this.estado,
  });

  factory Maquina.fromJson(Map<String, dynamic> json) {
    return Maquina(
      id: json['id'],
      nombre: json['nombre'],
      modelo: json['modelo'] ?? 'N/A',
      estado: json['estado'] ?? 'Desconocido',
    );
  }
}
