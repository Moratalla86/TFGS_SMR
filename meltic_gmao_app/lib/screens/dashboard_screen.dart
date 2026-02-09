import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart'; // Tu servicio de IPs
import '../models/maquina.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<List<Maquina>> getMaquinas() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/maquinas'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((m) => Maquina.fromJson(m)).toList();
    } else {
      throw Exception('Error al conectar con Java');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Meltic GMAO - Panel Multiplataforma')),
      body: FutureBuilder<List<Maquina>>(
        future: getMaquinas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Aquí detectamos el ancho de la pantalla
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                // MODO WEB / WINDOWS (Grid de 3 columnas)
                return GridView.builder(
                  padding: EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 3,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, i) => _cardMaquina(snapshot.data![i]),
                );
              } else {
                // MODO MÓVIL (Lista vertical)
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, i) => _cardMaquina(snapshot.data![i]),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _cardMaquina(Maquina m) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: ListTile(
        leading: Icon(Icons.precision_manufacturing, color: Colors.blue),
        title: Text(m.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${m.modelo} - Estado: ${m.estado}"),
        trailing: CircleAvatar(
          backgroundColor: m.estado == "OK" ? Colors.green : Colors.red,
          radius: 10,
        ),
      ),
    );
  }
}
