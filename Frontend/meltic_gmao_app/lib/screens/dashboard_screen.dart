import 'dart:async';
import 'package:flutter/material.dart';
import '../services/global_telemetry_historian.dart';
import '../services/maquina_service.dart';
import '../services/orden_trabajo_service.dart';
import '../services/stats_service.dart';
import '../models/orden_trabajo.dart';
import '../models/maquina.dart';
import '../services/app_session.dart';
import '../widgets/sala_servidores_widget.dart';
import '../services/alerta_service.dart';

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

  List<Maquina> _maquinas = [];
  List<OrdenTrabajo> _ots = [];
  List<Alerta> _alertasActivas = [];
  Map<String, dynamic>? _kpiStats;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;
  Timer? _alertaTimer;
  int _lastAlertaCount = 0;
  final AlertaService _alertaService = AlertaService();

  @override
  void initState() {
    super.initState();
    _loadMaquinas();
    _loadAlertas();
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) _loadMaquinas(quiet: true);
    });

    _alertaTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) _checkNewAlertas();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _alertaTimer?.cancel();
    super.dispose();
  }

  void _loadData({bool quiet = false}) {
    _loadMaquinas(quiet: quiet);
  }

  Future<void> _loadMaquinas({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final maquinas = await _maquinaService.fetchMaquinas();
      final ots = await _otService.fetchOrdenes();
      
      GlobalTelemetryHistorian.instance.startTracking(maquinas);

      if (!quiet && _kpiStats == null) {
        try {
          final stats = await StatsService().fetchDashboardStats();
          if (mounted) setState(() { _kpiStats = stats; });
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _maquinas = maquinas;
          _ots = ots;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && !quiet) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadAlertas() async {
    try {
      final alertas = await _alertaService.fetchActivas();
      if (mounted) {
        setState(() {
          _alertasActivas = alertas;
          _lastAlertaCount = alertas.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkNewAlertas() async {
    try {
      final count = await _alertaService.fetchCount();
      if (count > _lastAlertaCount) {
        await _loadAlertas();
        if (_alertasActivas.isNotEmpty) {
          _showNewAlertaBanner(_alertasActivas.first);
        }
      } else if (count < _lastAlertaCount) {
        _loadAlertas();
      }
    } catch (_) {}
  }

  void _navigateToMaquina(int maquinaId) {
    final matches = _maquinas.where((m) => m.id == maquinaId);
    if (matches.isNotEmpty) {
      Navigator.pushNamed(context, '/machine-detail', arguments: matches.first.toJson());
    }
  }

  void _showNewAlertaBanner(Alerta alerta) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: IndustrialTheme.criticalRed,
        leading: const Icon(Icons.warning_sharp, color: Colors.white, size: 28),
        content: Text(
          "ALARMA: ${alerta.maquinaNombre}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              _navigateToMaquina(alerta.maquinaId);
            },
            child: const Text("VER MÁQUINA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text("CERRAR", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

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
          'PANEL DE CONTROL',
          style: TextStyle(letterSpacing: 2, fontSize: 15, color: Colors.white),
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
                  child: const Icon(Icons.person, color: IndustrialTheme.neonCyan, size: 16),
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
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      Text(
                        session.userRol?.replaceAll('_', ' ') ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 8, color: IndustrialTheme.neonCyan),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: IndustrialTheme.neonCyan, size: 20),
                  onPressed: () => _loadData(),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: IndustrialTheme.neonCyan))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 64, color: IndustrialTheme.slateGray.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text('SERVIDOR NO DISPONIBLE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white54)),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white30)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _loadData(),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('REINTENTAR'),
                        ),
                      ],
                    ),
                  ),
                )
              : _maquinas.isEmpty
                  ? const Center(child: Text("No se encontraron máquinas"))
                  : RefreshIndicator(
                      onRefresh: () async { await _loadMaquinas(); },
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
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool isDesktop = constraints.maxWidth > 600;
                                      if (isDesktop) {
                                        return Row(
                                          children: [
                                            _buildKpiCard("ESTADO PLANTA", "${_maquinas.where((m) => m.estado == 'OK' || m.estado == 'Operativo').length}/${_maquinas.length}", Icons.precision_manufacturing, IndustrialTheme.operativeGreen, onTap: () => Navigator.pushNamed(context, '/kpis')),
                                            const SizedBox(width: 12),
                                            _buildKpiCard("ALERTAS CRÍTICAS", "${_maquinas.length - _maquinas.where((m) => m.estado == 'OK' || m.estado == 'Operativo').length}", Icons.warning_amber_rounded, (_maquinas.length - _maquinas.where((m) => m.estado == 'OK' || m.estado == 'Operativo').length) > 0 ? IndustrialTheme.criticalRed : IndustrialTheme.slateGray, onTap: () => Navigator.pushNamed(context, '/activos-plc')),
                                            const SizedBox(width: 12),
                                            _buildKpiCard("TOTAL TAREAS", "${_ots.length}", Icons.assignment_outlined, IndustrialTheme.electricBlue, onTap: () => Navigator.pushNamed(context, '/ordenes')),
                                            const SizedBox(width: 12),
                                            _buildKpiCard("OT PENDIENTES", "${_ots.where((ot) => ot.estado != 'FINALIZADA' && ot.estado != 'CERRADA').length}", Icons.assignment_late_outlined, IndustrialTheme.warningOrange, onTap: () => Navigator.pushNamed(context, '/ordenes')),
                                          ],
                                        );
                                      } else {
                                        return Column(
                                          children: [
                                            Row(
                                              children: [
                                                _buildKpiCard("ESTADO PLANTA", "${_maquinas.where((m) => m.estado == 'OK' || m.estado == 'Operativo').length}/${_maquinas.length}", Icons.precision_manufacturing, IndustrialTheme.operativeGreen, onTap: () => Navigator.pushNamed(context, '/kpis')),
                                                const SizedBox(width: 12),
                                                _buildKpiCard("ALERTAS CRÍTICAS", "${_maquinas.length - _maquinas.where((m) => m.estado == 'OK' || m.estado == 'Operativo').length}", Icons.warning_amber_rounded, (_maquinas.length - _maquinas.where((m) => m.estado == 'OK' || m.estado == 'Operativo').length) > 0 ? IndustrialTheme.criticalRed : IndustrialTheme.slateGray, onTap: () => Navigator.pushNamed(context, '/activos-plc')),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                _buildKpiCard("TOTAL TAREAS", "${_ots.length}", Icons.assignment_outlined, IndustrialTheme.electricBlue, onTap: () => Navigator.pushNamed(context, '/ordenes')),
                                                const SizedBox(width: 12),
                                                _buildKpiCard("OT PENDIENTES", "${_ots.where((ot) => ot.estado != 'FINALIZADA' && ot.estado != 'CERRADA').length}", Icons.assignment_late_outlined, IndustrialTheme.warningOrange, onTap: () => Navigator.pushNamed(context, '/ordenes')),
                                              ],
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Row(children: [
                                    Container(width: 3, height: 14, decoration: BoxDecoration(color: IndustrialTheme.neonCyan, borderRadius: BorderRadius.circular(2))),
                                    const SizedBox(width: 8),
                                    const Text("KPIs OPERACIONALES", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                                  ]),
                                  const SizedBox(height: 12),
                                  if (_kpiStats != null) ...[
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        bool isDesktop = constraints.maxWidth > 800;
                                        if (isDesktop) {
                                          return Row(
                                            children: [
                                              _buildOperationalKpiCard('OEE', '${((_kpiStats!['oeeGlobal'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%', 'Eficiencia Global', Icons.speed, _oeeColor((_kpiStats!['oeeGlobal'] as num?)?.toDouble() ?? 0)),
                                              const SizedBox(width: 12),
                                              _buildOperationalKpiCard('MTBF', '${((_kpiStats!['mtbfHoras'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}h', 'Tiempo Entre Fallos', Icons.av_timer, _mtbfColor((_kpiStats!['mtbfHoras'] as num?)?.toDouble() ?? 0)),
                                              const SizedBox(width: 12),
                                              _buildOperationalKpiCard('MTTR', '${((_kpiStats!['mttrHoras'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}h', 'Tiempo Reparación', Icons.build_circle_outlined, _mttrColor((_kpiStats!['mttrHoras'] as num?)?.toDouble() ?? 0)),
                                              const SizedBox(width: 12),
                                              _buildOperationalKpiCard('DISPONIB.', '${((_kpiStats!['disponibilidadPct'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%', 'Disponibilidad', Icons.precision_manufacturing, _dispColor((_kpiStats!['disponibilidadPct'] as num?)?.toDouble() ?? 0)),
                                            ],
                                          );
                                        } else {
                                          return Column(
                                            children: [
                                              Row(children: [
                                                _buildOperationalKpiCard('OEE', '${((_kpiStats!['oeeGlobal'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%', 'Eficiencia Global', Icons.speed, _oeeColor((_kpiStats!['oeeGlobal'] as num?)?.toDouble() ?? 0)),
                                                const SizedBox(width: 12),
                                                _buildOperationalKpiCard('MTBF', '${((_kpiStats!['mtbfHoras'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}h', 'Tiempo Entre Fallos', Icons.av_timer, _mtbfColor((_kpiStats!['mtbfHoras'] as num?)?.toDouble() ?? 0)),
                                              ]),
                                              const SizedBox(height: 12),
                                              Row(children: [
                                                _buildOperationalKpiCard('MTTR', '${((_kpiStats!['mttrHoras'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}h', 'Tiempo Reparación', Icons.build_circle_outlined, _mttrColor((_kpiStats!['mttrHoras'] as num?)?.toDouble() ?? 0)),
                                                const SizedBox(width: 12),
                                                _buildOperationalKpiCard('DISPONIB.', '${((_kpiStats!['disponibilidadPct'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%', 'Disponibilidad', Icons.precision_manufacturing, _dispColor((_kpiStats!['disponibilidadPct'] as num?)?.toDouble() ?? 0)),
                                              ]),
                                            ],
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  Row(children: [
                                    Container(width: 3, height: 14, decoration: BoxDecoration(color: IndustrialTheme.neonCyan, borderRadius: BorderRadius.circular(2))),
                                    const SizedBox(width: 8),
                                    const Text("SALA DE SERVIDORES", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                                  ]),
                                  const SizedBox(height: 12),
                                  const SalaServidoresWidget(),
                                  const SizedBox(height: 30),
                                  if (_alertasActivas.isNotEmpty) ...[
                                    Row(children: [
                                      Container(width: 3, height: 14, decoration: BoxDecoration(color: IndustrialTheme.criticalRed, borderRadius: BorderRadius.circular(2))),
                                      const SizedBox(width: 8),
                                      const Text("ALARMAS ACTIVAS", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                                    ]),
                                    const SizedBox(height: 12),
                                    ..._alertasActivas.map((alerta) => _buildAlertaUiItem(alerta)),
                                    const SizedBox(height: 20),
                                  ],
                                  Row(children: [
                                    Container(width: 3, height: 14, decoration: BoxDecoration(color: IndustrialTheme.neonCyan, borderRadius: BorderRadius.circular(2))),
                                    const SizedBox(width: 8),
                                    const Text("MONITOREO DE ACTIVOS", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                                  ]),
                                  const SizedBox(height: 12),
                                  _buildMachineGrid(_maquinas),
                                  const SizedBox(height: 30),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(children: [
                                        Container(width: 3, height: 14, decoration: BoxDecoration(color: IndustrialTheme.neonCyan, borderRadius: BorderRadius.circular(2))),
                                        const SizedBox(width: 8),
                                        const Text("RECENT ACTIVITY LOG", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                                      ]),
                                      const Text("HISTORY", style: TextStyle(color: IndustrialTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ..._ots.take(5).map((ot) => _buildOtDetailedItem(context, ot)),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth > 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("INTERFAZ DE CONTROL", style: TextStyle(color: IndustrialTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3)),
              const SizedBox(height: 8),
              Text("ESTADO OPERATIVO \nDE FÁBRICA", style: TextStyle(color: Colors.white, fontSize: isLarge ? 36 : 28, fontWeight: FontWeight.w900, height: 1.1)),
            ],
          );
        },
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
                Text(session.displayName.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: IndustrialTheme.neonCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(session.userRol?.replaceAll('_', ' ') ?? 'OPERARIO', style: const TextStyle(color: IndustrialTheme.neonCyan, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            ),
          ),
          _drawerItem(Icons.dashboard_outlined, "CONTROL PANEL", () { Navigator.of(context).pop(); setState(() {}); }, active: true),
          if (session.isJefe) _drawerItem(Icons.people_outline, "PERSONAL", () { Navigator.of(context).pop(); Navigator.of(context).pushNamed('/usuarios'); }),
          _drawerItem(Icons.bar_chart_rounded, "INDICADORES KPI", () { Navigator.of(context).pop(); Navigator.of(context).pushNamed('/kpis'); }),
          _drawerItem(Icons.event_note_outlined, "CALENDARIO PREVENTIVO", () { Navigator.of(context).pop(); Navigator.of(context).pushNamed('/calendario'); }),
          _drawerItem(Icons.assignment_outlined, "ORDENES DE TRABAJO", () { Navigator.of(context).pop(); Navigator.of(context).pushNamed('/ordenes'); }),
          _drawerItem(Icons.precision_manufacturing_outlined, "ACTIVOS PLC", () { Navigator.of(context).pop(); Navigator.of(context).pushNamed('/activos-plc'); }),
          const Spacer(),
          const Divider(color: Colors.white10),
          _drawerItem(Icons.logout, "DESCONECTAR", () { AppSession.instance.clear(); Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); }, color: IndustrialTheme.criticalRed),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {bool active = false, Color? color}) {
    final tile = ListTile(
      leading: Icon(icon, color: color ?? (active ? IndustrialTheme.neonCyan : IndustrialTheme.slateGray)),
      title: Text(title, style: TextStyle(color: color ?? (active ? Colors.white : IndustrialTheme.slateGray), fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      onTap: onTap,
    );
    if (active) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: IndustrialTheme.neonCyan.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: IndustrialTheme.neonCyan.withValues(alpha: 0.15))),
        child: tile,
      );
    }
    return tile;
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: IndustrialTheme.claudCloud,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 12),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOut);
  }

  Color _oeeColor(double v)  => v >= 85 ? IndustrialTheme.operativeGreen : v >= 65 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;
  Color _mtbfColor(double v) => v >= 48 ? IndustrialTheme.operativeGreen : v >= 24 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;
  Color _mttrColor(double v) => v <= 2 ? IndustrialTheme.operativeGreen : v <= 4 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;
  Color _dispColor(double v) => v >= 90 ? IndustrialTheme.operativeGreen : v >= 75 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;

  Widget _buildOperationalKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: IndustrialTheme.claudCloud,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: IndustrialTheme.slateGray)),
        ]),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildAlertaUiItem(Alerta alerta) {
    Color sColor = alerta.severidad == 'CRITICAL' ? IndustrialTheme.criticalRed : IndustrialTheme.warningOrange;
    return InkWell(
      onTap: () => _navigateToMaquina(alerta.maquinaId),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: IndustrialTheme.claudCloud,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sColor.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: sColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(alerta.severidad == 'CRITICAL' ? Icons.error_outline : Icons.warning_amber_rounded, color: sColor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Flexible(child: Text(alerta.maquinaNombre, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14))),
                                const SizedBox(width: 8),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: sColor, borderRadius: BorderRadius.circular(4)), child: Text(alerta.severidad, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                              ]),
                              Text(alerta.descripcion, style: TextStyle(fontSize: 11, color: sColor.withValues(alpha: 0.7))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${alerta.timestamp.hour}:${alerta.timestamp.minute.toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 10, color: IndustrialTheme.slateGray)),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right, color: sColor.withValues(alpha: 0.5), size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMachineGrid(List<Maquina> maquinas) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = constraints.maxWidth > 900 ? 4
                 : constraints.maxWidth > 600 ? 3
                 : 2;
        double aspectRatio = cols >= 3 ? 1.8 : 1.3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: maquinas.length,
          itemBuilder: (context, index) {
            final m = maquinas[index];
            bool isOk = m.estado == 'OK' || m.estado == 'Operativo';
            Color mColor = isOk ? IndustrialTheme.operativeGreen : IndustrialTheme.criticalRed;
            
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/machine-detail', arguments: m.toJson()),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: IndustrialTheme.claudCloud,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: mColor.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: mColor.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.precision_manufacturing, color: mColor, size: 20),
                    const SizedBox(height: 12),
                    Text(
                      m.nombre.toUpperCase(),
                      style: TextStyle(
                        fontSize: 18, // Ligeramente menor que el valor numérico para que quepa bien
                        fontWeight: FontWeight.w900,
                        color: isOk ? Colors.white : mColor,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.ubicacion,
                      style: const TextStyle(
                        color: IndustrialTheme.slateGray,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
        leading: Icon(Icons.build_circle_outlined, color: IndustrialTheme.neonCyan),
        title: Text(ot.maquinaNombre ?? 'EQ_IND_GENERIC', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(ot.descripcion, maxLines: 1, style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(ot.estado, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}
