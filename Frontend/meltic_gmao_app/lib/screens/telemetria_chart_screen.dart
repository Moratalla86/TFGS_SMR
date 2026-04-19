import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/telemetria.dart';
import '../services/plc_service.dart';
import '../theme/industrial_theme.dart';

class TelemetriaChartScreen extends StatefulWidget {
  const TelemetriaChartScreen({super.key});

  @override
  State<TelemetriaChartScreen> createState() => _TelemetriaChartScreenState();
}

class _TelemetriaChartScreenState extends State<TelemetriaChartScreen> {
  List<Telemetria> _readings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await PLCService.fetchTelemetriaList(1);
      final readings = all.length > 60 ? all.sublist(all.length - 60) : all;
      if (mounted) {
        setState(() {
          _readings = readings;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IndustrialTheme.spaceCadet,
      appBar: AppBar(
        title: const Text(
          'SALA DE SERVIDORES',
          style: TextStyle(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: IndustrialTheme.neonCyan),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: IndustrialTheme.neonCyan),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: IndustrialTheme.neonCyan,
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: IndustrialTheme.neonCyan),
              )
            : _error != null
                ? _buildError()
                : _readings.isEmpty
                    ? const Center(
                        child: Text(
                          'SIN DATOS',
                          style: TextStyle(
                            color: IndustrialTheme.slateGray,
                            fontSize: 14,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildLegend(),
                          const SizedBox(height: 16),
                          _buildChart(),
                          const SizedBox(height: 24),
                          _buildLastValues(),
                        ],
                      ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: IndustrialTheme.slateGray),
          const SizedBox(height: 16),
          const Text(
            'Error cargando datos',
            style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('REINTENTAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(IndustrialTheme.criticalRed, 'TEMPERATURA (°C)'),
        const SizedBox(width: 24),
        _legendDot(IndustrialTheme.neonCyan, 'HUMEDAD (%)'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: IndustrialTheme.slateGray,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    final readings = _readings;
    final tempSpots = <FlSpot>[];
    final humSpots = <FlSpot>[];
    for (int i = 0; i < readings.length; i++) {
      tempSpots.add(FlSpot(i.toDouble(), readings[i].temperatura));
      humSpots.add(FlSpot(i.toDouble(), readings[i].humedad));
    }

    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 8),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: tempSpots,
              isCurved: true,
              color: IndustrialTheme.criticalRed,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: IndustrialTheme.criticalRed.withValues(alpha: 0.1),
              ),
            ),
            LineChartBarData(
              spots: humSpots,
              isCurved: true,
              color: IndustrialTheme.neonCyan,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: IndustrialTheme.neonCyan.withValues(alpha: 0.08),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: max(1, (readings.length / 6).floorToDouble()),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= readings.length) return const SizedBox();
                  final ts = readings[idx].timestamp;
                  return Text(
                    DateFormat('HH:mm').format(ts),
                    style: const TextStyle(
                      fontSize: 9,
                      color: IndustrialTheme.slateGray,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 9,
                    color: IndustrialTheme.slateGray,
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => const FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          backgroundColor: IndustrialTheme.claudCloud,
        ),
      ),
    );
  }

  Widget _buildLastValues() {
    if (_readings.isEmpty) return const SizedBox();
    final last = _readings.last;
    final tempColor = last.temperatura >= 35.0
        ? IndustrialTheme.criticalRed
        : IndustrialTheme.warningOrange;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _valueItem(
              Icons.thermostat,
              '${last.temperatura.toStringAsFixed(1)}°C',
              'TEMPERATURA',
              tempColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _valueItem(
              Icons.water_drop_outlined,
              '${last.humedad.toStringAsFixed(1)}%',
              'HUMEDAD',
              IndustrialTheme.neonCyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: IndustrialTheme.slateGray,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
