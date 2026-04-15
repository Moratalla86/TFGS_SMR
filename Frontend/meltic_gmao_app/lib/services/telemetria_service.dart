import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'app_session.dart';
import '../models/telemetria.dart';

class TelemetriaService {
  /// Carga inicial: devuelve los últimos 3600 registros (buffer preload).
  /// Equivalente al historico inicial que un SCADA carga al abrir una pantalla.
  Future<List<Telemetria>> fetchPorMaquina(int maquinaId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/plc/maquina/$maquinaId'),
      headers: AppSession.instance.authHeaders,
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((item) => Telemetria.fromJson(item)).toList();
    }
    throw Exception('Error carga inicial: ${response.statusCode}');
  }

  /// Polling incremental SCADA: devuelve SOLO los registros más nuevos que [since].
  /// En un historian real esto equivale al "subscription update" o "report-by-exception".
  /// El servidor filtra en BD — el cliente recibe 0–N puntos, nunca miles.
  Future<List<Telemetria>> fetchDesde(int maquinaId, DateTime since) async {
    final epochMs = since.toUtc().millisecondsSinceEpoch;
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/plc/maquina/$maquinaId?since=$epochMs'),
      headers: AppSession.instance.authHeaders,
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((item) => Telemetria.fromJson(item)).toList();
    }
    throw Exception('Error polling incremental: ${response.statusCode}');
  }

  /// Consulta histórica multi-escala: cualquier rango temporal → ≤ 2000 puntos.
  /// El servidor aplica downsampling estadístico (MongoDB \$sample).
  /// Usar cuando la ventana supera 1 día (semanas, meses, años).
  Future<List<Telemetria>> fetchHistorico(int maquinaId, DateTime desde, DateTime hasta) async {
    final desdeMs = desde.toUtc().millisecondsSinceEpoch;
    final hastaMs = hasta.toUtc().millisecondsSinceEpoch;
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/plc/maquina/$maquinaId/historico?desde=$desdeMs&hasta=$hastaMs'),
      headers: AppSession.instance.authHeaders,
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((item) => Telemetria.fromJson(item)).toList();
    }
    throw Exception('Error histórico: ${response.statusCode}');
  }
}
