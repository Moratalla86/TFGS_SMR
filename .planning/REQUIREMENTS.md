# Requirements: Mèltic GMAO

**Defined:** 2026-04-17
**Core Value:** El técnico puede gestionar el mantenimiento industrial completo desde el móvil.

## v1 Requirements

### KPI Dashboard

- [ ] **KPI-01**: El técnico ve 4 KPIs clave (OEE, MTBF, MTTR, disponibilidad) en mini-cards en DashboardScreen con valores simulados realistas
- [ ] **KPI-02**: El usuario puede acceder a KpisScreen desde el drawer lateral
- [ ] **KPI-03**: KpisScreen muestra gráfica de barras de evolución mensual con datos simulados
- [ ] **KPI-04**: KpisScreen muestra métricas de OTs por estado, tipo y máquina con datos simulados
- [ ] **KPI-05**: DashboardScreen muestra widget de Sala de Servidores con temperatura y humedad reales del Controllino en tiempo real
- [ ] **KPI-06**: El usuario puede exportar el informe KPI a PDF desde KpisScreen

### Alertas y Notificaciones

- [ ] **ALR-01**: El usuario ve lista de alarmas activas con timestamp y severidad en DashboardScreen
- [ ] **ALR-02**: Al activarse una alarma nueva aparece un banner in-app (Web/Windows)
- [ ] **ALR-03**: El técnico Android recibe notificación push cuando una máquina entra en alarma
- [ ] **ALR-04**: El técnico puede registrar su FCM token al iniciar sesión en Android

### Calendario Preventivo

- [ ] **CAL-01**: El usuario ve OTs preventivas planificadas en vista calendario mensual
- [ ] **CAL-02**: Al tocar un día el usuario ve las OTs preventivas de ese día en un panel inferior
- [ ] **CAL-03**: El usuario puede crear una OT preventiva con fecha planificada desde el calendario
- [ ] **CAL-04**: El calendario es accesible desde el drawer lateral

### Exportación

- [ ] **EXP-01**: El usuario puede exportar el listado de OTs a PDF desde OrdenesScreen

## v2 Requirements (deferred)

### KPI Avanzado

- **KPI-ADV-01**: KPIs calculados desde datos reales del backend (todos los endpoints de stats)
- **KPI-ADV-02**: Filtros por rango de fechas en KpisScreen

### Notificaciones Avanzadas

- **ALR-ADV-01**: El técnico puede silenciar o reconocer alertas individualmente
- **ALR-ADV-02**: Historial de alertas pasadas con resolución

## Out of Scope

| Feature | Reason |
|---------|--------|
| Exportación a Excel | Complejidad extra sin valor diferencial para la defensa |
| Push notifications en iOS | No es el target del TFG |
| Push en Web/Windows | `flutter_local_notifications` no soporta Web; in-app banner es suficiente |
| Tests unitarios/integración | Tiempo insuficiente, se menciona como mejora futura |
| Paginación de endpoints | Deuda técnica conocida, no afecta a la demo |
| Drag-and-drop en calendario | Complejidad innecesaria para la defensa |
| Recurrencias automáticas en OTs | Fuera del alcance del planificador básico |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| KPI-01 | Phase 1 | Pending |
| KPI-02 | Phase 1 | Pending |
| KPI-03 | Phase 1 | Pending |
| KPI-04 | Phase 1 | Pending |
| KPI-05 | Phase 1 | Pending |
| KPI-06 | Phase 1 | Pending |
| ALR-01 | Phase 2 | Pending |
| ALR-02 | Phase 2 | Pending |
| ALR-03 | Phase 3 | Pending |
| ALR-04 | Phase 3 | Pending |
| CAL-01 | Phase 4 | Pending |
| CAL-02 | Phase 4 | Pending |
| CAL-03 | Phase 4 | Pending |
| CAL-04 | Phase 4 | Pending |
| EXP-01 | Phase 1 | Pending |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-17*
*Last updated: 2026-04-17 — initial definition*
