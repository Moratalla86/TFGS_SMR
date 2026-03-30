import 'package:flutter/material.dart' hide SelectionDetails;
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/telemetria.dart';
import '../models/maquina.dart';
import '../theme/industrial_theme.dart';
import '../utils/metric_definitions.dart';
import 'package:intl/intl.dart';

class IndustrialChart extends StatelessWidget {
  final List<Telemetria> telemetria;
  final Maquina maquina;
  final bool isVirtual;

  const IndustrialChart({
    super.key,
    required this.telemetria,
    required this.maquina,
    this.isVirtual = false,
  });

  @override
  Widget build(BuildContext context) {
    final activas = maquina.sensoresConfigurados;

    return Container(
      height: 450,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        title: ChartTitle(
          text: isVirtual
              ? 'SIMULACIÓN ANALÍTICA GEMELO DIGITAL'
              : 'ANÁLISIS TEOLÓGICO DE PROCESOS',
          textStyle: const TextStyle(
            color: IndustrialTheme.slateGray,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        legend: const Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          textStyle: TextStyle(color: Colors.white70, fontSize: 9),
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        zoomPanBehavior: ZoomPanBehavior(
          enablePinching: true,
          enablePanning: true,
          enableDoubleTapZooming: true,
          zoomMode: ZoomMode.x,
        ),
        // Sustituimos Tooltip y Crosshair por Trackball Magnético (UX mejorada para Windows/Android)
        trackballBehavior: TrackballBehavior(
          enable: true,
          activationMode:
              ActivationMode.singleTap, // Reacciona al instante al tocar
          tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
          lineType: TrackballLineType.vertical,
          lineDashArray: const [5, 5],
          lineColor: IndustrialTheme.neonCyan.withOpacity(0.5),
          lineWidth: 1,
          tooltipSettings: const InteractiveTooltip(
            enable: true,
            color: IndustrialTheme.spaceCadet,
          ),
          builder: (BuildContext context, TrackballDetails details) {
            if (details.pointIndex == null ||
                details.pointIndex! < 0 ||
                details.pointIndex! >= telemetria.length) {
              return const SizedBox.shrink();
            }

            final Telemetria t = telemetria[details.pointIndex!];
            final String timeStr = DateFormat(
              'HH:mm:ss',
              'es_ES',
            ).format(t.timestamp);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: IndustrialTheme.spaceCadet,
                border: Border.all(
                  color: IndustrialTheme.neonCyan.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REGISTRO CRONOLÓGICO $timeStr',
                    style: const TextStyle(
                      color: IndustrialTheme.slateGray,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (activas.contains('temperatura'))
                    _tooltipRow(
                      'TEMP',
                      '${t.temperatura.toStringAsFixed(1)}°C',
                      IndustrialTheme.criticalRed,
                    ),
                  if (activas.contains('humedad'))
                    _tooltipRow(
                      'HUM',
                      '${t.humedad.toStringAsFixed(1)}%',
                      IndustrialTheme.electricBlue,
                    ),
                  ...activas
                      .where((id) => id != 'temperatura' && id != 'humedad')
                      .map((id) {
                        final def = MetricDefinition.getById(id);
                        final val = t.sensores[id] ?? 0.0;
                        return _tooltipRow(
                          def.label,
                          '${val.toStringAsFixed(1)}${def.unit}',
                          def.color,
                        );
                      }),
                ],
              ),
            );
          },
        ),
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat.Hms('es_ES'),
          labelStyle: const TextStyle(
            color: IndustrialTheme.slateGray,
            fontSize: 9,
          ),
          majorGridLines: const MajorGridLines(width: 0),
          edgeLabelPlacement: EdgeLabelPlacement.shift,
          intervalType: DateTimeIntervalType.auto,
          // Mantenemos el cartel inferior (Eje X) solicitado
          interactiveTooltip: const InteractiveTooltip(
            enable: true,
            color: IndustrialTheme.spaceCadet,
          ),
        ),
        primaryYAxis: NumericAxis(
          labelStyle: const TextStyle(
            color: IndustrialTheme.slateGray,
            fontSize: 9,
          ),
          axisLine: const AxisLine(width: 0),
          majorGridLines: MajorGridLines(
            color: Colors.white.withOpacity(0.05),
            dashArray: const [5, 5],
          ),
          // Desactivado cartel lateral
          interactiveTooltip: const InteractiveTooltip(enable: false),
        ),
        axes: <ChartAxis>[
          NumericAxis(
            name: 'highScaleAxis',
            opposedPosition: true,
            labelStyle: const TextStyle(
              color: IndustrialTheme.warningOrange,
              fontSize: 8,
            ),
            majorGridLines: const MajorGridLines(width: 0),
            title: AxisTitle(
              text: 'RPM / V',
              textStyle: const TextStyle(
                color: IndustrialTheme.slateGray,
                fontSize: 8,
              ),
            ),
            interactiveTooltip: const InteractiveTooltip(enable: false),
          ),
        ],
        series: _buildDynamicSeries(activas, telemetria),
      ),
    );
  }

  List<CartesianSeries<Telemetria, DateTime>> _buildDynamicSeries(
    List<String> activas,
    List<Telemetria> data,
  ) {
    List<CartesianSeries<Telemetria, DateTime>> list = [];

    for (String id in activas) {
      final def = MetricDefinition.getById(id);
      final isHighScale = id == 'rpm' || id == 'voltaje_fase';

      if (id == 'temperatura') {
        list.add(
          SplineAreaSeries<Telemetria, DateTime>(
            name: 'TEMP',
            dataSource: data,
            xValueMapper: (Telemetria t, _) => t.timestamp,
            yValueMapper: (Telemetria t, _) => t.temperatura,
            gradient: LinearGradient(
              colors: [
                IndustrialTheme.criticalRed.withOpacity(0.3),
                IndustrialTheme.criticalRed.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderColor: IndustrialTheme.criticalRed,
            borderWidth: 2,
            markerSettings: const MarkerSettings(
              isVisible: true,
              width: 2,
              height: 2,
            ),
          ),
        );
      } else {
        list.add(
          SplineSeries<Telemetria, DateTime>(
            name: def.label.toUpperCase(),
            dataSource: data,
            yAxisName: isHighScale ? 'highScaleAxis' : null,
            xValueMapper: (Telemetria t, _) => t.timestamp,
            yValueMapper: (Telemetria t, _) {
              if (id == 'humedad') return t.humedad;
              return t.sensores[id] ?? 0.0;
            },
            color: def.color,
            width: 2,
            markerSettings: const MarkerSettings(
              isVisible: true,
              width: 2,
              height: 2,
            ),
          ),
        );
      }
    }
    return list;
  }

  Widget _tooltipRow(String label, String val, Color col) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: col, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
