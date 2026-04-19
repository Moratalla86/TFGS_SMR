---
status: partial
phase: 1-kpi-dashboard-pdf-export
source: [01-VERIFICATION.md]
started: 2026-04-19T00:00:00Z
updated: 2026-04-19T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. KPI-01 — Cards con valores reales
expected: DashboardScreen muestra 4 mini-cards "KPIs OPERACIONALES" (OEE, MTBF, MTTR, DISPONIB.) con valores numéricos reales tras cargar stats del backend
result: [pending]

### 2. KPI-03 — Gráfica fl_chart renderiza
expected: KpisScreen muestra BarChart con barras verdes (preventivo) y rojas (correctivo) por mes, animación de entrada, sin crash en estado vacío
result: [pending]

### 3. KPI-05 — Polling en vivo + navegación
expected: SalaServidoresWidget muestra spinner, transiciona a valores de temperatura/humedad en ≤5s; punto verde pulsante cuando Controllino conectado; tap navega a TelemetriaChartScreen con gráfica de líneas
result: [pending]

### 4. KPI-06 — PDF de KPI se abre
expected: Botón "EXPORTAR PDF" en KpisScreen abre visor de PDF con documento de 6 secciones: cabecera, tabla KPIs, distribución, estado, evolución mensual, ranking
result: [pending]

### 5. EXP-01 — PDF de OTs se abre
expected: Botón "EXPORTAR PDF" en OrdenesScreen abre visor de PDF con tabla de 7 columnas (#, MÁQUINA, TÉCNICO, TIPO, ESTADO, PRIORIDAD, FECHA) y número correcto de filas
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
