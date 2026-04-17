import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'app_session.dart';

class StatsService {
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/stats/dashboard'),
      headers: AppSession.instance.authHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar estadísticas: ${response.statusCode}');
    }
  }
}
