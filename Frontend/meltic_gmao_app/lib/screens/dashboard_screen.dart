import 'package:flutter/material.dart';
import '../services/maquina_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MaquinaService _maquinaService = MaquinaService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Control - Meltic"),
        backgroundColor: Colors.blue[900],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}), // Refresca la lista
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de Bienvenida
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.blue[900],
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bienvenido, Santi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Técnico de Mantenimiento",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Resumen de Actividad",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // Fila de tarjetas de estado (KPIs)
                  Row(
                    children: [
                      _buildStatCard(
                        "MÁQUINAS",
                        "Real",
                        Icons.settings,
                        Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard("AVERÍAS", "3", Icons.warning, Colors.red),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "Maquinaria en Planta",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // LÓGICA DE CONEXIÓN REAL CON EL BACKEND
                  FutureBuilder<List<dynamic>>(
                    future: _maquinaService.fetchMaquinas(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error de conexión: Verifica el Backend",
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text("No hay máquinas en la DB"),
                        );
                      }

                      // Si hay datos, generamos la lista dinámicamente
                      return Column(
                        children: snapshot.data!.map((m) {
                          return _buildMachineItem(
                            context,
                            name: m['nombre'] ?? 'Sin nombre',
                            location: m['ubicacion'] ?? 'Sin ubicación',
                            status: m['estado'] ?? 'Desconocido',
                            // Color dinámico según estado
                            statusColor:
                                (m['estado'] == 'OK' ||
                                    m['estado'] == 'Operativo')
                                ? Colors.green
                                : Colors.orange,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue[900],
        child: const Icon(Icons.add_alert),
      ),
    );
  }

  // Widget para las tarjetas de estadísticas superiores
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para cada ítem de la lista de máquinas
  Widget _buildMachineItem(
    BuildContext context, {
    required String name,
    required String location,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.precision_manufacturing, color: statusColor),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(location),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/machine-detail',
            arguments: {'name': name, 'status': status, 'location': location},
          );
        },
      ),
    );
  }
}
