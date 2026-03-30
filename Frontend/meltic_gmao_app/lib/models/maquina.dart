class Maquina {
  final int id;
  final String nombre;
  final String ubicacion;
  final String estado;
  final double? limiteMB;
  final double? limiteB;
  final double? limiteA;
  final double? limiteMA;

  // Lista de métricas industriales configuradas para esta máquina
  final List<String> sensoresConfigurados;

  Maquina({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.estado,
    this.limiteMB,
    this.limiteB,
    this.limiteA,
    this.limiteMA,
    this.sensoresConfigurados = const ['temperatura', 'humedad'],
  });

  factory Maquina.fromJson(Map<String, dynamic> json) {
    return Maquina(
      id: json['id'],
      nombre: json['nombre'],
      ubicacion: json['ubicacion'],
      estado: json['estado'],
      limiteMB: json['limiteMB']?.toDouble(),
      limiteB: json['limiteB']?.toDouble(),
      limiteA: json['limiteA']?.toDouble(),
      limiteMA: json['limiteMA']?.toDouble(),
      sensoresConfigurados: json['sensoresConfigurados'] != null
          ? List<String>.from(json['sensoresConfigurados'])
          : ['temperatura', 'humedad'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'ubicacion': ubicacion,
      'estado': estado,
      'limiteMB': limiteMB,
      'limiteB': limiteB,
      'limiteA': limiteA,
      'limiteMA': limiteMA,
      'sensoresConfigurados': sensoresConfigurados,
    };
  }
}
