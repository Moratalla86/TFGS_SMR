import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/telemetria.dart';
import '../models/maquina.dart';
import '../models/metric_config.dart';

class MachineHistoryChart extends StatelessWidget {
  final List<Telemetria> telemetria;
  final Maquina? maquina;

  const MachineHistoryChart({
    super.key,
    required this.telemetria,
    this.maquina,
  });

  @override
  Widget build(BuildContext context) {
    if (telemetria.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Sin datos históricos")),
      );
    }

    // Buscar configuración de temperatura
    MetricConfig? tempConfig;
    if (maquina != null) {
      try {
        tempConfig = maquina!.configs.firstWhere((c) => c.nombreMetrica == 'temperatura');
      } catch (e) {
        debugPrint('MachineHistoryChart: config temperatura no encontrada: $e');
        tempConfig = null;
      }
    }

    // Ordenar por fecha ascendente para la gráfica
    final sortedData = List<Telemetria>.from(telemetria).reversed.toList();

    // Limitar a los últimos 20 puntos para que no se sature
    final displayData = sortedData.length > 20
        ? sortedData.sublist(sortedData.length - 20)
        : sortedData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            "HISTÓRICO DE TEMPERATURA (°C)",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          height: 250,
          padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= displayData.length) {
                        return const SizedBox();
                      }
                      if (index % 5 != 0) {
                        return const SizedBox(); // Mostrar cada 5 puntos
                      }

                      DateTime date = displayData[index].timestamp;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('HH:mm').format(date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 10,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        "${value.toInt()}°",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (displayData.length - 1).toDouble(),
              minY: 0,
              maxY: 60,
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (tempConfig?.limiteMA != null)
                    HorizontalLine(
                      y: tempConfig!.limiteMA!,
                      color: Colors.red[900]!,
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (line) => 'MA',
                      ),
                    ),
                  if (tempConfig?.limiteA != null)
                    HorizontalLine(
                      y: tempConfig!.limiteA!,
                      color: Colors.red,
                      strokeWidth: 1.5,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (line) => 'A',
                      ),
                    ),
                  if (tempConfig?.limiteB != null)
                    HorizontalLine(
                      y: tempConfig!.limiteB!,
                      color: Colors.blue,
                      strokeWidth: 1.5,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (line) => 'B',
                      ),
                    ),
                  if (tempConfig?.limiteMB != null)
                    HorizontalLine(
                      y: tempConfig!.limiteMB!,
                      color: Colors.blue[900]!,
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (line) => 'MB',
                      ),
                    ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: displayData.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.temperatura);
                  }).toList(),
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[300]!],
                  ),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[700]!.withOpacity(0.3),
                        Colors.blue[300]!.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueAccent.withOpacity(0.8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final data = displayData[spot.x.toInt()];
                      final motorStr = data.motorOn ? "ENCENDIDO" : "PARADO";
                      return LineTooltipItem(
                        "${spot.y}°C\n$motorStr",
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildLegendItem("Temperatura", Colors.blue),
            const SizedBox(width: 20),
            _buildLegendItem("Estado Motor", Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
