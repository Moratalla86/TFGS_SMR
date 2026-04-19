---
phase: 1
plan: D
type: execute
wave: 2
depends_on:
  - plan-B
files_modified:
  - Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart
autonomous: true
requirements:
  - KPI-02
  - KPI-03
  - KPI-04
  - KPI-06
must_haves:
  truths:
    - "KpisScreen bar chart uses fl_chart BarChart with grouped bars (preventivo=operativeGreen, correctivo=criticalRed) replacing the hand-rolled custom chart"
    - "Bar chart is guarded against empty evolucionMensual list — shows SIN DATOS container instead of crashing"
    - "KpisScreen AppBar has an ElevatedButton.icon EXPORTAR PDF to the left of the refresh button"
    - "EXPORTAR PDF button is disabled (onPressed: null) while stats are loading"
    - "Tapping EXPORTAR PDF shows a SnackBar 'Generando PDF...' and calls PdfGenerator.generarKpiPdf(_stats!)"
    - "KPI-02 and KPI-04 are verified present (no code change needed)"
  artifacts:
    - path: "Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart"
      provides: "fl_chart BarChart + PDF export button"
      contains: "BarChart("
  key_links:
    - from: "KpisScreen AppBar actions"
      to: "PdfGenerator.generarKpiPdf(_stats!)"
      via: "_exportarPdf() method"
      pattern: "PdfGenerator\\.generarKpiPdf"
    - from: "_buildEvolucionChart"
      to: "BarChart(BarChartData(...))"
      via: "replacement of hand-rolled chart"
      pattern: "BarChart\\(BarChartData"
---

<objective>
Replace KpisScreen's hand-rolled bar chart with fl_chart BarChart and add the PDF export button.

Purpose: Deliver KPI-03 (professional bar chart) and KPI-06 (PDF export from KpisScreen). Also verify KPI-02 (drawer already wired) and KPI-04 (existing OT metrics sections already complete).

Depends on: Plan B must be complete (PdfGenerator.generarKpiPdf must exist before this plan calls it).

Output: Modified `kpis_screen.dart` with fl_chart BarChart and EXPORTAR PDF button in AppBar.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/phases/01-kpi-dashboard-pdf-export/01-RESEARCH.md
@.planning/phases/01-kpi-dashboard-pdf-export/01-PATTERNS.md
@.planning/phases/01-kpi-dashboard-pdf-export/01-UI-SPEC.md
@.planning/phases/01-kpi-dashboard-pdf-export/01-B-SUMMARY.md

<interfaces>
<!-- Key types and contracts the executor needs. Extracted from PATTERNS.md. -->

From lib/screens/kpis_screen.dart (EXISTING — key sections):
```dart
// EXISTING AppBar actions (lines 41–46) — REPLACE:
actions: [
  IconButton(
    icon: const Icon(Icons.refresh, color: IndustrialTheme.neonCyan),
    onPressed: _load,
  ),
],

// EXISTING _buildEvolucionChart() structure (lines 301–369):
// Container wrapper (lines 324–331) — KEEP unchanged
// SizedBox containing the old chart bars (lines 332–361) — REPLACE with BarChart
// Legend Row (lines 362–367) — KEEP unchanged

// EXISTING empty guard (lines 302–312) — KEEP:
if (evolucion.isEmpty) {
  return Container(height: 160, alignment: Alignment.center, ...);
}

// EXISTING _stats field (where stats map is stored):
Map<String, dynamic>? _stats;

// EXISTING import line for fl_chart — may or may not be present; ADD if missing:
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show max;

// EXISTING import needed:
import '../utils/pdf_generator.dart';
```

From lib/utils/pdf_generator.dart (from Plan B — must exist):
```dart
static Future<void> generarKpiPdf(Map<String, dynamic> stats) async { ... }
```

From lib/theme/industrial_theme.dart:
```dart
static const Color operativeGreen = Color(0xFF00C853);  // preventivo bars
static const Color criticalRed    = Color(0xFFD32F2F);  // correctivo bars
static const Color neonCyan       = Color(0xFF00E5FF);
static const Color slateGray      = Color(0xFF8892B0);
static const Color electricBlue   = Color(0xFF00E5FF);  // export button bg
static const Color spaceCadet     = Color(0xFF0A192F);  // export button fg
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Replace hand-rolled bar chart with fl_chart BarChart in _buildEvolucionChart</name>
  <files>Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart</files>
  <read_first>
    - Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart — read the FULL file to see: current imports, the _buildEvolucionChart method (lines 301–369), the empty guard pattern, the legend helper, and the Container wrapper structure
    - .planning/phases/01-kpi-dashboard-pdf-export/01-PATTERNS.md lines 188–291 — contains the exact new BarChart body with all field values
    - .planning/phases/01-kpi-dashboard-pdf-export/01-UI-SPEC.md Surface 2 (lines 169–214) — BarChart configuration contract (alignment, maxY formula, rod width, touch behavior)
  </read_first>
  <action>
Make two changes to kpis_screen.dart:

**1. Add/verify imports** at the top of the file:
```dart
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show max;
```
If already present, skip. If not, add them.

**2. Replace the hand-rolled chart content inside `_buildEvolucionChart()`.**

The existing method has a Container wrapper around a Column. The Column has:
- OLD: `SizedBox` with a manually-built Row of Container bars (the hand-rolled chart)
- EXISTING: legend Row at the bottom — KEEP THIS UNCHANGED

Replace ONLY the old bar rendering content (the inner SizedBox containing manual bars) with this new BarChart:

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
```

The empty guard before the Container must remain:
```dart
if (evolucion.isEmpty) {
  return Container(
    height: 160,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: IndustrialTheme.claudCloud,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text('SIN DATOS',
        style: TextStyle(color: Colors.white24)),
  );
}
```

Do NOT add flutter_animate wrapper on the BarChart — fl_chart handles its own entry animation. Keep any existing .animate() wrapper that was on the Container (not the inner chart), but remove any flutter_animate on the chart widget itself.
  </action>
  <verify>
    <automated>grep -n "BarChart\|BarChartData\|BarChartGroupData\|BarChartRodData" "Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart"</automated>
  </verify>
  <acceptance_criteria>
    - `kpis_screen.dart` contains `import 'package:fl_chart/fl_chart.dart'`
    - `kpis_screen.dart` contains `BarChart(BarChartData(`
    - `kpis_screen.dart` contains `BarChartGroupData(`
    - `kpis_screen.dart` contains `BarChartRodData(`
    - `kpis_screen.dart` contains `color: IndustrialTheme.operativeGreen` inside a BarChartRodData
    - `kpis_screen.dart` contains `color: IndustrialTheme.criticalRed` inside a BarChartRodData
    - `kpis_screen.dart` contains `BarChartAlignment.spaceAround`
    - `kpis_screen.dart` contains `BarTouchData(enabled: false)`
    - `kpis_screen.dart` contains `'SIN DATOS'` in the empty guard
    - `kpis_screen.dart` contains `FlGridData(show: false)`
    - `kpis_screen.dart` contains `FlBorderData(show: false)`
    - The `_legend` helper calls remain unchanged (verify legend Row still present)
  </acceptance_criteria>
  <done>KpisScreen _buildEvolucionChart renders a fl_chart BarChart with grouped green/red bars for preventivo/correctivo, with month labels on x-axis and safe empty guard.</done>
</task>

<task type="auto">
  <name>Task 2: Add EXPORTAR PDF button to KpisScreen AppBar and verify KPI-02/KPI-04</name>
  <files>Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart</files>
  <read_first>
    - Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart — re-read (after Task 1 changes) to see exact current AppBar actions block and confirm _stats field name
    - .planning/phases/01-kpi-dashboard-pdf-export/01-PATTERNS.md lines 294–358 — contains exact AppBar actions replacement and _exportarPdf() method
    - .planning/phases/01-kpi-dashboard-pdf-export/01-UI-SPEC.md Surface 4 (lines 273–302) — button spec: electricBlue background, spaceCadet foreground, padding, shape
  </read_first>
  <action>
Make THREE changes to kpis_screen.dart:

**1. Add import** (if not already present):
```dart
import '../utils/pdf_generator.dart';
```

**2. Replace AppBar actions** — find the existing actions list (contains only IconButton refresh) and replace it with:
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

NOTE: If the stats state field is NOT named `_stats`, adjust `_stats == null` to match the actual field name (e.g., `_data == null` or `_kpiData == null`). Read the file first to confirm.

**3. Add `_exportarPdf()` method** — add as a private method in `_KpisScreenState`:
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

Adjust `_stats!` if the actual field name differs. The argument to `generarKpiPdf` must be the same `Map<String, dynamic>` that was received from `fetchDashboardStats()`.

**4. Verify KPI-02 and KPI-04 (no code change):**
- Search for the drawer 'INDICADORES KPI' entry in the file — if found in the drawer, KPI-02 is done.
- Search for the existing OT estado, ratio, and ranking sections — if all three are present, KPI-04 is done.
  </action>
  <verify>
    <automated>grep -n "EXPORTAR PDF\|_exportarPdf\|generarKpiPdf\|ElevatedButton.icon\|picture_as_pdf" "Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart"</automated>
  </verify>
  <acceptance_criteria>
    - `kpis_screen.dart` contains `'EXPORTAR PDF'` as button label text
    - `kpis_screen.dart` contains `ElevatedButton.icon(`
    - `kpis_screen.dart` contains `Icons.picture_as_pdf`
    - `kpis_screen.dart` contains `backgroundColor: IndustrialTheme.electricBlue`
    - `kpis_screen.dart` contains `foregroundColor: IndustrialTheme.spaceCadet`
    - `kpis_screen.dart` contains `_stats == null ? null : () => _exportarPdf()`  (or equivalent with actual field name)
    - `kpis_screen.dart` contains `Future<void> _exportarPdf()`
    - `kpis_screen.dart` contains `PdfGenerator.generarKpiPdf(`
    - `kpis_screen.dart` contains `'Generando PDF...'`
    - `kpis_screen.dart` contains `'Error al generar PDF. Comprueba los datos.'`
    - `kpis_screen.dart` contains `backgroundColor: IndustrialTheme.criticalRed` in error SnackBar
    - `kpis_screen.dart` contains `import '../utils/pdf_generator.dart'`
    - `flutter analyze Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart` produces no errors
  </acceptance_criteria>
  <done>KpisScreen AppBar shows EXPORTAR PDF button (disabled while loading, triggers PDF generation via PdfGenerator.generarKpiPdf on tap). KPI-02 drawer entry and KPI-04 OT metrics sections confirmed present.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Flutter client → PdfGenerator | Client-side only. Stats data already in _stats map from previous fetch. No new network call for PDF generation. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-1D-01 | Denial | BarChart crash on empty evolucionMensual | mitigate | `if (evolucion.isEmpty) return _emptyChart()` guard must run before BarChartData construction. Never pass empty barGroups list to BarChart |
| T-1D-02 | Denial | _exportarPdf called with null _stats | mitigate | `onPressed: _stats == null ? null : () => _exportarPdf()` disables button while loading. Non-null assertion `_stats!` is safe when button is enabled |
| T-1D-03 | Denial | generarKpiPdf throws exception | mitigate | Wrapped in try/catch with error SnackBar feedback. Never propagates to UI as unhandled exception |
| T-1D-04 | Information Disclosure | KPI data in PDF file | accept | PDF delivered to authenticated user's own device via Printing.layoutPdf. Same as existing PdfGenerator behavior. No external transmission |
| T-1D-05 | Tampering | (m['preventivo'] as num?) null access in BarChart | mitigate | `?? 0` fallback on all bar value extractions. Empty/null entry renders as 0-height bar rather than crash |
</threat_model>

<verification>
After both tasks complete:

1. `grep -n "BarChart\|BarChartData" Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart` — must return matches
2. `grep -n "EXPORTAR PDF\|_exportarPdf" Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart` — must return matches
3. `grep -n "generarKpiPdf" Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart` — must return 1 match
4. `grep -n "SIN DATOS" Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart` — must return 1 match (empty guard)
5. `flutter analyze Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart` — no errors
</verification>

<success_criteria>
- KpisScreen bar chart is fl_chart BarChart with green/red grouped bars and month labels
- Chart handles empty data gracefully with SIN DATOS fallback
- EXPORTAR PDF button visible in AppBar, disabled while loading
- Tapping button shows SnackBar feedback and opens PDF via Printing.layoutPdf
- KPI-02 (drawer entry) confirmed present
- KPI-04 (OT estado/tipo/máquina metrics) confirmed present in existing sections
- flutter analyze passes with no errors
</success_criteria>

<output>
After completion, create `.planning/phases/01-kpi-dashboard-pdf-export/01-D-SUMMARY.md` with:
- Actual stats field name found in kpis_screen.dart (used in button disabled check)
- Confirmation that BarChart replaced hand-rolled chart
- KPI-02 and KPI-04 verification results
- flutter analyze result
</output>
