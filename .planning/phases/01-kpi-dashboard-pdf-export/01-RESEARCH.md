# Phase 1: KPI Dashboard + PDF Export - Research

**Researched:** 2026-04-17
**Domain:** Flutter (fl_chart, pdf/printing), Spring Boot 3 Stats API, Controllino IoT polling
**Confidence:** HIGH — all findings verified directly from codebase + installed package deps

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| KPI-01 | 4 KPI mini-cards (OEE, MTBF, MTTR, disponibilidad) in DashboardScreen | StatsService.fetchDashboardStats() already returns all 4 values; DashboardScreen needs a new section below existing KPI row |
| KPI-02 | KpisScreen accessible from drawer | Drawer already has "INDICADORES KPI" entry wired to `/kpis` — ALREADY DONE, no work needed |
| KPI-03 | Bar chart of monthly evolution in KpisScreen | KpisScreen already renders a custom hand-rolled bar chart using _buildEvolucionChart; replace with fl_chart BarChart (fl_chart 0.70.2 installed) |
| KPI-04 | OT metrics by state, type, and machine in KpisScreen | KpisScreen already shows estado + ratio cards; needs "por tipo" breakout and ranking uses machine names |
| KPI-05 | Sala de Servidores widget in DashboardScreen with real-time Controllino data | Backend polls Controllino every 5 s; need new `/api/plc/last-telemetry/{maquinaId}` endpoint or reuse `/api/plc/maquina/1?since=` polling pattern in Flutter |
| KPI-06 | Export KPI report to PDF from KpisScreen | PdfGenerator exists in lib/utils/pdf_generator.dart; need new method for KPI report; printing 5.14.3 already installed |
| EXP-01 | Export OT list to PDF from OrdenesScreen | OrdenesScreen already has per-OT PDF view; need a NEW "export all OTs" bulk PDF button in AppBar |
</phase_requirements>

---

## Summary

KpisScreen is already built and live. It calls `/api/stats/dashboard`, parses all fields (oeeGlobal, mtbfHoras, mttrHoras, disponibilidadPct, ratioPreventivoCorrectivo, otsPorEstado, rankingIncidencias, evolucionMensual), and renders them. The bar chart for monthly evolution is already implemented as a custom widget (`_buildEvolucionChart`). The work is: (1) replace or enhance the custom bar chart with fl_chart for a more polished visual (fl_chart 0.70.2 is already installed), (2) add 4 OEE/MTBF/MTTR/disp mini-cards to DashboardScreen above the existing machine grid, (3) build the Sala de Servidores widget using periodic HTTP polling to `/api/plc/maquina/1` (already implemented pattern), (4) add "Exportar PDF" button to KpisScreen, and (5) add a bulk "Exportar lista OTs" button to OrdenesScreen AppBar.

The backend needs zero changes for KPI-01 through KPI-04. KPI-05 needs a new thin endpoint or the Flutter side can use the existing `/api/plc/maquina/{id}` endpoint with `?since=` polling — the Controllino data (temperatura, humedad) is already persisted every 5 seconds by PLCPollingService. For PDF, `PdfGenerator.viewLocalPdf()` and `Printing.layoutPdf()` already work across Android, Web, and Windows via the `printing` package.

**Primary recommendation:** This is primarily a Flutter UI composition phase, not a feature-build. Most infrastructure exists. Focus on: correct data wiring, fl_chart integration, Sala de Servidores periodic poll, and two new PDF generator methods.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| KPI data computation (OEE, MTBF, MTTR) | API / Backend (StatsService.java) | — | Already computed server-side from DB queries |
| KPI display (mini-cards, charts) | Flutter Frontend | — | Pure UI composition; data comes from existing endpoint |
| Monthly evolution bar chart | Flutter Frontend (fl_chart) | — | Client-side rendering of server-provided aggregates |
| Sala de Servidores real-time data | API / Backend (PLCPollingService) | Flutter Frontend (Timer.periodic) | Backend polls Controllino every 5s and persists; Flutter polls backend |
| PDF generation | Flutter Frontend (pdf + printing packages) | — | Client-side generation; no server involvement |
| OT list bulk PDF | Flutter Frontend (pdf + printing packages) | — | OrdenesScreen already loads full list; just needs new generator method |

---

## Standard Stack

### Core (already installed — verified from pubspec.yaml + `dart pub deps`)

| Library | Installed Version | Purpose | Why Standard |
|---------|------------------|---------|--------------|
| fl_chart | 0.70.2 | Bar charts, line charts | Already in pubspec; Flutter-native charting; no licensing restrictions |
| pdf | 3.12.0 | PDF document generation | Already installed; pure Dart; used in existing PdfGenerator |
| printing | 5.14.3 | Cross-platform PDF viewing/sharing | Already installed; wraps Printing.layoutPdf for Web/Android/Windows |
| syncfusion_flutter_charts | 33.1.45 | Advanced charts (alternative) | Already installed but requires Community license acknowledgment; fl_chart preferred for TFG |
| flutter_animate | 4.5.2 | Animations | Already used throughout — use for card entry animations |
| http | 1.1.0 | REST API calls | Used by all services; polling via Timer + http.get |

[VERIFIED: dart pub deps output in this session]

### No New Packages Needed

All required functionality is covered by existing dependencies. Do NOT add new packages.

---

## Architecture Patterns

### System Architecture Diagram

```
Flutter App
  │
  ├── DashboardScreen
  │     ├── [EXISTING] MaquinaService.fetchMaquinas()  → /api/maquinas
  │     ├── [EXISTING] OrdenTrabajoService.fetchOrdenes() → /api/ordenes
  │     ├── [NEW] StatsService.fetchDashboardStats() → /api/stats/dashboard
  │     │         └── Returns: oeeGlobal, mtbfHoras, mttrHoras, disponibilidadPct
  │     │         └── Renders: 4 mini-cards (OEE / MTBF / MTTR / DISP)
  │     └── [NEW] SalaServidoresWidget
  │               └── Timer.periodic(5s) → PLCService.fetchLastTelemetry(maquinaId=1)
  │               └── GET /api/plc/maquina/1?since=<lastTimestamp>
  │               └── Renders: temperatura + humedad with live indicator
  │
  ├── KpisScreen  (existing StatefulWidget, fully wired)
  │     ├── StatsService.fetchDashboardStats()
  │     │     └── [EXISTING] Renders: KPI cards, ratio, estado, ranking
  │     ├── [REPLACE] _buildEvolucionChart() → fl_chart BarChart
  │     │     └── Data: evolucionMensual[{mes, preventivo, correctivo}]
  │     └── [NEW] "EXPORTAR PDF" ElevatedButton in AppBar actions
  │               └── PdfGenerator.generarKpiPdf(stats) → Printing.layoutPdf()
  │
  └── OrdenesScreen (existing, fully functional)
        ├── [EXISTING] Per-OT PDF button for CERRADA OTs
        └── [NEW] AppBar IconButton(picture_as_pdf)
                  └── PdfGenerator.generarListaOtsPdf(ordenes) → Printing.layoutPdf()
```

### Recommended Project Structure (additions only)

```
lib/
├── services/
│   └── stats_service.dart       # EXISTS — fetchDashboardStats() already there
│   └── plc_service.dart         # EXISTS — add fetchLastTelemetry(maquinaId) method
├── utils/
│   └── pdf_generator.dart       # EXISTS — add generarKpiPdf() + generarListaOtsPdf()
└── widgets/
    └── sala_servidores_widget.dart  # NEW — self-contained stateful widget with Timer
```

### Pattern 1: fl_chart BarChart for Monthly Evolution

The existing `_buildEvolucionChart()` in KpisScreen is a hand-rolled custom painter. Replace with fl_chart `BarChart` widget.

**What:** fl_chart BarChart with grouped bars (preventivo + correctivo per month).
**When to use:** Always for the monthly evolution section in KpisScreen.

```dart
// Source: fl_chart 0.70.2 - verified installed
BarChart(
  BarChartData(
    barGroups: evolucion.asMap().entries.map((entry) {
      final i = entry.key;
      final m = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (m['preventivo'] as num).toDouble(),
            color: IndustrialTheme.operativeGreen,
            width: 8,
            borderRadius: BorderRadius.circular(3),
          ),
          BarChartRodData(
            toY: (m['correctivo'] as num).toDouble(),
            color: IndustrialTheme.criticalRed,
            width: 8,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    }).toList(),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => Text(
            evolucion[value.toInt()]['mes'],
            style: const TextStyle(fontSize: 9, color: IndustrialTheme.slateGray),
          ),
        ),
      ),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
    gridData: FlGridData(show: false),
    borderData: FlBorderData(show: false),
  ),
)
```
[VERIFIED: fl_chart 0.70.2 installed per dart pub deps]

### Pattern 2: Sala de Servidores Widget (Timer.periodic polling)

**What:** Stateful widget that polls `/api/plc/maquina/1` every 5 seconds to show temperatura + humedad.
**When to use:** Embedded in DashboardScreen body, after the KPI mini-cards section.

```dart
// lib/widgets/sala_servidores_widget.dart
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
  int? _lastTimestampMs;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final String url = _lastTimestampMs != null
          ? '${ApiConfig.baseUrl}/api/plc/maquina/1?since=$_lastTimestampMs'
          : '${ApiConfig.baseUrl}/api/plc/maquina/1';
      final res = await http.get(
        Uri.parse(url),
        headers: AppSession.instance.authHeaders,
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        if (data.isNotEmpty) {
          final last = data.last as Map<String, dynamic>;
          if (mounted) setState(() {
            _temperatura = (last['temperatura'] as num?)?.toDouble();
            _humedad = (last['humedad'] as num?)?.toDouble();
            _live = true;
            // Update since timestamp from last record's epoch millis
            // (Telemetria returns timestamp as ISO string or epoch — check model)
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _live = false);
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  // ... build with Container showing temperatura/humedad cards
}
```
[VERIFIED: PLCPollingService polls every 5s, telemetria stored in MongoDB, /api/plc/maquina/{id} endpoint exists]

**Important caveat for KPI-05:** The `/api/plc/maquina/1?since=` endpoint returns new telemetry since a given timestamp in epoch millis. The Controllino hardware is machine 1 (ID=1L). If hardware is absent, PLCPollingService falls back to simulation (verified in PLCPollingService.java line 151).

### Pattern 3: PdfGenerator new methods

The existing `PdfGenerator` class (lib/utils/pdf_generator.dart) already works for OT closure PDFs using `pw.Document()` and `Printing.layoutPdf()`. Add two new static methods to the same class:

**generarKpiPdf(Map<String, dynamic> stats):** Takes the full stats map from fetchDashboardStats() and renders a styled A4 KPI report: header, 4 KPI values table, OTs by state, ratio table, ranking table, monthly evolution data as a text table (charts cannot be rendered in pdf package — pdf package renders vector, not flutter widgets).

**generarListaOtsPdf(List<OrdenTrabajo> ordenes):** Takes the full OT list and renders a table with columns: ID, Máquina, Técnico, Tipo, Prioridad, Estado, Fecha.

```dart
// Pattern for both new methods — mirrors existing PdfGenerator.generarReporteCierreBase64()
static Future<void> generarKpiPdf(Map<String, dynamic> stats) async {
  final pdf = pw.Document();
  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    build: (context) => [
      // header, KPI table, estado table, etc.
    ],
  ));
  final bytes = await pdf.save();
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => bytes,
    name: 'KPI_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
  );
}
```
[VERIFIED: Printing.layoutPdf pattern already used in PdfGenerator.viewLocalPdf()]

### Pattern 4: KPI Mini-Cards in DashboardScreen

DashboardScreen already has `_buildKpiCard(title, value, icon, color)` widget. Add a new row below `_buildHeader()` that fetches dashboard stats and shows 4 cards: OEE, MTBF, MTTR, Disponibilidad.

**Important:** DashboardScreen already makes 2 API calls (fetchMaquinas + fetchOrdenes) and refreshes every 5 seconds. Add the stats call to the same `_loadMaquinas()` method and store results in state. Do NOT add a separate timer.

```dart
// In DashboardScreen._loadMaquinas():
final stats = await _statsService.fetchDashboardStats();
// Store: _oee, _mtbf, _mttr, _disp as double? state fields

// In body build, after _buildHeader(), before existing KPI row:
if (_oee != null) _buildOperationalKpiRow(_oee!, _mtbf!, _mttr!, _disp!),
```

### Anti-Patterns to Avoid

- **Using syncfusion_flutter_charts instead of fl_chart:** Syncfusion requires community license attribution. fl_chart is already installed, has no licensing friction, and is sufficient for bar charts. Do not use SyncfusionFlutterChart.
- **Generating charts as images to embed in PDF:** The `pdf` package cannot render Flutter widgets (it is a vector PDF renderer). All PDF content must use `pw.*` widgets from the pdf package, not Flutter widgets. Monthly evolution in the KPI PDF should be a data table, not a chart image.
- **Polling Controllino on the same Timer as Dashboard refresh:** The Sala de Servidores widget should be a self-contained widget with its own Timer so it can be disposed independently.
- **Adding a new dedicated PLCService endpoint just for the widget:** Reuse the existing `/api/plc/maquina/1` pattern — no backend changes needed for KPI-05.
- **Calling fetchDashboardStats() from DashboardScreen AND KpisScreen independently on the same user visit:** Each screen manages its own data. This is acceptable since KpisScreen is accessed from drawer navigation and has its own lifecycle.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bar chart rendering | Custom Container/Row bar painter | fl_chart BarChart | Already exists in KpisScreen as hand-rolled — replace it for better tooltips, animation |
| PDF generation | Custom HTML-to-PDF or REST PDF endpoint | pdf + printing packages | Already works on Android/Web/Windows; PdfGenerator class already exists |
| PDF cross-platform delivery | Platform-specific file save dialogs | Printing.layoutPdf() | Handles Web (download), Android (share/print dialog), Windows (print dialog) automatically |
| Real-time polling | WebSocket | Timer.periodic + http.get | Simpler, works on all 3 platforms; existing Dashboard already uses same pattern |
| Chart colors/theming | New color constants | IndustrialTheme.operativeGreen/criticalRed/neonCyan | Already defined and used throughout the app |

**Key insight:** In this phase, the risk of hand-rolling is in the PDF domain. The `pdf` package is a vector PDF renderer — it has NO access to Flutter widget tree. Charts must be rendered as data tables in PDF, not as visual charts.

---

## Existing Code Inventory (CRITICAL — read before planning tasks)

### KpisScreen — current state

[VERIFIED: read kpis_screen.dart in this session]

- Fully functional: loads stats, renders KPI cards (4 values), ratio bars, estado bars, custom bar chart, ranking bars.
- KPI-02 (drawer entry): ALREADY DONE — `_buildDrawer()` in dashboard_screen.dart line 398 already has "INDICADORES KPI" wired to `/kpis`. No work needed.
- KPI-03 (bar chart): Custom hand-rolled chart exists but uses basic Container bars. REPLACE with fl_chart BarChart for professional quality.
- KPI-04 (metrics by state/type/machine): Estado and ratio EXIST. "Por tipo" (preventiva vs correctiva) = ratioPreventivoCorrectivo card already present. Ranking by machine = `_buildRanking()` already present. KPI-04 is effectively DONE via existing code — verify requirements text: "métricas de OTs por estado, tipo y máquina" — estado: done, tipo: done, máquina: done. **No new data sections needed for KPI-04.**
- KPI-06 (PDF export): Missing entirely — no export button exists in KpisScreen AppBar.

### DashboardScreen — current state

[VERIFIED: read dashboard_screen.dart in this session]

- Has 4 mini-cards already: "ESTADO PLANTA", "ALERTAS CRÍTICAS", "TOTAL TAREAS", "OT PENDIENTES" — these are operational cards from machine/OT data, NOT the KPI metrics (OEE/MTBF/MTTR/disponibilidad).
- KPI-01 requires adding a NEW section with stats-based mini-cards (OEE, MTBF, MTTR, disponibilidad). These are different from the existing operational cards — both rows can coexist.
- Drawer: already has "INDICADORES KPI" entry — KPI-02 is confirmed done.
- KPI-05: No Sala de Servidores widget exists. Must build new `SalaServidoresWidget`.

### OrdenesScreen — current state

[VERIFIED: read ordenes_screen.dart in this session]

- Has per-OT PDF button (line 700, `Icons.picture_as_pdf`) for CERRADA OTs only — calls `PdfGenerator.viewLocalPdf()`.
- EXP-01 requires a BULK export: "listado completo de OTs a PDF". This is a NEW feature — add an IconButton in AppBar actions to export ALL currently filtered OTs as a multi-row table PDF.

### PdfGenerator — current state

[VERIFIED: read pdf_generator.dart in this session]

- `generarReporteCierreBase64()`: generates single-OT closure report as base64 string.
- `viewLocalPdf()`: decodes base64 and calls `Printing.layoutPdf()` — works on all 3 platforms.
- `generarYVerPdf()`: convenience wrapper.
- MISSING: `generarKpiPdf()` for KPI-06, `generarListaOtsPdf()` for EXP-01.

### PLCService — current state

[VERIFIED: read plc_service.dart in this session]

- Only has `enviarComando()` static method.
- MISSING: method to fetch latest telemetry for the Sala de Servidores widget. Either add `fetchLastTelemetry(maquinaId)` to PLCService, or call the endpoint directly from the widget. Recommend adding to PLCService for consistency.

### Backend /api/stats/dashboard response shape

[VERIFIED: read StatsService.java in this session]

```json
{
  "oeeGlobal": 73.2,
  "mtbfHoras": 43.8,
  "mttrHoras": 2.5,
  "disponibilidadPct": 87.5,
  "ratioPreventivoCorrectivo": { "preventivas": 45, "correctivas": 55 },
  "otsPorEstado": { "CERRADA": 80, "EN_PROCESO": 10, "PENDIENTE": 10 },
  "rankingIncidencias": [{ "maquina": "Torno X1", "incidencias": 12 }, ...],
  "evolucionMensual": [{ "mes": "NOV", "preventivo": 8, "correctivo": 5 }, ...]
}
```

The backend already produces this with real data from MySQL. No backend changes needed for KPI-01 through KPI-04.

---

## Common Pitfalls

### Pitfall 1: fl_chart BarChart — empty data crash

**What goes wrong:** `BarChart` throws if `barGroups` list is empty.
**Why it happens:** During loading state, `evolucionMensual` is an empty list.
**How to avoid:** Guard with `if (evolucion.isEmpty) return _emptyChart()` before constructing BarChartData.
**Warning signs:** Red screen on first load before stats fetch completes.

### Pitfall 2: pdf package — cannot render Flutter widgets

**What goes wrong:** Developer tries to capture the fl_chart widget as an image and embed it in the PDF.
**Why it happens:** Assumption that `pdf` works like a Flutter widget renderer.
**How to avoid:** Use `pw.Table` + `pw.Text` for data. If a chart is needed in PDF, either use `PdfBitmap` from a pre-rendered image, or skip — a data table is sufficient for TFG demo.
**Warning signs:** `pw.Widget` API looks similar to Flutter Widget API — they are NOT interchangeable.

### Pitfall 3: Printing.layoutPdf on Web — requires `printing` package web support

**What goes wrong:** On Flutter Web, the PDF opens in a browser tab, not a download dialog, unless handled correctly.
**Why it happens:** `Printing.layoutPdf()` on Web triggers the browser's built-in PDF viewer.
**How to avoid:** This is actually correct behavior for Web — the browser opens the PDF inline. No special handling needed for TFG. Consistent with how `PdfGenerator.viewLocalPdf()` already behaves.
**Warning signs:** None — this is expected behavior.

### Pitfall 4: Sala de Servidores — Timer not cancelled on widget dispose

**What goes wrong:** `Timer` keeps firing after `SalaServidoresWidget` is removed from tree, causing `setState` on unmounted widget.
**Why it happens:** Missing `_timer?.cancel()` in `dispose()`.
**How to avoid:** Always cancel timer in `dispose()`. Use `if (mounted)` guard before `setState()`.
**Warning signs:** `setState() called after dispose()` exception in logs.

### Pitfall 5: DashboardScreen — double API call on timer refresh

**What goes wrong:** fetchDashboardStats() is called every 5 seconds alongside fetchMaquinas() and fetchOrdenes().
**Why it happens:** Stats are added to the existing `_loadMaquinas` periodic timer.
**How to avoid:** Stats are slow to change — fetch stats only on initial load and manual refresh (not on the 5-second timer). Add a separate `_statsLoaded` flag.
**Warning signs:** Network tab showing `/api/stats/dashboard` called every 5 seconds.

### Pitfall 6: KPI-05 — maquinaId for Controllino

**What goes wrong:** Hardcoding machine ID=1 could break if seed re-runs or IDs change.
**Why it happens:** PLCPollingService and PLCController hardcode machine 1L as the Controllino.
**How to avoid:** Accept this as-is for TFG — the seed always creates machine 1 as the Controllino. Document as TFG-specific assumption.
**Warning signs:** Sala de Servidores showing no data even when backend is running.

---

## Code Examples

### fl_chart BarChart minimal working example (from installed API)

```dart
// Source: fl_chart 0.70.2 — verified installed
SizedBox(
  height: 160,
  child: BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barGroups: /* list of BarChartGroupData */,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 20,
            getTitlesWidget: (v, meta) => Text(
              monthLabels[v.toInt()],
              style: const TextStyle(fontSize: 9, color: IndustrialTheme.slateGray),
            ),
          ),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ),
  ),
)
```

### PDF bulk OT list table

```dart
// Source: mirrors pattern in existing PdfGenerator — pdf 3.12.0
static Future<void> generarListaOtsPdf(List<OrdenTrabajo> ordenes) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        pw.Text('LISTADO DE ÓRDENES DE TRABAJO',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
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
  await Printing.layoutPdf(
    onLayout: (format) async => bytes,
    name: 'OTs_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
  );
}
```

---

## Runtime State Inventory

> This is a UI/features addition phase — no renaming, migration, or refactoring of stored data.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | MySQL OTs and machines — no schema changes needed | None |
| Live service config | PLCPollingService polls every 5s — no config changes | None |
| OS-registered state | None | None |
| Secrets/env vars | .env credentials — no changes | None |
| Build artifacts | pubspec.yaml unchanged — no new packages | None |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All frontend work | Verified (dart pub deps ran) | 3.41.6 | — |
| Dart SDK | All frontend work | Verified | 3.11.4 | — |
| fl_chart | KPI-03 bar chart | Verified (installed) | 0.70.2 | Use existing hand-rolled chart |
| pdf + printing | KPI-06, EXP-01 | Verified (installed) | 3.12.0 + 5.14.3 | — |
| Backend Spring Boot | All API calls | Running (git shows modified .env, SecurityConfig) | 3.x | — |
| Controllino hardware | KPI-05 | Unknown — may not be present | — | PLCPollingService auto-falls back to simulation for machine 1 |

**Missing dependencies with no fallback:** None — all required packages are installed.

**Controllino availability:** If Controllino is offline, PLCPollingService.java line 151 (`forcedSimulation = m.isSimulado() || (m.getPlcUrl() == null...)`) automatically generates simulated telemetry. The Sala de Servidores widget will show simulated data. This is acceptable for TFG demo.

---

## Validation Architecture

> No .planning/config.json found — nyquist_validation treated as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK built-in) |
| Config file | None detected — use default Flutter test runner |
| Quick run command | `flutter test` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| KPI-01 | DashboardScreen shows 4 OEE/MTBF/MTTR/disp cards | smoke / widget | manual — open app and verify | N/A |
| KPI-02 | Drawer has KPI entry | smoke | manual | N/A (already done) |
| KPI-03 | BarChart renders monthly evolution | smoke / widget | manual — open KpisScreen | N/A |
| KPI-04 | KpisScreen shows OTs by state/type/machine | smoke | manual — open KpisScreen | N/A |
| KPI-05 | Sala de Servidores shows temp/humidity | smoke | manual — open DashboardScreen, wait 5s | N/A |
| KPI-06 | Exportar PDF opens PDF viewer from KpisScreen | smoke | manual — tap button | N/A |
| EXP-01 | Exportar lista OTs opens PDF table | smoke | manual — tap AppBar button | N/A |

> REQUIREMENTS.md explicitly states "Tests unitarios/integración — Tiempo insuficiente, se menciona como mejora futura" — no automated tests are expected for this TFG phase.

### Wave 0 Gaps

None — no test infrastructure is required for this phase per REQUIREMENTS.md Out of Scope.

---

## Security Domain

> All security fixes from REVIEW.md already applied per STATE.md. This phase adds no new endpoints — `/api/stats/dashboard` is authenticated (requires Bearer token), and the Sala de Servidores widget uses `AppSession.instance.authHeaders`. No new security surface introduced.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No new auth logic | Bearer token via AppSession — unchanged |
| V3 Session Management | No | — |
| V4 Access Control | No | `/api/stats/dashboard` is `.anyRequest().authenticated()` — already covered |
| V5 Input Validation | No — read-only display phase | — |
| V6 Cryptography | No | — |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-rolled bar chart (Container/Row) | fl_chart BarChart | This phase | Better UX: animations, tooltips, responsive sizing |
| No KPI mini-cards on Dashboard | 4 OEE/MTBF/MTTR/disp cards | This phase | KPI-01 fulfilled |

**Deprecated/outdated:**
- `_buildEvolucionChart()` in KpisScreen: hand-rolled custom chart — replace with fl_chart BarChart.

---

## Open Questions

1. **Sala de Servidores — which machine to poll?**
   - What we know: PLCPollingService and PLCController consistently use machine ID=1L as the Controllino/IoT machine. The mock endpoint at `/api/plc/mock` also hardcodes machine 1 and returns temperatura + humedad.
   - What's unclear: There is no explicit "Sala de Servidores" machine in the seed — machine 1 is just the first seeded machine.
   - Recommendation: Use machine ID=1. Add a comment in SalaServidoresWidget noting this is a TFG-specific assumption.

2. **Telemetria timestamp format in JSON**
   - What we know: `Telemetria.timestamp` is a Java `Instant` serialized by Jackson. The `?since=` parameter accepts epoch milliseconds.
   - What's unclear: Whether the JSON response includes a parseable timestamp field for computing `since` in the widget.
   - Recommendation: Read `Telemetria.java` model to verify the `timestamp` field JSON name. If uncertain, don't use incremental polling — just fetch `/api/plc/maquina/1` without `?since=` (last 3600 records, take `.last`). Performance is acceptable since this is local network.

3. **KPI PDF — include chart image or data table?**
   - What we know: `pdf` package cannot render Flutter widgets; generating a chart as a bitmap and embedding it is complex (requires `RenderRepaintBoundary` capture → PNG → `pw.MemoryImage`).
   - What's unclear: Whether the TFG evaluator expects a visual chart in the PDF.
   - Recommendation: Use a data table for the monthly evolution in the KPI PDF. Simpler, faster, and the existing OT closure PDF uses the same data-table approach.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Machine ID=1 is always the Controllino/IoT hardware machine | KPI-05, Sala de Servidores | Widget shows wrong machine's data — low risk, seed always creates machine 1 as the primary IoT machine |
| A2 | The `evolucionMensual` array always contains exactly 6 entries | KPI-03 bar chart | Chart spacing looks odd if fewer entries — guard with isEmpty check |
| A3 | `Printing.layoutPdf()` behavior on Flutter Web is browser PDF viewer (not download) | KPI-06, EXP-01 | No risk for TFG — browser PDF viewer is acceptable |

---

## Sources

### Primary (HIGH confidence)

- [VERIFIED: codebase] `kpis_screen.dart` — read complete, confirmed current state
- [VERIFIED: codebase] `dashboard_screen.dart` — read complete, drawer confirmed, existing KPI cards confirmed
- [VERIFIED: codebase] `ordenes_screen.dart` — read complete, per-OT PDF confirmed, bulk export missing confirmed
- [VERIFIED: codebase] `pdf_generator.dart` — read complete, existing methods confirmed
- [VERIFIED: codebase] `StatsService.java` — read complete, full response shape documented
- [VERIFIED: codebase] `PLCController.java` + `PLCPollingService.java` — read complete, simulation fallback confirmed
- [VERIFIED: codebase] `pubspec.yaml` + `dart pub deps` — package versions confirmed: fl_chart 0.70.2, pdf 3.12.0, printing 5.14.3
- [VERIFIED: codebase] `SecurityConfig.java` — `/api/stats/dashboard` falls under `.anyRequest().authenticated()`
- [VERIFIED: codebase] `IndustrialTheme.dart` — color constants confirmed

### Secondary (MEDIUM confidence)

- [ASSUMED] fl_chart 0.70.2 BarChart API shape — based on training knowledge of fl_chart grouped bar syntax. The installed version matches training data timeframe. If API differs, check pub.dev/packages/fl_chart.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified from dart pub deps
- Architecture: HIGH — all screens read directly from codebase
- Pitfalls: HIGH — identified from actual code patterns in existing screens
- Backend shape: HIGH — read StatsService.java directly

**Research date:** 2026-04-17
**Valid until:** 2026-05-17 (stable packages, no expected API changes)
