import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'app_session.dart';
import '../models/orden_trabajo.dart';

class OrdenTrabajoService {
  final String _base = '${ApiConfig.baseUrl}/api/ordenes';

  Future<List<OrdenTrabajo>> fetchOrdenes() async {
    final res = await http.get(
      Uri.parse(_base),
      headers: AppSession.instance.authHeaders,
    );
    if (res.statusCode == 200) {
      final List<dynamic> body = json.decode(res.body);
      return body.map((e) => OrdenTrabajo.fromJson(e)).toList();
    }
    throw Exception('Error al cargar órdenes: ${res.statusCode}');
  }

  Future<List<OrdenTrabajo>> fetchOrdenesPorTecnico(int tecnicoId) async {
    final res = await http.get(
      Uri.parse('$_base/tecnico/$tecnicoId'),
      headers: AppSession.instance.authHeaders,
    );
    if (res.statusCode == 200) {
      final List<dynamic> body = json.decode(res.body);
      return body.map((e) => OrdenTrabajo.fromJson(e)).toList();
    }
    throw Exception('Error al cargar OTs del técnico: ${res.statusCode}');
  }

  Future<OrdenTrabajo> crearOrden(
    OrdenTrabajo ot, {
    int? tecnicoId,
    int? maquinaId,
  }) async {
    final body = {
      'descripcion': ot.descripcion,
      'prioridad': ot.prioridad,
      'estado': ot.estado,
      'tipo': ot.tipo,
      if (ot.fotoBase64 != null) 'fotoBase64': ot.fotoBase64,
      if (ot.solicitanteId != null) 'solicitante': {'id': ot.solicitanteId},
      if (tecnicoId != null) 'tecnico': {'id': tecnicoId},
      if (maquinaId != null) 'maquina': {'id': maquinaId},
    };
    final res = await http.post(
      Uri.parse(_base),
      headers: AppSession.instance.authHeaders,
      body: json.encode(body),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return OrdenTrabajo.fromJson(json.decode(res.body));
    }
    throw Exception('Error al crear OT: ${res.statusCode}');
  }

  Future<OrdenTrabajo> asignar(int id, {int? tecnicoId, int? maquinaId}) async {
    String url = '$_base/$id/asignar?';
    if (tecnicoId != null) url += 'tecnicoId=$tecnicoId&';
    if (maquinaId != null) url += 'maquinaId=$maquinaId';
    final res = await http.patch(
      Uri.parse(url),
      headers: AppSession.instance.authHeaders,
    );
    if (res.statusCode == 200) {
      return OrdenTrabajo.fromJson(json.decode(res.body));
    }
    throw Exception('Error al asignar OT: ${res.statusCode}');
  }

  Future<OrdenTrabajo> actualizarEstado(int id, String estado) async {
    final res = await http.patch(
      Uri.parse('$_base/$id/estado?estado=$estado'),
      headers: AppSession.instance.authHeaders,
    );
    if (res.statusCode == 200) {
      return OrdenTrabajo.fromJson(json.decode(res.body));
    }
    throw Exception('Error al actualizar estado: ${res.statusCode}');
  }

  Future<OrdenTrabajo> iniciarOT(int id) async {
    final res = await http.patch(
      Uri.parse('$_base/$id/iniciar'),
      headers: AppSession.instance.authHeaders,
    );
    if (res.statusCode == 200) {
      return OrdenTrabajo.fromJson(json.decode(res.body));
    }
    throw Exception('Error al iniciar OT: ${res.statusCode}');
  }

  Future<OrdenTrabajo> actualizarAcciones(int id, String trabajos) async {
    final res = await http.patch(
      Uri.parse('$_base/$id/acciones'),
      headers: AppSession.instance.authHeaders,
      body: json.encode({'trabajosRealizados': trabajos}),
    );
    if (res.statusCode == 200) {
      return OrdenTrabajo.fromJson(json.decode(res.body));
    }
    throw Exception('Error al actualizar acciones: ${res.statusCode}');
  }

  Future<OrdenTrabajo> cerrarOT(
    int id, {
    String? trabajos,
    String? firmaTecnico,
    String? firmaCliente,
    String? checklists,
    String? fotoBase64,
    String? reportePdfBase64,
  }) async {
    final body = <String, String>{};
    if (trabajos != null) body['trabajosRealizados'] = trabajos;
    if (firmaTecnico != null) body['firmaTecnico'] = firmaTecnico;
    if (firmaCliente != null) body['firmaCliente'] = firmaCliente;
    if (checklists != null) body['checklists'] = checklists;
    if (fotoBase64 != null) body['fotoBase64'] = fotoBase64;
    if (reportePdfBase64 != null) body['reportePdfBase64'] = reportePdfBase64;
    final res = await http.patch(
      Uri.parse('$_base/$id/cerrar'),
      headers: AppSession.instance.authHeaders,
      body: json.encode(body),
    );
    if (res.statusCode == 200) {
      return OrdenTrabajo.fromJson(json.decode(res.body));
    }
    throw Exception('Error al cerrar OT: ${res.statusCode}');
  }

  Future<void> eliminarOT(int id) async {
    final res = await http.delete(
      Uri.parse('$_base/$id'),
      headers: AppSession.instance.authHeaders,
    );
    if (res.statusCode != 204) {
      throw Exception('Error al eliminar OT: ${res.statusCode}');
    }
  }
}
