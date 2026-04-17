# Technology Stack — New Feature Packages

**Project:** Meltic GMAO v1.0 Final Sprint
**Researched:** 2026-04-17
**Mode:** Subsequent milestone — additions to existing Flutter + Spring Boot 3 app

---

## Existing Stack (Do Not Change)

| Package | Current in pubspec | Status |
|---------|-------------------|--------|
| `fl_chart` | `^0.70.2` | UPGRADE NEEDED (latest: 1.2.0) |
| `syncfusion_flutter_charts` | `^33.1.45` | UPGRADE NEEDED (latest: 33.1.49) |
| `pdf` | `^3.11.1` | Already present — use for KPI PDF |
| `printing` | `^5.13.2` | Already present — use for PDF output |
| `flutter_animate` | `^4.5.0` | Already present |
| `intl` | `^0.20.2` | Already present — required by table_calendar |
| `http` | `^1.1.0` | Already present |
| `shared_preferences` | `^2.3.5` | Already present |

---

## Feature Area 1: KPI Dashboard — Bar Charts and Trend Lines

### Decision: Use `fl_chart` (already in pubspec) — upgrade to 1.2.0

**Why fl_chart over syncfusion for KPI charts:**
The project already has BOTH `fl_chart` and `syncfusion_flutter_charts`. `syncfusion_flutter_charts` is the right choice for the SCADA real-time trend chart (`industrial_chart.dart`) because it has DateTimeAxis and live-streaming capabilities. For KPI bar charts and monthly trend lines in `KpisScreen`, `fl_chart` is lighter, fully open-source (no license overhead), and its `BarChart`/`LineChart` API is a better fit for the discrete aggregated data returned by `/api/stats/dashboard`.

The existing `KpisScreen` already renders bar charts using custom `Container`/`LinearProgressIndicator` widgets. These should be replaced with `fl_chart`'s `BarChart` for proper visual impact.

| Package | Version to use | Why |
|---------|---------------|-----|
| `fl_chart` | `^1.2.0` | Bar charts (OTs by state/type/month), line trend (evolución mensual). Already in pubspec — only version bump needed. |

**Key API surface for KPI charts:**
```dart
// Bar chart — OTs por estado / evolución mensual
BarChart(
  BarChartData(
    barGroups: [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: value, color: color)]),
    ],
    titlesData: FlTitlesData(bottomTitles: AxisTitles(...)),
    gridData: FlGridData(show: true),
    borderData: FlBorderData(show: false),
  ),
)

// Trend line — MTTR/MTBF over time
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(spots: [FlSpot(x, y), ...], color: color, isCurved: true),
    ],
  ),
)
```

**pubspec change:** `fl_chart: ^1.2.0` (bump from `^0.70.2`)

**No new package needed** — just the version upgrade.

---

## Feature Area 2: In-App Alert Panel (Web/Windows) + Firebase Push (Android)

### Decision: Split strategy by platform

The PROJECT.md explicitly states: "Notificaciones in-app para Web/Windows" and "Firebase para push Android". These are two separate implementation paths.

#### 2a. In-App Alerts — Web and Windows

**No new package needed.** Implement as a custom overlay using Flutter's built-in `OverlayEntry` or as a persistent `AnimatedList`/`Column` panel in the app scaffold. The existing `DashboardScreen` already polls machine state every 5 seconds. An in-app alert panel reads alarm state from that same polling loop and renders a dismissable alert list widget using `flutter_animate` (already present) for entrance animations.

Rationale for NOT adding `flutter_local_notifications` for Web: The package explicitly does NOT support Web (confirmed at pub.dev). Windows is supported, but native Windows toast notifications for an academic GMAO demo add setup complexity (WinRT C++ layer) with zero benefit over a well-styled in-app overlay. Avoid.

Rationale for NOT adding `overlay_support`: Unmaintained (last update 2022), conflicts with modern Flutter null-safety patterns. Native `Overlay` API is sufficient.

#### 2b. Firebase Push Notifications — Android only

Three packages are required. They must be added together as a coordinated set.

| Package | Version | Why |
|---------|---------|-----|
| `firebase_core` | `^4.7.0` | Foundation — required before any FlutterFire package. Must initialize `Firebase.initializeApp()` in `main()`. |
| `firebase_messaging` | `^16.2.0` | Receives FCM push tokens, handles foreground/background/terminated app notification states on Android. |

**Key API surface:**
```dart
// main.dart — before runApp
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

// Service — token registration
final token = await FirebaseMessaging.instance.getToken();
// POST token to Spring Boot backend: /api/notificaciones/token

// Foreground handler
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Show in-app alert overlay
});

// Background handler — must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // handle silently
}
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

**Android minimum SDK:** Already met. The project's `flutter_launcher_icons` config sets `min_sdk_android: 21`. Firebase Messaging requires minSdk 19+. No conflict.

**Required setup steps (not a package, but critical):**
1. Create Firebase project at console.firebase.google.com
2. Download `google-services.json` → place in `android/app/`
3. Add `com.google.gms:google-services` plugin to `android/build.gradle` and `android/app/build.gradle`
4. These are config file changes, not pubspec changes

**Do NOT add** `firebase_messaging` to `firebase_core`/`firebase_messaging` under a Web or Windows target — FCM push is Android-only in this project per PROJECT.md scope.

#### 2c. Spring Boot Backend for FCM

**New Maven dependency in `pom.xml`:**

```xml
<dependency>
    <groupId>com.google.firebase</groupId>
    <artifactId>firebase-admin</artifactId>
    <version>9.7.1</version>
</dependency>
```

**Why firebase-admin and not a raw HTTP call:** The Admin SDK handles OAuth2 token refresh for FCM HTTP v1 API automatically. The legacy FCM API (which used a static server key) was deprecated in June 2024. The Admin SDK uses the current v1 API by default.

**What backend needs to implement:**
- `POST /api/notificaciones/token` — stores Android device FCM token per user (add `fcm_token` column to `usuarios` table)
- `NotificationService.java` — calls `FirebaseMessaging.getInstance().send(Message)` when a machine alarm fires
- `FirebaseConfig.java` — initializes `FirebaseApp` with a service account JSON (`serviceAccountKey.json`, loaded from classpath, NOT committed to git)

**Spring Boot change scope:** Small. One new dependency, one config class, one service method, one controller endpoint, one DB column. No restructuring needed.

---

## Feature Area 3: Maintenance Calendar / Preventive OT Planner

### Decision: `table_calendar` ^3.2.0

| Package | Version | Why |
|---------|---------|-----|
| `table_calendar` | `^3.2.0` | De facto standard for Flutter calendar UIs. Month/week/two-week format switching out of the box. EventLoader pattern maps directly to the List of OTs returned by existing `OrdenTrabajoService.fetchOrdenes()`. Locale support via `intl` already in pubspec (`locale: 'es_ES'`). |

**Why not build custom:** The existing bar chart in `KpisScreen` was hand-built (Canvas `Container` blocks). That's acceptable for simple bar charts, but a full interactive calendar with day selection, event dots, and format switching has 400+ lines of layout logic. `table_calendar` covers this in ~80 lines.

**Why not `syncfusion_flutter_calendar`:** Syncfusion's calendar widget requires a community license acknowledgment for open use and adds another Syncfusion package to the already-present `syncfusion_flutter_charts`. The `table_calendar` package is MIT licensed, zero friction.

**Key API surface:**
```dart
TableCalendar<OrdenTrabajo>(
  firstDay: DateTime.utc(2024, 1, 1),
  lastDay: DateTime.utc(2026, 12, 31),
  focusedDay: _focusedDay,
  calendarFormat: _calendarFormat,
  locale: 'es_ES',
  eventLoader: (day) {
    // Return OTs whose fechaProgramada matches `day`
    return _otsMap[day] ?? [];
  },
  onDaySelected: (selectedDay, focusedDay) {
    setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
  },
  onFormatChanged: (format) => setState(() => _calendarFormat = format),
  calendarStyle: CalendarStyle(
    markerDecoration: BoxDecoration(color: IndustrialTheme.neonCyan, shape: BoxShape.circle),
  ),
)
```

**Integration note:** `intl` is already in pubspec and already used for date formatting. `table_calendar` requires calling `initializeDateFormatting('es_ES')` before `runApp()` — this is one line, already doable in `main.dart`.

---

## Feature Area 4: Export KPIs and OT List to PDF

### Decision: Use existing `pdf` + `printing` packages — no new packages

Both `pdf: ^3.11.1` and `printing: ^5.13.2` are already in `pubspec.yaml` and already used for OT detail PDF generation (the existing OT PDF flow is validated). The KPI PDF and OT list PDF are additive uses of the same packages.

**What needs to be added:** A new `KpiPdfGenerator` class (or extend the existing PDF service) that:
1. Builds a `pw.Document()` with KPI summary table, monthly evolution data
2. Calls `Printing.layoutPdf(onLayout: (format) => doc.save())` for print/save dialog

**Key API surface (already familiar from OT PDF):**
```dart
// Same pattern as existing OT PDF — nothing new
final doc = pw.Document();
doc.addPage(pw.Page(build: (context) => pw.Column(children: [
  pw.Text('INFORME KPIs — ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
  pw.Table.fromTextArray(data: kpiRows),
])));
await Printing.layoutPdf(onLayout: (_) => doc.save());
```

**Why NOT add `syncfusion_flutter_pdf`:** Would introduce a second PDF library alongside the already-working `pdf` package. Redundant dependency.

---

## Complete pubspec.yaml Changes Summary

```yaml
# CHANGES ONLY — add these or update versions:

dependencies:
  # BUMP version (already present):
  fl_chart: ^1.2.0                    # was ^0.70.2 — needed for proper BarChart/LineChart API
  syncfusion_flutter_charts: ^33.1.49 # was ^33.1.45 — minor patch update

  # ADD new packages:
  firebase_core: ^4.7.0               # Firebase initialization foundation
  firebase_messaging: ^16.2.0         # Android push notifications
  table_calendar: ^3.2.0              # Preventive OT calendar planner

# NO changes needed for:
#   pdf, printing    — already present, use as-is for KPI PDF
#   flutter_animate  — already present, use for alert animations
#   intl             — already present, table_calendar uses it for locale
#   http             — already present, FCM token registration via existing http pattern
```

---

## Spring Boot pom.xml Changes Summary

```xml
<!-- ADD to <dependencies> in pom.xml -->
<dependency>
    <groupId>com.google.firebase</groupId>
    <artifactId>firebase-admin</artifactId>
    <version>9.7.1</version>
</dependency>
```

New backend files needed (not packages, but scope clarification):
- `config/FirebaseConfig.java` — initializes FirebaseApp from service account JSON
- `service/NotificationService.java` — sends FCM messages via `FirebaseMessaging.getInstance().send()`
- `controller/NotificacionController.java` — `POST /api/notificaciones/token`
- DB migration: add `fcm_token VARCHAR(255)` column to `usuarios` table

No other Spring Boot dependencies needed. No Spring WebSocket, no Spring Security changes.

---

## What NOT to Add

| Package / Tech | Reason to Avoid |
|---------------|-----------------|
| `flutter_local_notifications` | Does NOT support Web. Windows support adds WinRT native setup complexity. In-app overlay via Flutter's built-in `Overlay` API is sufficient and zero-dependency. |
| `overlay_support` | Unmaintained since 2022. Not compatible with current Flutter versions without patching. |
| `syncfusion_flutter_calendar` | Already using Syncfusion for SCADA charts; adding another Syncfusion calendar module bloats the build and is redundant given `table_calendar`. |
| `syncfusion_flutter_pdf` | Redundant — `pdf` package already used and working for OT PDFs. Two PDF engines in one app is a maintenance hazard. |
| `firebase_messaging` on Web/Windows target | PROJECT.md explicitly scopes push notifications to Android only. Firebase Web push requires VAPID keys + service workers — significant setup for a TFG demo with no real users. |
| `firebase_analytics`, `firebase_crashlytics` | Out of scope for a TFG GMAO demo. Add complexity with zero value for the defense. |
| iOS push notifications | Explicitly out of scope per PROJECT.md. |
| `rxdart`, `bloc`, `riverpod` | State management migration mid-TFG is a rewrite risk. The existing setState + service pattern works and is understood. |
| Excel export (`syncfusion_flutter_xlsio`, `excel`) | Explicitly out of scope per PROJECT.md ("Exportación a Excel — complejidad extra sin valor diferencial"). |

---

## Alternatives Considered

| Decision | Chosen | Alternative | Why Not |
|----------|--------|-------------|---------|
| KPI charts | `fl_chart ^1.2.0` (existing, upgrade) | `syncfusion_flutter_charts` (already present) | Syncfusion is used for real-time SCADA; fl_chart is better for discrete aggregated KPI data; avoids mixing chart engines in same screen |
| Calendar | `table_calendar ^3.2.0` | `kalender` (newer, more features) | `kalender` is still maturing (v0.x API), less community adoption, overkill for a monthly OT planner |
| Push backend | `firebase-admin 9.7.1` (Admin SDK) | Raw HTTP to FCM v1 API | Admin SDK handles OAuth2 token auto-refresh; raw HTTP requires manual token management every 60 minutes |
| In-app alerts | Custom `Overlay` widget | `toastification` package | Toastification works but adds a package for something achievable with `flutter_animate` + built-in `Overlay` which is already present |

---

## Confidence Assessment

| Area | Confidence | Source |
|------|------------|--------|
| `fl_chart` v1.2.0 | HIGH | pub.dev package page fetched directly |
| `firebase_core` v4.7.0 | HIGH | pub.dev package page fetched directly |
| `firebase_messaging` v16.2.0 | HIGH | pub.dev package page fetched directly |
| `table_calendar` v3.2.0 | HIGH | pub.dev package page fetched directly |
| `firebase-admin` 9.7.1 Java | HIGH | GitHub firebase-admin-java releases + search |
| `syncfusion_flutter_charts` v33.1.49 | HIGH | pub.dev package page fetched directly |
| flutter_local_notifications Web gap | HIGH | pub.dev explicitly lists supported platforms, Web absent |
| FCM legacy API deprecated June 2024 | MEDIUM | Firebase official migration docs referenced in search |

---

## Sources

- [fl_chart pub.dev](https://pub.dev/packages/fl_chart)
- [firebase_core pub.dev](https://pub.dev/packages/firebase_core)
- [firebase_messaging pub.dev](https://pub.dev/packages/firebase_messaging)
- [table_calendar pub.dev](https://pub.dev/packages/table_calendar)
- [syncfusion_flutter_charts pub.dev](https://pub.dev/packages/syncfusion_flutter_charts)
- [flutter_local_notifications pub.dev](https://pub.dev/packages/flutter_local_notifications)
- [firebase-admin Java GitHub releases](https://github.com/firebase/firebase-admin-java/releases)
- [Spring Boot + FCM HTTP v1 API — Baeldung](https://www.baeldung.com/spring-fcm)
- [FCM migrate to HTTP v1 — Firebase official docs](https://firebase.google.com/docs/cloud-messaging/migrate-v1)
