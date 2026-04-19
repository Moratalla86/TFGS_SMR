# Roadmap: Mèltic GMAO — Milestone v1.0 TFG Final Sprint

**Milestone:** v1.0 TFG Final Sprint
**Created:** 2026-04-17
**Granularity:** Fine (4 phases from natural delivery boundaries)
**Coverage:** 15/15 requirements mapped

---

## Phases

- [x] **Phase 1: KPI Dashboard + PDF Export** ✓ 2026-04-19 - El técnico ve KPIs reales, gráficas y widget de Sala de Servidores, y puede exportar informes a PDF
- [x] **Phase 2: Alertas In-App** ✓ 2026-04-19 - El técnico ve alarmas activas en tiempo real con banners in-app en Web y Windows
- [x] **Phase 3: Firebase Push Android** ✓ 2026-04-19 - Infraestructura lista; activar con google-services.json real siguiendo PLACEHOLDER
- [x] **Phase 4: Calendario Preventivo** ✓ 2026-04-19 - El técnico planifica y consulta OTs preventivas en un calendario mensual visual

---

## Phase Details

### Phase 1: KPI Dashboard + PDF Export
**Goal**: El técnico puede consultar los KPIs operacionales con gráficas, ver el widget de Sala de Servidores en el dashboard y exportar informes a PDF.
**Depends on**: Nothing (first phase — backend `/api/stats/dashboard` already exists)
**Requirements**: KPI-01, KPI-02, KPI-03, KPI-04, KPI-05, KPI-06, EXP-01
**Effort**: 3 days
**Success Criteria** (what must be TRUE):
  1. El técnico abre DashboardScreen y ve 4 mini-cards (OEE, MTBF, MTTR, disponibilidad) con valores simulados realistas
  2. El técnico accede a KpisScreen desde el drawer lateral y ve una gráfica de barras de evolución mensual y métricas de OTs por estado, tipo y máquina
  3. El widget de Sala de Servidores en DashboardScreen muestra temperatura y humedad del Controllino actualizándose en tiempo real
  4. El técnico pulsa "Exportar PDF" en KpisScreen y recibe un PDF descargable con el informe de KPIs
  5. El técnico pulsa "Exportar PDF" en OrdenesScreen y recibe un PDF con el listado completo de OTs
**Plans**: 5 plans (Wave 1: A, B — Wave 2: C, D, E)
Plans:
- [x] 01-PLAN-A.md — PLCService.fetchLastTelemetry + SalaServidoresWidget (KPI-05 foundation)
- [x] 01-PLAN-B.md — PdfGenerator.generarKpiPdf + generarListaOtsPdf (KPI-06, EXP-01 foundation)
- [x] 01-PLAN-C.md — DashboardScreen: KPI mini-cards + Sala de Servidores integration (KPI-01, KPI-05)
- [x] 01-PLAN-D.md — KpisScreen: fl_chart BarChart + PDF export button (KPI-02, KPI-03, KPI-04, KPI-06)
- [x] 01-PLAN-E.md — OrdenesScreen: bulk PDF export button (EXP-01)
**UI hint**: yes

### Phase 2: Alertas In-App
**Goal**: El técnico ve en DashboardScreen la lista de alarmas activas de máquinas y recibe un banner in-app cuando se activa una alarma nueva (Web y Windows).
**Depends on**: Phase 1 (no technical dependency, but Phase 1 must be done first to stay on schedule)
**Requirements**: ALR-01, ALR-02
**Effort**: 2 days
**Success Criteria** (what must be TRUE):
  1. Al abrir DashboardScreen el técnico ve una lista de alarmas activas con timestamp y severidad
  2. Cuando una máquina entra en alarma, aparece automáticamente un MaterialBanner in-app sin que el usuario tenga que recargar la pantalla
  3. La lista de alarmas se actualiza en tiempo real y desaparece una alarma cuando la máquina sale del estado de alarma
**Plans**: TBD
**UI hint**: yes

### Phase 3: Firebase Push Android
**Goal**: El técnico Android recibe notificaciones push nativas en el dispositivo cuando cualquier máquina entra en alarma, incluso con la app en segundo plano.
**Depends on**: Phase 2 (backend AlertaService debe estar operativo)
**Requirements**: ALR-03, ALR-04
**Effort**: 2 days
**Success Criteria** (what must be TRUE):
  1. Al iniciar sesión desde Android, el dispositivo registra su FCM token en el backend sin errores
  2. Cuando una máquina entra en alarma, el técnico Android recibe una notificación push nativa con el nombre de la máquina y la severidad
  3. La notificación push llega tanto con la app en primer plano, en segundo plano y con la app cerrada
  4. La integración Firebase no afecta a las plataformas Web y Windows (guard Android-only activo)
**Plans**: TBD

### Phase 4: Calendario Preventivo
**Goal**: El técnico puede planificar, visualizar y crear OTs preventivas en un calendario mensual accesible desde el drawer lateral.
**Depends on**: Nothing (independent of Phases 2 and 3 — can be built in parallel if needed)
**Requirements**: CAL-01, CAL-02, CAL-03, CAL-04
**Effort**: 2 days
**Success Criteria** (what must be TRUE):
  1. El técnico accede al calendario desde el drawer lateral y ve un mes completo con marcadores en los días que tienen OTs preventivas planificadas
  2. Al tocar un día con OTs, aparece un panel inferior con el listado de OTs preventivas de ese día (número de OT, máquina, descripción)
  3. El técnico puede crear una OT preventiva con fecha planificada desde el FAB del calendario y la OT aparece en el día correspondiente al guardar
  4. El calendario funciona correctamente en español (nombres de meses y días de semana en es_ES)
**Plans**: TBD
**UI hint**: yes

---

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. KPI Dashboard + PDF Export | 5/5 | Complete | 2026-04-19 |
| 2. Alertas In-App | 1/1 | Complete | 2026-04-19 |
| 3. Firebase Push Android | 1/1 | Complete | 2026-04-19 |
| 4. Calendario Preventivo | 1/1 | Complete | 2026-04-19 |

---

## Coverage Map

| Requirement | Phase | Category |
|-------------|-------|----------|
| KPI-01 | Phase 1 | KPI Dashboard |
| KPI-02 | Phase 1 | KPI Dashboard |
| KPI-03 | Phase 1 | KPI Dashboard |
| KPI-04 | Phase 1 | KPI Dashboard |
| KPI-05 | Phase 1 | KPI Dashboard |
| KPI-06 | Phase 1 | KPI Dashboard |
| EXP-01 | Phase 1 | Exportacion |
| ALR-01 | Phase 2 | Alertas |
| ALR-02 | Phase 2 | Alertas |
| ALR-03 | Phase 3 | Alertas Firebase |
| ALR-04 | Phase 3 | Alertas Firebase |
| CAL-01 | Phase 4 | Calendario |
| CAL-02 | Phase 4 | Calendario |
| CAL-03 | Phase 4 | Calendario |
| CAL-04 | Phase 4 | Calendario |

**Total v1 requirements:** 15
**Mapped:** 15
**Unmapped:** 0

---

## Risk Notes

- **Firebase applicationId mismatch** (Phase 3): Confirmar que `build.gradle.kts` usa el applicationId final ANTES de ejecutar `flutterfire configure`. Error conocido con coste de 4-8 h.
- **Background FCM handler** (Phase 3): Declarar el handler como funcion top-level con `@pragma('vm:entry-point')`. Funciona en debug pero falla silenciosamente en release.
- **Locale calendario** (Phase 4): Ejecutar `await initializeDateFormatting('es_ES', null)` en `main()`. `Intl.defaultLocale` solo no es suficiente — provoca `LocaleDataException` en runtime.
- **Cut decision**: Si el tiempo aprieta antes de la defensa, Firebase Push (Phase 3) es el candidato a recortar. El demo sigue completo con Phases 1, 2 y 4.

---

*Roadmap created: 2026-04-17*
*Total estimated effort: ~9 days (within 2-week constraint)*
