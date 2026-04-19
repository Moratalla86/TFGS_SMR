---
phase: 1
plan: D
subsystem: frontend/kpis
tags: [fl_chart, bar-chart, pdf-export, kpis-screen]
dependency_graph:
  requires: [plan-B]
  provides: [fl_chart-bar-chart, pdf-export-button]
  affects: [Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart]
tech_stack:
  added: []
  patterns: [fl_chart BarChart, ElevatedButton.icon in AppBar, SnackBar feedback, try/catch async error handling]
key_files:
  modified:
    - Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart
decisions:
  - "Removed unused _bar() helper method (replaced by fl_chart rod rendering)"
  - "Kept .animate().fadeIn() wrapper on the Container — only the inner SizedBox content was replaced"
  - "Stats field confirmed as _stats (Map<String, dynamic>?) — button uses _stats == null check"
metrics:
  duration: "~2 minutes"
  completed: "2026-04-19T09:12:30Z"
  tasks_completed: 2
  files_modified: 1
---

# Phase 1 Plan D: fl_chart BarChart + EXPORTAR PDF Button Summary

**One-liner:** fl_chart BarChart with grouped green/red bars replaces hand-rolled chart; EXPORTAR PDF ElevatedButton added to KpisScreen AppBar calling PdfGenerator.generarKpiPdf.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Replace hand-rolled bar chart with fl_chart BarChart | 6e8f137 | kpis_screen.dart |
| 2 | Add EXPORTAR PDF button to AppBar + verify KPI-02/KPI-04 | 6e8f137 | kpis_screen.dart |

Note: Both tasks modified only `kpis_screen.dart` and were committed together in one atomic commit.

## Implementation Details

### Stats Field Name

The actual field name in `_KpisScreenState` is `_stats` (type `Map<String, dynamic>?`), declared at line 18. The button uses `_stats == null ? null : () => _exportarPdf()` as specified.

### fl_chart BarChart (Task 1)

- Replaced the hand-rolled `SizedBox(height: barMaxH+32, child: Row(...))` with `SizedBox(height: 160, child: BarChart(BarChartData(...)))`
- Removed stale local variables `maxVal` and `barMaxH` (no longer needed)
- Removed unused `_bar()` helper method — fl_chart handles rod rendering internally
- `BarChartAlignment.spaceAround`, `maxY` computed via `fold` with `* 1.25` multiplier, minimum 1.0
- Two rods per group: `operativeGreen` (preventivo), `criticalRed` (correctivo), width 8, `BorderRadius.vertical(top: Radius.circular(3))`
- `BarTouchData(enabled: false)` — no tooltips
- `FlGridData(show: false)`, `FlBorderData(show: false)`
- Bottom titles with month labels from `evolucion[idx]['mes']`, `reservedSize: 20`, fontSize 9, slateGray
- Left/top/right titles hidden
- Empty guard at top of `_buildEvolucionChart()` returns SIN DATOS container (height 160) — preserved unchanged
- Outer Container `.animate().fadeIn(duration: 500.ms, delay: 400.ms)` preserved
- Legend row (`_legend()` calls) preserved unchanged

### EXPORTAR PDF Button (Task 2)

- `ElevatedButton.icon` added to AppBar actions, LEFT of refresh IconButton
- Wrapped in `Padding(EdgeInsets.symmetric(vertical: 8, horizontal: 4))` to prevent AppBar overflow
- `backgroundColor: IndustrialTheme.electricBlue`, `foregroundColor: IndustrialTheme.spaceCadet`
- `onPressed: _stats == null ? null : () => _exportarPdf()` — disabled while loading
- `_exportarPdf()` method: shows `SnackBar('Generando PDF...')` immediately, calls `PdfGenerator.generarKpiPdf(_stats!)`, catches exceptions with error SnackBar (`criticalRed` background)
- Added imports: `package:fl_chart/fl_chart.dart`, `dart:math show max`, `../utils/pdf_generator.dart`

### KPI-02 Verification

Confirmed: `dashboard_screen.dart` line 470 — `_drawerItem(Icons.bar_chart_rounded, "INDICADORES KPI", () { Navigator.of(context).pushNamed('/kpis'); })`. No code change needed.

### KPI-04 Verification

Confirmed: `kpis_screen.dart` contains all three required OT metric sections:
- `_buildRatioCard(ratio)` — OTs por tipo (PREVENTIVAS / CORRECTIVAS)
- `_buildEstadoCard(porEstado)` — OTs por estado (CERRADAS / EN PROCESO / PENDIENTES)
- `_buildRanking(ranking)` — ranking de incidencias por máquina

No code change needed. KPI-04 was already complete.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed stale maxVal/barMaxH variables**
- **Found during:** Task 1
- **Issue:** After replacing the hand-rolled chart body, the local variables `maxVal` and `barMaxH` computed for the old chart remained in the method, causing unused-variable warnings
- **Fix:** Removed the for-loop and variable declarations; maxY is now computed inline via `fold` in `BarChartData`
- **Files modified:** Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart
- **Commit:** 6e8f137

**2. [Rule 1 - Bug] Removed unused _bar() helper method**
- **Found during:** Task 1
- **Issue:** `Widget _bar(double height, Color color)` was only called from the hand-rolled chart body. After replacement, it became a dead method that flutter analyze would flag
- **Fix:** Removed the method entirely; fl_chart handles rod rendering via `BarChartRodData`
- **Files modified:** Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart
- **Commit:** 6e8f137

## flutter analyze Result

```
Analyzing kpis_screen.dart...
No issues found! (ran in 4.6s)
```

## Known Stubs

None — all data is wired from `_stats` map populated by `StatsService.fetchDashboardStats()`. No hardcoded placeholders or empty collections flow to the UI.

## Threat Flags

No new network endpoints, auth paths, or file access patterns introduced. PDF export is client-side only via `Printing.layoutPdf`. All threats from plan's threat_model have been mitigated:

- T-1D-01: Empty guard confirmed present (lines 305-315)
- T-1D-02: Button disabled via `_stats == null ? null : ...`
- T-1D-03: try/catch in `_exportarPdf()` with error SnackBar
- T-1D-05: All bar values use `?? 0` fallback

## Self-Check: PASSED

- [x] `Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart` — exists and modified
- [x] Commit 6e8f137 — confirmed in git log
- [x] `flutter analyze` — no issues
- [x] All success criteria grep patterns verified
