class Telemetria {
  final String id;
  final int maquinaId;
  final double temperatura;
  final double humedad;
  final String rfidTag;
  final String? usuarioNombre;
  final bool motorOn;
  final String? alarma;
  final DateTime timestamp;

  // Mapa flexible para métricas industriales adicionales
  final Map<String, double> sensores;

  Telemetria({
    required this.id,
    required this.maquinaId,
    required this.temperatura,
    required this.humedad,
    required this.rfidTag,
    required this.usuarioNombre,
    required this.motorOn,
    this.alarma,
    required this.timestamp,
    this.sensores = const {},
  });

  factory Telemetria.fromJson(Map<String, dynamic> json) {
    // Extraer sensores dinámicos si existen en el JSON
    final Map<String, double> extra = {};
    if (json['sensores'] != null) {
      (json['sensores'] as Map<String, dynamic>).forEach((k, v) {
        extra[k] = (v as num).toDouble();
      });
    }

    return Telemetria(
      id: json['id'] ?? '',
      maquinaId: json['maquinaId'] ?? 0,
      temperatura: (json['temperatura'] ?? 0).toDouble(),
      humedad: (json['humedad'] ?? 0).toDouble(),
      rfidTag: json['rfidTag'] ?? '',
      usuarioNombre: json['usuarioNombre'],
      motorOn: json['motorOn'] ?? false,
      alarma: json['alarma'],
      timestamp: DateTime.parse(json['timestamp']).toLocal(),
      sensores: extra,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maquinaId': maquinaId,
      'temperatura': temperatura,
      'humedad': humedad,
      'rfidTag': rfidTag,
      'usuarioNombre': usuarioNombre,
      'motorOn': motorOn,
      'alarma': alarma,
      'timestamp': timestamp.toIso8601String(),
      'sensores': sensores,
    };
  }
}
