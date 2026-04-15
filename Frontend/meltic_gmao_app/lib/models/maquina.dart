import 'metric_config.dart';

class Maquina {
  final int? id;
  final String nombre;
  final String ubicacion;
  final String estado;
  final String? modelo;
  final String? descripcion;
  final List<MetricConfig> configs;
  final String? plcUrl;
  final bool simulado;

  Maquina({
    this.id,
    required this.nombre,
    required this.modelo,
    required this.ubicacion,
    this.descripcion,
    required this.estado,
    this.configs = const [],
    this.plcUrl,
    this.simulado = false,
  });

  factory Maquina.fromJson(Map<String, dynamic> json) {
    return Maquina(
      id: json['id'] is int ? json['id'] : null,
      nombre: json['nombre'] ?? '',
      ubicacion: json['ubicacion'] ?? '',
      estado: json['estado'] ?? 'OK',
      modelo: json['modelo'],
      descripcion: json['descripcion'],
      plcUrl: json['plcUrl'],
      simulado: json['simulado'] ?? false,
      configs: (json['configs'] as List?)
              ?.map((c) => MetricConfig.fromJson(c))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'ubicacion': ubicacion,
      'estado': estado,
      'modelo': modelo,
      'descripcion': descripcion,
      'plcUrl': plcUrl,
      'simulado': simulado,
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
    String? plcUrl,
    bool? simulado,
  }) {
    return Maquina(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      ubicacion: ubicacion ?? this.ubicacion,
      estado: estado ?? this.estado,
      modelo: modelo ?? this.modelo,
      descripcion: descripcion ?? this.descripcion,
      configs: configs ?? this.configs,
      plcUrl: plcUrl ?? this.plcUrl,
      simulado: simulado ?? this.simulado,
    );
  }
}
