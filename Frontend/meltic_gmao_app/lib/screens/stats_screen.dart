import 'package:flutter/material.dart';
import '../services/stats_service.dart';
import '../theme/industrial_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StatsService _statsService = StatsService();
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _statsService.fetchDashboardStats();
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MÉTRICAS Y RENDIMIENTO (KPI)', style: TextStyle(fontSize: 13, letterSpacing: 1.5)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: IndustrialTheme.neonCyan))
          : _stats == null
              ? const Center(child: Text("Sin datos estadísticos suficientes"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 30),
                      _buildMainKpi(),
                      const SizedBox(height: 30),
                      _buildSectionTitle("ESTRATEGIA DE MANTENIMIENTO"),
                      const SizedBox(height: 12),
                      _buildStrategyRatio(),
                      const SizedBox(height: 30),
                      _buildSectionTitle("DISTRIBUCIÓN DE CARGA POR ESTADO"),
                      const SizedBox(height: 12),
                      _buildStateDistribution(),
                      const SizedBox(height: 30),
                      _buildSectionTitle("CRITICIDAD POR ACTIVO (TOP 3)"),
                      const SizedBox(height: 12),
                      _buildTopMachines(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ANÁLISIS DE EFICIENCIA", style: TextStyle(color: IndustrialTheme.neonCyan, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 5),
        const Text("CONTROL DE KPIS", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
        Text("Último cálculo: ${_stats!['fechaCalculo']?.toString().split('.')[0] ?? 'Ahora'}", style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 11)),
      ],
    );
  }

  Widget _buildMainKpi() {
    return Column(
      children: [
        _buildKpiHero("MTTR", "Media de Reparación", "${_stats!['mttr']} min", Icons.timer_outlined, IndustrialTheme.neonCyan),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSmallKpi("MTBF", "Fiabilidad", "${_stats!['mtbf']} min", Icons.rebase_edit, IndustrialTheme.operativeGreen)),
            const SizedBox(width: 16),
            Expanded(child: _buildSmallKpi("LEAD TIME", "Respuesta", "${_stats!['leadTime']} min", Icons.speed, IndustrialTheme.electricBlue)),
          ],
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildKpiHero(String title, String subtitle, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [IndustrialTheme.spaceCadet, IndustrialTheme.claudCloud]
        )
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(subtitle, style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 11)),
                const SizedBox(height: 10),
                Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 40),
          )
        ],
      ),
    );
  }

  Widget _buildSmallKpi(String title, String subtitle, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildStrategyRatio() {
    double ratio = (_stats!['ratioPreventivo'] as num).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: IndustrialTheme.claudCloud, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  color: IndustrialTheme.operativeGreen,
                ),
                Center(
                  child: Text("${(ratio * 100).toInt()}%", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                )
              ],
            ),
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ESTRATEGIA 4.0", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                const Text("Cumplimiento del mantenimiento preventivo sobre el total de intervenciones.", 
                  style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white70));
  }

  Widget _buildStateDistribution() {
    final dist = _stats!['distribucionEstado'] as Map<String, dynamic>;
    return Column(
      children: dist.entries.map((e) {
        double progress = (e.value as num) / (_stats!['totalOTs'] as num);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: const TextStyle(fontSize: 11, color: Colors.white)),
                  Text("${e.value} OTs", style: const TextStyle(fontSize: 11, color: IndustrialTheme.slateGray)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  color: _getColorForState(e.key),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopMachines() {
    final top = _stats!['topMaquinas'] as List<dynamic>;
    if (top.isEmpty) return const Text("Sin incidencias registradas");
    
    return Column(
      children: top.map((item) {
        final entry = item as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: IndustrialTheme.claudCloud, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.precision_manufacturing, color: IndustrialTheme.slateGray, size: 20),
              const SizedBox(width: 15),
              Text(entry.keys.first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text("${entry.values.first} FALLOS", style: const TextStyle(color: IndustrialTheme.criticalRed, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForState(String state) {
    switch (state) {
      case 'CERRADA': return IndustrialTheme.operativeGreen;
      case 'EN_PROCESO': return IndustrialTheme.electricBlue;
      case 'PENDIENTE': return IndustrialTheme.warningOrange;
      default: return IndustrialTheme.slateGray;
    }
  }
}
