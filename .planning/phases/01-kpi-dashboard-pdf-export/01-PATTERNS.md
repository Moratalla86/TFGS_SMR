# Phase 1: KPI Dashboard + PDF Export — Pattern Map

**Mapped:** 2026-04-19
**Files analyzed:** 6 (5 modify, 1 new)
**Analogs found:** 6 / 6

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/screens/dashboard_screen.dart` | screen / StatefulWidget | request-response + timer polling | itself (modify in place) | exact |
| `lib/screens/kpis_screen.dart` | screen / StatefulWidget | request-response | itself (modify in place) | exact |
| `lib/screens/ordenes_screen.dart` | screen / StatefulWidget | CRUD + file-I/O | itself (modify in place) | exact |
| `lib/utils/pdf_generator.dart` | utility | file-I/O | itself (modify in place) | exact |
| `lib/services/plc_service.dart` | service | request-response | `lib/services/telemetria_service.dart` | exact role+flow |
| `lib/widgets/sala_servidores_widget.dart` | widget / StatefulWidget | event-driven (timer polling) | `lib/services/telemetria_service.dart` + `dashboard_screen.dart` timer pattern | role-match |

---

## Pattern Assignments

---

### `lib/screens/dashboard_screen.dart` (screen, request-response + timer)

**Analog:** itself — read in full above.

**Insertion point in body** (lines 228–250 of dashboard_screen.dart):

The new KPI operational section goes between the existing second KPI row and the `SizedBox(height: 30)` spacer that precedes "INCIDENCIAS ACTIVAS":

```dart
// After existing row 2 (lines 243–249):
Row(
  children: [
    _buildKpiCard("TOTAL TAREAS", ...),
    const SizedBox(width: 12),
    _buildKpiCard("OT PENDIENTES", ...),
  ],
),
// INSERT HERE:
// SizedBox(height: 20),
// _buildSectionHeader("KPIs OPERACIONALES"),  ← new helper
// SizedBox(height: 12),
// if (_kpiStats != null) ...[
//   Row([_buildKpiCard("OEE", ...), SizedBox(width:12), _buildKpiCard("MTBF", ...)]),
//   SizedBox(height: 12),
//   Row([_buildKpiCard("MTTR", ...), SizedBox(width:12), _buildKpiCard("DISPONIB.", ...)]),
// ],
// SizedBox(height: 20),
// _buildSectionHeader("SALA DE SERVIDORES"),
// SizedBox(height: 12),
// SalaServidoresWidget(),
// THEN existing SizedBox(height: 30) + INCIDENCIAS ACTIVAS section
```

**Existing `_buildKpiCard` pattern to reuse verbatim** (lines 457–500):

```dart
Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
  ).animate().scale(duration: 400.ms, curve: Curves.easeOut);  // keep this
}
```

**Section header pattern** (lines 262–264 — existing inline usage to convert into helper):

```dart
// Existing inline style (INCIDENCIAS ACTIVAS header, line 256):
Row(children: [
  Icon(Icons.sensors_off, color: IndustrialTheme.criticalRed, size: 20),
  const SizedBox(width: 8),
  const Text("INCIDENCIAS ACTIVAS",
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
          letterSpacing: 1.1, color: Colors.white70)),
]),
// For KPI sections use same Text style, no icon:
const Text("KPIs OPERACIONALES",
    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
        letterSpacing: 1.1, color: Colors.white70)),
```

**New state fields to add to `_DashboardScreenState`:**

```dart
Map<String, dynamic>? _kpiStats;
// (no StatsService instance needed in timer — load once)
```

**New stats load — add to `_loadMaquinas()` initial load only** (after line 60, guarded by `!quiet`):

```dart
// In _loadMaquinas(), inside the try block, after fetching maquinas+ots:
if (!quiet && _kpiStats == null) {
  // Only load KPI stats once — not on every 5-second refresh
  try {
    final stats = await StatsService().fetchDashboardStats();
    if (mounted) setState(() { _kpiStats = stats; });
  } catch (_) {
    // KPI stats failure is non-fatal — dashboard still shows operational data
  }
}
```

**New import to add** (top of dashboard_screen.dart):

```dart
import '../services/stats_service.dart';
import '../widgets/sala_servidores_widget.dart';  // NEW file
```

**Color threshold helpers to add** (mirror KpisScreen — see kpis_screen.dart lines 466–473):

```dart
// Use same logical thresholds as KpisScreen but DIFFERENT boundary values per UI-SPEC:
Color _oeeColor(double v)  => v >= 85 ? IndustrialTheme.operativeGreen
    : v >= 65 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;
Color _mtbfColor(double v) => v >= 48 ? IndustrialTheme.operativeGreen
    : v >= 24 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;
Color _mttrColor(double v) => v <= 2 ? IndustrialTheme.operativeGreen
    : v <= 4 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;
Color _dispColor(double v) => v >= 90 ? IndustrialTheme.operativeGreen
    : v >= 75 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;
// NOTE: KpisScreen has different thresholds (75/50, 100/50, 4/8, 85/70).
// DashboardScreen uses the stricter thresholds from UI-SPEC.
```

**KPI card call pattern** (how to call `_buildKpiCard` for stats values):

```dart
// Stats data extraction (mirror kpis_screen.dart lines 75–78):
final double oee  = (_kpiStats!['oeeGlobal']        as num?)?.toDouble() ?? 0;
final double mtbf = (_kpiStats!['mtbfHoras']         as num?)?.toDouble() ?? 0;
final double mttr = (_kpiStats!['mttrHoras']         as num?)?.toDouble() ?? 0;
final double disp = (_kpiStats!['disponibilidadPct'] as num?)?.toDouble() ?? 0;

// Card calls with subtitle — note: existing _buildKpiCard has no subtitle param.
// Either: (a) add optional subtitle param to _buildKpiCard, or
//         (b) use KpisScreen's _kpiCard pattern (has subtitle) as a new private method.
// RECOMMEND (b): add _buildOperationalKpiCard(label, value, subtitle, icon, color)
// that mirrors kpis_screen.dart _kpiCard (lines 148–180) verbatim.
```

---

### `lib/screens/kpis_screen.dart` (screen, request-response)

**Analog:** itself — read in full above.

**Change 1: Replace `_buildEvolucionChart` with fl_chart BarChart**

The existing hand-rolled chart is at lines 301–369. The Container wrapper (lines 324–368) stays; only the internal `SizedBox(...Row(...evolucion.map(...)))` block (lines 332–361) is replaced with a `SizedBox(height: 160, child: BarChart(...))`.

**New import to add:**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show max;
```

**Empty guard — keep existing pattern** (lines 302–312):

```dart
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
```

**New BarChart body** (replaces lines 332–361 inside the existing Container.child Column):

```dart
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
            BarChartRodData(
              toY: (m['correctivo'] as num?)?.toDouble() ?? 0,
              color: IndustrialTheme.criticalRed,
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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
```

**Legend rows to keep unchanged** (lines 362–367):

```dart
const SizedBox(height: 10),
Row(mainAxisAlignment: MainAxisAlignment.center, children: [
  _legend(IndustrialTheme.operativeGreen, 'PREVENTIVO'),
  const SizedBox(width: 20),
  _legend(IndustrialTheme.criticalRed, 'CORRECTIVO'),
]),
```

**Change 2: Add "EXPORTAR PDF" button to AppBar actions**

Existing AppBar actions (lines 41–46):

```dart
actions: [
  IconButton(
    icon: const Icon(Icons.refresh, color: IndustrialTheme.neonCyan),
    onPressed: _load,
  ),
],
```

Replace with:

```dart
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
```

**New `_exportarPdf()` method** (add to `_KpisScreenState`):

```dart
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
```

**New import to add:**

```dart
import '../utils/pdf_generator.dart';
```

---

### `lib/screens/ordenes_screen.dart` (screen, CRUD + file-I/O)

**Analog:** itself — read in full above.

**Existing AppBar** (lines 234–241):

```dart
appBar: AppBar(
  title: const Text(
    'GESTIÓN DE ÓRDENES (OT)',
    style: TextStyle(letterSpacing: 2, fontSize: 16),
  ),
  centerTitle: false,
  actions: [IconButton(icon: const Icon(Icons.sync), onPressed: _load)],
),
```

**Replace `actions` with:**

```dart
actions: [
  IconButton(
    icon: const Icon(Icons.picture_as_pdf, color: IndustrialTheme.neonCyan),
    tooltip: 'Exportar lista de OTs a PDF',
    onPressed: _ordenes.isEmpty ? null : () => _exportarListaOts(),
  ),
  IconButton(icon: const Icon(Icons.sync), onPressed: _load),
],
```

**New `_exportarListaOts()` method** — mirror `_verReportePdf` pattern (lines 111–133):

```dart
Future<void> _exportarListaOts() async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
          'Generando PDF con ${_ordenes.length} órdenes de trabajo...'),
      duration: const Duration(seconds: 2),
    ),
  );
  try {
    await PdfGenerator.generarListaOtsPdf(_ordenes);
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
```

**Existing error SnackBar pattern** (lines 174–179) — copy exactly for error case:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('...'),
    backgroundColor: IndustrialTheme.criticalRed,
  ),
);
```

**Note:** The bulk export uses `_ordenes` (the full unfiltered list), not `_filteredOrdenes`. This matches the UI-SPEC requirement ("all currently loaded OTs"). The `_ordenes` field is populated at line 61.

---

### `lib/utils/pdf_generator.dart` (utility, file-I/O)

**Analog:** itself — read in full above.

**Existing pattern for `viewLocalPdf`** (lines 361–371) — both new methods must end with this:

```dart
await Printing.layoutPdf(
  onLayout: (PdfPageFormat format) async => bytes,
  name: 'filename.pdf',
);
```

**Existing `pw.Document()` + `pdf.addPage(pw.MultiPage(...))` + `await pdf.save()` skeleton** (lines 19, 71–73, 353):

```dart
final pdf = pw.Document();
pdf.addPage(
  pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    build: (context) => [ /* list of pw.Widget */ ],
  ),
);
final bytes = await pdf.save();
```

**New method 1: `generarKpiPdf`** — add as static method after `generarYVerPdf`:

```dart
static Future<void> generarKpiPdf(Map<String, dynamic> stats) async {
  final pdf = pw.Document();

  final double oee  = (stats['oeeGlobal']        as num?)?.toDouble() ?? 0;
  final double mtbf = (stats['mtbfHoras']         as num?)?.toDouble() ?? 0;
  final double mttr = (stats['mttrHoras']         as num?)?.toDouble() ?? 0;
  final double disp = (stats['disponibilidadPct'] as num?)?.toDouble() ?? 0;
  final Map<String, dynamic> ratio =
      (stats['ratioPreventivoCorrectivo'] as Map?)?.cast() ?? {};
  final Map<String, dynamic> porEstado =
      (stats['otsPorEstado'] as Map?)?.cast() ?? {};
  final List<dynamic> ranking = stats['rankingIncidencias'] as List? ?? [];
  final List<dynamic> evolucion = stats['evolucionMensual'] as List? ?? [];

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        // 1. Header
        pw.Text('INFORME KPI — MÈLTIC GMAO',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
            'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.Divider(height: 16, color: PdfColors.grey400),
        pw.SizedBox(height: 8),

        // 2. KPI values table
        pw.TableHelper.fromTextArray(
          headers: ['KPI', 'VALOR', 'DESCRIPCIÓN'],
          data: [
            ['OEE', '${oee.toStringAsFixed(1)}%', 'Eficiencia Global Equipos'],
            ['MTBF', '${mtbf.toStringAsFixed(1)}h', 'Tiempo Medio Entre Fallos'],
            ['MTTR', '${mttr.toStringAsFixed(1)}h', 'Tiempo Medio de Reparación'],
            ['DISPONIBILIDAD', '${disp.toStringAsFixed(1)}%', 'Disponibilidad de Planta'],
          ],
          headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 16),

        // 3. Distribución
        pw.Text('DISTRIBUCIÓN DE MANTENIMIENTO',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['TIPO', 'CANTIDAD', 'PORCENTAJE'],
          data: () {
            final int prev = (ratio['preventivas'] as num?)?.toInt() ?? 0;
            final int corr = (ratio['correctivas'] as num?)?.toInt() ?? 0;
            final int tot = prev + corr;
            return [
              ['PREVENTIVAS', '$prev',
                  tot > 0 ? '${(prev / tot * 100).toStringAsFixed(1)}%' : '-'],
              ['CORRECTIVAS', '$corr',
                  tot > 0 ? '${(corr / tot * 100).toStringAsFixed(1)}%' : '-'],
            ];
          }(),
          headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 16),

        // 4. OTs por estado
        pw.Text('ÓRDENES POR ESTADO',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['ESTADO', 'CANTIDAD', 'PORCENTAJE'],
          data: () {
            final int cerr = (porEstado['CERRADA']    as num?)?.toInt() ?? 0;
            final int enPr = (porEstado['EN_PROCESO'] as num?)?.toInt() ?? 0;
            final int pend = (porEstado['PENDIENTE']  as num?)?.toInt() ?? 0;
            final int tot = cerr + enPr + pend;
            return [
              ['CERRADA', '$cerr',
                  tot > 0 ? '${(cerr / tot * 100).toStringAsFixed(1)}%' : '-'],
              ['EN PROCESO', '$enPr',
                  tot > 0 ? '${(enPr / tot * 100).toStringAsFixed(1)}%' : '-'],
              ['PENDIENTE', '$pend',
                  tot > 0 ? '${(pend / tot * 100).toStringAsFixed(1)}%' : '-'],
            ];
          }(),
          headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 16),

        // 5. Evolución mensual
        pw.Text('EVOLUCIÓN MENSUAL',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['MES', 'PREVENTIVAS', 'CORRECTIVAS', 'TOTAL'],
          data: evolucion.map((m) {
            final int p = (m['preventivo'] as num?)?.toInt() ?? 0;
            final int c = (m['correctivo'] as num?)?.toInt() ?? 0;
            return [m['mes']?.toString() ?? '-', '$p', '$c', '${p + c}'];
          }).toList(),
          headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 16),

        // 6. Ranking
        pw.Text('RANKING DE INCIDENCIAS',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['#', 'MÁQUINA', 'INCIDENCIAS'],
          data: ranking.asMap().entries.take(5).map((e) => [
            '${e.key + 1}',
            e.value['maquina']?.toString() ?? '-',
            '${(e.value['incidencias'] as num?)?.toInt() ?? 0}',
          ]).toList(),
          headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 9),
        ),
      ],
    ),
  );

  final bytes = await pdf.save();
  final fileName =
      'KPI_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => bytes,
    name: fileName,
  );
}
```

**New method 2: `generarListaOtsPdf`** — add after `generarKpiPdf`:

```dart
static Future<void> generarListaOtsPdf(List<OrdenTrabajo> ordenes) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        pw.Text('LISTADO DE ÓRDENES DE TRABAJO',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
            'Total: ${ordenes.length} OTs  ·  '
            'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['#', 'MÁQUINA', 'TÉCNICO', 'TIPO', 'ESTADO', 'PRIORIDAD', 'FECHA'],
          data: ordenes.map((ot) => [
            ot.id.toString(),
            ot.maquinaNombre ?? '-',
            ot.tecnicoNombre ?? '-',
            ot.tipo ?? '-',
            ot.estado,
            ot.prioridad,
            ot.fechaCreacion != null
                ? DateFormat('dd/MM/yy').format(DateTime.parse(ot.fechaCreacion!))
                : '-',
          ]).toList(),
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          columnWidths: {
            0: const pw.FixedColumnWidth(25),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FixedColumnWidth(60),
            4: const pw.FixedColumnWidth(55),
            5: const pw.FixedColumnWidth(50),
            6: const pw.FixedColumnWidth(50),
          },
        ),
      ],
    ),
  );
  final bytes = await pdf.save();
  final fileName =
      'OTs_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => bytes,
    name: fileName,
  );
}
```

---

### `lib/services/plc_service.dart` (service, request-response)

**Analog:** `lib/services/telemetria_service.dart` — exact same endpoint, same auth pattern.

**Existing PLCService** (lines 1–23) — only has `enviarComando`. Add `fetchLastTelemetry`:

**Existing imports to keep:**

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
```

**New import to add:**

```dart
import 'app_session.dart';
import '../models/telemetria.dart';
```

**New `fetchLastTelemetry` method** — mirror `TelemetriaService.fetchPorMaquina` (telemetria_service.dart lines 10–20) exactly:

```dart
/// Devuelve el último registro de telemetría para una máquina.
/// Usa el mismo endpoint que TelemetriaService.fetchPorMaquina() —
/// GET /api/plc/maquina/{maquinaId} — y toma el último elemento de la lista.
/// Si la respuesta está vacía, devuelve null (sin lanzar excepción).
static Future<Telemetria?> fetchLastTelemetry(int maquinaId) async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/plc/maquina/$maquinaId'),
      headers: AppSession.instance.authHeaders,
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      if (body.isEmpty) return null;
      return Telemetria.fromJson(body.last as Map<String, dynamic>);
    }
    return null;
  } catch (e) {
    debugPrint('PLCService.fetchLastTelemetry error: $e');
    return null;
  }
}
```

**Note:** The method is `static` to match the existing `enviarComando` pattern. The `SalaServidoresWidget` calls `PLCService.fetchLastTelemetry(1)` without instantiating the service.

---

### `lib/widgets/sala_servidores_widget.dart` (NEW — widget, event-driven timer polling)

**Analogs:**
- Timer lifecycle pattern: `dashboard_screen.dart` lines 29–45 (`Timer? _refreshTimer`, `initState`, `dispose`)
- HTTP poll pattern: `telemetria_service.dart` lines 10–20
- Widget structure: `_buildKpiCard` in `dashboard_screen.dart` lines 457–500
- Mounted guard: `kpis_screen.dart` lines 29–30 (`if (mounted) setState(...)`)

**Full file pattern** (new file — no existing content):

```dart
import 'dart:async';
import 'dart:convert';  // only if not using PLCService
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/plc_service.dart';
import '../models/telemetria.dart';
import '../theme/industrial_theme.dart';

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

  // Mirror DashboardScreen initState timer pattern (dashboard_screen.dart lines 33-39):
  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  // Mirror DashboardScreen dispose pattern (dashboard_screen.dart lines 42-45):
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Mirror TelemetriaService.fetchPorMaquina call + mounted guard (kpis_screen.dart lines 29-30):
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
          // Keep stale values — do not null them out
        }
      });
    }
  }

  // Temperature color thresholds (per UI-SPEC Surface 3):
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
              color: IndustrialTheme.neonCyan, strokeWidth: 2),
        ),
      );
    }

    // Main widget — mirror _buildKpiCard container structure (dashboard_screen.dart lines 459-499):
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: EN VIVO badge + live dot
          Row(children: [
            const Icon(Icons.sensors, color: IndustrialTheme.neonCyan, size: 18),
            const SizedBox(width: 8),
            const Text('EN VIVO',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: IndustrialTheme.neonCyan,
                    letterSpacing: 1)),
            const Spacer(),
            _LiveDot(live: _live),
          ]),
          const SizedBox(height: 16),
          // Sensor cards row — mirror _buildKpiCard Expanded pattern:
          Row(children: [
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
          ]),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}

// Sub-widget: mirrors _buildKpiCard body (dashboard_screen.dart lines 459-499)
// but uses Expanded directly (parent Row supplies the flex context):
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1)),
        ]),
      ),
    );
  }
}

// Sub-widget: pulsing live dot
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
    // Pulsing animation when live (UI-SPEC Animation Contract):
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
```

---

## Shared Patterns

### Auth Headers
**Source:** `lib/services/app_session.dart` lines 77–83
**Apply to:** `PLCService.fetchLastTelemetry`, `SalaServidoresWidget._poll` (via PLCService)
```dart
Map<String, String> get authHeaders {
  final headers = {"Content-Type": "application/json"};
  if (authToken != null) {
    headers["Authorization"] = "Bearer $authToken";
  }
  return headers;
}
// Usage: headers: AppSession.instance.authHeaders
```

### Mounted Guard for setState
**Source:** `kpis_screen.dart` lines 29–30, `dashboard_screen.dart` lines 64–70
**Apply to:** All `setState` calls inside `async` methods in `SalaServidoresWidget` and `DashboardScreen`
```dart
if (mounted) setState(() { /* update fields */ });
```

### Timer Lifecycle (StatefulWidget)
**Source:** `dashboard_screen.dart` lines 29–45
**Apply to:** `SalaServidoresWidget`
```dart
Timer? _refreshTimer;

@override
void initState() {
  super.initState();
  _load();
  _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
    if (mounted) _load(quiet: true);
  });
}

@override
void dispose() {
  _refreshTimer?.cancel();
  super.dispose();
}
```

### SnackBar Feedback (success + error)
**Source:** `ordenes_screen.dart` lines 127–133 (info), lines 174–179 (error)
**Apply to:** `KpisScreen._exportarPdf()`, `OrdenesScreen._exportarListaOts()`
```dart
// Info snackbar:
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Generando PDF...'), duration: Duration(seconds: 2)),
);

// Error snackbar:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('...'),
    backgroundColor: IndustrialTheme.criticalRed,
  ),
);
```

### Error State Widget (full-screen)
**Source:** `kpis_screen.dart` lines 56–71
**Apply to:** KpisScreen (already has it — do not modify)
```dart
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
```

### Stats Data Parsing
**Source:** `kpis_screen.dart` lines 75–82
**Apply to:** `DashboardScreen` (when extracting values from `_kpiStats`), `PdfGenerator.generarKpiPdf`
```dart
final double oee  = (s['oeeGlobal']        as num?)?.toDouble() ?? 0;
final double mtbf = (s['mtbfHoras']         as num?)?.toDouble() ?? 0;
final double mttr = (s['mttrHoras']         as num?)?.toDouble() ?? 0;
final double disp = (s['disponibilidadPct'] as num?)?.toDouble() ?? 0;
final Map<String, dynamic> ratio     = (s['ratioPreventivoCorrectivo'] as Map?)?.cast() ?? {};
final Map<String, dynamic> porEstado = (s['otsPorEstado'] as Map?)?.cast() ?? {};
final List<dynamic> ranking   = s['rankingIncidencias'] as List? ?? [];
final List<dynamic> evolucion = s['evolucionMensual']   as List? ?? [];
```

### Telemetria Timestamp
**Source:** `lib/models/telemetria.dart` lines 98–119
**Apply to:** `PLCService.fetchLastTelemetry` (uses `Telemetria.fromJson` which handles both `timestampMillis` int and `timestamp` ISO string automatically — no manual parsing needed in the widget)
```dart
// Telemetria.fromJson already calls _parseDateTime which tries:
// 1. json['timestampMillis'] as epoch millis
// 2. json['timestamp'] as ISO string
// SalaServidoresWidget accesses: t.temperatura, t.humedad, t.timestamp directly.
```

### PDF Delivery (cross-platform)
**Source:** `pdf_generator.dart` lines 362–370
**Apply to:** Both new PdfGenerator methods
```dart
final bytes = await pdf.save();
await Printing.layoutPdf(
  onLayout: (PdfPageFormat format) async => bytes,
  name: 'fileName.pdf',
);
```

---

## No Analog Found

All 6 files have close analogs. No files require falling back to external documentation patterns.

| File | Status |
|------|--------|
| `sala_servidores_widget.dart` | Composed from 3 existing patterns (timer, http poll, card widget) — no single file analog, but fully covered by shared patterns above |

---

## Critical Warnings for Planner

1. **`_buildKpiCard` has no subtitle param** — KpisScreen's `_kpiCard` (lines 148–180) does have a subtitle. For DashboardScreen, either add an optional `subtitle` param to `_buildKpiCard`, or copy the `_kpiCard` pattern as a new private method `_buildOperationalKpiCard`. Do not change the existing `_buildKpiCard` signature in a way that breaks the existing 4 operational cards.

2. **Color thresholds differ between screens** — KpisScreen thresholds (lines 466–473) are softer than UI-SPEC thresholds for DashboardScreen. Do not copy KpisScreen color helpers verbatim for DashboardScreen; use the values from UI-SPEC Surface 1 threshold table.

3. **`_ordenes` vs `_filteredOrdenes`** — Bulk PDF export uses `_ordenes` (full list), not `_filteredOrdenes`. The variable is already declared at line 28.

4. **fl_chart `BarChart` crashes on empty list** — The existing empty guard in `_buildEvolucionChart` (lines 302–312) must be retained before constructing `BarChartData`. Never pass an empty `barGroups` list.

5. **PLCService `enviarComando` is static** — New `fetchLastTelemetry` must also be `static` to match the class pattern and allow `PLCService.fetchLastTelemetry(1)` call without instantiation.

6. **`TelemetriaService` already exists** — Do NOT use `TelemetriaService` in `SalaServidoresWidget`. Add the method to `PLCService` to keep PLC-related calls in the PLC service. `TelemetriaService` is used by the machine detail/history screens.

---

## Metadata

**Analog search scope:** `lib/screens/`, `lib/services/`, `lib/utils/`, `lib/widgets/`, `lib/models/`
**Files scanned:** 10 (dashboard_screen, kpis_screen, ordenes_screen, pdf_generator, plc_service, telemetria_service, stats_service, app_session, api_config, telemetria model)
**Pattern extraction date:** 2026-04-19
