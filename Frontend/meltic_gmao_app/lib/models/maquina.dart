import 'metric_config.dart';

class Maquina {
  final int id;
  final String nombre;
  final String ubicacion;
  final String estado;
  final String? modelo;
  final String? descripcion;
  final List<MetricConfig> configs;

  Maquina({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.estado,
    this.modelo,
    this.descripcion,
    required this.configs,
  });

  factory Maquina.fromJson(Map<String, dynamic> json) {
    return Maquina(
      id: json['id'],
      nombre: json['nombre'],
      ubicacion: json['ubicacion'],
      estado: json['estado'],
      modelo: json['modelo'],
      descripcion: json['descripcion'],
      configs: (json['configs'] as List?)
              ?.map((c) => MetricConfig.fromJson(c))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'ubicacion': ubicacion,
      'estado': estado,
      'modelo': modelo,
      'descripcion': descripcion,
      'configs': configs.map((c) => c.toJson()).toList(),
    };
  }

  Maquina copyWith({
    int? id,
    String? nombre,
    String? ubicacion,
    String? estado,
    String? modelo,
    String? descripcion,
    List<MetricConfig>? configs,
  }) {
    return Maquina(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      ubicacion: ubicacion ?? this.ubicacion,
      estado: estado ?? this.estado,
      modelo: modelo ?? this.modelo,
      descripcion: descripcion ?? this.descripcion,
      configs: configs ?? this.configs,
    );
  }
}
