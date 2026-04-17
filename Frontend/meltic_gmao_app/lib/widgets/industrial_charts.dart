import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/industrial_theme.dart';

class IndustrialGauge extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String label;
  final String subLabel;
  final Color color;
  final double height;
  final double width;
  final double fontSize;

  const IndustrialGauge({
    super.key,
    required this.value,
    required this.label,
    this.subLabel = "",
    this.color = IndustrialTheme.operativeGreen,
    this.height = 100,
    this.width = 160,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: width,
          child: CustomPaint(
            painter: _DialPainter(value: value, color: color),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   Text(
                    "${(value * 100).toInt()}%",
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (subLabel.isNotEmpty)
                    Text(
                      subLabel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: IndustrialTheme.slateGray,
                      ),
                    ),
                  SizedBox(height: height * 0.1),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _DialPainter extends CustomPainter {
  final double value;
  final Color color;
  _DialPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2.2;
    final strokeWidth = size.width * 0.08;

    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * value.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class IndustrialAreaChart extends StatelessWidget {
  final List<String> labels;
  final List<num> correctiveData;
  final List<num> preventiveData;
  final double height;

  const IndustrialAreaChart({
    super.key,
    required this.labels,
    required this.correctiveData,
    required this.preventiveData,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _AreaChartPainter(
                labels: labels,
                corrective: correctiveData.map((e) => e.toDouble()).toList(),
                preventive: preventiveData.map((e) => e.toDouble()).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: IndustrialTheme.criticalRed, label: "CORR."),
              const SizedBox(width: 12),
              _LegendItem(color: IndustrialTheme.operativeGreen, label: "PREV."),
            ],
          ),
        ],
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> corrective;
  final List<double> preventive;

  _AreaChartPainter({
    required this.labels,
    required this.corrective,
    required this.preventive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (labels.isEmpty) return;

    final double maxVal = [...corrective, ...preventive].reduce(math.max);
    final double stepX = size.width / (labels.length - 1);
    final double scaleY = size.height / (maxVal == 0 ? 1 : maxVal * 1.3);

    _drawGrid(canvas, size);

    _drawSmoothArea(canvas, size, preventive, stepX, scaleY, IndustrialTheme.operativeGreen);
    _drawSmoothArea(canvas, size, corrective, stepX, scaleY, IndustrialTheme.criticalRed);

    _drawLabels(canvas, size, stepX);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05)..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
        double y = size.height - (size.height / 3) * i;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawSmoothArea(Canvas canvas, Size size, List<double> data, double stepX, double scaleY, Color color) {
    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      points.add(Offset(i * stepX, size.height - (data[i] * scaleY)));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    final linePaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)]).createShader(Rect.fromLTRB(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final dotPaint = Paint()..color = color;
    for (var p in points) {
        canvas.drawCircle(p, 3, dotPaint);
    }
  }

  void _drawLabels(Canvas canvas, Size size, double stepX) {
    for (int i = 0; i < labels.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(text: labels[i], style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 8, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(i * stepX - (textPainter.width / 2), size.height + 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class IndustrialDonutChart extends StatelessWidget {
  final double preventiveValue; // 0.0 to 1.0
  final String label;
  final double height;
  final double width;

  const IndustrialDonutChart({
    super.key,
    required this.preventiveValue,
    required this.label,
    this.height = 160,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: width,
          child: CustomPaint(
            painter: _DonutPainter(preventiveValue: preventiveValue),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${(preventiveValue * 100).toInt()}%",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "PREVENTIVO",
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: IndustrialTheme.operativeGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: IndustrialTheme.slateGray,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double preventiveValue;
  _DonutPainter({required this.preventiveValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.2;
    final strokeWidth = size.width * 0.12;

    // Fondo / Correctivo (Rojo)
    final correctivePaint = Paint()
      ..color = IndustrialTheme.criticalRed.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      correctivePaint,
    );

    // Progreso / Preventivo (Verde)
    final preventivePaint = Paint()
      ..color = IndustrialTheme.operativeGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * preventiveValue.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      preventivePaint,
    );
    
    // Sombra interior sutil
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, radius + (strokeWidth / 2), shadowPaint);
    canvas.drawCircle(center, radius - (strokeWidth / 2), shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class IndustrialBarChart extends StatelessWidget {
  final List<String> labels;
  final List<num> correctiveData;
  final List<num> preventiveData;
  final double height;

  const IndustrialBarChart({
    super.key,
    required this.labels,
    required this.correctiveData,
    required this.preventiveData,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarChartPainter(
                labels: labels,
                corrective: correctiveData.map((e) => e.toDouble()).toList(),
                preventive: preventiveData.map((e) => e.toDouble()).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: IndustrialTheme.criticalRed, label: "CORRECTIVO"),
              const SizedBox(width: 20),
              _LegendItem(color: IndustrialTheme.operativeGreen, label: "PREVENTIVO"),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> corrective;
  final List<double> preventive;

  _BarChartPainter({
    required this.labels,
    required this.corrective,
    required this.preventive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (labels.isEmpty) return;

    final combined = [...corrective, ...preventive];
    final double maxVal = combined.isEmpty ? 0 : combined.reduce(math.max);
    final double stepX = size.width / labels.length;
    final double chartMax = maxVal == 0 ? 10 : maxVal * 1.2;
    final double scaleY = size.height / chartMax;

    _drawGrid(canvas, size, chartMax);

    final double barWidth = stepX * 0.35;
    for (int i = 0; i < labels.length; i++) {
        final double centerX = i * stepX + (stepX / 2);
        
        // Barra Preventiva (Verde)
        final pHeight = preventive[i] * scaleY;
        canvas.drawRRect(
            RRect.fromLTRBR(centerX + 2, size.height - pHeight, centerX + barWidth + 2, size.height, const Radius.circular(4)),
            Paint()..color = IndustrialTheme.operativeGreen
        );

        // Barra Correctiva (Roja)
        final cHeight = corrective[i] * scaleY;
        canvas.drawRRect(
            RRect.fromLTRBR(centerX - barWidth - 2, size.height - cHeight, centerX - 2, size.height, const Radius.circular(4)),
            Paint()..color = IndustrialTheme.criticalRed
        );
    }

    _drawLabels(canvas, size, stepX);
  }

  void _drawGrid(Canvas canvas, Size size, double chartMax) {
    final linePaint = Paint()..color = Colors.white.withValues(alpha: 0.05)..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 4; i++) {
        double y = size.height - (size.height / 4) * i;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

        // Etiquetas Y
        final val = (chartMax / 4) * i;
        textPainter.text = TextSpan(text: val.toInt().toString(), style: const TextStyle(color: Colors.white24, fontSize: 8));
        textPainter.layout();
        textPainter.paint(canvas, Offset(-12, y - (textPainter.height / 2)));
    }
  }

  void _drawLabels(Canvas canvas, Size size, double stepX) {
    for (int i = 0; i < labels.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(text: labels[i], style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 9, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(i * stepX + (stepX / 2) - (textPainter.width / 2), size.height + 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class IndustrialComparisonCard extends StatelessWidget {
  final num preventive;
  final num corrective;
  final String title;
  final double height;

  const IndustrialComparisonCard({
    super.key,
    required this.preventive,
    required this.corrective,
    required this.title,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final total = preventive + corrective;
    final pPct = (total == 0 || total.isNaN) ? 0.0 : (preventive / total).toDouble();
    final cPct = (total == 0 || total.isNaN) ? 0.0 : (corrective / total).toDouble();

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _ComparisonRow(label: "PREVENTIVO", value: preventive, percent: pPct, color: IndustrialTheme.operativeGreen),
          const SizedBox(height: 12),
          _ComparisonRow(label: "CORRECTIVO", value: corrective, percent: cPct, color: IndustrialTheme.criticalRed),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: IndustrialTheme.operativeGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(
              "OBJETIVO: > 80%",
              style: TextStyle(color: IndustrialTheme.operativeGreen.withValues(alpha: 0.7), fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final num value;
  final double percent;
  final Color color;

  const _ComparisonRow({required this.label, required this.value, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
            Text("$value", style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(height: 6, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3))),
            FractionallySizedBox(
              widthFactor: percent.clamp(0.01, 1.0),
              child: Container(height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
