---
status: complete
phase: 02-alerts
source: [SUMMARY.md]
started: 2026-04-19T00:00:00Z
updated: 2026-04-19T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Backend arranca con tabla alertas
expected: docker compose up levanta sin errores. Tabla `alertas` creada por JPA. GET /api/alertas/activas devuelve 200 + JSON array.
result: pass

### 2. Sección ALARMAS ACTIVAS visible en Dashboard
expected: Con al menos una alarma activa en el backend, DashboardScreen muestra sección "ALARMAS ACTIVAS" con cards que muestran nombre de máquina, severidad y descripción de cada alarma.
result: pass

### 3. Color coding por severidad
expected: Cards CRITICAL muestran icono/borde en rojo (criticalRed). Cards WARNING muestran en naranja (warningOrange). La diferencia es visual e inmediata.
result: pass

### 4. MaterialBanner al detectar nueva alarma
expected: Con la app abierta en DashboardScreen, cuando el backend registra una nueva alarma (PLCPollingService la detecta automáticamente), en el siguiente ciclo de polling (~10s) aparece un MaterialBanner "NUEVA ALARMA INDUSTRIAL DETECTADA" en la parte superior sin que el usuario recargue la pantalla.
result: pass

### 5. Alarmas resueltas desaparecen del listado
expected: Cuando una máquina sale del estado de alarma (desactivarAlertasMaquina se llama en PLCPollingService), la alarma desaparece de la sección "ALARMAS ACTIVAS" en el siguiente ciclo de polling (≤10s).
result: pass

### 6. Sin alarmas — sección oculta
expected: Cuando no hay alarmas activas en el backend, la sección "ALARMAS ACTIVAS" no aparece en DashboardScreen (la sección se oculta automáticamente con la condición if isNotEmpty).
result: pass

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
