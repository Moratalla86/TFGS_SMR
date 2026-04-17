# Architecture: Feature Integration Map

**Project:** Meltic GMAO — v1.0 TFG Final Sprint
**Researched:** 2026-04-17
**Scope:** 4 new features integrated into existing Spring Boot 3 + Flutter stack

---

## Existing Architecture Baseline

```
Flutter App (Android/Web/Windows)
  ├── AppSession (singleton, SharedPreferences)
  ├── ApiConfig (baseUrl from SharedPreferences)
  ├── services/  (http calls, authHeaders from AppSession)
  ├── screens/   (7 routes registered in main.dart)
  └── widgets/   (industrial_chart, machine_history_chart)

Spring Boot 3 Backend
  ├── SecurityConfig: stateless, TokenAuthFilter, RBAC
  ├── /api/auth/**       → public
  ├── /api/plc/**        → mixed (last-rfid public, simulate ADMIN)
  ├── /api/stats/**      → authenticated
  ├── /api/ordenes/**    → authenticated
  ├── /api/maquinas/**   → authenticated/ADMIN
  └── /api/usuarios/**   → JEFE+/ADMIN
  MySQL: OT, Maquina, Usuario, MetricConfig
  MongoDB: Telemetria (time-series)
```

**Key constraint:** No JWT — custom UUID tokens, 8h expiry. Token stored in AppSession.authToken, sent as `Authorization: Bearer <token>`. All new endpoints must follow this pattern in SecurityConfig.

---

## Feature 1: KPI Charts (fl_chart in KpisScreen + Dashboard widget)

### Current State
`KpisScreen` already exists and renders all KPI data from `/api/stats/dashboard` using custom bar charts built with `Container` + `LinearProgressIndicator`. The `pdf` and `fl_chart` packages are already in `pubspec.yaml`. `StatsService.fetchDashboardStats()` is fully wired.

### What Needs to Be Built

**Backend: no new endpoints needed.** The existing `/api/stats/dashboard` returns all required data:
- `oeeGlobal`, `mtbfHoras`, `mttrHoras`, `disponibilidadPct`
- `ratioPreventivoCorrectivo`, `otsPorEstado`
- `rankingIncidencias` (top 5 machines)
- `evolucionMensual` (last 6 months, preventivo/correctivo counts)

**Flutter: modify KpisScreen, add widget to DashboardScreen.**

Replace the hand-built bar chart in `_buildEvolucionChart()` with `fl_chart`'s `BarChart`. The data shape (`List<{mes, preventivo, correctivo}>`) maps directly to `BarChartGroupData`. The KPI cards already exist — no redesign needed.

Add a `KpiSummaryWidget` stateless widget in `lib/widgets/kpi_summary_widget.dart`:
- Receives `Map<String, dynamic> stats` (reuse the same `StatsService` call)
- Renders 4 mini-cards: OEE, MTBF, MTTR, Disponibilidad
- Placed in `DashboardScreen._buildBody()` below the machine status cards

**DashboardScreen integration:** DashboardScreen already loads maquinas and OTs every 5 seconds via `_refreshTimer`. The KPI widget should be loaded once (or with manual refresh), not on the 5s loop. Pattern: add `StatsService _statsService = StatsService()` and `Map<String,dynamic>? _kpiData` to DashboardScreen state, load in `initState`, refresh manually.

### Component Map

| Component | Action | File |
|-----------|--------|------|
| `/api/stats/dashboard` | No change | StatsController.java |
| `StatsService` | No change | stats_service.dart |
| `KpisScreen` | Replace custom bar chart with `BarChart` from fl_chart | kpis_screen.dart |
| `KpiSummaryWidget` | NEW stateless widget | widgets/kpi_summary_widget.dart |
| `DashboardScreen` | Add `KpiSummaryWidget` + stats loading | dashboard_screen.dart |

### Data Flow
```
DashboardScreen.initState()
  → StatsService.fetchDashboardStats()
  → GET /api/stats/dashboard (with Bearer token)
  → KpiSummaryWidget(stats: _kpiData)

KpisScreen (existing, separate navigation)
  → same StatsService call
  → fl_chart BarChart for evolucion mensual
```

---

## Feature 2: In-App Alerts (Web/Windows) + Panel

### Current State
`PLCPollingService.procesarAlertas()` already evaluates telemetry against `MetricConfig` thresholds and sets `maquina.estado` to `"OK"`, `"WARNING"`, or `"ERROR"`. DashboardScreen already polls machines every 5 seconds and renders `"INCIDENCIAS ACTIVAS"` for non-OK machines. Alarm data is implicitly embedded in `Maquina.estado`.

**The gap:** No structured alarm list with messages, timestamps, or severity. No dedicated alerts endpoint. The frontend detects alarms only by inferring from `maquina.estado != 'OK'`.

### Recommended Architecture: New `/api/alertas` endpoint

Do NOT poll `/api/plc/last-rfid` for alerts — that is RFID-specific. Add a proper `/api/alertas/activas` endpoint.

**Backend: new AlarmController + in-memory store.**

Given the 2-week deadline, avoid a new MySQL table. Use an in-memory `ConcurrentHashMap<Long, AlarmaDto>` in a new `@Service AlertaService`. `PLCPollingService.procesarAlertas()` calls `alertaService.registrar(machineId, mensaje, severidad, timestamp)` when state changes to WARNING/ERROR, and `alertaService.resolver(machineId)` when it returns to OK. This is effectively a live alarm rack — appropriate for a SCADA demo.

```java
// New: AlertaService (in-memory, no DB)
// AlarmaDto: { maquinaId, maquinaNombre, mensaje, severidad, timestamp }
// AlertaController: GET /api/alertas/activas → List<AlarmaDto>
```

SecurityConfig: add `/api/alertas/**` to `.anyRequest().authenticated()` (already covered by the catch-all — no special rule needed).

**Flutter: new `AlertasService` + banner/panel in DashboardScreen.**

`DashboardScreen` already has a 5-second `_refreshTimer`. Add `AlertasService.fetchAlertasActivas()` to that loop alongside `_loadMaquinas()`. Replace the current `_buildAlertaItem(Maquina m)` (which hardcodes "Corte de telemetría detectado") with `_buildAlertaItem(AlarmaDto a)` using real messages from the endpoint.

For Web/Windows, a `SnackBar` or persistent `MaterialBanner` on new alert arrival is sufficient. No special Web push needed.

**Do NOT build a separate AlertasScreen** — the dashboard panel is enough for the TFG demo.

### Component Map

| Component | Action | File |
|-----------|--------|------|
| `AlertaService` (backend) | NEW — in-memory alarm rack | service/AlertaService.java |
| `AlarmaDto` | NEW — DTO record | model/AlarmaDto.java (or inner record) |
| `AlertaController` | NEW — GET /api/alertas/activas | controller/AlertaController.java |
| `PLCPollingService.procesarAlertas()` | Modify — call AlertaService.registrar/resolver | PLCPollingService.java |
| `AlertasService` (Flutter) | NEW — fetchAlertasActivas() | services/alertas_service.dart |
| `AlarmaDto` (Flutter) | NEW — model | models/alarma.dart |
| `DashboardScreen` | Modify — replace inferred alarms with real AlarmaDto list | dashboard_screen.dart |

### Data Flow
```
PLCPollingService (every 5s, scheduled)
  → procesarAlertas(telemetria)
  → AlertaService.registrar(machineId, "MUY ALTA (TEMPERATURA)", "ERROR", now)
     OR AlertaService.resolver(machineId)

DashboardScreen._refreshTimer (every 5s)
  → AlertasService.fetchAlertasActivas()
  → GET /api/alertas/activas (authenticated)
  → setState → rebuild _buildAlertaItem widgets with real messages

If new alarms added since last poll → show MaterialBanner
```

---

## Feature 3: Firebase Push Notifications (Android only)

### Current State
No Firebase in the project. `pubspec.yaml` has no `firebase_*` packages. Backend has no Firebase Admin SDK dependency in `pom.xml`.

### Architecture Decision
Firebase push is Android-only per PROJECT.md. Web/Windows get the in-app banner approach from Feature 2. Keep these two notification paths strictly separate.

### Backend Changes Required

Add Firebase Admin SDK to `pom.xml`:
```xml
<dependency>
  <groupId>com.google.firebase</groupId>
  <artifactId>firebase-admin</artifactId>
  <version>9.3.0</version>
</dependency>
```

**FCM token storage:** Add `fcmToken` column to `Usuario` entity (nullable String). New endpoint:

```
POST /api/usuarios/{id}/fcm-token
Body: { "fcmToken": "..." }
Roles: authenticated (any user can update their own token)
```

The SecurityConfig catch-all `.anyRequest().authenticated()` covers this. Add to `UsuarioController`.

**Notification trigger:** `AlertaService.registrar()` (new service from Feature 2) calls `NotificacionService.enviarPush(maquinaId, mensaje)` which:
1. Queries all users with `fcmToken != null`
2. Sends via `FirebaseMessaging.getInstance().send(Message.builder()...)`

Use a `@PostConstruct` or `@Configuration` class to initialize `FirebaseApp` from a `serviceAccountKey.json` file referenced via an environment variable or `application.properties` path. Do NOT commit the key — add it to `.gitignore`.

**New backend components:**
- `NotificacionService.java` — wraps Firebase Admin SDK send
- `FirebaseConfig.java` — `@Configuration` that initializes `FirebaseApp`
- `Usuario.fcmToken` field + migration (JPA will add column automatically with `spring.jpa.hibernate.ddl-auto=update`)
- `POST /api/usuarios/{id}/fcm-token` in `UsuarioController`

### Flutter Changes Required

Add to `pubspec.yaml`:
```yaml
firebase_core: ^3.x
firebase_messaging: ^15.x
```

Platform targeting is critical: Firebase initialization must only run on Android. Pattern:

```dart
// main.dart
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // FCM token registration after login
  }
  ...
}
```

Register FCM token after login in `LoginScreen` (or in `AppSession.fromJson()`):

```dart
// After successful login on Android:
final token = await FirebaseMessaging.instance.getToken();
if (token != null) {
  await usuarioService.updateFcmToken(AppSession.instance.userId!, token);
}
```

`google-services.json` goes in `android/app/`. Add `android/app/google-services.json` to `.gitignore`.

**FCM foreground messages:** Use `FirebaseMessaging.onMessage.listen()` to show a `FlutterLocalNotificationsPlugin` notification when app is in foreground. Add `flutter_local_notifications: ^18.x` to `pubspec.yaml`.

### Component Map

| Component | Action | File |
|-----------|--------|------|
| `firebase-admin` | NEW — pom.xml dependency | pom.xml |
| `FirebaseConfig` | NEW — initialize FirebaseApp | config/FirebaseConfig.java |
| `NotificacionService` | NEW — FCM send wrapper | service/NotificacionService.java |
| `Usuario.fcmToken` | MODIFY — add nullable field | model/Usuario.java |
| `POST /api/usuarios/{id}/fcm-token` | NEW endpoint | UsuarioController.java |
| `AlertaService.registrar()` | MODIFY — call NotificacionService | service/AlertaService.java |
| `firebase_core`, `firebase_messaging` | NEW — pubspec.yaml | pubspec.yaml |
| `flutter_local_notifications` | NEW — pubspec.yaml | pubspec.yaml |
| FCM init in main.dart | MODIFY — Android-only guard | main.dart |
| FCM token registration | NEW — post-login | login_screen.dart |
| `google-services.json` | NEW — Firebase config | android/app/ |

### Data Flow
```
Android app (post-login)
  → FirebaseMessaging.instance.getToken()
  → POST /api/usuarios/{userId}/fcm-token { "fcmToken": "..." }
  → Usuario.fcmToken saved in MySQL

PLCPollingService → AlertaService.registrar()
  → NotificacionService.enviarPush(machineId, message)
  → Firebase Admin SDK → FCM → Android device
  → FirebaseMessaging.onMessage → FlutterLocalNotificationsPlugin.show()
```

---

## Feature 4: Preventive Calendar (OT creation from calendar view)

### Current State
`OrdenTrabajo` has `fechaCreacion` (auto-set at creation), `fechaInicio`, `fechaFin`, and `tipo = "PREVENTIVA"`. `OrdenTrabajoController` already has `POST /api/ordenes` which creates an OT. `OrdenTrabajoService` (Flutter) has `crearOrden()` which already sends `tipo`, `maquinaId`, `tecnicoId`. The `table_calendar` package is NOT yet in `pubspec.yaml`.

### What Needs to Be Built

**Backend: one new endpoint, one field addition.**

The calendar needs to display scheduled preventive OTs by date. `fechaCreacion` is the creation date (auto), not the scheduled date. Add a `fechaPlanificada` field to `OrdenTrabajo` for the intended execution date:

```java
// OrdenTrabajo.java — add:
private LocalDateTime fechaPlanificada;
```

JPA adds the column automatically. No migration script needed if using `ddl-auto=update`.

New query endpoint:
```
GET /api/ordenes/calendario?desde=<ISO>&hasta=<ISO>
→ List<OrdenTrabajo> where tipo=PREVENTIVA and fechaPlanificada BETWEEN desde AND hasta
```

Add to `OrdenTrabajoController` and `MantenimientoService`. The existing `/api/ordenes/buscar` endpoint already has `fechaDesde`/`fechaHasta` params but these filter on `fechaCreacion`. The new endpoint filters on `fechaPlanificada` and only returns `PREVENTIVA` type — cleaner for calendar use.

**No new controller needed** — add the calendar endpoint to the existing `OrdenTrabajoController`.

**Flutter: new CalendarioScreen + route.**

Add `table_calendar: ^3.1.x` to `pubspec.yaml`.

New `CalendarioScreen`:
- Uses `TableCalendar` with `EventLoader` mapping `fechaPlanificada` → OT list
- Tapping a day shows OTs scheduled for that day in a bottom sheet
- "+" FAB opens OT creation dialog (reuse the OT creation flow from `OrdenesScreen`)
- On creation, set `tipo = "PREVENTIVA"` and `fechaPlanificada` = selected day

**CalendarioService** (Flutter):
```dart
Future<List<OrdenTrabajo>> fetchCalendario(DateTime desde, DateTime hasta)
// GET /api/ordenes/calendario?desde=...&hasta=...
```

Register route `/calendario` in `main.dart` and add drawer entry in `DashboardScreen._buildDrawer()`.

### Component Map

| Component | Action | File |
|-----------|--------|------|
| `OrdenTrabajo.fechaPlanificada` | NEW field | model/OrdenTrabajo.java |
| `GET /api/ordenes/calendario` | NEW endpoint | OrdenTrabajoController.java |
| Calendar query in service | NEW method | service/MantenimientoService.java |
| `OrdenTrabajoRepository` | NEW query method | repository/OrdenTrabajoRepository.java |
| `table_calendar` | NEW dependency | pubspec.yaml |
| `CalendarioScreen` | NEW screen | screens/calendario_screen.dart |
| `CalendarioService` | NEW service | services/calendario_service.dart |
| Route `/calendario` | NEW | main.dart |
| Drawer entry | MODIFY | dashboard_screen.dart |
| `OrdenTrabajo.fromJson()` | MODIFY — add fechaPlanificada | models/orden_trabajo.dart |

### Data Flow
```
CalendarioScreen.initState()
  → CalendarioService.fetchCalendario(firstDay, lastDay)
  → GET /api/ordenes/calendario?desde=...&hasta=... (authenticated)
  → List<OrdenTrabajo> (only PREVENTIVA with fechaPlanificada)

User taps day → shows scheduled OTs
User taps FAB → OT creation dialog
  → OrdenTrabajoService.crearOrden(ot, maquinaId: ..., tecnicoId: ...)
    with tipo=PREVENTIVA, fechaPlanificada=selectedDay
  → POST /api/ordenes
  → CalendarioService.fetchCalendario() refresh
```

---

## Feature 5: PDF Export (KPI report + OT list)

### Current State
`pdf: ^3.11.1` and `printing: ^5.13.2` are already in `pubspec.yaml`. The backend already generates OT PDFs (stored as `reportePdfBase64` in the DB). PDF generation for individual OTs happens in Flutter (`MantenimientoService.obtenerReportePdf` on backend is also available but returns backend-generated PDFs). The pattern for Flutter-side PDF generation exists — just needs to be applied to KPI data.

### What Needs to Be Built

**Backend: no new endpoints needed.** KPI data already comes from `/api/stats/dashboard`. OT list data already comes from `/api/ordenes`. Both have all the fields needed for a PDF report.

**Flutter: two PDF generation functions + export trigger in KpisScreen.**

Add an `ExportService` in `lib/services/export_service.dart`:

```dart
class ExportService {
  // KPI report: takes Map<String,dynamic> stats → generates PDF → Printing.layoutPdf()
  Future<void> exportarKpisPdf(Map<String, dynamic> stats) async { ... }

  // OT list report: takes List<OrdenTrabajo> → generates PDF → Printing.layoutPdf()
  Future<void> exportarOtsPdf(List<OrdenTrabajo> ordenes) async { ... }
}
```

Use `Printing.layoutPdf(onLayout: (format) => doc.save())` which handles share/print/save on Android, Web, and Windows uniformly — this is already the pattern used elsewhere in the app.

**KpisScreen:** Add an export IconButton in AppBar (`Icons.picture_as_pdf`). On tap: call `ExportService.exportarKpisPdf(_stats!)`. The stats map is already loaded.

**OrdenesScreen:** Add an export action. On tap: call `ExportService.exportarOtsPdf(_ots)`. No new service call needed — data is already loaded.

**PDF content for KPI report:**
- Header: "INFORME KPI — Meltic GMAO" + date
- Section 1: OEE, MTBF, MTTR, Disponibilidad (table)
- Section 2: Ratio preventivo/correctivo (table)
- Section 3: OTs por estado (table)
- Section 4: Ranking incidencias (top 5, table)
- Section 5: Evolución mensual (table — charts not supported in `pdf` package, use data table)

### Component Map

| Component | Action | File |
|-----------|--------|------|
| `/api/stats/dashboard` | No change | StatsController.java |
| `/api/ordenes` | No change | OrdenTrabajoController.java |
| `ExportService` | NEW — PDF generation | services/export_service.dart |
| `KpisScreen` AppBar | MODIFY — add PDF export button | kpis_screen.dart |
| `OrdenesScreen` | MODIFY — add PDF export action | ordenes_screen.dart |

### Data Flow
```
KpisScreen (stats already loaded in _stats)
  → user taps export icon
  → ExportService.exportarKpisPdf(_stats!)
  → pdf package builds Document
  → Printing.layoutPdf() → share sheet / print dialog

OrdenesScreen (ots already in _ots list)
  → user taps export icon
  → ExportService.exportarOtsPdf(_ots)
  → pdf package builds Document
  → Printing.layoutPdf()
```

---

## Suggested Build Order

Dependencies drive order: alerts infrastructure enables Firebase push; PDF export requires loaded data (depends on KPI charts working); calendar is independent.

| Step | Feature | Component | Why This Order |
|------|---------|-----------|----------------|
| 1 | KPI Charts | `KpiSummaryWidget` + fl_chart in KpisScreen | No backend changes. Highest visual impact. Establishes pattern for data-to-UI mapping. Other features don't depend on it but it validates the stats endpoint is reliable. |
| 2 | KPI Charts | `KpiSummaryWidget` injected into DashboardScreen | Depends on Step 1 widget existing. |
| 3 | PDF Export | `ExportService` (KPI report) | Depends on Step 1 (KPI data shape confirmed). No backend work. Quick win. |
| 4 | PDF Export | OT list export in OrdenesScreen | Trivial extension of Step 3's ExportService. |
| 5 | In-App Alerts | Backend: `AlertaService` + `AlertaController` + modify `PLCPollingService` | No Flutter changes yet. Can be tested via Swagger/curl. Enables Step 6 and is prerequisite for Step 7. |
| 6 | In-App Alerts | Flutter: `AlertasService` + `AlarmaDto` + DashboardScreen integration | Depends on Step 5 endpoint being live. |
| 7 | Firebase Push | Backend: `FirebaseConfig` + `NotificacionService` + `fcmToken` field + endpoint | Depends on Step 5 (`AlertaService.registrar()` is the trigger point). Firebase Admin SDK setup. |
| 8 | Firebase Push | Flutter: packages + FCM init + token registration + foreground handler | Depends on Step 7 backend being ready. Android-only work. |
| 9 | Calendar | Backend: `fechaPlanificada` field + `/api/ordenes/calendario` endpoint | Independent of all other features. Can be done in parallel with Steps 7-8 if time allows. |
| 10 | Calendar | Flutter: `table_calendar` + `CalendarioScreen` + route + drawer entry | Depends on Step 9 endpoint. |

### Parallel Opportunity
Steps 7-8 (Firebase) and Steps 9-10 (Calendar) can be developed in parallel by splitting backend vs. frontend work, or by two separate sessions. Firebase setup is self-contained; calendar is self-contained.

---

## Security: New Endpoints in SecurityConfig

All new endpoints fall under the existing `.anyRequest().authenticated()` catch-all. No changes to `SecurityConfig.java` are required **unless** role restrictions are desired:

| Endpoint | Default (catch-all) | Recommended restriction |
|----------|---------------------|------------------------|
| `GET /api/alertas/activas` | authenticated | No change — all roles see alarms |
| `POST /api/usuarios/{id}/fcm-token` | authenticated | No change — own token registration |
| `GET /api/ordenes/calendario` | authenticated | No change |

---

## New vs Modified Components Summary

### Backend

| Component | New / Modified |
|-----------|---------------|
| `AlertaService.java` | NEW |
| `AlertaController.java` | NEW |
| `FirebaseConfig.java` | NEW |
| `NotificacionService.java` | NEW |
| `OrdenTrabajo.fechaPlanificada` | MODIFIED (add field) |
| `Usuario.fcmToken` | MODIFIED (add field) |
| `PLCPollingService.procesarAlertas()` | MODIFIED (call AlertaService) |
| `OrdenTrabajoController` | MODIFIED (add /calendario endpoint) |
| `MantenimientoService` | MODIFIED (add calendar query method) |
| `UsuarioController` | MODIFIED (add FCM token endpoint) |
| `pom.xml` | MODIFIED (add firebase-admin) |

### Flutter

| Component | New / Modified |
|-----------|---------------|
| `widgets/kpi_summary_widget.dart` | NEW |
| `services/alertas_service.dart` | NEW |
| `services/export_service.dart` | NEW |
| `services/calendario_service.dart` | NEW |
| `models/alarma.dart` | NEW |
| `screens/calendario_screen.dart` | NEW |
| `kpis_screen.dart` | MODIFIED (fl_chart, export button) |
| `dashboard_screen.dart` | MODIFIED (KpiSummaryWidget, real alerts) |
| `ordenes_screen.dart` | MODIFIED (export button) |
| `models/orden_trabajo.dart` | MODIFIED (fechaPlanificada field) |
| `main.dart` | MODIFIED (Firebase init guard, /calendario route) |
| `pubspec.yaml` | MODIFIED (table_calendar, firebase_core, firebase_messaging, flutter_local_notifications) |

---

## Critical Integration Notes

**1. Firebase on multiplatform:** `Firebase.initializeApp()` must be guarded with `defaultTargetPlatform == TargetPlatform.android`. Calling it on Web or Windows will crash. The `kIsWeb` constant also works. Do not add `google-services.json` references to the Web or Windows build paths.

**2. In-memory alert store reboot risk:** `AlertaService` in-memory `ConcurrentHashMap` is wiped on server restart. For a TFG demo this is fine — PLC polling will re-trigger alarms within 5 seconds. Document this explicitly in the demo script.

**3. `fechaPlanificada` vs `fechaCreacion`:** `OrdenTrabajo.fechaCreacion` is auto-set in the constructor to `LocalDateTime.now()`. `fechaPlanificada` is the user-chosen date and can be null for corrective OTs. The calendar endpoint should filter `fechaPlanificada IS NOT NULL AND tipo = 'PREVENTIVA'` to avoid null pointer issues in stream operations.

**4. PDF on Web:** `Printing.layoutPdf()` on Flutter Web triggers a browser print dialog, which is the correct behavior. No special handling needed.

**5. Existing OT PDF pattern:** The backend stores `reportePdfBase64` in MySQL for closed OTs. The new `ExportService` (Feature 5) generates PDFs client-side in Flutter and does NOT interact with this field — it generates fresh KPI or list reports, not OT close reports. These are separate concerns.

**6. SecurityConfig catch-all:** The final `.anyRequest().authenticated()` rule covers all new endpoints. Verify that new controller mappings (`/api/alertas/**`, `/api/usuarios/*/fcm-token`, `/api/ordenes/calendario`) do not accidentally match an existing `permitAll()` or role rule by checking the order of `requestMatchers` in SecurityConfig. Spring Security evaluates rules top-to-bottom, first match wins.
