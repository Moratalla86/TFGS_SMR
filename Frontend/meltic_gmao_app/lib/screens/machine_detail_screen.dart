import 'dart:async';
import 'package:flutter/material.dart';
import '../services/telemetria_service.dart';
import '../models/telemetria.dart';

class MachineDetailScreen extends StatefulWidget {
  const MachineDetailScreen({super.key});

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  final TelemetriaService _telemetriaService = TelemetriaService();
  Timer? _timer;
  late Future<List<Telemetria>> _telemetriaFuture;
  Map<String, dynamic>? _machine;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_machine == null) {
      _machine = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _refreshData();
      // Iniciar el Timer para refrescar cada 5 segundos
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          _refreshData();
        }
      });
    }
  }

  void _refreshData() {
    setState(() {
      _telemetriaFuture = _telemetriaService.fetchPorMaquina(_machine?['id'] ?? 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_machine == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(_machine!['name']),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- SECCIÓN 1: ESTADO LÓGICO ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  const Icon(Icons.precision_manufacturing, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    "ESTADO: ${_machine!['status']}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // --- SECCIÓN 2: SENSORES IOT (CONTROLLINO) ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Telemetría en Vivo",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 10, color: Colors.green),
                            const SizedBox(width: 5),
                            Text("CONECTADO", style: TextStyle(color: Colors.green[800], fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  FutureBuilder<List<Telemetria>>(
                    future: _telemetriaFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Error obteniendo telemetría: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("Esperando datos del PLC..."));
                      }
                      
                      Telemetria actual = snapshot.data!.first;
                      
                      return Column(
                        children: [
                          // Medidores
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSensorGauge(
                                  "Temperatura",
                                  "${actual.temperatura.toStringAsFixed(1)}°C",
                                  Icons.thermostat,
                                  actual.temperatura > 40 ? Colors.red : Colors.orange,
                                ),
                                _buildSensorGauge(
                                  "Humedad",
                                  "${actual.humedad.toStringAsFixed(1)}%",
                                  Icons.water_drop,
                                  Colors.blue,
                                ),
                                _buildSensorGauge(
                                  "Sistema",
                                  "OK",
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),

                          // --- SECCIÓN RFID: TÉCNICO DETECTADO ---
                          if (actual.usuarioNombre.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.blue[800]!, Colors.blue[600]!]),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Colors.white24,
                                    child: Icon(Icons.person, color: Colors.white),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("TÉCNICO EN MÁQUINA", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                        Text(actual.usuarioNombre, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.sensors, color: Colors.white54),
                                ],
                              ),
                            ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),

            const Divider(),

            // --- SECCIÓN 3: ACCIONES TÉCNICAS ---
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text("Historial de Mantenimiento"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.red),
              title: const Text("Reportar Avería"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const SizedBox(height: 100), // Espacio para el FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text("ARRANCAR MOTOR"),
        icon: const Icon(Icons.play_arrow),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  Widget _buildSensorGauge(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

