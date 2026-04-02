import 'package:flutter/material.dart';
import '../services/maquina_service.dart';
import '../services/orden_trabajo_service.dart';
import '../models/orden_trabajo.dart';
import '../models/maquina.dart';
import '../services/app_session.dart';

import 'package:flutter_animate/flutter_animate.dart';
import '../theme/industrial_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MaquinaService _maquinaService = MaquinaService();
  final OrdenTrabajoService _otService = OrdenTrabajoService();
  AppSession get session => AppSession.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      1, 0, 0, 0, 0,
                      0, 1, 0, 0, 0,
                      0, 0, 1, 0, 0,
                      -1, -1, -1, 1, 2.55,
                    ]),
                    child: Image.asset(
                      'assets/images/logo_meltic_clean.png',
                      height: 28,
                      width: 28,
                      errorBuilder: (context, error, stackTrace) => 
                        Image.asset('assets/images/logo_meltic.png', height: 28, width: 28),
                    ),
                  ),
                  const Icon(Icons.menu, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
        leadingWidth: 72,
        title: const Text(
          'PANEL PRINCIPAL',
          style: TextStyle(letterSpacing: 2, fontSize: 14),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: IndustrialTheme.neonCyan.withValues(alpha: 0.15),
                  radius: 14,
                  child: const Icon(
                    Icons.person,
                    color: IndustrialTheme.neonCyan,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.displayName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        session.userRol?.replaceAll('_', ' ') ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8,
                          color: IndustrialTheme.neonCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: IndustrialTheme.neonCyan,
                    size: 20,
                  ),
                  onPressed: () => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: FutureBuilder(
        future: Future.wait([
          _maquinaService.fetchMaquinas(),
          _otService.fetchOrdenes(),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: IndustrialTheme.neonCyan),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 64,
                      color: IndustrialTheme.slateGray.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SERVIDOR NO DISPONIBLE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Comprueba la conexión de red\ny que el servidor esté activo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white30),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('REINTENTAR'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<Maquina> maquinas = snapshot.data![0] as List<Maquina>;
          final List<OrdenTrabajo> ots =
              snapshot.data![1] as List<OrdenTrabajo>;

          int maquinasOperativas = maquinas
              .where((m) => m.estado == 'OK' || m.estado == 'Operativo')
              .length;
          int alertasActivas = maquinas.length - maquinasOperativas;
          int otPendientes = ots
              .where(
                (ot) => ot.estado != 'FINALIZADA' && ot.estado != 'CERRADA',
              )
              .length;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // KPI CARDS INDUSTRIAL
                        Row(
                          children: [
                            _buildKpiCard(
                              "ESTADO PLANTA",
                              "$maquinasOperativas/${maquinas.length}",
                              Icons.precision_manufacturing,
                              IndustrialTheme.operativeGreen,
                            ),
                            const SizedBox(width: 12),
                            _buildKpiCard(
                              "ALERTAS CRÍTICAS",
                              "$alertasActivas",
                              Icons.warning_amber_rounded,
                              alertasActivas > 0
                                  ? IndustrialTheme.criticalRed
                                  : IndustrialTheme.slateGray,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildKpiCard(
                              "TOTAL TAREAS",
                              "${ots.length}",
                              Icons.assignment_outlined,
                              IndustrialTheme.electricBlue,
                            ),
                            const SizedBox(width: 12),
                            _buildKpiCard(
                              "OT PENDIENTES",
                              "$otPendientes",
                              Icons.assignment_late_outlined,
                              IndustrialTheme.warningOrange,
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // ALERTAS SECCIÓN
                        if (alertasActivas > 0) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.sensors_off,
                                color: IndustrialTheme.criticalRed,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "INCIDENCIAS ACTIVAS",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...maquinas
                              .where(
                                (m) =>
                                    m.estado != 'OK' && m.estado != 'Operativo',
                              )
                              .map((m) {
                                return _buildAlertaItem(m);
                              }),
                          const SizedBox(height: 20),
                        ],

                        const Text(
                          "MONITOREO DE ACTIVOS",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (maquinas.isEmpty)
                          const Text(
                            "Sin equipos vinculados",
                            style: TextStyle(color: IndustrialTheme.slateGray),
                          )
                        else
                          _buildHorizontalMachineList(maquinas),

                        const SizedBox(height: 30),

                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "RECENT ACTIVITY LOG",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              "HISTORY",
                              style: TextStyle(
                                color: IndustrialTheme.neonCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (ots.isEmpty)
                          const Text(
                            "Registro vacío",
                            style: TextStyle(color: IndustrialTheme.slateGray),
                          )
                        else
                          ...ots
                              .take(5)
                              .map((ot) => _buildOtDetailedItem(context, ot)),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: AppSession.instance.isJefe
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: IndustrialTheme.neonCyan,
              child: const Icon(Icons.add, color: IndustrialTheme.spaceCadet),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
      decoration: const BoxDecoration(
        color: IndustrialTheme.spaceCadet,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "INTERFAZ DE CONTROL",
            style: TextStyle(
              color: IndustrialTheme.neonCyan,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "ESTADO OPERATIVO \nDE FÁBRICA",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: IndustrialTheme.spaceCadet,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: IndustrialTheme.claudCloud),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    1, 0, 0, 0, 0,
                    0, 1, 0, 0, 0,
                    0, 0, 1, 0, 0,
                    -1, -1, -1, 1, 2.55,
                  ]),
                  child: Image.asset(
                    'assets/images/logo_meltic_clean.png',
                    height: 56,
                    width: 56,
                    errorBuilder: (context, error, stackTrace) => 
                      Image.asset('assets/images/logo_meltic.png', height: 56, width: 56),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  session.displayName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: IndustrialTheme.neonCyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    session.userRol?.replaceAll('_', ' ') ?? 'OPERARIO',
                    style: const TextStyle(
                      color: IndustrialTheme.neonCyan,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(
            Icons.dashboard_outlined,
            "CONTROL PANEL",
            () => Navigator.pop(context),
            active: true,
          ),
          _drawerItem(Icons.people_outline, "PERSONAL", () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/usuarios');
          }),
          _drawerItem(Icons.assignment_outlined, "ORDENES DE TRABAJO", () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/ordenes');
          }),
          _drawerItem(
            Icons.precision_manufacturing_outlined,
            "ACTIVOS PLC",
            () {
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          const Divider(color: Colors.white10),
          _drawerItem(
            Icons.logout,
            "DESCONECTAR",
            () {
              AppSession.instance.clear();
              Navigator.pushReplacementNamed(context, '/');
            },
            color: IndustrialTheme.criticalRed,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool active = false,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            color ??
            (active ? IndustrialTheme.neonCyan : IndustrialTheme.slateGray),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? (active ? Colors.white : IndustrialTheme.slateGray),
          fontSize: 13,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: IndustrialTheme.claudCloud,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: IndustrialTheme.slateGray,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildAlertaItem(Maquina m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IndustrialTheme.criticalRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: IndustrialTheme.criticalRed),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "Corte de telemetría detectado",
                  style: TextStyle(
                    fontSize: 11,
                    color: IndustrialTheme.criticalRed.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: IndustrialTheme.slateGray,
            size: 14,
          ),
        ],
      ),
    ).animate().shake(duration: 1.seconds);
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
          Color mColor = isOk
              ? IndustrialTheme.operativeGreen
              : IndustrialTheme.criticalRed;

          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/machine-detail',
              arguments: m.toJson(),
            ),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16, bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: IndustrialTheme.claudCloud,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.memory,
                        color: IndustrialTheme.neonCyan,
                        size: 24,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: mColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOk ? "LIVE" : "DOWN",
                          style: TextStyle(
                            color: mColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                      ),
                      Text(
                        m.ubicacion,
                        style: const TextStyle(
                          color: IndustrialTheme.slateGray,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtDetailedItem(BuildContext context, OrdenTrabajo ot) {
    Color statusColor = IndustrialTheme.warningOrange;
    if (ot.estado == 'FINALIZADA' || ot.estado == 'CERRADA') {
      statusColor = IndustrialTheme.operativeGreen;
    }

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          Icons.build_circle_outlined,
          color: IndustrialTheme.neonCyan,
        ),
        title: Text(
          ot.maquinaNombre ?? 'EQ_IND_GENERIC',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          ot.descripcion,
          maxLines: 1,
          style: const TextStyle(
            color: IndustrialTheme.slateGray,
            fontSize: 11,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            ot.estado,
            style: TextStyle(
              color: statusColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
