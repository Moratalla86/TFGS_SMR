---
phase: 1
plan: E
type: execute
wave: 2
depends_on:
  - plan-B
files_modified:
  - Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart
autonomous: true
requirements:
  - EXP-01
must_haves:
  truths:
    - "OrdenesScreen AppBar has a picture_as_pdf IconButton (neonCyan) as the first action before the existing sync button"
    - "The export button is disabled (onPressed: null) when _ordenes is empty"
    - "Tapping the button shows a SnackBar 'Generando PDF con N órdenes de trabajo...' and calls PdfGenerator.generarListaOtsPdf(_ordenes)"
    - "The bulk export uses _ordenes (full list) not _filteredOrdenes"
  artifacts:
    - path: "Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart"
      provides: "Bulk OT PDF export button in AppBar"
      contains: "_exportarListaOts"
  key_links:
    - from: "OrdenesScreen AppBar IconButton(picture_as_pdf)"
      to: "PdfGenerator.generarListaOtsPdf(_ordenes)"
      via: "_exportarListaOts() method"
      pattern: "PdfGenerator\\.generarListaOtsPdf"
---

<objective>
Add a bulk OT PDF export button to OrdenesScreen AppBar.

Purpose: Fulfil EXP-01 — the technician can export the full list of OTs to PDF from OrdenesScreen. The existing per-OT PDF button (for CERRADA OTs) is unchanged; this adds a new LIST-level export.

Depends on: Plan B must be complete (PdfGenerator.generarListaOtsPdf must exist before this plan calls it).

Output: Modified `ordenes_screen.dart` with a new AppBar IconButton that triggers bulk PDF export.
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

From lib/screens/ordenes_screen.dart (EXISTING — key sections):
```dart
// EXISTING AppBar (lines 234–241) — replace actions only:
appBar: AppBar(
  title: const Text('GESTIÓN DE ÓRDENES (OT)', style: TextStyle(letterSpacing: 2, fontSize: 16)),
  centerTitle: false,
  actions: [IconButton(icon: const Icon(Icons.sync), onPressed: _load)],
),

// EXISTING _ordenes state field (line 28) — use for bulk export, NOT _filteredOrdenes:
List<OrdenTrabajo> _ordenes = [];

// EXISTING _verReportePdf pattern (lines 111–133) — mirror for _exportarListaOts:
Future<void> _verReportePdf(OrdenTrabajo ot) async {
  // calls PdfGenerator.generarYVerPdf(ot)
}

// EXISTING error SnackBar pattern (lines 174–179):
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('...'),
    backgroundColor: IndustrialTheme.criticalRed,
  ),
);
```

From lib/utils/pdf_generator.dart (from Plan B — must exist):
```dart
static Future<void> generarListaOtsPdf(List<OrdenTrabajo> ordenes) async { ... }
```

From lib/theme/industrial_theme.dart:
```dart
static const Color neonCyan    = Color(0xFF00E5FF);  // export icon color
static const Color criticalRed = Color(0xFFD32F2F);  // error SnackBar bg
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add bulk OT PDF export button and method to OrdenesScreen</name>
  <files>Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart</files>
  <read_first>
    - Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart — read the FULL file to understand: current imports, AppBar actions (lines 234–241), existing _ordenes field declaration, _filteredOrdenes field, existing per-OT PDF button (line 700), and _verReportePdf method pattern
    - .planning/phases/01-kpi-dashboard-pdf-export/01-PATTERNS.md lines 369–435 — contains exact AppBar replacement and _exportarListaOts() method
    - .planning/phases/01-kpi-dashboard-pdf-export/01-UI-SPEC.md Surface 5 (lines 306–325) — icon spec: picture_as_pdf, neonCyan color, tooltip text, placement as FIRST action
  </read_first>
  <action>
Make THREE changes to ordenes_screen.dart:

**1. Add import** (if not already present — pdf_generator may already be imported for per-OT export):
```dart
import '../utils/pdf_generator.dart';
```
If already present, skip this step.

**2. Replace AppBar actions** — find the existing actions list and replace it with the new actions. The NEW picture_as_pdf icon must be FIRST (leftmost action), the existing sync button remains:
```dart
actions: [
  IconButton(
    icon: const Icon(Icons.picture_as_pdf, color: IndustrialTheme.neonCyan),
    tooltip: 'Exportar lista de OTs a PDF',
    onPressed: _ordenes.isEmpty ? null : () => _exportarListaOts(),
  ),
  IconButton(
    icon: const Icon(Icons.sync),
    onPressed: _load,
  ),
],
```

CRITICAL: Use `_ordenes` (the full unfiltered list declared at line 28), NOT `_filteredOrdenes`. The bulk export must include all loaded OTs regardless of the active filter.

CRITICAL: Do NOT touch the existing per-OT PDF button at line ~700 (the `Icons.picture_as_pdf` inside the OT list item for CERRADA OTs). This is a separate button for single-OT closure reports and must remain unchanged.

**3. Add `_exportarListaOts()` method** — add as a private method in `_OrdenesScreenState`, after the existing `_verReportePdf` method:
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

If the full list field has a different name than `_ordenes` (verify from reading the file), adjust accordingly. The list must contain all OTs from the last fetchOrdenes call.
  </action>
  <verify>
    <automated>grep -n "_exportarListaOts\|generarListaOtsPdf\|picture_as_pdf\|Exportar lista de OTs" "Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart"</automated>
  </verify>
  <acceptance_criteria>
    - `ordenes_screen.dart` contains `Future<void> _exportarListaOts()`
    - `ordenes_screen.dart` contains `PdfGenerator.generarListaOtsPdf(_ordenes)` (or with actual list field name)
    - `ordenes_screen.dart` contains `'Exportar lista de OTs a PDF'` as tooltip
    - `ordenes_screen.dart` contains `Icons.picture_as_pdf` in AppBar actions (new button)
    - `ordenes_screen.dart` contains `color: IndustrialTheme.neonCyan` on the new AppBar icon
    - `ordenes_screen.dart` contains `_ordenes.isEmpty ? null : () => _exportarListaOts()`
    - `ordenes_screen.dart` contains `'Generando PDF con '` and `'órdenes de trabajo...'`
    - `ordenes_screen.dart` contains `'Error al generar PDF. Comprueba los datos.'`
    - `ordenes_screen.dart` contains `backgroundColor: IndustrialTheme.criticalRed` in error SnackBar
    - The existing per-OT `Icons.picture_as_pdf` button (in OT list items for CERRADA OTs, ~line 700) is unchanged
    - `flutter analyze Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart` produces no errors
  </acceptance_criteria>
  <done>OrdenesScreen AppBar has a picture_as_pdf export button that calls generarListaOtsPdf with the full _ordenes list. Existing per-OT PDF button unchanged.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
All 5 plans implemented (Plans A–E):
- Plan A: PLCService.fetchLastTelemetry + SalaServidoresWidget
- Plan B: PdfGenerator.generarKpiPdf + generarListaOtsPdf
- Plan C: DashboardScreen KPI cards + Sala de Servidores
- Plan D: KpisScreen fl_chart + EXPORTAR PDF button
- Plan E: OrdenesScreen bulk PDF export button

Run `flutter analyze` on the Frontend project to confirm zero compile errors before visual verification.
  </what-built>
  <how-to-verify>
With the app running (flutter run):

**KPI-01 — DashboardScreen KPI mini-cards:**
1. Open app, navigate to Dashboard screen
2. Scroll down past the 4 operational cards (ESTADO PLANTA, ALERTAS CRÍTICAS, TOTAL TAREAS, OT PENDIENTES)
3. Verify a "KPIs OPERACIONALES" section header appears
4. Verify 4 mini-cards: OEE (%), MTBF (h), MTTR (h), DISPONIB. (%) with realistic numeric values
5. Verify card colors reflect threshold state (green/orange/red)

**KPI-02 — Drawer entry:**
6. Open drawer (hamburger menu)
7. Verify "INDICADORES KPI" entry exists and tapping it navigates to KpisScreen

**KPI-03 — Bar chart:**
8. Navigate to KpisScreen via drawer
9. Scroll to the evolución mensual section
10. Verify a bar chart appears with green bars (PREVENTIVO) and red bars (CORRECTIVO) per month

**KPI-04 — OT metrics:**
11. On KpisScreen, verify sections for OTs por estado, tipo/ratio, and ranking por máquina are visible

**KPI-05 — Sala de Servidores:**
12. Return to DashboardScreen
13. Scroll past KPIs OPERACIONALES section
14. Verify "SALA DE SERVIDORES" section appears with a widget showing TEMPERATURA and HUMEDAD values
15. Wait 5 seconds — verify the values update (or confirm the green live dot is visible)

**KPI-06 — KPI PDF export:**
16. Navigate to KpisScreen
17. Tap "EXPORTAR PDF" button in AppBar
18. Verify SnackBar "Generando PDF..." appears
19. Verify PDF viewer opens showing: INFORME KPI — MÈLTIC GMAO header, KPI values table, distribución, estado, evolución mensual, ranking tables

**EXP-01 — OT list PDF export:**
20. Navigate to Órdenes screen (drawer)
21. Verify picture_as_pdf icon in AppBar (first action, neonCyan color)
22. Tap the icon
23. Verify SnackBar "Generando PDF con N órdenes de trabajo..." appears
24. Verify PDF viewer opens showing: LISTADO DE ÓRDENES DE TRABAJO header, 7-column OT table
  </how-to-verify>
  <resume-signal>Type "approved" if all 7 requirements pass. Or describe any failures (e.g., "KPI-03 chart not showing") for gap closure.</resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Flutter client → PDF file | Client-side only. OT data already in _ordenes list from previous fetchOrdenes call. No new network call for PDF generation. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-1E-01 | Information Disclosure | PDF contains full OT list including all OTs regardless of active filter | accept | Export is explicitly a FULL list export (per EXP-01 requirement). User is authenticated and viewing the same data in the list. No new disclosure surface |
| T-1E-02 | Denial | generarListaOtsPdf throws on empty ordenes | mitigate | Button disabled when `_ordenes.isEmpty` — generarListaOtsPdf is never called with an empty list. Plan B also wraps the call in try/catch for any runtime error |
| T-1E-03 | Denial | OrdenTrabajo field null access (maquinaNombre, fechaCreacion) | mitigate | PdfGenerator.generarListaOtsPdf uses `?? '-'` and `ot.fechaCreacion != null ? ... : '-'` guards. Null fields show '-' in PDF rather than crash |
| T-1E-04 | Tampering | N/A — PDF is read-only export of existing in-memory data | accept | No write operations, no API mutations, no auth changes |
</threat_model>

<verification>
After Task 1 complete (before checkpoint):

1. `grep -n "_exportarListaOts\|generarListaOtsPdf" Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart` — must return matches
2. `grep -n "Exportar lista de OTs" Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart` — must return 1 match
3. `flutter analyze Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart` — no errors
4. `flutter analyze Frontend/meltic_gmao_app/lib/` — zero errors across full project (run before checkpoint)
</verification>

<success_criteria>
- OrdenesScreen AppBar has picture_as_pdf icon (neonCyan) as first action
- Button disabled when ordenes list is empty
- Tapping generates PDF and opens it via Printing.layoutPdf
- Existing per-OT PDF button (CERRADA OTs) unchanged
- flutter analyze passes with zero errors across entire project
- All 7 Phase 1 requirements confirmed working in human verification checkpoint
</success_criteria>

<output>
After completion, create `.planning/phases/01-kpi-dashboard-pdf-export/01-E-SUMMARY.md` with:
- Actual _ordenes field name confirmed from file read
- flutter analyze project-wide result
- Human verification checkpoint outcome
- Any gap closure items needed
</output>
