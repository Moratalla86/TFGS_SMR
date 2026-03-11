import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/telemetria.dart';

class TelemetriaService {
  Future<List<Telemetria>> fetchPorMaquina(int maquinaId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/plc/maquina/$maquinaId'),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((item) => Telemetria.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar telemetría: ${response.statusCode}');
    }
  }
}
