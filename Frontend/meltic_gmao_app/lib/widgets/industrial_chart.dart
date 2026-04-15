import 'package:flutter/material.dart' hide SelectionDetails;
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/telemetria.dart';
import '../models/maquina.dart';
import '../theme/industrial_theme.dart';
import '../utils/metric_definitions.dart';
import 'package:intl/intl.dart';

/// ─────────────────────────────────────────────────
///  SCADA TREND CHART — Estilo industrial profesional
///
///  Implementa el patrón "Trellis / Stacked Pens":
///  • Una sub-gráfica por variable ("pen")
///  • Cada pen tiene su propio eje Y calibrado a su rango real
///  • Eje X compartido con ventana temporal deslizante
///  • Tabla de pens debajo con valor actual, min y max
///  • Crosshair con fecha/hora completa y todos los valores
/// ─────────────────────────────────────────────────
class IndustrialChart extends StatelessWidget {
  final List<Telemetria> telemetria;
  final Maquina maquina;
  final bool isVirtual;
  final double timeRange;
  final DateTimeIntervalType timeMagnitude;

  const IndustrialChart({
    super.key,
    required this.telemetria,
    required this.maquina,
    this.isVirtual = false,
    this.timeRange = 5,
    this.timeMagnitude = DateTimeIntervalType.minutes,
    this.staticXMin,
    this.staticXMax,
  });

  /// Cuando se proveen, el chart usa estos límites absolutos (modo histórico)
  /// en lugar de DateTime.now() como xMax.
  final DateTime? staticXMin;
  final DateTime? staticXMax;

  Duration get _windowDuration {
    switch (timeMagnitude) {
      case DateTimeIntervalType.seconds:
        return Duration(seconds: timeRange.toInt());
      case DateTimeIntervalType.minutes:
        return Duration(minutes: timeRange.toInt());
      case DateTimeIntervalType.hours:
        return Duration(hours: timeRange.toInt());
      case DateTimeIntervalType.days:
        return Duration(days: timeRange.toInt());
      default:
        return Duration(minutes: timeRange.toInt());
    }
  }

  double _getValue(Telemetria t, String id) {
    switch (id) {
      case 'temperatura': return t.temperatura;
      case 'humedad': return t.humedad;
      case 'vibracion': return t.vibracion;
      case 'presion': return t.presion;
      case 'voltaje': return t.voltaje;
      case 'intensidad': return t.intensidad;
      default: return t.sensores[id] ?? 0.0;
    }
  }

  DateFormat get _xFormat {
    switch (timeMagnitude) {
      case DateTimeIntervalType.seconds:
      case DateTimeIntervalType.minutes:
        return DateFormat('HH:mm:ss');
      case DateTimeIntervalType.hours:
        return DateFormat('HH:mm');
      default:
        return DateFormat('HH:mm:ss');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Todos los datos ordenados (el eje X filtra la ventana visible)
    final List<Telemetria> allData = List<Telemetria>.from(telemetria)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // El extremo derecho es SIEMPRE DateTime.now() en modo live.
    // En modo histórico (staticXMax != null), usa los límites proporcionados
    // por el caller (que incluye exactamente el rango consultado al historian).
    final DateTime xMax = staticXMax ?? DateTime.now();
    final DateTime xMin = staticXMin ?? xMax.subtract(_windowDuration);

    // Definir los "pens" (variables a monitorizar)
    final activeConfigs = maquina.configs.where((c) => c.habilitado).toList();
    final List<_Pen> pens = activeConfigs.isNotEmpty
        ? activeConfigs.map((c) {
            final def = MetricDefinition.getById(c.nombreMetrica);
            return _Pen(id: c.nombreMetrica, label: def.label, unit: c.unidadSeleccionada, color: def.color);
          }).toList()
        : [
            _Pen(id: 'temperatura', label: 'TEMP. AMBIENTE', unit: '°C', color: Colors.orange),
            _Pen(id: 'humedad', label: 'HUMEDAD REL.', unit: '%', color: Colors.blue),
            _Pen(id: 'intensidad', label: 'INTENSIDAD', unit: 'A', color: Colors.indigo),
            _Pen(id: 'presion', label: 'PRESIÓN', unit: 'Bar', color: Colors.redAccent),
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Cabecera ──────────────────────────────────
          _Header(isVirtual: isVirtual, pts: allData.length),
          const SizedBox(height: 8),
          // ── Línea de tiempo compartida (mini) ─────────
          _TimeRuler(xMin: xMin, xMax: xMax, xFormat: _xFormat),
          const SizedBox(height: 4),
          // ── Pens apilados (SCADA Trellis) ─────────────
          ...pens.map((pen) => _PenChart(
            pen: pen,
            data: allData,
            xMin: xMin,
            xMax: xMax,
            getValue: _getValue,
          )),
          const SizedBox(height: 8),
          // ── Tabla de pens (PEN TABLE) ──────────────────
          _PenTable(pens: pens, data: allData, getValue: _getValue),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Cabecera
// ─────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isVirtual;
  final int pts;
  const _Header({required this.isVirtual, required this.pts});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: IndustrialTheme.neonCyan, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            isVirtual ? 'SIMULACIÓN — GEMELO DIGITAL' : 'TENDENCIAS EN TIEMPO REAL',
            style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: pts > 0 ? IndustrialTheme.operativeGreen.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$pts registros',
            style: TextStyle(color: pts > 0 ? IndustrialTheme.operativeGreen : Colors.orange, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Regla de tiempo compartida (eje X solo)
// ─────────────────────────────────────────────────────────────────
class _TimeRuler extends StatelessWidget {
  final DateTime xMin, xMax;
  final DateFormat xFormat;
  const _TimeRuler({required this.xMin, required this.xMax, required this.xFormat});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        primaryXAxis: DateTimeAxis(
          minimum: xMin,
          maximum: xMax,
          dateFormat: xFormat,
          labelStyle: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 8),
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 1, color: IndustrialTheme.slateGray),
          edgeLabelPlacement: EdgeLabelPlacement.shift,
        ),
        primaryYAxis: NumericAxis(isVisible: false),
        series: const <CartesianSeries>[],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Una sola gráfica por PEN (SCADA Trellis)
// ─────────────────────────────────────────────────────────────────
class _PenChart extends StatelessWidget {
  final _Pen pen;
  final List<Telemetria> data;
  final DateTime xMin;
  final DateTime xMax;
  final double Function(Telemetria, String) getValue;
  const _PenChart({
    required this.pen, required this.data,
    required this.xMin, required this.xMax,
    required this.getValue,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox(height: 90);

    // Calcular min/max real de ESTE pen para el eje Y preciso
    final values = data.map((t) => getValue(t, pen.id)).toList();
    double vMin = values.reduce((a, b) => a < b ? a : b);
    double vMax = values.reduce((a, b) => a > b ? a : b);
    final range = vMax - vMin;
    // Si todos los valores son iguales, dar margen artificial
    if (range < 0.01) {
      vMin = vMin - (vMin.abs() * 0.1).clamp(0.5, 10.0);
      vMax = vMax + (vMax.abs() * 0.1).clamp(0.5, 10.0);
    } else {
      final pad = range * 0.15;
      vMin = vMin - pad;
      vMax = vMax + pad;
    }

    // Valor actual (último)
    final currentVal = data.isNotEmpty ? getValue(data.last, pen.id) : 0.0;

    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: pen.color.withValues(alpha: 0.6), width: 3),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Etiqueta izquierda (nombre + valor actual)
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pen.label, style: TextStyle(color: pen.color, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(
                    currentVal.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                  Text(pen.unit, style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 8)),
                ],
              ),
            ),
          ),
          // Mini eje Y con valores
          SizedBox(
            width: 36,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(vMax.toStringAsFixed(1), style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 7)),
                Text(((vMin + vMax) / 2).toStringAsFixed(1), style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 7)),
                Text(vMin.toStringAsFixed(1), style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 7)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // La gráfica
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              margin: EdgeInsets.zero,
              trackballBehavior: TrackballBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
                lineType: TrackballLineType.vertical,
                lineColor: pen.color.withValues(alpha: 0.7),
                lineWidth: 1,
                lineDashArray: const [4, 4],
                builder: (context, details) {
                  final idx = details.pointIndex ?? 0;
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  final t = data[idx];
                  final val = getValue(t, pen.id);
                  final ts = DateFormat('dd/MM/yyyy HH:mm:ss').format(t.timestamp);
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1628),
                      border: Border.all(color: pen.color.withValues(alpha: 0.6)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ts, style: const TextStyle(color: IndustrialTheme.neonCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: pen.color, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('${pen.label}: ', style: const TextStyle(color: Colors.white70, fontSize: 9)),
                          Text('${val.toStringAsFixed(3)} ${pen.unit}', style: TextStyle(color: pen.color, fontSize: 9, fontWeight: FontWeight.bold)),
                        ]),
                      ],
                    ),
                  );
                },
              ),
              primaryXAxis: DateTimeAxis(
                minimum: xMin,
                maximum: xMax,
                isVisible: false,
                majorGridLines: MajorGridLines(color: Colors.white.withValues(alpha: 0.03)),
              ),
              primaryYAxis: NumericAxis(
                minimum: vMin,
                maximum: vMax,
                isVisible: false,
                majorGridLines: MajorGridLines(color: Colors.white.withValues(alpha: 0.05), dashArray: const [4, 4]),
              ),
              series: [
                SplineSeries<Telemetria, DateTime>(
                  dataSource: data,
                  xValueMapper: (t, _) => t.timestamp,
                  yValueMapper: (t, _) => getValue(t, pen.id),
                  color: pen.color,
                  width: 2,
                  splineType: SplineType.natural,
                  animationDuration: 0,
                  markerSettings: MarkerSettings(
                    isVisible: data.length < 60,
                    width: 3,
                    height: 3,
                    shape: DataMarkerType.circle,
                    borderWidth: 1,
                    color: const Color(0xFF0A1628),
                    borderColor: pen.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Tabla de pens (PEN TABLE — estilo SCADA)
// ─────────────────────────────────────────────────────────────────
class _PenTable extends StatelessWidget {
  final List<_Pen> pens;
  final List<Telemetria> data;
  final double Function(Telemetria, String) getValue;
  const _PenTable({required this.pens, required this.data, required this.getValue});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Cabecera de la tabla
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                SizedBox(width: 12),
                SizedBox(width: 8),
                Expanded(flex: 3, child: Text('VARIABLE', style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 1))),
                Expanded(flex: 2, child: Text('ACTUAL', style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 7, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('MÍNIMO', style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 7, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('MÁXIMO', style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 7, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text('UD', style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 7, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 8),
          // Filas por pen
          ...pens.map((pen) {
            final values = data.map((t) => getValue(t, pen.id)).toList();
            final current = values.isNotEmpty ? values.last : 0.0;
            final minVal = values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : 0.0;
            final maxVal = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: pen.color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: Text(pen.label, style: TextStyle(color: pen.color, fontSize: 8, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text(current.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text(minVal.toStringAsFixed(2), style: const TextStyle(color: Colors.blueAccent, fontSize: 8), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text(maxVal.toStringAsFixed(2), style: const TextStyle(color: Colors.redAccent, fontSize: 8), textAlign: TextAlign.center)),
                  Expanded(flex: 1, child: Text(pen.unit, style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 8), textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Modelo interno de "pen" (variable de tendencia)
// ─────────────────────────────────────────────────────────────────
class _Pen {
  final String id;
  final String label;
  final String unit;
  final Color color;
  const _Pen({required this.id, required this.label, required this.unit, required this.color});
}
