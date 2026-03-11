import 'package:flutter/material.dart';
import '../services/maquina_service.dart';
import '../services/orden_trabajo_service.dart';
import '../models/orden_trabajo.dart';
import '../models/maquina.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MaquinaService _maquinaService = MaquinaService();
  final OrdenTrabajoService _otService = OrdenTrabajoService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Panel de Control", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: FutureBuilder(
        future: Future.wait([
          _maquinaService.fetchMaquinas(),
          _otService.fetchOrdenes(),
        ]),
        builder: (context, AsyncSnapshot<List<Object>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error de conexión al servidor:\n${snapshot.error}", textAlign: TextAlign.center, style: TextStyle(color: Colors.red)));
          }

          final List<Maquina> maquinas = snapshot.data![0] as List<Maquina>;
          final List<OrdenTrabajo> ots = snapshot.data![1] as List<OrdenTrabajo>;

          int maquinasOperativas = maquinas.where((m) => m.estado == 'OK' || m.estado == 'Operativo').length;
          int alertasActivas = maquinas.length - maquinasOperativas;
          int otPendientes = ots.where((ot) => ot.estado != 'FINALIZADA' && ot.estado != 'CERRADA').length;

          return RefreshIndicator(
            onRefresh: () async { setState(() {}); },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        
                        // KPI OVERVIEW CARDS
                        Row(
                          children: [
                            _buildKpiCard("MÁQUINAS OK", "$maquinasOperativas/${maquinas.length}", Icons.precision_manufacturing, Colors.green),
                            const SizedBox(width: 12),
                            _buildKpiCard("ALERTAS", "$alertasActivas", Icons.warning_amber_rounded, alertasActivas > 0 ? Colors.red : Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildKpiCard("OT TOTALES", "${ots.length}", Icons.assignment_outlined, Colors.blue),
                            const SizedBox(width: 12),
                            _buildKpiCard("OT PENDIENTES", "$otPendientes", Icons.assignment_late_outlined, Colors.orange),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // ALERTAS SECCIÓN (Render solo si hay alertas)
                        if (alertasActivas > 0) ...[
                          const Row(
                            children: [
                              Icon(Icons.notification_important, color: Colors.red),
                              SizedBox(width: 8),
                              Text("Alertas en Fábrica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...maquinas.where((m) => m.estado != 'OK' && m.estado != 'Operativo').map((m) {
                            return _buildAlertaItem(m);
                          }),
                          const SizedBox(height: 20),
                        ],
                        
                        const Text("Maquinaria", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (maquinas.isEmpty) const Text("No hay máquinas registradas.")
                        else _buildHorizontalMachineList(maquinas),

                        const SizedBox(height: 30),
                        
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Órdenes de Trabajo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("Ver todas", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (ots.isEmpty) const Text("No hay OTs registradas.")
                        else ...ots.take(5).map((ot) => _buildOtDetailedItem(context, ot)),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bienvenido al área \nde mantenimiento.",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
          ),
          SizedBox(height: 8),
          Text(
            "Aquí tienes un resumen del estado de planta.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.blue[900]),
            accountName: const Text("Técnico / Admin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: const Text("Gestión GMAO"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blue),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Usuarios'),
            onTap: () {
               Navigator.pop(context);
               Navigator.pushNamed(context, '/usuarios');
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: const Text('Órdenes de Trabajo'),
            onTap: () {
               Navigator.pop(context);
               Navigator.pushNamed(context, '/ordenes');
            },
          ),
          ListTile(
            leading: const Icon(Icons.precision_manufacturing_outlined),
            title: const Text('Máquinas'),
            onTap: () {
               // Navegación futura
               Navigator.pop(context);
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pantalla del Parque de Máquinas en desarrollo")));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configuración'),
            onTap: () {
              // Navegación futura
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.grey[800])),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertaItem(Maquina m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[100]!),
        boxShadow: [
          BoxShadow(color: Colors.red.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      child: Row(
        children: [
          Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
             child: const Icon(Icons.warning_rounded, color: Colors.red),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Alerta en ${m.nombre}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[900], fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text("Estado: ", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    Text(m.estado, style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
             onPressed: () {},
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.white,
               foregroundColor: Colors.red[700],
               elevation: 0,
               side: BorderSide(color: Colors.red[200]!),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
             ),
             child: const Text("VER"),
          )
        ],
      ),
    );
  }

  Widget _buildHorizontalMachineList(List<Maquina> maquinas) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: maquinas.length,
        itemBuilder: (context, index) {
          final m = maquinas[index];
          bool isOk = m.estado == 'OK' || m.estado == 'Operativo';
          Color mColor = isOk ? Colors.green : Colors.red;
          
          return GestureDetector(
            onTap: () {
               Navigator.pushNamed(
                context,
                '/machine-detail',
                arguments: {'id': m.id, 'name': m.nombre, 'status': m.estado, 'location': m.modelo}, // 'modelo' is the closest to location right now based on the dart model
              );
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16, bottom: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.precision_manufacturing, color: Colors.blue[800], size: 24),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: mColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: mColor)),
                            const SizedBox(width: 4),
                            Text(isOk ? "OK" : "ERR", style: TextStyle(color: mColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(m.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800]), maxLines: 1, overflow: TextOverflow.ellipsis),
                       const SizedBox(height: 4),
                       Text(m.modelo, style: TextStyle(color: Colors.grey[500], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtDetailedItem(BuildContext context, OrdenTrabajo ot) {
    Color statusColor = Colors.orange;
    if (ot.estado == 'FINALIZADA' || ot.estado == 'CERRADA') statusColor = Colors.green;
    
    Color priorityColor = Colors.grey;
    if (ot.prioridad == 'ALTA') priorityColor = Colors.red;
    if (ot.prioridad == 'MEDIA') priorityColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.build_circle, color: Colors.blue[900]),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(ot.maquinaNombre ?? 'Sin Máquina Asignada', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(ot.prioridad, style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ot.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                       Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                       const SizedBox(width: 4),
                       Text((ot.fechaCreacion != null && ot.fechaCreacion!.length >= 10) ? ot.fechaCreacion!.substring(0,10) : "", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                  Text(ot.estado, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        onTap: () {
          // TODO: Navegar al detalle
        },
      ),
    );
  }
}
