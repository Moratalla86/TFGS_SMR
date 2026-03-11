import 'package:flutter/material.dart';
import '../services/telemetria_service.dart';
import '../models/telemetria.dart';

class MachineDetailScreen extends StatelessWidget {
  const MachineDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> machine =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final TelemetriaService telemetriaService = TelemetriaService();

    return Scaffold(
      appBar: AppBar(
        title: Text(machine['name']),
        backgroundColor: Colors.blue[900],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- SECCIÓN 1: ESTADO LÓGICO ---
            Container(
              width: double.infinity,
              color: Colors.blue[900],
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.precision_manufacturing,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "ESTADO: ${machine['status']}",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            // --- SECCIÓN 2: SENSORES IOT (CONTROLLINO) ---
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Telemetría en Tiempo Real",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),
                  
                  FutureBuilder<List<Telemetria>>(
                    future: telemetriaService.fetchPorMaquina(machine['id'] ?? 0),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Error obteniendo telemetría", style: TextStyle(color: Colors.red)));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text("No hay datos de telemetría recientes conectados."));
                      }
                      
                      // Coger el último registro que suele venir primero por el OrderByDesc del backend
                      Telemetria actual = snapshot.data!.first;
                      
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSensorGauge(
                            "Temp.",
                            "${actual.temperatura.toStringAsFixed(1)}°C",
                            Icons.thermostat,
                            actual.temperatura > 50 ? Colors.red : Colors.orange,
                          ),
                          _buildSensorGauge(
                            "Humedad",
                            "${actual.humedad.toStringAsFixed(1)}%",
                            Icons.water_drop,
                            Colors.blue,
                          ),
                          _buildSensorGauge(
                            "Motor",
                            "ON",
                            Icons.settings_input_component,
                            Colors.green,
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),

            Divider(),

            // --- SECCIÓN 3: ACCIONES TÉCNICAS ---
            ListTile(
              leading: Icon(Icons.history, color: Colors.blue),
              title: Text("Historial de Mantenimiento"),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                /* Ir a historial */
              },
            ),
            ListTile(
              leading: Icon(Icons.report_problem, color: Colors.red),
              title: Text("Reportar Avería"),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                /* Abrir formulario de avería */
              },
            ),
          ],
        ),
      ),
      // BOTÓN DE ACCIÓN PARA EL HARDWARE
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Aquí enviaremos la orden al Controllino para encender el ventilador
        },
        label: Text("ARRANCAR MOTOR"),
        icon: Icon(Icons.play_arrow),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  Widget _buildSensorGauge(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
