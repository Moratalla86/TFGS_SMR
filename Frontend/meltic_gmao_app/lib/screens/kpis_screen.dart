import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show max;
import '../services/stats_service.dart';
import '../theme/industrial_theme.dart';
import '../utils/pdf_generator.dart';

class KpisScreen extends StatefulWidget {
  const KpisScreen({super.key});

  @override
  State<KpisScreen> createState() => _KpisScreenState();
}

class _KpisScreenState extends State<KpisScreen> {
  final StatsService _statsService = StatsService();
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _statsService.fetchDashboardStats();
      if (mounted) setState(() { _stats = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('INDICADORES KPI',
            style: TextStyle(fontSize: 15, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: _stats == null ? null : () => _exportarPdf(),
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('EXPORTAR PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: IndustrialTheme.electricBlue,
                foregroundColor: IndustrialTheme.spaceCadet,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh, color: IndustrialTheme.neonCyan),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: IndustrialTheme.neonCyan))
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 56, color: IndustrialTheme.slateGray),
        const SizedBox(height: 16),
        const Text('ERROR DE CONEXIÓN',
            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('REINTENTAR'),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    final s = _stats!;
    final double oee          = (s['oeeGlobal']       as num?)?.toDouble() ?? 0;
    final double mtbf         = (s['mtbfHoras']        as num?)?.toDouble() ?? 0;
    final double mttr         = (s['mttrHoras']        as num?)?.toDouble() ?? 0;
    final double disp         = (s['disponibilidadPct'] as num?)?.toDouble() ?? 0;
    final Map<String, dynamic> ratio = (s['ratioPreventivoCorrectivo'] as Map?)?.cast() ?? {};
    final Map<String, dynamic> porEstado = (s['otsPorEstado'] as Map?)?.cast() ?? {};
    final List<dynamic> ranking = s['rankingIncidencias'] as List? ?? [];
    final List<dynamic> evolucion = s['evolucionMensual'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      color: IndustrialTheme.neonCyan,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('KPIs GLOBALES'),
            const SizedBox(height: 12),
            Row(children: [
              _kpiCard('OEE', '${oee.toStringAsFixed(1)}%',
                  Icons.speed, _oeeColor(oee), 'Eficiencia Global Equipos'),
              const SizedBox(width: 12),
              _kpiCard('MTBF', '${mtbf.toStringAsFixed(1)}h',
                  Icons.av_timer, _mtbfColor(mtbf), 'Tiempo Medio Entre Fallos'),
            ]).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            Row(children: [
              _kpiCard('MTTR', '${mttr.toStringAsFixed(1)}h',
                  Icons.build_circle_outlined, _mttrColor(mttr), 'Tiempo Medio de Reparación'),
              const SizedBox(width: 12),
              _kpiCard('DISPONIB.', '${disp.toStringAsFixed(1)}%',
                  Icons.precision_manufacturing, _dispColor(disp), 'Disponibilidad de Planta'),
            ]).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),

            const SizedBox(height: 28),

            _sectionTitle('DISTRIBUCIÓN DE MANTENIMIENTO'),
            const SizedBox(height: 12),
            _buildRatioCard(ratio),

            const SizedBox(height: 20),

            _sectionTitle('ÓRDENES POR ESTADO'),
            const SizedBox(height: 12),
            _buildEstadoCard(porEstado),

            const SizedBox(height: 28),

            _sectionTitle('EVOLUCIÓN MENSUAL (ÚLTIMOS 6 MESES)'),
            const SizedBox(height: 12),
            _buildEvolucionChart(evolucion),

            const SizedBox(height: 28),

            _sectionTitle('RANKING DE INCIDENCIAS'),
            const SizedBox(height: 12),
            _buildRanking(ranking),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: IndustrialTheme.claudCloud,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const Spacer(),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ]),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                  color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(fontSize: 8, color: IndustrialTheme.slateGray),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildRatioCard(Map<String, dynamic> ratio) {
    final int prev = (ratio['preventivas'] as num?)?.toInt() ?? 0;
    final int corr = (ratio['correctivas'] as num?)?.toInt() ?? 0;
    final int total = prev + corr;
    final double prevPct = total > 0 ? prev / total : 0;
    final double corrPct = total > 0 ? corr / total : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _ratioRow('PREVENTIVAS', prev, prevPct, IndustrialTheme.operativeGreen),
        const SizedBox(height: 14),
        _ratioRow('CORRECTIVAS', corr, corrPct, IndustrialTheme.criticalRed),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: prevPct >= 0.8
                ? const Color(0x1A00C853)
                : const Color(0x1AFFA500),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(
              prevPct >= 0.8 ? Icons.check_circle_outline : Icons.info_outline,
              size: 14,
              color: prevPct >= 0.8 ? IndustrialTheme.operativeGreen : IndustrialTheme.warningOrange,
            ),
            const SizedBox(width: 6),
            Flexible(child: Text(
              prevPct >= 0.8
                  ? 'OBJETIVO CUMPLIDO: > 80% preventivo'
                  : 'OBJETIVO: aumentar preventivo a > 80% (actual ${(prevPct * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: prevPct >= 0.8 ? IndustrialTheme.operativeGreen : IndustrialTheme.warningOrange,
              ),
            )),
          ]),
        ),
      ]),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _ratioRow(String label, int count, double pct, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        Text('$count  ·  ${(pct * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct.clamp(0.0, 1.0),
          minHeight: 8,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ]);
  }

  Widget _buildEstadoCard(Map<String, dynamic> porEstado) {
    final int cerradas    = (porEstado['CERRADA']    as num?)?.toInt() ?? 0;
    final int enProceso   = (porEstado['EN_PROCESO'] as num?)?.toInt() ?? 0;
    final int pendientes  = (porEstado['PENDIENTE']  as num?)?.toInt() ?? 0;
    final int total = cerradas + enProceso + pendientes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: [
        _estadoRow('CERRADAS',   cerradas,   total, IndustrialTheme.operativeGreen),
        const SizedBox(height: 12),
        _estadoRow('EN PROCESO', enProceso,  total, IndustrialTheme.neonCyan),
        const SizedBox(height: 12),
        _estadoRow('PENDIENTES', pendientes, total, IndustrialTheme.warningOrange),
      ]),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _estadoRow(String label, int count, int total, Color color) {
    final double pct = total > 0 ? count / total : 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        Text('$count  ·  ${(pct * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct.clamp(0.0, 1.0),
          minHeight: 8,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ]);
  }

  Widget _buildEvolucionChart(List<dynamic> evolucion) {
    if (evolucion.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: IndustrialTheme.claudCloud,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('SIN DATOS', style: TextStyle(color: Colors.white24)),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: [
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: evolucion.fold<double>(1.0, (prev, m) {
                final p = (m['preventivo'] as num?)?.toDouble() ?? 0;
                final c = (m['correctivo'] as num?)?.toDouble() ?? 0;
                return max(prev, max(p, c));
              }) * 1.25,
              barGroups: evolucion.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: (m['preventivo'] as num?)?.toDouble() ?? 0,
                      color: IndustrialTheme.operativeGreen,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                    ),
                    BarChartRodData(
                      toY: (m['correctivo'] as num?)?.toDouble() ?? 0,
                      color: IndustrialTheme.criticalRed,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= evolucion.length) return const SizedBox();
                      return Text(
                        evolucion[idx]['mes']?.toString() ?? '',
                        style: const TextStyle(
                            fontSize: 9,
                            color: IndustrialTheme.slateGray,
                            fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                leftTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData:   FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _legend(IndustrialTheme.operativeGreen, 'PREVENTIVO'),
          const SizedBox(width: 20),
          _legend(IndustrialTheme.criticalRed, 'CORRECTIVO'),
        ]),
      ]),
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }

  Future<void> _exportarPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generando PDF...'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      await PdfGenerator.generarKpiPdf(_stats!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al generar PDF. Comprueba los datos.'),
            backgroundColor: IndustrialTheme.criticalRed,
          ),
        );
      }
    }
  }

  Widget _legend(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              color: IndustrialTheme.slateGray, fontSize: 8, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildRanking(List<dynamic> ranking) {
    if (ranking.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: IndustrialTheme.claudCloud,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('SIN DATOS', style: TextStyle(color: Colors.white24)),
      );
    }

    final int maxInc = (ranking.first['incidencias'] as num?)?.toInt() ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: ranking.asMap().entries.map<Widget>((e) {
          final int idx = e.key;
          final String maq = e.value['maquina']?.toString() ?? '';
          final int inc = (e.value['incidencias'] as num?)?.toInt() ?? 0;
          final double pct = maxInc > 0 ? inc / maxInc : 0;
          final Color barColor = _rankColor(idx);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4)),
                  alignment: Alignment.center,
                  child: Text('${idx + 1}',
                      style: TextStyle(
                          color: barColor, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(maq,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                ),
                Text('$inc incidencias',
                    style: TextStyle(fontSize: 9, color: barColor, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 500.ms);
  }

  Color _oeeColor(double v)  => v >= 75 ? IndustrialTheme.operativeGreen
      : v >= 50 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;
  Color _mtbfColor(double v) => v >= 100 ? IndustrialTheme.operativeGreen
      : v >= 50 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;
  Color _mttrColor(double v) => v <= 4 ? IndustrialTheme.operativeGreen
      : v <= 8 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;
  Color _dispColor(double v) => v >= 85 ? IndustrialTheme.operativeGreen
      : v >= 70 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;

  Color _rankColor(int idx) {
    const colors = [
      IndustrialTheme.criticalRed,
      Color(0xFFE53935),
      IndustrialTheme.warningOrange,
      Color(0xFFFFB74D),
      IndustrialTheme.slateGray,
    ];
    return idx < colors.length ? colors[idx] : IndustrialTheme.slateGray;
  }

  Widget _sectionTitle(String title) {
    return Row(children: [
      Container(width: 3, height: 13,
        decoration: BoxDecoration(color: IndustrialTheme.neonCyan, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        )),
    ]);
  }
}
