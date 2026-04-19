import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_session.dart';
import 'api_config.dart';

class Alerta {
  final int id;
  final int maquinaId;
  final String maquinaNombre;
  final String severidad;
  final String descripcion;
  final DateTime timestamp;
  final bool activa;

  Alerta({
    required this.id,
    required this.maquinaId,
    required this.maquinaNombre,
    required this.severidad,
    required this.descripcion,
    required this.timestamp,
    required this.activa,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: json['id'],
      maquinaId: json['maquinaId'],
      maquinaNombre: json['maquinaNombre'] ?? 'N/A',
      severidad: json['severidad'] ?? 'INFO',
      descripcion: json['descripcion'] ?? 'Sin descripción',
      timestamp: DateTime.parse(json['timestamp']),
      activa: json['activa'] ?? false,
    );
  }
}

class AlertaService {
  Future<List<Alerta>> fetchActivas() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/alertas/activas'),
      headers: AppSession.instance.authHeaders,
    );
    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((item) => Alerta.fromJson(item)).toList();
    }
    return [];
  }

  Future<int> fetchCount() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/alertas/activas/count'),
      headers: AppSession.instance.authHeaders,
    );
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['count'] ?? 0;
    }
    return 0;
  }

  Future<bool> forzarAlarma({
    required int maquinaId,
    required String maquinaNombre,
    String severidad = 'CRITICAL',
    String descripcion = 'Alarma forzada manualmente [DEMO]',
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/alertas/forzar'),
      headers: {...AppSession.instance.authHeaders, 'Content-Type': 'application/json'},
      body: json.encode({
        'maquinaId': maquinaId,
        'maquinaNombre': maquinaNombre,
        'severidad': severidad,
        'descripcion': descripcion,
      }),
    );
    return response.statusCode == 200;
  }
}
