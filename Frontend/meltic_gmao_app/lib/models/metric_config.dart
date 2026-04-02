class MetricConfig {
  final int? id;
  final String nombreMetrica;
  String unidadSeleccionada;
  double? limiteMB;
  double? limiteB;
  double? limiteA;
  double? limiteMA;
  bool habilitado;

  MetricConfig({
    this.id,
    required this.nombreMetrica,
    required this.unidadSeleccionada,
    this.limiteMB,
    this.limiteB,
    this.limiteA,
    this.limiteMA,
    this.habilitado = true,
  });

  factory MetricConfig.fromJson(Map<String, dynamic> json) {
    return MetricConfig(
      id: json['id'],
      nombreMetrica: json['nombreMetrica'],
      unidadSeleccionada: json['unidadSeleccionada'] ?? '',
      limiteMB: json['limiteMB']?.toDouble(),
      limiteB: json['limiteB']?.toDouble(),
      limiteA: json['limiteA']?.toDouble(),
      limiteMA: json['limiteMA']?.toDouble(),
      habilitado: json['habilitado'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreMetrica': nombreMetrica,
      'unidadSeleccionada': unidadSeleccionada,
      'limiteMB': limiteMB,
      'limiteB': limiteB,
      'limiteA': limiteA,
      'limiteMA': limiteMA,
      'habilitado': habilitado,
    };
  }

  MetricConfig copyWith({
    double? limiteMB,
    double? limiteB,
    double? limiteA,
    double? limiteMA,
    String? unidadSeleccionada,
    bool? habilitado,
  }) {
    return MetricConfig(
      id: id,
      nombreMetrica: nombreMetrica,
      unidadSeleccionada: unidadSeleccionada ?? this.unidadSeleccionada,
      limiteMB: limiteMB ?? this.limiteMB,
      limiteB: limiteB ?? this.limiteB,
      limiteA: limiteA ?? this.limiteA,
      limiteMA: limiteMA ?? this.limiteMA,
      habilitado: habilitado ?? this.habilitado,
    );
  }
}
