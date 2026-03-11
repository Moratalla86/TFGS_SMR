class Telemetria {
  final String id;
  final int maquinaId;
  final double temperatura;
  final double humedad;
  final String timestamp;

  Telemetria({
    required this.id,
    required this.maquinaId,
    required this.temperatura,
    required this.humedad,
    required this.timestamp,
  });

  factory Telemetria.fromJson(Map<String, dynamic> json) {
    return Telemetria(
      id: json['id'] ?? '',
      maquinaId: json['maquinaId'] ?? 0,
      temperatura: (json['temperatura'] ?? 0).toDouble(),
      humedad: (json['humedad'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? '',
    );
  }
}
