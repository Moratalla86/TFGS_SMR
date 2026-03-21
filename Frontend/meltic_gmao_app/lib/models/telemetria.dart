class Telemetria {
  final String id;
  final int maquinaId;
  final double temperatura;
  final double humedad;
  final String rfidTag;
  final String usuarioNombre;
  final String timestamp;

  Telemetria({
    required this.id,
    required this.maquinaId,
    required this.temperatura,
    required this.humedad,
    required this.rfidTag,
    required this.usuarioNombre,
    required this.timestamp,
  });

  factory Telemetria.fromJson(Map<String, dynamic> json) {
    return Telemetria(
      id: json['id'] ?? '',
      maquinaId: json['maquinaId'] ?? 0,
      temperatura: (json['temperatura'] ?? 0).toDouble(),
      humedad: (json['humedad'] ?? 0).toDouble(),
      rfidTag: json['rfidTag'] ?? '',
      usuarioNombre: json['usuarioNombre'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

