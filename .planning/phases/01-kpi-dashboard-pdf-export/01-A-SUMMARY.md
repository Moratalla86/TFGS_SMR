---
phase: 1
plan: A
subsystem: frontend-plc-polling
tags: [flutter, plc, websocket, timer, live-data]
dependency_graph:
  requires: []
  provides: [PLCService.fetchLastTelemetry, SalaServidoresWidget]
  affects: [01-PLAN-C.md]
tech_stack:
  added: [flutter_animate]
  patterns: [Timer.periodic polling, if(mounted) guard, static service method]
key_files:
  created:
    - Frontend/meltic_gmao_app/lib/widgets/sala_servidores_widget.dart
  modified:
    - Frontend/meltic_gmao_app/lib/services/plc_service.dart
decisions:
  - Keep PLC calls in PLCService (not TelemetriaService) — single responsibility per service
  - Stale data shown on poll error (null values not cleared) — avoids flicker during transient failures
  - Machine ID=1 hardcoded in widget (TFG-specific Controllino assumption, documented inline)
metrics:
  duration: ~40min
  completed: 2026-04-19
  tasks_completed: 2
  tasks_total: 2
  files_changed: 2
---

# Phase 1 Plan A: PLC Polling Infrastructure Summary

**One-liner:** Static `PLCService.fetchLastTelemetry` + `SalaServidoresWidget` with Timer polling, live dot, and flutter_animate entrance animation for Sala de Servidores KPI-05.

## What Was Built

### Task 1 — PLCService.fetchLastTelemetry (commit: 10392bb)

Added `static Future<Telemetria?> fetchLastTelemetry(int maquinaId)` to the existing `PLCService` class. The method:
- Calls `GET /api/plc/maquina/{maquinaId}` with `AppSession.instance.authHeaders`
- Parses the JSON list and returns `body.last` as a `Telemetria?`
- Returns `null` (never throws) on empty body, non-200 status, or network error
- Uses `debugPrint` for error logging (no user-visible error state)

Added imports: `app_session.dart`, `../models/telemetria.dart`.

### Task 2 — SalaServidoresWidget (commit: ad528c8)

Created `lib/widgets/sala_servidores_widget.dart` — a self-contained StatefulWidget with:
- `Timer.periodic(5s)` calling `PLCService.fetchLastTelemetry(1)` on each tick
- `_timer?.cancel()` in `dispose()` before `super.dispose()`
- All `setState` calls guarded with `if (mounted)`
- `_live = false` on null/error (stale temperatura/humedad kept to avoid flicker)
- Temperature color thresholds: green (<25), orange (<35), red (>=35)
- `_SensorCard` sub-widget (Expanded container mirroring `_buildKpiCard` pattern)
- `_LiveDot` sub-widget: pulsing scale animate loop when live, static red dot when offline
- Entry animation: `.animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0)`

## Acceptance Criteria Results

| Criterion | Result |
|-----------|--------|
| `class SalaServidoresWidget extends StatefulWidget` | PASS |
| `Timer? _timer` | PASS |
| `_timer?.cancel()` in dispose() | PASS |
| `if (mounted)` before every setState | PASS |
| `PLCService.fetchLastTelemetry(1)` | PASS |
| `_live = false` in null/error branch | PASS |
| `class _SensorCard extends StatelessWidget` | PASS |
| `class _LiveDot extends StatelessWidget` | PASS |
| `.animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0)` | PASS |
| `.animate(onPlay: (c) => c.repeat()).scale` (multi-line) | PASS |
| `IndustrialTheme.neonCyan` | PASS |
| `flutter analyze` no errors | PASS (ran in 36s, "No issues found!") |

## Deviations from Plan

None — plan executed exactly as written. The `.animate(onPlay: (c) => c.repeat()).scale` acceptance criterion spans two lines in the actual file (Dart formatting), which is semantically identical to the single-line form in the criterion.

## Threat Model Compliance

| Threat ID | Mitigation | Status |
|-----------|------------|--------|
| T-1A-02 | `_timer?.cancel()` in dispose + `if (mounted)` guard | IMPLEMENTED |
| T-1A-03 | `AppSession.instance.authHeaders` — established pattern | IMPLEMENTED |

## Known Stubs

None — widget connects to live `PLCService.fetchLastTelemetry` which calls the real backend endpoint.

## Self-Check: PASSED

- `Frontend/meltic_gmao_app/lib/widgets/sala_servidores_widget.dart` — exists (commit ad528c8)
- `Frontend/meltic_gmao_app/lib/services/plc_service.dart` — modified (commit 10392bb)
- `flutter analyze` — No issues found
