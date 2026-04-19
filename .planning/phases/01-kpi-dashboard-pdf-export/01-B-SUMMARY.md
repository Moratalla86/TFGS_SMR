---
phase: 1
plan: B
subsystem: frontend/pdf
tags: [pdf, kpi, ordenes-trabajo, printing]
dependency_graph:
  requires: []
  provides: [PdfGenerator.generarKpiPdf, PdfGenerator.generarListaOtsPdf]
  affects: [KpisScreen, OrdenesScreen]
tech_stack:
  added: []
  patterns: [pw.TableHelper.fromTextArray, Printing.layoutPdf, null-coalescing cast guards]
key_files:
  modified:
    - Frontend/meltic_gmao_app/lib/utils/pdf_generator.dart
decisions:
  - Both methods added in a single commit (single file, single edit); no intermediate broken state introduced
  - OrdenTrabajo field names confirmed matching plan spec (maquinaNombre, tecnicoNombre, tipo, estado, prioridad, fechaCreacion)
  - Monthly evolution rendered as data table (not chart) — pdf package cannot access Flutter widget tree
metrics:
  duration: "105s"
  completed: "2026-04-19"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
---

# Phase 1 Plan B: PDF Generator Methods Summary

One-liner: Added `generarKpiPdf` (6-section A4 KPI report) and `generarListaOtsPdf` (7-column A4 OT table) to PdfGenerator using `pw.*` widgets and `Printing.layoutPdf` for cross-platform delivery.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add generarKpiPdf static method | 4ed1d24 | pdf_generator.dart |
| 2 | Add generarListaOtsPdf static method | 4ed1d24 | pdf_generator.dart |

## Methods Added

### PdfGenerator.generarKpiPdf(Map<String, dynamic> stats)

- **Signature:** `static Future<void> generarKpiPdf(Map<String, dynamic> stats)`
- **Sections:**
  1. Header: title + generation timestamp
  2. KPI values table: OEE, MTBF, MTTR, DISPONIBILIDAD (headers: KPI / VALOR / DESCRIPCIÓN)
  3. Distribución de mantenimiento: preventivas vs correctivas with % (headers: TIPO / CANTIDAD / PORCENTAJE)
  4. Órdenes por estado: CERRADA, EN PROCESO, PENDIENTE with % (headers: ESTADO / CANTIDAD / PORCENTAJE)
  5. Evolución mensual: data table MES / PREVENTIVAS / CORRECTIVAS / TOTAL
  6. Ranking de incidencias: top-5 machines (headers: # / MÁQUINA / INCIDENCIAS)
- **Delivery:** `Printing.layoutPdf` with filename `KPI_Report_yyyyMMdd_HHmm.pdf`

### PdfGenerator.generarListaOtsPdf(List<OrdenTrabajo> ordenes)

- **Signature:** `static Future<void> generarListaOtsPdf(List<OrdenTrabajo> ordenes)`
- **Table headers:** # / MÁQUINA / TÉCNICO / TIPO / ESTADO / PRIORIDAD / FECHA
- **Column widths:** FixedColumnWidth(25) for #, FlexColumnWidth(2) for MÁQUINA/TÉCNICO, FixedColumnWidth(60/55/50/50) for remaining
- **Date format:** `dd/MM/yy` via `DateFormat('dd/MM/yy').format(DateTime.parse(...))`
- **Delivery:** `Printing.layoutPdf` with filename `OTs_yyyyMMdd_HHmm.pdf`

## OrdenTrabajo Field Verification

Fields match plan spec exactly — no adjustments needed:

| Plan field | Actual field | Status |
|------------|-------------|--------|
| `id` | `id` (int) | OK |
| `maquinaNombre` | `maquinaNombre` (String?) | OK |
| `tecnicoNombre` | `tecnicoNombre` (String?) | OK |
| `tipo` | `tipo` (String?) | OK |
| `estado` | `estado` (String) | OK |
| `prioridad` | `prioridad` (String) | OK |
| `fechaCreacion` | `fechaCreacion` (String?) | OK |

## Verification Results

1. `generarKpiPdf` definition found at line 391
2. `generarListaOtsPdf` definition found at line 525
3. `INFORME KPI — MÈLTIC GMAO` found at line 411
4. `LISTADO DE ÓRDENES DE TRABAJO` found at line 532
5. `Printing.layoutPdf` appears 3 times (viewLocalPdf + generarKpiPdf + generarListaOtsPdf)
6. `flutter analyze lib/utils/pdf_generator.dart` — No issues found

## Deviations from Plan

### Commit granularity

Both tasks were implemented and committed atomically in a single commit (`4ed1d24`) rather than two separate commits. Both methods were inserted into the same file in a single edit. Splitting into two commits would have produced an intermediate state where `generarKpiPdf` exists but `generarListaOtsPdf` does not, which is valid but unnecessary. The single commit covers both acceptance criteria sets fully.

No other deviations — plan executed as written.

## Known Stubs

None. Both methods use live data passed as parameters. No hardcoded placeholder values in rendered content.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes introduced. PDF generation is purely client-side (consistent with T-1B-04 accept disposition).

## Self-Check: PASSED

- [x] `pdf_generator.dart` modified and committed at `4ed1d24`
- [x] `generarKpiPdf` present at line 391
- [x] `generarListaOtsPdf` present at line 525
- [x] All 7 acceptance-criteria strings confirmed present in file
- [x] `flutter analyze` — no issues
- [x] Existing methods (`generarReporteCierreBase64`, `viewLocalPdf`, `generarYVerPdf`) unchanged
