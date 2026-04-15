import 'package:flutter/foundation.dart';
class Telemetria {
  final String id;
  final int maquinaId;
  final double temperatura;
  final double humedad;
  final double vibracion;
  final double presion;
  final double voltaje;
  final double intensidad;
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
    required this.vibracion,
    required this.presion,
    required this.voltaje,
    required this.intensidad,
    required this.rfidTag,
    required this.usuarioNombre,
    required this.motorOn,
    this.alarma,
    required this.timestamp,
    this.sensores = const {},
  });

  Telemetria copyWith({
    String? id,
    int? maquinaId,
    double? temperatura,
    double? humedad,
    double? vibracion,
    double? presion,
    double? voltaje,
    double? intensidad,
    String? rfidTag,
    String? usuarioNombre,
    bool? motorOn,
    String? alarma,
    DateTime? timestamp,
    Map<String, double>? sensores,
  }) {
    return Telemetria(
      id: id ?? this.id,
      maquinaId: maquinaId ?? this.maquinaId,
      temperatura: temperatura ?? this.temperatura,
      humedad: humedad ?? this.humedad,
      vibracion: vibracion ?? this.vibracion,
      presion: presion ?? this.presion,
      voltaje: voltaje ?? this.voltaje,
      intensidad: intensidad ?? this.intensidad,
      rfidTag: rfidTag ?? this.rfidTag,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      motorOn: motorOn ?? this.motorOn,
      alarma: alarma ?? this.alarma,
      timestamp: timestamp ?? this.timestamp,
      sensores: sensores ?? this.sensores,
    );
  }

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
      vibracion: (json['vibracion'] ?? 0).toDouble(),
      presion: (json['presion'] ?? 0).toDouble(),
      voltaje: (json['voltaje'] ?? 0).toDouble(),
      intensidad: (json['intensidad'] ?? 0).toDouble(),
      rfidTag: json['rfidTag'] ?? '',
      usuarioNombre: json['usuarioNombre'],
      motorOn: json['motorOn'] ?? false,
      alarma: json['alarma'],
      timestamp: _parseDateTime(json),
      sensores: extra,
    );
  }

  static DateTime _parseDateTime(Map<String, dynamic> json) {
    try {
      if (json['timestampMillis'] != null) {
        // Puede venir como int o double según Jackson/JSON
        final int millis = (json['timestampMillis'] is num) 
            ? (json['timestampMillis'] as num).toInt() 
            : int.parse(json['timestampMillis'].toString());
        
        // Si el valor es absurdo (ej: 0 o anterior a 2024), intentamos el fallback
        if (millis > 1704067200000) { // 1 Jan 2024
          return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
        }
      }
      
      if (json['timestamp'] != null) {
        return DateTime.parse(json['timestamp'].toString()).toLocal();
      }
    } catch (e) {
      debugPrint("Error parsing timestamp: $e");
    }
    return DateTime.now(); // Último recurso: hora actual
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maquinaId': maquinaId,
      'temperatura': temperatura,
      'humedad': humedad,
      'vibracion': vibracion,
      'presion': presion,
      'voltaje': voltaje,
      'intensidad': intensidad,
      'rfidTag': rfidTag,
      'usuarioNombre': usuarioNombre,
      'motorOn': motorOn,
      'alarma': alarma,
      'timestamp': timestamp.toIso8601String(),
      'sensores': sensores,
    };
  }
}
