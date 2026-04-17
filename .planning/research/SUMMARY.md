# Research Summary — Meltic GMAO v1.0 TFG Final Sprint

**Synthesized:** 2026-04-17
**Milestone:** KPI charts · Alerts/Push · Calendar · PDF export

---

## Stack Additions

| Package | Action | Version |
|---------|--------|---------|
| `fl_chart` | BUMP | `^1.2.0` (was `^0.70.2`) |
| `syncfusion_flutter_charts` | BUMP | `^33.1.49` |
| `firebase_core` | ADD | `^4.7.0` |
| `firebase_messaging` | ADD | `^16.2.0` |
| `table_calendar` | ADD | `^3.2.0` |

Backend pom.xml: add `firebase-admin:9.7.1`. No other dependency changes.
Do NOT add: `flutter_local_notifications` (no Web support), any Excel package.

---

## Feature Table Stakes

**KPIs:** KpiSummaryWidget (4 mini-cards) en DashboardScreen + BarChart en KpisScreen con datos reales. Drawer entry ya existe pero no navega a KpisScreen correctamente.

**Alertas:** Lista de alarmas activas con timestamp + severidad. In-app MaterialBanner (Web/Windows). Firebase push (Android). Backend necesita AlertaService en memoria + AlertaController.

**Calendario:** Vista mensual de OTs preventivas. Tap día → OTs del día. FAB → crear OT preventiva con `fechaPlanificada`. Requiere campo nuevo en `OrdenTrabajo`.

**PDF:** Export button en KpisScreen y OrdenesScreen. Reutiliza `Printing.layoutPdf()` ya validado. Contenido como tabla de datos (no capturas de gráficas).

---

## Key Architecture Decisions

- KPI y PDF: **cero cambios backend** — `/api/stats/dashboard` ya devuelve todo
- Alertas: `AlertaService` en memoria (ConcurrentHashMap), sin tabla nueva en BD
- Nuevos endpoints: `GET /api/alertas/activas`, `POST /api/usuarios/{id}/fcm-token`, `GET /api/ordenes/calendario`
- `OrdenTrabajo` necesita campo `fechaPlanificada` (nullable, JPA lo crea automáticamente)
- Firebase: **guard Android-only obligatorio** — `Firebase.initializeApp()` crashea en Web/Windows

---

## Watch Out For (Top 3)

1. **Firebase applicationId mismatch** — `build.gradle.kts` tiene `com.example.meltic_gmao_app`. Cambiar a nombre final ANTES de `flutterfire configure`. Riesgo: 4-8 h perdidas.

2. **Background FCM handler tree-shaken en release** — declarar como función top-level con `@pragma('vm:entry-point')`. Funciona en debug, falla en release sin error visible.

3. **`table_calendar` LocaleDataException** — añadir `await initializeDateFormatting('es_ES', null)` en `main()`. `Intl.defaultLocale` solo no es suficiente.

---

## Suggested Build Order

| Fase | Features | Backend | Dependencias |
|------|----------|---------|--------------|
| 1 | KPI Charts + Widget Dashboard + PDF | Ninguno | — |
| 2 | Alertas backend + Flutter in-app | AlertaService + AlertaController | — |
| 3 | Firebase Push Android | FirebaseConfig + NotificacionService | Fase 2 |
| 4 | Calendario preventivo | fechaPlanificada + /api/ordenes/calendario | — |

Fases 3 y 4 son independientes entre sí. Si el tiempo aprieta, cortar Firebase y entregar solo alertas in-app + calendario — el demo sigue completo.
