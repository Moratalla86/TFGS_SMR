import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/usuario.dart';

class UsuarioService {
  final String _base = '${ApiConfig.baseUrl}/api/usuarios';

  Future<List<Usuario>> fetchUsuarios() async {
    final res = await http.get(Uri.parse(_base));
    if (res.statusCode == 200) {
      final List<dynamic> body = json.decode(res.body);
      return body.map((e) => Usuario.fromJson(e)).toList();
    }
    throw Exception('Error al cargar usuarios: ${res.statusCode}');
  }

  Future<Usuario> crearUsuario(Usuario u) async {
    final res = await http.post(
      Uri.parse(_base),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(u.toJson()),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Usuario.fromJson(json.decode(res.body));
    }
    throw Exception('Error al crear usuario: ${res.statusCode}');
  }

  Future<Usuario> actualizarUsuario(int id, Usuario u) async {
    final res = await http.put(
      Uri.parse('$_base/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(u.toJson()),
    );
    if (res.statusCode == 200) {
      return Usuario.fromJson(json.decode(res.body));
    }
    throw Exception('Error al actualizar usuario: ${res.statusCode}');
  }

  Future<void> eliminarUsuario(int id) async {
    final res = await http.delete(Uri.parse('$_base/$id'));
    if (res.statusCode != 204) {
      throw Exception('Error al eliminar usuario: ${res.statusCode}');
    }
  }
}
