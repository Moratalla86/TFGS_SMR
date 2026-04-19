---
phase: 1
plan: B
type: execute
wave: 1
depends_on: []
files_modified:
  - Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart
autonomous: true
requirements:
  - KPI-06
  - EXP-01
must_haves:
  truths:
    - "PdfGenerator.generarKpiPdf(stats) generates and opens an A4 PDF with KPI values table, distribución, estado, evolución mensual, and ranking sections"
    - "PdfGenerator.generarListaOtsPdf(ordenes) generates and opens an A4 PDF with a 7-column OT table"
    - "Both methods use Printing.layoutPdf for cross-platform delivery (Android share sheet, Web browser, Windows print dialog)"
    - "PDF content uses pw.* widgets only — no Flutter widget captures"
  artifacts:
    - path: "Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart"
      provides: "generarKpiPdf and generarListaOtsPdf static methods"
      contains: "static Future<void> generarKpiPdf"
  key_links:
    - from: "KpisScreen._exportarPdf()"
      to: "PdfGenerator.generarKpiPdf(_stats!)"
      via: "static call"
      pattern: "PdfGenerator\\.generarKpiPdf"
    - from: "OrdenesScreen._exportarListaOts()"
      to: "PdfGenerator.generarListaOtsPdf(_ordenes)"
      via: "static call"
      pattern: "PdfGenerator\\.generarListaOtsPdf"
---

<objective>
Add two new static PDF generation methods to the existing PdfGenerator utility class.

Purpose: Deliver the PDF infrastructure for KPI-06 (KPI report) and EXP-01 (OT list export). This is a Wave 1 foundation plan — KpisScreen (Plan D) and OrdenesScreen (Plan E) call these methods and depend on them existing.

Output:
- `PdfGenerator.generarKpiPdf(Map<String, dynamic> stats)` — KPI report with 6 data sections
- `PdfGenerator.generarListaOtsPdf(List<OrdenTrabajo> ordenes)` — OT list table
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

<interfaces>
<!-- Key types and contracts the executor needs. Extracted from PATTERNS.md and RESEARCH.md. -->

From lib/utils/pdf_generator.dart (EXISTING — modify in place):
```dart
// EXISTING methods to keep untouched:
static Future<String> generarReporteCierreBase64(OrdenTrabajo ot) async { ... }
static Future<void> viewLocalPdf(String base64String) async { ... }
static Future<void> generarYVerPdf(OrdenTrabajo ot) async { ... }

// EXISTING pw.Document + MultiPage + Printing.layoutPdf skeleton (lines 19, 71–73, 353):
final pdf = pw.Document();
pdf.addPage(pw.MultiPage(
  pageFormat: PdfPageFormat.a4,
  margin: const pw.EdgeInsets.all(32),
  build: (context) => [ /* list of pw.Widget */ ],
));
final bytes = await pdf.save();
await Printing.layoutPdf(
  onLayout: (PdfPageFormat format) async => bytes,
  name: 'fileName.pdf',
);
```

From lib/models/orden_trabajo.dart (used in generarListaOtsPdf):
```dart
class OrdenTrabajo {
  final int id;
  final String? maquinaNombre;
  final String? tecnicoNombre;
  final String? tipo;
  final String estado;
  final String prioridad;
  final String? fechaCreacion;
}
```

Backend /api/stats/dashboard response shape (used in generarKpiPdf):
```json
{
  "oeeGlobal": 73.2,
  "mtbfHoras": 43.8,
  "mttrHoras": 2.5,
  "disponibilidadPct": 87.5,
  "ratioPreventivoCorrectivo": { "preventivas": 45, "correctivas": 55 },
  "otsPorEstado": { "CERRADA": 80, "EN_PROCESO": 10, "PENDIENTE": 10 },
  "rankingIncidencias": [{ "maquina": "Torno X1", "incidencias": 12 }],
  "evolucionMensual": [{ "mes": "NOV", "preventivo": 8, "correctivo": 5 }]
}
```

CRITICAL anti-pattern: Do NOT attempt to render fl_chart widgets or any Flutter widget as an image
in the PDF. The `pdf` package (pw.*) is a vector PDF renderer with NO access to the Flutter widget tree.
Monthly evolution MUST be a data table (pw.TableHelper.fromTextArray), not a chart.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add generarKpiPdf static method to PdfGenerator</name>
  <files>Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart</files>
  <read_first>
    - Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart — read the FULL file to understand current imports (pdf, printing, pw.*, DateFormat, PdfPageFormat) and find the correct insertion point after generarYVerPdf
    - .planning/phases/01-kpi-dashboard-pdf-export/01-PATTERNS.md lines 467–601 — contains the complete generarKpiPdf method body
    - .planning/phases/01-kpi-dashboard-pdf-export/01-UI-SPEC.md PDF Document Design Contract (lines 334–368) — exact section order and pw.TableHelper headers
  </read_first>
  <action>
Add the following static method to PdfGenerator class, after the existing `generarYVerPdf` method.

**CRITICAL:** The `pdf` package uses `pw.*` widgets (not Flutter widgets). Do not use `BarChart`, `Container`, or any Flutter widget inside the PDF build function. Use ONLY `pw.Text`, `pw.SizedBox`, `pw.Divider`, `pw.TableHelper.fromTextArray`, `pw.MultiPage`.

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
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
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

        // 5. Evolución mensual (data table — NOT a chart; pdf package cannot render Flutter widgets)
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

        // 6. Ranking de incidencias (top 5)
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
  </action>
  <verify>
    <automated>grep -n "static Future\&lt;void\&gt; generarKpiPdf" "Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart"</automated>
  </verify>
  <acceptance_criteria>
    - `pdf_generator.dart` contains `static Future<void> generarKpiPdf(Map<String, dynamic> stats)`
    - `pdf_generator.dart` contains `'INFORME KPI — MÈLTIC GMAO'`
    - `pdf_generator.dart` contains `headers: ['KPI', 'VALOR', 'DESCRIPCIÓN']`
    - `pdf_generator.dart` contains `headers: ['TIPO', 'CANTIDAD', 'PORCENTAJE']`
    - `pdf_generator.dart` contains `headers: ['ESTADO', 'CANTIDAD', 'PORCENTAJE']`
    - `pdf_generator.dart` contains `headers: ['MES', 'PREVENTIVAS', 'CORRECTIVAS', 'TOTAL']`
    - `pdf_generator.dart` contains `headers: ['#', 'MÁQUINA', 'INCIDENCIAS']`
    - `pdf_generator.dart` contains `KPI_Report_` in the file name string
    - `pdf_generator.dart` contains `Printing.layoutPdf` in generarKpiPdf
    - No Flutter widget types (BarChart, Container, Row, Column) appear inside the generarKpiPdf build list
    - The existing `generarReporteCierreBase64`, `viewLocalPdf`, and `generarYVerPdf` methods are unchanged
  </acceptance_criteria>
  <done>PdfGenerator.generarKpiPdf(stats) generates an A4 PDF with 6 sections (header, KPI table, distribución, estado, evolución, ranking) and delivers it via Printing.layoutPdf.</done>
</task>

<task type="auto">
  <name>Task 2: Add generarListaOtsPdf static method to PdfGenerator</name>
  <files>Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart</files>
  <read_first>
    - Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart — re-read the file (already modified in Task 1) to find correct insertion point after generarKpiPdf
    - Frontend/meltic_gmao_app/lib/models/orden_trabajo.dart — verify field names: id, maquinaNombre, tecnicoNombre, tipo, estado, prioridad, fechaCreacion
    - .planning/phases/01-kpi-dashboard-pdf-export/01-PATTERNS.md lines 604–659 — complete generarListaOtsPdf method body
    - .planning/phases/01-kpi-dashboard-pdf-export/01-UI-SPEC.md generarListaOtsPdf section (lines 373–392) — exact column widths
  </read_first>
  <action>
Add the following static method to PdfGenerator class, after the `generarKpiPdf` method just added in Task 1.

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
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
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

If `OrdenTrabajo` model field names differ from the above (e.g., `maquina` instead of `maquinaNombre`), adjust the field access to match the actual model. Read `orden_trabajo.dart` first to confirm.
  </action>
  <verify>
    <automated>grep -n "static Future\&lt;void\&gt; generarListaOtsPdf" "Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart"</automated>
  </verify>
  <acceptance_criteria>
    - `pdf_generator.dart` contains `static Future<void> generarListaOtsPdf(List<OrdenTrabajo> ordenes)`
    - `pdf_generator.dart` contains `'LISTADO DE ÓRDENES DE TRABAJO'`
    - `pdf_generator.dart` contains `headers: ['#', 'MÁQUINA', 'TÉCNICO', 'TIPO', 'ESTADO', 'PRIORIDAD', 'FECHA']`
    - `pdf_generator.dart` contains `columnWidths:` with FixedColumnWidth and FlexColumnWidth entries
    - `pdf_generator.dart` contains `OTs_` in the file name string
    - `pdf_generator.dart` contains `Printing.layoutPdf` in generarListaOtsPdf
    - `pdf_generator.dart` contains `DateFormat('dd/MM/yy').format` for date formatting
    - `flutter analyze Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart` produces no errors
  </acceptance_criteria>
  <done>PdfGenerator.generarListaOtsPdf(ordenes) generates an A4 PDF with a 7-column OT table showing all OTs and delivers it via Printing.layoutPdf.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Flutter client → PDF file | Client-side only. No server round-trip for PDF generation. Stats/OT data already in memory. |
| PDF → OS delivery | Printing.layoutPdf handles platform-specific delivery. No external network call. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-1B-01 | Information Disclosure | PDF contains KPI/OT business data | accept | PDF is generated client-side and delivered to the authenticated user's own device (share sheet / print dialog). No server transmission. Consistent with existing PdfGenerator.viewLocalPdf behavior |
| T-1B-02 | Tampering | stats map casting (as num?, as Map?, as List?) | mitigate | All casts use safe null-coalescing (`?? 0`, `?? {}`, `?? []`). Malformed API response produces 0/empty values in PDF rather than crash |
| T-1B-03 | Denial | DateTime.parse on null fechaCreacion | mitigate | Guarded with `ot.fechaCreacion != null ? ... : '-'` before calling DateTime.parse |
| T-1B-04 | Elevation of Privilege | N/A — PDF generation is purely client-side | accept | No auth context, no new API calls, no permissions required beyond what already exists |
</threat_model>

<verification>
After both tasks complete:

1. `grep -n "generarKpiPdf\|generarListaOtsPdf" Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart` — must return 2 definitions
2. `grep -n "INFORME KPI\|LISTADO DE ÓRDENES" Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart` — must return 2 matches
3. `grep -n "Printing.layoutPdf" Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart` — must return 3 matches (viewLocalPdf + generarKpiPdf + generarListaOtsPdf)
4. `flutter analyze Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart` — no errors
</verification>

<success_criteria>
- PdfGenerator has both `generarKpiPdf` and `generarListaOtsPdf` static methods
- KPI PDF has 6 sections (header, KPI values, distribución, estado, evolución, ranking)
- OT PDF has 7-column table with correct column widths
- Both methods call Printing.layoutPdf for cross-platform delivery
- No Flutter widgets used inside pdf build functions
- Existing methods unchanged and still compile
</success_criteria>

<output>
After completion, create `.planning/phases/01-kpi-dashboard-pdf-export/01-B-SUMMARY.md` with:
- Files modified
- Two new methods confirmed present
- Any OrdenTrabajo field name adjustments made
- Confirmation that flutter analyze passes
</output>
