---
phase: 01-kpi-dashboard-pdf-export
verified: 2026-04-19T00:00:00Z
status: human_needed
score: 5/5 must-haves verified
overrides_applied: 0
human_verification:
  - test: "KPI-01 — DashboardScreen KPI mini-cards render with real API values"
    expected: "4 mini-cards (OEE, MTBF, MTTR, DISPONIB.) appear below OT PENDIENTES row with numeric values and color-coded thresholds (green/orange/red)"
    why_human: "Cards only render when _kpiStats != null (guarded by if block). Requires live backend to call /api/stats/dashboard and return non-null map. Cannot verify rendering programmatically without running the app."
  - test: "KPI-03 — fl_chart BarChart renders monthly evolution bars"
    expected: "Bar chart in KpisScreen shows green (PREVENTIVO) and red (CORRECTIVO) bars per month from evolucionMensual data"
    why_human: "fl_chart rendering requires a running Flutter widget tree. Cannot verify chart output statically."
  - test: "KPI-05 — SalaServidoresWidget updates temperatura/humedad every 5 seconds"
    expected: "After 5 seconds the widget transitions from CircularProgressIndicator to sensor cards showing numeric values; green pulsing dot visible when connected"
    why_human: "Requires live Controllino/IoT backend at /api/plc/maquina/1. Real-time polling behavior needs visual confirmation over at least one timer cycle."
  - test: "KPI-06 — KpisScreen EXPORTAR PDF generates and opens a viewable PDF"
    expected: "Tapping EXPORTAR PDF: (1) SnackBar 'Generando PDF...' appears, (2) PDF viewer opens, (3) document shows INFORME KPI — MÈLTIC GMAO header with all 6 data sections"
    why_human: "Printing.layoutPdf opens the platform PDF viewer (Android share sheet / Windows print dialog). Cannot verify platform delivery or PDF content layout without running the app."
  - test: "EXP-01 — OrdenesScreen EXPORTAR PDF generates a 7-column OT table PDF"
    expected: "Tapping EXPORTAR PDF: (1) SnackBar 'Generando PDF con N ordenes de trabajo...' appears, (2) PDF viewer opens, (3) document shows LISTADO DE ORDENES DE TRABAJO header with all OT rows"
    why_human: "Same Printing.layoutPdf platform delivery concern. Content correctness (7 columns, correct OT data) requires visual inspection."
---

# Phase 1: KPI Dashboard + PDF Export — Verification Report

**Phase Goal:** El técnico puede consultar los KPIs operacionales con gráficas, ver el widget de Sala de Servidores en el dashboard y exportar informes a PDF.
**Verified:** 2026-04-19
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | El técnico abre DashboardScreen y ve 4 mini-cards (OEE, MTBF, MTTR, disponibilidad) con valores simulados realistas | VERIFIED (code) / human needed (render) | `dashboard_screen.dart` lines 263–309: `if (_kpiStats != null)` block renders 4 `_buildOperationalKpiCard` calls with OEE/MTBF/MTTR/DISPONIB. from `_kpiStats`. `StatsService().fetchDashboardStats()` populates `_kpiStats` from real API `/api/stats/dashboard`. |
| 2 | El técnico accede a KpisScreen desde el drawer lateral y ve una gráfica de barras de evolución mensual y métricas de OTs por estado, tipo y máquina | VERIFIED | Drawer: `dashboard_screen.dart` line 470 — `_drawerItem(Icons.bar_chart_rounded, "INDICADORES KPI", () { Navigator.of(context).pushNamed('/kpis'); })`. Chart: `kpis_screen.dart` lines 343–411 — `BarChart(BarChartData(...))` with `BarChartGroupData`/`BarChartRodData`. Metrics: `_buildRatioCard`, `_buildEstadoCard`, `_buildRanking` all called and defined. |
| 3 | El widget de Sala de Servidores en DashboardScreen muestra temperatura y humedad del Controllino actualizándose en tiempo real | VERIFIED (code) / human needed (live data) | `SalaServidoresWidget` embedded at `dashboard_screen.dart` line 321. Widget polls `PLCService.fetchLastTelemetry(1)` every 5s via `Timer.periodic`. `_timer?.cancel()` in dispose. All `setState` guarded with `if (mounted)`. |
| 4 | El técnico pulsa "Exportar PDF" en KpisScreen y recibe un PDF descargable con el informe de KPIs | VERIFIED (code) / human needed (platform delivery) | `kpis_screen.dart` line 47–60: ElevatedButton.icon EXPORTAR PDF, disabled when `_stats == null`. `_exportarPdf()` calls `PdfGenerator.generarKpiPdf(_stats!)`. `generarKpiPdf` confirmed at `pdf_generator.dart` line 391 with all 6 sections. `Printing.layoutPdf` at line 519. |
| 5 | El técnico pulsa "Exportar PDF" en OrdenesScreen y recibe un PDF con el listado completo de OTs | VERIFIED (code) / human needed (platform delivery) | `ordenes_screen.dart` line 265–283: ElevatedButton.icon EXPORTAR PDF, disabled when `_ordenes.isEmpty`. `_exportarListaOts()` calls `PdfGenerator.generarListaOtsPdf(_ordenes)`. `generarListaOtsPdf` at `pdf_generator.dart` line 525 with 7-column table. `Printing.layoutPdf` at line 573. |

**Score:** 5/5 truths verified at code level. All 5 require human verification for runtime/visual confirmation.

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Frontend/meltic_gmao_app/lib/services/plc_service.dart` | PLCService.fetchLastTelemetry static method | VERIFIED | `static Future<Telemetria?> fetchLastTelemetry(int maquinaId)` at line 49. Uses `AppSession.instance.authHeaders`, returns `body.last`. `fetchTelemetriaList` also present (added by Plan E for TelemetriaChartScreen). |
| `Frontend/meltic_gmao_app/lib/widgets/sala_servidores_widget.dart` | SalaServidoresWidget StatefulWidget with Timer polling | VERIFIED | File exists. `class SalaServidoresWidget extends StatefulWidget`, `Timer? _timer`, `_timer?.cancel()` in dispose, `if (mounted)` guards, `PLCService.fetchLastTelemetry(1)`, `_SensorCard`, `_LiveDot`, animate chain. InkWell wrapping added (Plan E checkpoint fix) — navigates to TelemetriaChartScreen. |
| `Frontend/meltic_gmao_app/lib/screens/telemetria_chart_screen.dart` | TelemetriaChartScreen (added at checkpoint) | VERIFIED | File exists. LineChart with temperature (criticalRed) and humidity (neonCyan) lines, pull-to-refresh, loading/error/empty states. Uses `PLCService.fetchTelemetriaList(1)`. |
| `Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart` | generarKpiPdf and generarListaOtsPdf static methods | VERIFIED | `generarKpiPdf` at line 391 (6 sections, `Printing.layoutPdf`). `generarListaOtsPdf` at line 525 (7-column table, `Printing.layoutPdf`). Existing methods unchanged (3 `Printing.layoutPdf` occurrences total). |
| `Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart` | KPI operational cards + SalaServidoresWidget embedding | VERIFIED | `_kpiStats` state field, `StatsService().fetchDashboardStats()` guarded with `!quiet && _kpiStats == null`, color helpers `_oeeColor/_mtbfColor/_mttrColor/_dispColor`, `_buildOperationalKpiCard`, `'KPIs OPERACIONALES'` section, `'SALA DE SERVIDORES'` section, `const SalaServidoresWidget()`, `'INDICADORES KPI'` drawer entry at line 470. |
| `Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart` | fl_chart BarChart + EXPORTAR PDF button | VERIFIED | `import 'package:fl_chart/fl_chart.dart'`, `BarChart(` line 345, `BarChartData(` line 346, `BarChartGroupData`, `BarChartRodData` (operativeGreen + criticalRed), `BarChartAlignment.spaceAround`, `BarTouchData(enabled: false)`, `FlGridData(show: false)`, `FlBorderData(show: false)`, `'SIN DATOS'` guard. ElevatedButton.icon EXPORTAR PDF at lines 47–60, `_exportarPdf()` at line 414, `PdfGenerator.generarKpiPdf(_stats!)`, `'Generando PDF...'` SnackBar, error SnackBar with `criticalRed`. |
| `Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart` | Bulk OT PDF export button in AppBar | VERIFIED | ElevatedButton.icon EXPORTAR PDF at lines 265–283 (electricBlue/spaceCadet style, matches KpisScreen — checkpoint fix applied). `onPressed: _ordenes.isEmpty ? null : () => _exportarListaOts()`. `_exportarListaOts()` at line 137. `PdfGenerator.generarListaOtsPdf(_ordenes)`. `'Generando PDF con ${_ordenes.length} ordenes de trabajo...'`. Per-OT `picture_as_pdf` button (lines 748, 788) is separate and unchanged. |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `SalaServidoresWidget._poll()` | `PLCService.fetchLastTelemetry(1)` | static method call | WIRED | `sala_servidores_widget.dart` line 40: `final Telemetria? t = await PLCService.fetchLastTelemetry(1);` |
| `_SalaServidoresWidgetState.dispose()` | `_timer` | cancel call | WIRED | `sala_servidores_widget.dart` line 33: `_timer?.cancel();` before `super.dispose()` |
| `SalaServidoresWidget` (tap) | `TelemetriaChartScreen` | InkWell Navigator.push | WIRED | `sala_servidores_widget.dart` lines 79–83: `onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelemetriaChartScreen()))` |
| `DashboardScreen._loadMaquinas()` | `StatsService().fetchDashboardStats()` | conditional call | WIRED | `dashboard_screen.dart` lines 67–74: `if (!quiet && _kpiStats == null) { try { final stats = await StatsService().fetchDashboardStats(); if (mounted) setState(...) } catch (_) {} }` |
| `DashboardScreen body` | `SalaServidoresWidget()` | widget embedding | WIRED | `dashboard_screen.dart` line 321: `const SalaServidoresWidget()` |
| `KpisScreen AppBar actions` | `PdfGenerator.generarKpiPdf(_stats!)` | `_exportarPdf()` method | WIRED | `kpis_screen.dart` line 422: `await PdfGenerator.generarKpiPdf(_stats!);` inside `_exportarPdf()`, triggered by ElevatedButton.icon `onPressed: _stats == null ? null : () => _exportarPdf()` |
| `OrdenesScreen AppBar IconButton` | `PdfGenerator.generarListaOtsPdf(_ordenes)` | `_exportarListaOts()` method | WIRED | `ordenes_screen.dart` line 146: `await PdfGenerator.generarListaOtsPdf(_ordenes);` inside `_exportarListaOts()`, triggered by ElevatedButton.icon `onPressed: _ordenes.isEmpty ? null : () => _exportarListaOts()` |
| `_buildEvolucionChart` | `BarChart(BarChartData(...))` | fl_chart replacement | WIRED | `kpis_screen.dart` lines 343–411: `SizedBox(height: 160, child: BarChart(BarChartData(...)))` with `evolucion` data from `_stats['evolucionMensual']` |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `dashboard_screen.dart` KPI cards | `_kpiStats` | `StatsService().fetchDashboardStats()` → GET `/api/stats/dashboard` | Yes — `stats_service.dart` performs a real HTTP GET with Bearer auth and decodes JSON response body | FLOWING |
| `sala_servidores_widget.dart` | `_temperatura`, `_humedad` | `PLCService.fetchLastTelemetry(1)` → GET `/api/plc/maquina/1` | Yes — `plc_service.dart` performs a real HTTP GET with Bearer auth, decodes JSON list, returns `body.last` as `Telemetria?` | FLOWING |
| `kpis_screen.dart` BarChart | `evolucion` (from `_stats['evolucionMensual']`) | `StatsService().fetchDashboardStats()` → GET `/api/stats/dashboard` | Yes — same StatsService real HTTP call; `evolucion` is extracted from the live API response | FLOWING |
| `pdf_generator.dart` generarKpiPdf | `stats` param | Caller passes `_stats!` (KpisScreen's live stats map) | Yes — data is already fetched from `/api/stats/dashboard`; no hardcoded values in PDF build | FLOWING |
| `pdf_generator.dart` generarListaOtsPdf | `ordenes` param | Caller passes `_ordenes` (OrdenesScreen's fetched OT list) | Yes — data is fetched from backend via `OrdenTrabajoService.fetchOrdenes()`; no hardcoded values | FLOWING |

---

### Behavioral Spot-Checks

Step 7b: SKIPPED — requires running Flutter app with live backend. All entry points are Flutter UI widgets that cannot be tested without `flutter run`.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| KPI-01 | Plan C | 4 KPI mini-cards (OEE, MTBF, MTTR, disponibilidad) in DashboardScreen | SATISFIED | `_buildOperationalKpiCard` called 4× in dashboard body guarded by `if (_kpiStats != null)` |
| KPI-02 | Plans C, D | Drawer entry navigates to KpisScreen | SATISFIED | `dashboard_screen.dart` line 470: `_drawerItem("INDICADORES KPI", () => pushNamed('/kpis'))` |
| KPI-03 | Plan D | KpisScreen bar chart of monthly evolution | SATISFIED | `kpis_screen.dart` lines 343–411: `BarChart(BarChartData(...))` with fl_chart |
| KPI-04 | Plan D (existing) | KpisScreen OTs por estado, tipo, máquina metrics | SATISFIED | `_buildRatioCard`, `_buildEstadoCard`, `_buildRanking` all defined and called in `_buildBody()` |
| KPI-05 | Plans A, C, E | Sala de Servidores widget with real-time temp/humidity | SATISFIED (code) | `SalaServidoresWidget` polls `PLCService.fetchLastTelemetry(1)` every 5s; embedded in DashboardScreen; navigates to `TelemetriaChartScreen` |
| KPI-06 | Plans B, D | Export KPI report to PDF from KpisScreen | SATISFIED (code) | ElevatedButton.icon EXPORTAR PDF → `PdfGenerator.generarKpiPdf` → `Printing.layoutPdf` |
| EXP-01 | Plans B, E | Export OT list to PDF from OrdenesScreen | SATISFIED (code) | ElevatedButton.icon EXPORTAR PDF → `PdfGenerator.generarListaOtsPdf` → `Printing.layoutPdf` |

No orphaned requirements — all 7 Phase 1 requirements are covered.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `telemetria_chart_screen.dart` | 164–165 | `tempSpots.add(FlSpot(..., readings[i].temperatura))` — `Telemetria.temperatura` is accessed as non-nullable Double directly | Info | Plan E added `fetchTelemetriaList` which returns `List<Telemetria>`; the `Telemetria` model's `temperatura`/`humedad` are typed as non-nullable `double`. Verify `Telemetria.fromJson` enforces this (null backend values would produce 0.0). No visual stub — data flows from real API. |

No blockers. No TODO/FIXME/placeholder comments found in phase files. No empty return stubs. No hardcoded empty collections flowing to UI.

---

### Human Verification Required

#### 1. KPI-01 — DashboardScreen KPI Mini-Cards

**Test:** Open the app, log in, navigate to DashboardScreen. Scroll down past the 4 operational cards (ESTADO PLANTA, ALERTAS CRITICAS, TOTAL TAREAS, OT PENDIENTES). Verify a "KPIs OPERACIONALES" section header appears with 4 cards: OEE (%), MTBF (h), MTTR (h), DISPONIB. (%).

**Expected:** Numeric values are shown (not "--" or 0.0). Card border colors reflect threshold state (green = target met, orange = warning, red = critical). If the backend is unreachable, the section should simply not appear (graceful degradation).

**Why human:** Cards are rendered inside `if (_kpiStats != null)` — only visible after live API response from `/api/stats/dashboard`.

---

#### 2. KPI-03 — KpisScreen fl_chart BarChart

**Test:** Navigate to KpisScreen via the drawer "INDICADORES KPI" entry. Scroll to the "EVOLUCION MENSUAL (ULTIMOS 6 MESES)" section.

**Expected:** A bar chart appears with grouped bars per month: green bars (PREVENTIVO) and red bars (CORRECTIVO). Month labels appear on x-axis. Legend (green/red dots) appears below the chart. No hand-rolled bars.

**Why human:** fl_chart rendering requires a running Flutter widget tree with mounted canvas.

---

#### 3. KPI-05 — SalaServidoresWidget Live Polling

**Test:** From DashboardScreen, scroll past KPIs OPERACIONALES to the "SALA DE SERVIDORES" section. Wait at least 5 seconds.

**Expected:** (a) On first load: loading spinner (CircularProgressIndicator) briefly visible. (b) After poll: two sensor cards TEMPERATURA (degrees C) and HUMEDAD (%). (c) If Controllino is connected: green pulsing dot visible. (d) Tap the widget — navigates to TelemetriaChartScreen with a LineChart showing historical readings.

**Why human:** Requires live Controllino backend at `/api/plc/maquina/1`. Timer polling behavior needs at least one 5-second cycle to observe.

---

#### 4. KPI-06 — KpisScreen PDF Export

**Test:** On KpisScreen, verify the "EXPORTAR PDF" button is visible in the AppBar. Wait for stats to load (button enabled = not disabled). Tap the button.

**Expected:** (1) SnackBar "Generando PDF..." appears immediately. (2) Platform PDF viewer opens (Android share sheet OR Windows print dialog). (3) PDF shows "INFORME KPI — MELTIC GMAO" header, generation timestamp, and 6 data sections (KPI table, distribucion, estado, evolucion mensual, ranking).

**Why human:** `Printing.layoutPdf` opens the platform-native PDF delivery surface — cannot verify programmatically.

---

#### 5. EXP-01 — OrdenesScreen OT List PDF Export

**Test:** Navigate to OrdenesScreen via the drawer "ORDENES DE TRABAJO" entry. Wait for OTs to load. Verify the "EXPORTAR PDF" button is visible in the AppBar (ElevatedButton.icon, electricBlue style). Tap it.

**Expected:** (1) SnackBar "Generando PDF con N ordenes de trabajo..." appears with actual count. (2) Platform PDF viewer opens. (3) PDF shows "LISTADO DE ORDENES DE TRABAJO" header and a 7-column table (#, MAQUINA, TECNICO, TIPO, ESTADO, PRIORIDAD, FECHA) with one row per OT.

**Why human:** `Printing.layoutPdf` platform delivery and PDF column layout require visual inspection.

---

### Gaps Summary

No gaps found. All 5 roadmap success criteria are satisfied at code level:

- All required artifacts exist, are substantive (not stubs), and are wired
- Data flows from real API endpoints through all rendering paths
- PDF infrastructure uses live in-memory data (no hardcoded placeholders)
- Both PDF methods call `Printing.layoutPdf` for cross-platform delivery
- Checkpoint feedback fixes applied (ElevatedButton.icon style unified across KpisScreen and OrdenesScreen; TelemetriaChartScreen added; SalaServidoresWidget navigates to live chart) — human-approved

Human verification is required for 5 runtime behaviors (card rendering with live API, chart rendering, timer polling observation, and platform PDF delivery on both screens). These are standard UI/runtime verifications that cannot be replaced by static analysis.

---

_Verified: 2026-04-19_
_Verifier: Claude (gsd-verifier)_
