import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/maquina.dart'; // Importamos el modelo nuevo

class MaquinaService {
  // Ahora devuelve una lista de objetos Maquina, no dynamic
  Future<List<Maquina>> fetchMaquinas() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/maquinas'), // Usamos el getter dinámico
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      // Mapeamos cada elemento del JSON al constructor Maquina.fromJson
      return body.map((item) => Maquina.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar máquinas: ${response.statusCode}');
    }
  }
}
