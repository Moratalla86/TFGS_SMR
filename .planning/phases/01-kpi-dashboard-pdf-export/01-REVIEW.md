---
phase: 01-kpi-dashboard-pdf-export
reviewed: 2026-04-19T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart
  - Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart
  - Frontend/meltic_gmao_app/lib/screens/telemetria_chart_screen.dart
  - Frontend/meltic_gmao_app/lib/services/plc_service.dart
  - Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart
  - Frontend/meltic_gmao_app/lib/widgets/sala_servidores_widget.dart
  - Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart
findings:
  critical: 2
  warning: 6
  info: 5
  total: 13
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-04-19T00:00:00Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

This phase adds KPI PDF export to `KpisScreen`, a bulk OT list PDF export to `OrdenesScreen`, a new `TelemetriaChartScreen` with a line chart of temperature/humidity readings, and a `SalaServidoresWidget` that navigates to that chart. `DashboardScreen` embeds the new widget and adds operational KPI mini-cards.

The code is overall well-structured and follows Flutter lifecycle patterns correctly (all `setState` calls are guarded with `mounted`, timers are cancelled in `dispose`). The main concerns are:

1. **Two critical issues** — a silent error suppression in `PdfGenerator.generarReporteCierreBase64` that destroys the error signal to callers, and an unauthenticated API call in `PLCService.enviarComando` which sends commands without an auth token.
2. **Several warnings** — a `DateTime.parse` call that can throw inside `generarListaOtsPdf`, an export button that uses `_ordenes` instead of `_filteredOrdenes` (user-visible bug), inconsistent KPI color thresholds across Dashboard and KpisScreen, a missing validation on the OT description field, and an unguarded `!` operator on `_session.userId`.
3. **A handful of info items** — duplicate color-threshold helpers, a `_loadData` wrapper that adds no value, and a few minor style notes.

---

## Critical Issues

### CR-01: Silent `catch` in `generarReporteCierreBase64` discards all errors and returns `null`

**File:** `Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart:355-357`

**Issue:** The top-level `try/catch` in `generarReporteCierreBase64` catches every exception and returns `null` without logging or re-throwing. The caller `generarYVerPdf` (line 386) silently skips `viewLocalPdf` when `b64` is null, so any PDF-generation failure — including a corrupted base64 image, a PDF-library panic, or an out-of-memory error — is completely invisible to the user and to log output. `debugPrint` is already used everywhere else in the codebase for exactly this purpose.

```dart
// current (line 354-357)
} catch (e) {
  return null;
}

// fix: log the error so failures are diagnosable
} catch (e, st) {
  debugPrint('PdfGenerator.generarReporteCierreBase64 error: $e\n$st');
  return null;
}
```

Additionally, callers that invoke `generarYVerPdf` (e.g. `OrdenesScreen._verReportePdf` at line 133) should surface the failure to the user when `b64` is null:

```dart
// in generarYVerPdf
if (b64 != null) {
  await viewLocalPdf(b64, 'Reporte_OT_${ot.id}.pdf');
} else {
  // propagate failure to caller so UI can show a SnackBar
  throw Exception('PDF generation failed');
}
```

---

### CR-02: `PLCService.enviarComando` sends commands without an auth token

**File:** `Frontend/meltic_gmao_app/lib/services/plc_service.dart:11-23`

**Issue:** `enviarComando` builds the HTTP request with only `Content-Type` in the headers, omitting `AppSession.instance.authHeaders`. Every other HTTP call in the same file (`fetchTelemetriaList`, line 32; `fetchLastTelemetry`, line 52) correctly attaches the auth header. An unauthenticated POST to `/api/plc/comando` means any process on the same network can trigger PLC commands if the backend does not enforce its own auth check independently. Even if the backend does enforce auth, this silently fails with a 401 and returns `false`, giving the caller no distinction between a network error and an auth error.

```dart
// current
headers: {'Content-Type': 'application/json'},

// fix
headers: {
  'Content-Type': 'application/json',
  ...AppSession.instance.authHeaders,
},
```

---

## Warnings

### WR-01: `DateTime.parse` in `generarListaOtsPdf` can throw, crashing PDF generation

**File:** `Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart:552`

**Issue:** `DateTime.parse(ot.fechaCreacion!)` is called without a try/catch or null-safe fallback. If `fechaCreacion` contains a malformed date string, `parse` throws a `FormatException`, which propagates out of the `data:` map builder and crashes the entire PDF export. `OrdenesScreen._formatDate` (line 829) already handles this correctly with `DateTime.tryParse`. Apply the same pattern here.

```dart
// current
ot.fechaCreacion != null
    ? DateFormat('dd/MM/yy').format(DateTime.parse(ot.fechaCreacion!))
    : '-',

// fix
ot.fechaCreacion != null
    ? () {
        final d = DateTime.tryParse(ot.fechaCreacion!);
        return d != null ? DateFormat('dd/MM/yy').format(d) : '-';
      }()
    : '-',
```

---

### WR-02: Bulk PDF export uses `_ordenes` (all) instead of `_filteredOrdenes` (visible subset)

**File:** `Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart:146` and `266`

**Issue:** The "EXPORTAR PDF" button and the snackbar message both reference `_ordenes` (the unfiltered full list). When the user has applied machine or date filters, they see a filtered list in the UI but the exported PDF always contains every work order. This is a user-visible logic bug — the PDF does not match what is displayed.

The button's `onPressed` guard (line 266) also uses `_ordenes.isEmpty`, which means the button is enabled even when `_filteredOrdenes` is empty (the user sees "SIN RESULTADOS" but the export button is still active).

```dart
// current (line 266)
onPressed: _ordenes.isEmpty ? null : () => _exportarListaOts(),

// fix
onPressed: _filteredOrdenes.isEmpty ? null : () => _exportarListaOts(),

// and in _exportarListaOts (line 141-146):
// pass _filteredOrdenes to the snackbar and to PdfGenerator.generarListaOtsPdf
SnackBar(content: Text('Generando PDF con ${_filteredOrdenes.length} órdenes...')),
// ...
await PdfGenerator.generarListaOtsPdf(_filteredOrdenes);
```

---

### WR-03: `_session.userId!` force-unwrap without null guard in `_load`

**File:** `Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart:55`

**Issue:** `_otService.fetchOrdenesPorTecnico(_session.userId!)` force-unwraps `userId` which is typed as `int?`. If the session is in an inconsistent state (e.g., a non-jefe user whose `userId` was not set during login), this throws a `Null check operator used on a null value` at runtime. The surrounding `try/catch` will absorb it, but only after showing a generic connection-error UI rather than a meaningful message.

```dart
// fix: guard before calling
final uid = _session.userId;
if (uid == null) {
  setState(() { _error = 'Sesión inválida. Vuelve a iniciar sesión.'; _loading = false; });
  return;
}
data = await _otService.fetchOrdenesPorTecnico(uid);
```

---

### WR-04: OT description field has no validation — an empty OT can be submitted

**File:** `Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart:910-916`

**Issue:** `_guardar` (line 1062) calls `_formKey.currentState!.validate()`, but the description `TextFormField` has no `validator` callback. This means the form always passes validation, and a work order with an empty description can be submitted to the backend. If the backend rejects it (e.g., NOT NULL constraint), the error is shown as a raw exception string in a SnackBar.

```dart
// fix: add validator to the description field
TextFormField(
  controller: _desc,
  maxLines: 2,
  decoration: const InputDecoration(labelText: "DESCRIPCIÓN DE LA AVERÍA"),
  validator: (v) =>
      (v == null || v.trim().isEmpty) ? 'La descripción es obligatoria' : null,
),
```

---

### WR-05: Inconsistent KPI color thresholds between `DashboardScreen` and `KpisScreen`

**File:** `Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart:574-584` vs `Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart:519-526`

**Issue:** The same four KPI metrics (OEE, MTBF, MTTR, DISPONIBILIDAD) use different color thresholds depending on which screen renders them. For example:

| Metric | DashboardScreen green | KpisScreen green |
|--------|-----------------------|-----------------|
| OEE    | >= 85                 | >= 75           |
| MTBF   | >= 48 h               | >= 100 h        |
| MTTR   | <= 2 h                | <= 4 h          |
| DISP   | >= 90 %               | >= 85 %         |

A value of OEE=80% shows green on KpisScreen but orange on DashboardScreen. This erodes user trust and is a correctness issue for an industrial monitoring tool. The thresholds should be defined once in a shared constant (e.g., `IndustrialTheme` or a dedicated `KpiThresholds` class) and referenced from both screens.

---

### WR-06: `TelemetriaChartScreen` temperature "good" state is never reachable — all temps render warning or critical

**File:** `Frontend/meltic_gmao_app/lib/screens/telemetria_chart_screen.dart:256-258`

**Issue:** `_buildLastValues` computes `tempColor` as:

```dart
final tempColor = last.temperatura >= 35.0
    ? IndustrialTheme.criticalRed
    : IndustrialTheme.warningOrange;
```

There is no green/normal branch. Any temperature below 35°C is shown in `warningOrange`, including e.g. 18°C, which is perfectly safe. In contrast, `SalaServidoresWidget._tempColor` has three correct bands: green below 25°C, orange 25–35°C, red ≥35°C (line 57-61). The chart screen should use the same logic.

```dart
// fix
final tempColor = last.temperatura >= 35.0
    ? IndustrialTheme.criticalRed
    : last.temperatura >= 25.0
        ? IndustrialTheme.warningOrange
        : IndustrialTheme.operativeGreen;
```

---

## Info

### IN-01: Duplicate KPI color-threshold helpers across two screens

**File:** `Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart:574-584` and `Frontend/meltic_gmao_app/lib/screens/kpis_screen.dart:519-526`

**Issue:** `_oeeColor`, `_mtbfColor`, `_mttrColor`, `_dispColor` are private instance methods duplicated in both screen classes (with differing values, see WR-05). Extracting them to a shared utility removes both the duplication and the threshold inconsistency in one change.

**Fix:** Move to a `KpiColors` static class or add constants to `IndustrialTheme`.

---

### IN-02: `_loadData` wrapper in `DashboardScreen` is dead forwarding code

**File:** `Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart:50-52`

**Issue:** `_loadData` exists solely to call `_loadMaquinas`. It adds a layer of indirection with no additional logic and is only called from two places that could call `_loadMaquinas` directly. It also has a `quiet` parameter that is passed but the two callers always use the default.

**Fix:** Remove `_loadData` and call `_loadMaquinas()` directly from the refresh button (line 183) and the retry button (line 223).

---

### IN-03: `fetchTelemetriaList` and `fetchLastTelemetry` make redundant full-list requests

**File:** `Frontend/meltic_gmao_app/lib/services/plc_service.dart:28-65`

**Issue:** Both methods call the same endpoint (`GET /api/plc/maquina/{id}`) and return the full list. `fetchLastTelemetry` then discards all but the last element on the client side. If the backend grows to return thousands of records, this wastes bandwidth on every 5-second poll. The comment on line 45-48 acknowledges this. It is noted here as an architectural observation — not a blocker for the current TFG data volume — but worth a backend endpoint (`/api/plc/maquina/{id}/last`) if the dataset grows.

**Fix (deferred):** Add a dedicated `/last` backend endpoint, or at minimum document the payload size concern.

---

### IN-04: Commented-out code artifact in `pdf_generator.dart`

**File:** `Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart:63-65`

**Issue:** The `map(...)` call on checklist entries ends with a trailing comma followed by an empty line before the closing bracket (lines 63-65). While syntactically valid in Dart, the blank line between the last mapped widget and the closing `]` of the `children` list looks like leftover editing debris and reduces readability.

**Fix:** Remove the trailing blank line inside the `children` list literal.

---

### IN-05: `_buildAlertaItem` alarm description is always hardcoded regardless of machine state

**File:** `Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart:675`

**Issue:** Every machine in a non-OK state shows the fixed string `"Corte de telemetría detectado"` regardless of the actual `estado` value. If the `Maquina` model carries a richer status (e.g., "EN_MANTENIMIENTO", "AVERÍA"), this message is misleading.

**Fix:** Use `m.estado` or a helper to derive a human-readable alarm reason, e.g.:
```dart
Text(
  m.estado == 'EN_MANTENIMIENTO'
      ? 'En mantenimiento programado'
      : 'Corte de telemetría detectado',
  ...
)
```

---

_Reviewed: 2026-04-19T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
