import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'api_config.dart';
import '../models/telemetria.dart';

class TelemetriaService {
  Duration _serverOffset = Duration.zero;

  Future<List<Telemetria>> fetchPorMaquina(int maquinaId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/plc/maquina/$maquinaId'),
    );

    if (response.statusCode == 200) {
      // Sincronización de reloj con el servidor
      final serverDateStr = response.headers['date'];
      if (serverDateStr != null) {
        try {
          final serverDate = HttpDate.parse(serverDateStr);
          _serverOffset = DateTime.now().difference(serverDate);
        } catch (_) {}
      }

      List<dynamic> body = json.decode(response.body);
      return body.map((item) {
        final t = Telemetria.fromJson(item);
        // Ajustamos la telemetría con el offset calculado para coherencia total
        return _applyOffset(t);
      }).toList();
    } else {
      throw Exception('Error al cargar telemetría: ${response.statusCode}');
    }
  }

  Telemetria _applyOffset(Telemetria t) {
    return t.copyWith(
      timestamp: t.timestamp.add(_serverOffset),
    );
  }
}
