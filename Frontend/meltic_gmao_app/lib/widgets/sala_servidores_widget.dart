import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/plc_service.dart';
import '../models/telemetria.dart';
import '../theme/industrial_theme.dart';
import '../screens/telemetria_chart_screen.dart';

class SalaServidoresWidget extends StatefulWidget {
  const SalaServidoresWidget({super.key});

  @override
  State<SalaServidoresWidget> createState() => _SalaServidoresWidgetState();
}

class _SalaServidoresWidgetState extends State<SalaServidoresWidget> {
  Timer? _timer;
  double? _temperatura;
  double? _humedad;
  bool _live = false;

  // Mirror DashboardScreen initState timer pattern:
  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  // Mirror DashboardScreen dispose pattern — cancel before super.dispose():
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Polls PLCService and updates state — all setState guarded with if (mounted):
  Future<void> _poll() async {
    // NOTE: machine ID=1 is the Controllino/IoT hardware — TFG-specific assumption.
    final Telemetria? t = await PLCService.fetchLastTelemetry(1);
    if (mounted) {
      setState(() {
        if (t != null) {
          _temperatura = t.temperatura;
          _humedad = t.humedad;
          _live = true;
        } else {
          _live = false;
          // Keep stale values — do not null them out on error
        }
      });
    }
  }

  // Temperature color thresholds per UI-SPEC Surface 3:
  Color _tempColor(double? temp) {
    if (temp == null) return IndustrialTheme.slateGray;
    if (temp < 25.0) return IndustrialTheme.operativeGreen;
    if (temp < 35.0) return IndustrialTheme.warningOrange;
    return IndustrialTheme.criticalRed;
  }

  @override
  Widget build(BuildContext context) {
    // Loading state: no data yet and not live
    if (_temperatura == null && _humedad == null && !_live) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(
            color: IndustrialTheme.neonCyan,
            strokeWidth: 2,
          ),
        ),
      );
    }

    // Main widget — mirrors _buildKpiCard container structure:
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TelemetriaChartScreen()),
      ),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: EN VIVO badge + live dot + chevron hint
          Row(
            children: [
              const Icon(Icons.sensors, color: IndustrialTheme.neonCyan, size: 18),
              const SizedBox(width: 8),
              const Text(
                'EN VIVO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: IndustrialTheme.neonCyan,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              _LiveDot(live: _live),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: IndustrialTheme.slateGray, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          // Sensor cards row
          Row(
            children: [
              _SensorCard(
                label: 'TEMPERATURA',
                value: '${_temperatura?.toStringAsFixed(1) ?? '--'}°C',
                icon: Icons.thermostat,
                color: _tempColor(_temperatura),
              ),
              const SizedBox(width: 12),
              _SensorCard(
                label: 'HUMEDAD',
                value: '${_humedad?.toStringAsFixed(1) ?? '--'}%',
                icon: Icons.water_drop_outlined,
                color: IndustrialTheme.neonCyan,
              ),
            ],
          ),
        ],
      ),
    ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}

// Sub-widget: sensor value card — mirrors _buildKpiCard in dashboard_screen.dart
class _SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SensorCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: IndustrialTheme.claudCloud,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
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
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sub-widget: pulsing live indicator dot
class _LiveDot extends StatelessWidget {
  final bool live;
  const _LiveDot({required this.live});

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: live ? IndustrialTheme.operativeGreen : IndustrialTheme.criticalRed,
        shape: BoxShape.circle,
      ),
    );
    if (!live) return dot;
    // Pulsing animation when live — per UI-SPEC Animation Contract:
    return dot
        .animate(onPlay: (c) => c.repeat())
        .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.4, 1.4),
            duration: 800.ms,
            curve: Curves.easeInOut)
        .then()
        .scale(
            begin: const Offset(1.4, 1.4),
            end: const Offset(1, 1),
            duration: 800.ms);
  }
}
