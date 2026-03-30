import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class PLCService {
  static Future<bool> enviarComando(String accion, {String? tipo}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/plc/comando'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accion': accion, if (tipo != null) 'tipo': tipo}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error enviando comando PLC: $e');
      return false;
    }
  }
}
