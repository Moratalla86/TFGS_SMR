# Domain Pitfalls — Meltic GMAO v1.0 TFG Final Sprint

**Stack:** Flutter 3.x + Spring Boot 3 + MySQL + Firebase (not yet integrated)
**Researched:** 2026-04-17
**Scope:** KPIs/charts, Firebase push, calendar, PDF export — 2-week deadline

---

## Quick Reference: All Pitfalls by Impact

| # | Pitfall | Feature | Time Lost | Impact | Prevention | Phase |
|---|---------|---------|-----------|--------|------------|-------|
| 1 | Firebase package ID mismatch (`com.example.*` vs Firebase console) | Push | 4-8 h | App silently never receives any FCM token | Change `applicationId` in `build.gradle.kts` BEFORE creating Firebase project app entry | Phase 2 (Firebase setup) |
| 2 | `@pragma('vm:entry-point')` missing on background handler | Push | 2-4 h | Background notifications disappear in release build, work in debug | Annotate top-level handler function; verify with `flutter run --release` | Phase 2 |
| 3 | `Firebase.initializeApp()` not called in background isolate | Push | 1-3 h | Crash / silent failure when app is killed and notification arrives | Call `WidgetsFlutterBinding.ensureInitialized()` + `Firebase.initializeApp()` at top of background handler | Phase 2 |
| 4 | `firebase_core` / `firebase_messaging` missing from `pubspec.yaml` + no `firebase_options.dart` | Push | 1-2 h | Build fails; `firebase_options.dart` does not exist yet | Run `flutterfire configure` first; adds both packages and generates options file | Phase 2 |
| 5 | `POST_NOTIFICATIONS` permission not requested at runtime (Android 13+) | Push | 1-2 h | Notifications never shown on Android 13+ devices; no error | Call `FirebaseMessaging.instance.requestPermission()` from Dart; also add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` to `AndroidManifest.xml` | Phase 2 |
| 6 | Stats endpoint returns MTTR = 0 when all seed OTs have `tipo == PREVENTIVA` for a machine | KPIs | 1 h | KPI card shows 0 h MTTR, misleading for demo | Verify seed data has `fechaFin` set for CERRADA correctivas; `DataInitializer.buildOT()` already does this when `setClosed=true` — confirm by querying `SELECT tipo, estado, fecha_inicio, fecha_fin FROM ordenes_trabajo LIMIT 20` | Phase 1 (KPIs) |
| 7 | `evolucionMensual` list empty when DB is freshly seeded on a different month than expected | KPIs | 30 min | Bar chart shows "SIN DATOS" in demo | Seed uses `now.minusMonths(i)` — always relative to current date, so this is safe. Pitfall is only if backend restarts mid-demo and seed guard (`usuarioRepo.count() > 0`) prevents re-seeding | Phase 1 |
| 8 | `table_calendar` header shows English month names despite `Intl.defaultLocale = 'es_ES'` | Calendar | 1-2 h | Calendar header reads "April" not "Abril" in demo | Call `initializeDateFormatting('es_ES')` in `main()` before `runApp()`; pass `locale: 'es_ES'` to `TableCalendar`; translate `availableCalendarFormats` map manually | Phase 3 (Calendar) |
| 9 | Duplicate OT creation from rapid double-tap on calendar day | Calendar | 30 min | Same OT created twice, polluting seed data for demo | Use a `bool _creatingOt` guard + `setState` lock in `onDaySelected` callback; or use a debounce with 500 ms minimum interval | Phase 3 |
| 10 | `table_calendar` not yet in `pubspec.yaml` — package missing | Calendar | 15 min | Build fails immediately | Add `table_calendar: ^3.1.2` before starting calendar screen | Phase 3 |
| 11 | `PdfPreview` widget shows "Unable to display document" on Flutter Web | PDF | 1-2 h | KPI PDF export looks broken in browser demo | Use `Printing.layoutPdf()` (already used in `viewLocalPdf`) instead of `PdfPreview` widget; on Web this opens browser print dialog, which works | Phase 4 (PDF) |
| 12 | KPI PDF contains charts as text/tables, not rendered chart images | PDF | 2-4 h | PDF looks plain; no visual charts in demo document | The `pdf` package cannot capture Flutter widget trees. Use `pw.Table` / `pw.BarcodeWidget` or render chart to `ui.Image` with `RepaintBoundary` + `toImage()` + encode to PNG before embedding | Phase 4 |
| 13 | `fl_chart` (already in `pubspec.yaml`) not needed for KPIs — current `kpis_screen.dart` uses a fully custom bar chart | KPIs | 1-2 h wasted | Developer spends time wiring `fl_chart` when the chart is already built and working | Read `kpis_screen.dart` `_buildEvolucionChart()` before touching — the custom bar painter is production-ready. Only use `fl_chart` if adding a new chart type | Phase 1 |
| 14 | `compileSdk` set to `flutter.compileSdkVersion` (not hardcoded 35) in `build.gradle.kts` | Push | 30 min | `firebase_messaging` requires `compileSdk >= 35`; build may fail with older Flutter SDK default | Explicitly set `compileSdk = 35` in `android/app/build.gradle.kts`; similarly set `minSdk = 21` | Phase 2 |
| 15 | `onBackgroundMessage` handler references a class method or closure | Push | 1 h | Dart tree shaker removes the handler in release builds; no crash in debug | Handler must be a `static` top-level function, declared at file scope, with `@pragma('vm:entry-point')` | Phase 2 |
| 16 | Dashboard 5-second refresh timer fires while Firebase init is running | Push | 30 min | Race condition between `_loadMaquinas()` and Firebase setup on app startup | Initialize Firebase in `main()` before `runApp()`, not lazily inside a screen | Phase 2 |
| 17 | `Printing.layoutPdf()` on Windows opens system print dialog, not save | PDF | 30 min | Demo on Windows forces print dialog instead of saving file | Add `kIsWeb` / `Platform.isWindows` branch; use `Printing.sharePdf()` for mobile, `html.AnchorElement` download for web | Phase 4 |
| 18 | Seed guard (`if (usuarioRepo.count() > 0) return`) prevents updating existing data | KPIs | 30 min | Changing seed data requires manual DB wipe (`docker compose down -v`) | Document this: wipe with `docker compose down -v && docker compose up -d`; never mutate seed without wiping | Phase 1 |

---

## Top 3 Risks — Narrative Detail

### Risk 1: Firebase — Package ID Mismatch Will Block Everything (CRITICAL)

**Confidence:** HIGH (verified against FlutterFire official docs + GitHub issues)

The current `android/app/build.gradle.kts` has `applicationId = "com.example.meltic_gmao_app"`. This is the default Flutter stub ID. The `google-services.json` file exists on disk but is empty/placeholder (the file reads 0 bytes in git). There is no `firebase_options.dart` and no Firebase package in `pubspec.lock`.

**What happens if you skip this:** You register a Firebase app for package `com.meltic.gmao` in the Firebase Console, download `google-services.json`, place it in `android/app/`, but the build.gradle still says `com.example.meltic_gmao_app`. The Gradle plugin silently fails to find the matching client entry in `google-services.json`. The app builds and runs, but `FirebaseMessaging.instance.getToken()` returns `null` forever. You spend hours debugging the Dart code when the problem is a two-line Gradle change.

**Correct order of operations:**
1. Change `applicationId` in `build.gradle.kts` to `com.meltic.gmao` (or any custom ID — do it once, never change again)
2. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. Run `flutterfire configure` from the Flutter project root — this creates `firebase_options.dart` and downloads a correct `google-services.json`
4. Add `firebase_core` and `firebase_messaging` to `pubspec.yaml`, then `flutter pub get`
5. Call `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` in `main()` before `runApp()`

**Time cost if missed:** 4-8 hours. This is the single highest time-waster in the milestone.

---

### Risk 2: Background Handler Silently Disappears in Release Builds (HIGH)

**Confidence:** HIGH (official FlutterFire docs + confirmed GitHub issue #9932)

Flutter's tree-shaker removes Dart functions that appear unreachable in release builds. The `FirebaseMessaging.onBackgroundMessage(myHandler)` registration happens at runtime, so the compiler cannot see that `myHandler` is "used" and removes it from the compiled output.

**Exact code pattern that fails silently in release:**

```dart
// WRONG — will be tree-shaken in release
void _handleBackground(RemoteMessage message) { ... }

// WRONG — anonymous function, impossible to annotate
FirebaseMessaging.onBackgroundMessage((msg) async { ... });

// WRONG — class method, requires initialization context
class NotifService {
  Future<void> handle(RemoteMessage msg) async { ... }
}
```

**Correct pattern:**

```dart
// CORRECT — top-level function with pragma
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // handle notification
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // ...
  runApp(const SmrGmaoApp());
}
```

**Critical additional constraint:** The background handler runs in a completely separate Dart isolate. It cannot call `setState`, access any `Provider`/singleton state from the main isolate, or use `AppSession.instance`. It must re-initialize Firebase from scratch. For this app, the background handler should only store the notification locally (e.g., SharedPreferences) and let the foreground app display it when resumed.

**Time cost if missed:** 2-4 hours debugging why push works in debug but not release.

---

### Risk 3: table_calendar Spanish Locale — Two Independent Steps, Both Required (MEDIUM)

**Confidence:** HIGH (Flutter intl docs + table_calendar source)

The app already has `Intl.defaultLocale = 'es_ES'` in `main()` and `flutter_localizations` configured correctly. However, `table_calendar` uses the `intl` package's `DateFormat` internally, and `DateFormat` requires locale data to be explicitly loaded — setting `defaultLocale` is not enough.

**What happens if you skip `initializeDateFormatting`:**

```
Unhandled Exception: LocaleDataException: Locale data has not been initialized,
call initializeDateFormatting('es_ES').
```

This crashes the calendar screen on first open.

**Additionally**, `table_calendar` does not auto-translate its `FormatButton` labels ("Month", "2 weeks", "Week") — these remain in English even with locale set to Spanish.

**Correct setup in `main.dart`:**

```dart
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null); // <-- NEW LINE
  Intl.defaultLocale = 'es_ES';
  await ApiConfig.init();
  runApp(const SmrGmaoApp());
}
```

**Correct `TableCalendar` widget call:**

```dart
TableCalendar(
  locale: 'es_ES',
  firstDay: DateTime.utc(2024, 1, 1),
  lastDay: DateTime.utc(2027, 12, 31),
  focusedDay: _focusedDay,
  availableCalendarFormats: const {
    CalendarFormat.month: 'Mes',
    CalendarFormat.twoWeeks: '2 semanas',
    CalendarFormat.week: 'Semana',
  },
  // ...
)
```

**Time cost if missed:** 1-2 hours. Easy fix once identified, but confusing because the crash appears to contradict the already-configured locale in the app.

---

## Phase-Specific Warnings

| Phase Topic | Most Likely Pitfall | Mitigation |
|-------------|-------------------|------------|
| Phase 1 — KPI real data | MTTR shows 0.0 if correctiva OTs lack `fechaFin` | Verify with SQL before building UI; seed already sets `fechaFin` for CERRADA, so only new OTs created via UI without closing flow are at risk |
| Phase 1 — KPI real data | `evolucionMensual` bar chart already works with custom painter; re-implementing with `fl_chart` wastes 2 h | Read `kpis_screen.dart` before touching chart code |
| Phase 2 — Firebase | `applicationId` mismatch = silent FCM failure | Change applicationId first, then run `flutterfire configure` |
| Phase 2 — Firebase | Background handler tree-shaken in release | Use `@pragma` + top-level function pattern |
| Phase 2 — Firebase | Android 13+ POST_NOTIFICATIONS never shown | Call `requestPermission()` in Dart + manifest entry |
| Phase 3 — Calendar | Missing `initializeDateFormatting` = crash on open | Add to `main()` before `runApp()` |
| Phase 3 — Calendar | Double-tap creates duplicate OT in database | Guard with `bool _isCreating` flag in state |
| Phase 4 — PDF KPIs | `PdfPreview` widget broken on Web | Use `Printing.layoutPdf()` (already used for OT PDFs — reuse same pattern) |
| Phase 4 — PDF KPIs | Charts won't render inside `pdf` package | Use `pw.Table` for numeric data; optionally capture chart via `RepaintBoundary.toImage()` |
| All phases | Docker DB wipe needed if seed changes | `docker compose down -v && docker compose up -d` |

---

## Minor Pitfalls

### `table_calendar` `firstDayOfWeek`
Pass `startingDayOfWeek: StartingDayOfWeek.monday` not an integer. European locale expects Monday as first day; default is Sunday.

### `pdf` Package Unicode Characters
The default Helvetica/Times fonts in the `pdf` package do not support characters like `✓`, `°`, or `ñ`. The existing `pdf_generator.dart` uses `✓` (line 58) — this renders as a box on some platforms. Fix: embed a TrueType font with `pw.Font.ttf(...)` or replace with ASCII equivalents.

### `Printing.layoutPdf()` on Web Opens Print Dialog
On Web, `Printing.layoutPdf()` triggers the browser's native print dialog — not a download. For a KPI export the user expects a file download. Use `dart:html` `AnchorElement` with base64 data URI for web, guarded by `kIsWeb`.

### Stats Endpoint `otsPorEstado` Missing States
If no OT has state `EN_PROCESO`, the map returned by the backend won't contain that key. The Flutter code in `kpis_screen.dart` already handles this with `?? 0` fallbacks (line 256-258) — this pitfall is already mitigated.

### `syncfusion_flutter_charts` License
`pubspec.yaml` already includes `syncfusion_flutter_charts: ^33.1.45`. Syncfusion requires a license key for commercial use; for TFG/academic demo this is acceptable but the `SfCartesianChart` will display a watermark without a key. Use `fl_chart` or the existing custom painter instead to avoid the watermark in screenshots.

---

## Sources

- FlutterFire Messaging Usage: https://firebase.flutter.dev/docs/messaging/usage/
- FCM Receive Messages (Flutter): https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
- FlutterFire Permissions: https://firebase.flutter.dev/docs/messaging/permissions/
- Background handler not executing (GitHub #9932): https://github.com/firebase/flutterfire/issues/9932
- Background duplicate isolate (GitHub #10412): https://github.com/firebase/flutterfire/issues/10412
- flutter_local_notifications (compileSdk 35 requirement): https://pub.dev/packages/flutter_local_notifications
- table_calendar pub.dev: https://pub.dev/packages/table_calendar
- intl LocaleDataException fix: https://widget-chat.com/blog/flutter-intl-localedataexception-troubleshooting-guide/
- pdf package web download (GitHub #813): https://github.com/DavBfr/dart_pdf/issues/813
- PdfPreview web broken (GitHub #593): https://github.com/DavBfr/dart_pdf/issues/593
- fl_chart empty data exception (GitHub #1050): https://github.com/imaNNeo/fl_chart/issues/1050
- FlutterFire Android manual install: https://firebase.flutter.dev/docs/manual-installation/android/
