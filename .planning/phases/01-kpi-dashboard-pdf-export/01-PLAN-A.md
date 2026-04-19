---
phase: 1
plan: A
type: execute
wave: 1
depends_on: []
files_modified:
  - Frontend/meltic_gmao_app/lib/services/plc_service.dart
  - Frontend/meltic_gmao_app/lib/widgets/sala_servidores_widget.dart
autonomous: true
requirements:
  - KPI-05
must_haves:
  truths:
    - "PLCService.fetchLastTelemetry(1) returns a Telemetria? by calling GET /api/plc/maquina/1 with Bearer auth and returning body.last"
    - "SalaServidoresWidget polls every 5 seconds, shows temperatura and humedad, and cancels its timer on dispose"
    - "SalaServidoresWidget shows a pulsing green dot when _live=true and a red dot when _live=false"
    - "No setState is called after widget dispose — all setState calls guarded with if (mounted)"
  artifacts:
    - path: "Frontend/meltic_gmao_app/lib/services/plc_service.dart"
      provides: "PLCService.fetchLastTelemetry static method"
      contains: "static Future<Telemetria?> fetchLastTelemetry"
    - path: "Frontend/meltic_gmao_app/lib/widgets/sala_servidores_widget.dart"
      provides: "SalaServidoresWidget StatefulWidget with Timer polling"
      exports: ["SalaServidoresWidget"]
  key_links:
    - from: "SalaServidoresWidget._poll()"
      to: "PLCService.fetchLastTelemetry(1)"
      via: "static method call"
      pattern: "PLCService\\.fetchLastTelemetry\\(1\\)"
    - from: "_SalaServidoresWidgetState.dispose()"
      to: "_timer"
      via: "cancel call"
      pattern: "_timer\\?\\.cancel\\(\\)"
---

<objective>
Build the Sala de Servidores real-time data infrastructure for KPI-05.

Purpose: Deliver the polling service method and self-contained widget that display live Controllino temperatura/humedad in DashboardScreen. This is a Wave 1 foundation plan — DashboardScreen integration (Plan C) depends on this widget existing.

Output:
- `PLCService.fetchLastTelemetry(int maquinaId)` — new static method in existing service
- `lib/widgets/sala_servidores_widget.dart` — new file, self-contained StatefulWidget
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/phases/01-kpi-dashboard-pdf-export/01-RESEARCH.md
@.planning/phases/01-kpi-dashboard-pdf-export/01-PATTERNS.md
@.planning/phases/01-kpi-dashboard-pdf-export/01-UI-SPEC.md

<interfaces>
<!-- Key types and contracts the executor needs. Extracted from codebase patterns in PATTERNS.md. -->

From lib/services/plc_service.dart (EXISTING — add to this file):
```dart
// EXISTING method (keep as-is):
static Future<void> enviarComando(int maquinaId, String comando) async { ... }
// EXISTING imports already present:
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
// ADD these imports:
import 'app_session.dart';
import '../models/telemetria.dart';
```

From lib/models/telemetria.dart (referenced type):
```dart
class Telemetria {
  final double? temperatura;
  final double? humedad;
  final DateTime? timestamp;
  static Telemetria fromJson(Map<String, dynamic> json) { ... }
  // fromJson handles both 'timestampMillis' int and 'timestamp' ISO string automatically
}
```

From lib/services/app_session.dart (auth pattern):
```dart
Map<String, String> get authHeaders {
  final headers = {"Content-Type": "application/json"};
  if (authToken != null) headers["Authorization"] = "Bearer $authToken";
  return headers;
}
// Usage: AppSession.instance.authHeaders
```

From lib/theme/industrial_theme.dart (color constants):
```dart
static const Color operativeGreen = Color(0xFF00C853);
static const Color warningOrange  = Color(0xFFFFA500);
static const Color criticalRed    = Color(0xFFD32F2F);
static const Color neonCyan       = Color(0xFF00E5FF);
static const Color slateGray      = Color(0xFF8892B0);
static const Color claudCloud     = Color(0xFF112240);
static const Color spaceCadet     = Color(0xFF0A192F);
```

From lib/screens/dashboard_screen.dart (Timer lifecycle pattern):
```dart
Timer? _refreshTimer;

@override
void initState() {
  super.initState();
  _load();
  _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
    if (mounted) _load(quiet: true);
  });
}

@override
void dispose() {
  _refreshTimer?.cancel();
  super.dispose();
}
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add PLCService.fetchLastTelemetry static method</name>
  <files>Frontend/meltic_gmao_app/lib/services/plc_service.dart</files>
  <read_first>
    - Frontend/meltic_gmao_app/lib/services/plc_service.dart — read current full content to see existing imports, class declaration, and enviarComando signature before modifying
    - Frontend/meltic_gmao_app/lib/services/telemetria_service.dart — read the fetchPorMaquina method (lines 10–20) to mirror the exact HTTP call pattern
    - Frontend/meltic_gmao_app/lib/models/telemetria.dart — read fromJson to confirm it handles the JSON response shape correctly
    - .planning/phases/01-kpi-dashboard-pdf-export/01-PATTERNS.md lines 664–712 — contains the exact new method body
  </read_first>
  <action>
Add two imports at the top of plc_service.dart (after existing imports, before the class):
```dart
import 'app_session.dart';
import '../models/telemetria.dart';
```

Then add the following static method to the PLCService class, after the existing `enviarComando` method:

```dart
/// Devuelve el último registro de telemetría para una máquina.
/// GET /api/plc/maquina/{maquinaId} — toma el último elemento de la lista.
/// Devuelve null si la respuesta está vacía o hay error (sin lanzar excepción).
/// Machine ID=1 es el Controllino/IoT — asunción TFG-específica.
static Future<Telemetria?> fetchLastTelemetry(int maquinaId) async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/plc/maquina/$maquinaId'),
      headers: AppSession.instance.authHeaders,
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      if (body.isEmpty) return null;
      return Telemetria.fromJson(body.last as Map<String, dynamic>);
    }
    return null;
  } catch (e) {
    debugPrint('PLCService.fetchLastTelemetry error: $e');
    return null;
  }
}
```

Rules:
- Method MUST be `static` to match the existing `enviarComando` pattern (callers use `PLCService.fetchLastTelemetry(1)` without instantiation)
- Do NOT use TelemetriaService — keep PLC calls in PLCService
- Do NOT use `?since=` parameter — simple fetch, take `.last` element
- Auth via `AppSession.instance.authHeaders` (existing pattern in all services)
  </action>
  <verify>
    <automated>grep -n "static Future\&lt;Telemetria?\&gt; fetchLastTelemetry" "Frontend/meltic_gmao_app/lib/services/plc_service.dart"</automated>
  </verify>
  <acceptance_criteria>
    - `plc_service.dart` contains `static Future<Telemetria?> fetchLastTelemetry(int maquinaId)`
    - `plc_service.dart` contains `import 'app_session.dart'`
    - `plc_service.dart` contains `import '../models/telemetria.dart'`
    - `plc_service.dart` contains `AppSession.instance.authHeaders`
    - `plc_service.dart` contains `body.last as Map<String, dynamic>`
    - `plc_service.dart` contains `debugPrint('PLCService.fetchLastTelemetry error`
    - The existing `enviarComando` method is unchanged
  </acceptance_criteria>
  <done>PLCService.fetchLastTelemetry(1) can be called statically and returns Telemetria? with temperatura and humedad fields populated from /api/plc/maquina/1 response.</done>
</task>

<task type="auto">
  <name>Task 2: Create SalaServidoresWidget</name>
  <files>Frontend/meltic_gmao_app/lib/widgets/sala_servidores_widget.dart</files>
  <read_first>
    - Frontend/meltic_gmao_app/lib/widgets/ — list directory to confirm no existing sala_servidores_widget.dart before creating
    - .planning/phases/01-kpi-dashboard-pdf-export/01-PATTERNS.md lines 715–933 — contains the FULL file pattern with all three sub-widgets (_SalaServidoresWidgetState, _SensorCard, _LiveDot)
    - .planning/phases/01-kpi-dashboard-pdf-export/01-UI-SPEC.md Surface 3 (lines 218–270) — temperature color thresholds and animation contract
    - Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart lines 457–500 — _buildKpiCard pattern to mirror in _SensorCard
  </read_first>
  <action>
Create `Frontend/meltic_gmao_app/lib/widgets/sala_servidores_widget.dart` as a NEW file with this exact structure:

**Imports:**
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/plc_service.dart';
import '../models/telemetria.dart';
import '../theme/industrial_theme.dart';
```

**SalaServidoresWidget (StatefulWidget):** Main widget with `const SalaServidoresWidget({super.key})`.

**_SalaServidoresWidgetState fields:**
```dart
Timer? _timer;
double? _temperatura;
double? _humedad;
bool _live = false;
```

**initState:** Call `_poll()` immediately, then start `Timer.periodic(const Duration(seconds: 5), (_) => _poll())`.

**dispose:** `_timer?.cancel(); super.dispose();` — MUST cancel before super.dispose().

**_poll():** `async` method that calls `PLCService.fetchLastTelemetry(1)`. On non-null result: update `_temperatura`, `_humedad`, `_live = true`. On null: `_live = false` but do NOT null out existing values (stale data shown). All `setState` calls MUST be inside `if (mounted)` guard.

**_tempColor(double? temp):** Returns:
- `IndustrialTheme.slateGray` if temp is null
- `IndustrialTheme.operativeGreen` if temp < 25.0
- `IndustrialTheme.warningOrange` if temp < 35.0
- `IndustrialTheme.criticalRed` if temp >= 35.0

**build():** 
- Loading state (when `_temperatura == null && _humedad == null && !_live`): return `SizedBox(height: 60, child: Center(child: CircularProgressIndicator(color: IndustrialTheme.neonCyan, strokeWidth: 2)))`
- Main state: `Container` with `padding: const EdgeInsets.all(16)`, `color: IndustrialTheme.claudCloud`, `borderRadius: BorderRadius.circular(16)`, `border: Border.all(color: Colors.white10)`. Child is a Column with:
  1. Row: `Icon(Icons.sensors, color: IndustrialTheme.neonCyan, size: 18)` + `SizedBox(width: 8)` + `Text('EN VIVO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w400, color: IndustrialTheme.neonCyan, letterSpacing: 1))` + `Spacer()` + `_LiveDot(live: _live)`
  2. `SizedBox(height: 16)`
  3. Row: `_SensorCard(label: 'TEMPERATURA', value: '${_temperatura?.toStringAsFixed(1) ?? '--'}°C', icon: Icons.thermostat, color: _tempColor(_temperatura))` + `SizedBox(width: 12)` + `_SensorCard(label: 'HUMEDAD', value: '${_humedad?.toStringAsFixed(1) ?? '--'}%', icon: Icons.water_drop_outlined, color: IndustrialTheme.neonCyan)`
- Apply entry animation on the outer Container: `.animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0)`

**_SensorCard (StatelessWidget private class):** Fields: `label`, `value`, `icon`, `color` (all required). Build returns `Expanded` wrapping a Container with `padding: const EdgeInsets.all(16)`, `color: IndustrialTheme.claudCloud`, `borderRadius: BorderRadius.circular(16)`, `border: Border.all(color: color.withValues(alpha: 0.3))`, `boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4))]`. Column children: `Icon(icon, color: color, size: 20)` + `SizedBox(height: 12)` + `Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5))` + `SizedBox(height: 4)` + `Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1))`.

**_LiveDot (StatelessWidget private class):** Field `live` (bool). Builds a `Container(width: 8, height: 8, decoration: BoxDecoration(color: live ? IndustrialTheme.operativeGreen : IndustrialTheme.criticalRed, shape: BoxShape.circle))`. When `!live` return the Container directly. When `live` apply pulse animation: `.animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.4, 1.4), duration: 800.ms, curve: Curves.easeInOut).then().scale(begin: const Offset(1.4, 1.4), end: const Offset(1, 1), duration: 800.ms)`.
  </action>
  <verify>
    <automated>flutter analyze Frontend/meltic_gmao_app/lib/widgets/sala_servidores_widget.dart 2>&amp;1 | head -20</automated>
  </verify>
  <acceptance_criteria>
    - File `lib/widgets/sala_servidores_widget.dart` exists
    - Contains `class SalaServidoresWidget extends StatefulWidget`
    - Contains `Timer? _timer`
    - Contains `_timer?.cancel()` in `dispose()`
    - Contains `if (mounted)` before every `setState` call
    - Contains `PLCService.fetchLastTelemetry(1)`
    - Contains `_live = false` in the error/null branch of `_poll()`
    - Contains `class _SensorCard extends StatelessWidget`
    - Contains `class _LiveDot extends StatelessWidget`
    - Contains `.animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0)`
    - Contains `.animate(onPlay: (c) => c.repeat()).scale`
    - Contains `IndustrialTheme.neonCyan` for humedad card color and CircularProgressIndicator
    - Contains `IndustrialTheme.operativeGreen` and `IndustrialTheme.criticalRed` in _LiveDot
    - `flutter analyze` reports no errors on this file (warnings acceptable)
  </acceptance_criteria>
  <done>SalaServidoresWidget is a self-contained StatefulWidget that polls /api/plc/maquina/1 every 5 seconds, renders temperatura and humedad with live status dot, and safely cancels its timer on dispose.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Flutter widget → Backend API | HTTP GET /api/plc/maquina/1 uses Bearer token from AppSession — same boundary as all existing service calls |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-1A-01 | Tampering | PLCService.fetchLastTelemetry response parsing | accept | Response is display-only telemetry (temperatura, humedad). Worst case: null values shown with '--'. Telemetria.fromJson already handles type coercion safely via `(num?)?.toDouble()` |
| T-1A-02 | Denial | Timer.periodic not cancelled on dispose | mitigate | `_timer?.cancel()` is mandatory in dispose() per PATTERNS.md and accepted by acceptance_criteria check. `if (mounted)` guard prevents setState on unmounted widget |
| T-1A-03 | Information Disclosure | Bearer token exposed in HTTP call | accept | AppSession.instance.authHeaders is the established project-wide auth pattern. Token is in memory only, not logged. Same pattern used in all existing services |
| T-1A-04 | Elevation of Privilege | N/A — read-only polling endpoint | accept | No write operations. No auth changes. Endpoint is behind `.anyRequest().authenticated()` in SecurityConfig |
</threat_model>

<verification>
After both tasks complete, verify the full plan:

1. `grep -n "static Future<Telemetria?> fetchLastTelemetry" Frontend/meltic_gmao_app/lib/services/plc_service.dart` — must return a match
2. `grep -n "_timer?.cancel()" Frontend/meltic_gmao_app/lib/widgets/sala_servidores_widget.dart` — must return a match
3. `grep -n "if (mounted)" Frontend/meltic_gmao_app/lib/widgets/sala_servidores_widget.dart` — must return at least 1 match
4. `grep -n "PLCService.fetchLastTelemetry(1)" Frontend/meltic_gmao_app/lib/widgets/sala_servidores_widget.dart` — must return a match
5. `flutter analyze Frontend/meltic_gmao_app/lib/services/plc_service.dart Frontend/meltic_gmao_app/lib/widgets/sala_servidores_widget.dart` — no errors
</verification>

<success_criteria>
- PLCService has `fetchLastTelemetry` static method callable as `PLCService.fetchLastTelemetry(1)`
- SalaServidoresWidget exists and compiles without errors
- Timer is always cancelled on widget dispose
- Every setState in SalaServidoresWidget is guarded with `if (mounted)`
- Widget renders two sensor cards (TEMPERATURA / HUMEDAD) and a pulsing live dot
</success_criteria>

<output>
After completion, create `.planning/phases/01-kpi-dashboard-pdf-export/01-A-SUMMARY.md` with:
- Files created/modified
- Key patterns used
- Any deviations from the plan
- Confirmation that all acceptance criteria passed
</output>
