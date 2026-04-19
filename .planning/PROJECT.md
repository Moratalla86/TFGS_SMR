# Mèltic GMAO

## What This Is

Sistema de Gestión de Mantenimiento Asistido por Ordenador (GMAO) industrial integrado con telemetría IoT en tiempo real. Permite a técnicos de mantenimiento gestionar órdenes de trabajo, monitorizar máquinas mediante un gemelo digital y autenticarse con tarjeta RFID. TFG de Santiago Moratalla (DAM2/SMR), defensa primavera 2026.

## Core Value

El técnico puede gestionar el mantenimiento industrial completo desde el móvil: desde la alerta de alarma hasta el cierre firmado digitalmente de la orden de trabajo.

## Current Milestone: v1.0 TFG Final Sprint

**Goal:** Completar el 20% restante del GMAO para la defensa — KPIs funcionales, notificaciones, calendario de planificación e informes exportables.

**Target features:**
- KPIs operacionales con datos reales, gráficas y widget en dashboard
- Notificaciones in-app (Web/Windows) y push nativas Android (Firebase)
- Calendario planificador de OTs preventivas
- Exportación de informes KPI y OTs a PDF

## Requirements

### Validated

- ✓ Autenticación RFID + credenciales (RBAC) — v0.x
- ✓ Telemetría en tiempo real / Digital Twin SCADA — v0.x
- ✓ Órdenes de Trabajo con PDF, firmas digitales y checklists — v0.x
- ✓ Gestión de usuarios y máquinas (CRUD) — v0.x
- ✓ Pantalla KpisScreen (estructura base) + endpoint /api/stats/dashboard — v0.x
- ✓ Correcciones de seguridad REVIEW.md (12 CRITICAL/HIGH/MEDIUM) — v0.x
- ✓ KPIs operacionales (OEE, MTBF, MTTR, disponibilidad) con datos reales + fl_chart BarChart — Phase 1
- ✓ Widget Sala de Servidores con polling en tiempo real + navegación TelemetriaChartScreen — Phase 1
- ✓ Exportación KPI a PDF (6 secciones) + Exportación listado OTs a PDF (tabla 7 columnas) — Phase 1

### Active

- [ ] Panel de alertas in-app (Web/Windows) con alarmas activas de máquinas
- [ ] Notificaciones push nativas Android via Firebase
- [ ] Calendario visual de OTs preventivas con planificador

### Out of Scope

- Exportación a Excel — complejidad extra sin valor diferencial para la defensa
- Push notifications en iOS — no es el target del TFG
- Chat entre técnicos — fuera del alcance GMAO
- Paginación de endpoints — deuda técnica conocida, no afecta a la demo
- Tests unitarios/integración — tiempo insuficiente, se menciona como mejora futura

## Context

- Stack: Spring Boot 3 + Flutter/Dart + MySQL (datos relacionales) + MongoDB (telemetría) + Docker Compose
- Hardware: Controllino (Arduino Mega) con RFID RC522 y sensores
- Branch activo: `tfg-rescate`
- App corre en: Android (hotspot WiFi), Web (localhost:8081), Windows nativo
- La IP del backend es configurable desde SharedPreferences (ApiConfig)
- El seed industrial genera 8 máquinas y ~100 OTs históricas para demo
- El endpoint `/api/stats/dashboard` ya existe y devuelve KPIs calculados

## Constraints

- **Timeline**: < 2 semanas hasta la defensa — priorizar impacto visual
- **Stack Flutter**: No cambiar el stack, usar packages existentes o bien conocidos
- **Hardware**: El Controllino puede no estar disponible siempre; la simulación debe ser robusta
- **Seguridad**: Todas las correcciones del REVIEW.md ya aplicadas — no regresar

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Polyglot persistence (MySQL + MongoDB) | Datos ACID vs time-series tienen necesidades distintas | ✓ Good |
| Token auth propio (no JWT estándar) | Simplicidad para TFG | ⚠️ Revisit en producción real |
| Flutter multiplataforma | Un solo codebase Android + Web + Windows | ✓ Good |
| Simulación de máquinas en backend | Permite demo sin hardware físico | ✓ Good |
| Notificaciones in-app para Web/Windows | Push web compleja y fuera de scope TFG | — Pending |
| Firebase para push Android | Estándar de industria, bien soportado en Flutter | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-19 — Phase 1 complete (KPI Dashboard + PDF Export)*
