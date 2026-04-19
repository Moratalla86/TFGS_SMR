import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'app_session.dart';
import '../models/telemetria.dart';

class PLCService {
  static Future<bool> enviarComando(String accion, {String? tipo}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/plc/comando'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accion': accion,
          if (tipo != null) 'tipo': tipo,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('PLCService.enviarComando error: $e');
      return false;
    }
  }

  /// Devuelve el último registro de telemetría para una máquina.
  /// GET /api/plc/maquina/{maquinaId} — toma el último elemento de la lista.
  /// Devuelve null si la respuesta está vacía o hay error (sin lanzar excepción).
  /// Machine ID=1 es el Controllino/IoT — asunción TFG-específica.
  static Future<Telemetria?> fetchLastTelemetry(int maquinaId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/plc/maquina/$maquinaId'),
        headers: AppSession.instance.authHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        if (body.isEmpty) return null;
        return Telemetria.fromJson(body.last as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('PLCService.fetchLastTelemetry error: $e');
      return null;
    }
  }
}
