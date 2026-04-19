---
phase: 1
plan: C
type: execute
wave: 2
depends_on:
  - plan-A
files_modified:
  - Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart
autonomous: true
requirements:
  - KPI-01
  - KPI-02
  - KPI-05
must_haves:
  truths:
    - "DashboardScreen shows 4 new KPI mini-cards (OEE, MTBF, MTTR, DISPONIB.) with values from /api/stats/dashboard below the existing operational card rows"
    - "KPI stats are fetched once on initState and not added to the 5-second refresh timer"
    - "DashboardScreen embeds SalaServidoresWidget below the KPI cards section, above INCIDENCIAS ACTIVAS"
    - "KPI-02 is confirmed working — drawer 'INDICADORES KPI' entry already wired to /kpis (no code change needed)"
  artifacts:
    - path: "Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart"
      provides: "KPI operational cards section + SalaServidoresWidget embedding"
      contains: "_buildOperationalKpiCard"
  key_links:
    - from: "DashboardScreen._loadMaquinas()"
      to: "StatsService().fetchDashboardStats()"
      via: "conditional call (!quiet && _kpiStats == null)"
      pattern: "fetchDashboardStats"
    - from: "DashboardScreen body"
      to: "SalaServidoresWidget()"
      via: "widget embedding"
      pattern: "SalaServidoresWidget\\(\\)"
---

<objective>
Integrate KPI mini-cards and SalaServidoresWidget into DashboardScreen.

Purpose: Fulfil KPI-01 (4 OEE/MTBF/MTTR/disponibilidad cards) and KPI-05 (Sala de Servidores widget) by wiring the Wave 1 widget into the existing DashboardScreen. Also verify KPI-02 (drawer entry already done).

Depends on: Plan A must be complete (SalaServidoresWidget must exist before DashboardScreen imports it).

Output: Modified `dashboard_screen.dart` with new KPIs OPERACIONALES section and Sala de Servidores section.
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
@.planning/phases/01-kpi-dashboard-pdf-export/01-A-SUMMARY.md

<interfaces>
<!-- Key types and contracts the executor needs. Extracted from PATTERNS.md. -->

From lib/screens/dashboard_screen.dart (EXISTING — key sections to read before editing):
```dart
// EXISTING _buildKpiCard (lines 457–500) — reuse verbatim for the new section:
Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 12),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
        SizedBox(height: 4),
        Text(title, style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    ),
  ).animate().scale(duration: 400.ms, curve: Curves.easeOut);
}

// EXISTING insertion point (lines 228–260 approximately):
// After Row([_buildKpiCard("TOTAL TAREAS",...), SizedBox(12), _buildKpiCard("OT PENDIENTES",...)])
// Before SizedBox(height: 30) + INCIDENCIAS ACTIVAS section

// EXISTING section header inline style (line 256):
Row(children: [
  Icon(Icons.sensors_off, color: IndustrialTheme.criticalRed, size: 20),
  SizedBox(width: 8),
  Text("INCIDENCIAS ACTIVAS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white70)),
]),

// EXISTING imports already present:
import 'package:flutter_animate/flutter_animate.dart';
// ADD new imports:
import '../services/stats_service.dart';
import '../widgets/sala_servidores_widget.dart';
```

From lib/services/stats_service.dart (already exists):
```dart
Future<Map<String, dynamic>> fetchDashboardStats() async { ... }
// Returns Map with keys: oeeGlobal, mtbfHoras, mttrHoras, disponibilidadPct, ...
```

From lib/theme/industrial_theme.dart (color constants):
```dart
static const Color operativeGreen = Color(0xFF00C853);
static const Color warningOrange  = Color(0xFFFFA500);
static const Color criticalRed    = Color(0xFFD32F2F);
static const Color neonCyan       = Color(0xFF00E5FF);
static const Color slateGray      = Color(0xFF8892B0);
static const Color claudCloud     = Color(0xFF112240);
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add KPI stats state, fetch call, and color threshold helpers to DashboardScreen</name>
  <files>Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart</files>
  <read_first>
    - Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart — read the FULL file to understand: current state fields, _loadMaquinas() body, existing imports, and the body widget tree structure around the existing operational KPI cards
    - .planning/phases/01-kpi-dashboard-pdf-export/01-PATTERNS.md lines 26–184 — contains exact state fields, load method insertion point, and color threshold helper code
    - Frontend/meltic_gmao_app/lib/services/stats_service.dart — verify fetchDashboardStats() return type and method signature
  </read_first>
  <action>
Make THREE additions to dashboard_screen.dart:

**1. New imports** (add at top, after existing imports):
```dart
import '../services/stats_service.dart';
import '../widgets/sala_servidores_widget.dart';
```

**2. New state field** (add to `_DashboardScreenState` alongside existing fields like `_maquinas`, `_ordenes`):
```dart
Map<String, dynamic>? _kpiStats;
```

**3. Stats fetch in `_loadMaquinas()`** (add inside the try block, after the existing fetchMaquinas and fetchOrdenes calls, BEFORE setState is called). IMPORTANT: guard with `!quiet && _kpiStats == null` so stats are only fetched once on first load, not on every 5-second refresh:
```dart
if (!quiet && _kpiStats == null) {
  try {
    final stats = await StatsService().fetchDashboardStats();
    if (mounted) setState(() { _kpiStats = stats; });
  } catch (_) {
    // KPI stats failure is non-fatal — dashboard still shows operational data
  }
}
```

**4. Color threshold helper methods** (add as private methods in `_DashboardScreenState`, alongside existing helper methods like `_buildKpiCard`). These use the STRICTER thresholds from UI-SPEC Surface 1, NOT KpisScreen thresholds:
```dart
Color _oeeColor(double v)  => v >= 85 ? IndustrialTheme.operativeGreen
    : v >= 65 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;

Color _mtbfColor(double v) => v >= 48 ? IndustrialTheme.operativeGreen
    : v >= 24 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;

Color _mttrColor(double v) => v <= 2 ? IndustrialTheme.operativeGreen
    : v <= 4 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;

Color _dispColor(double v) => v >= 90 ? IndustrialTheme.operativeGreen
    : v >= 75 ? IndustrialTheme.warningOrange : IndustrialTheme.criticalRed;
```

**5. New `_buildOperationalKpiCard` method** (add alongside existing `_buildKpiCard`). This mirrors `_buildKpiCard` but the existing method has no subtitle — use the same Card pattern from KpisScreen kpiCard for the operational KPIs. Keep `_buildKpiCard` signature UNCHANGED (existing 4 operational cards must continue to work):
```dart
Widget _buildOperationalKpiCard(
    String title, String value, String subtitle, IconData icon, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 12),
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(title,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 9,
                color: IndustrialTheme.slateGray)),
      ]),
    ),
  ).animate().scale(duration: 400.ms, curve: Curves.easeOut);
}
```
  </action>
  <verify>
    <automated>grep -n "_kpiStats\|_oeeColor\|_buildOperationalKpiCard\|stats_service\|sala_servidores_widget" "Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart"</automated>
  </verify>
  <acceptance_criteria>
    - `dashboard_screen.dart` contains `Map<String, dynamic>? _kpiStats`
    - `dashboard_screen.dart` contains `import '../services/stats_service.dart'`
    - `dashboard_screen.dart` contains `import '../widgets/sala_servidores_widget.dart'`
    - `dashboard_screen.dart` contains `StatsService().fetchDashboardStats()`
    - `dashboard_screen.dart` contains `!quiet && _kpiStats == null` as the fetch guard
    - `dashboard_screen.dart` contains `Color _oeeColor(double v)`
    - `dashboard_screen.dart` contains `Color _mtbfColor(double v)`
    - `dashboard_screen.dart` contains `Color _mttrColor(double v)`
    - `dashboard_screen.dart` contains `Color _dispColor(double v)`
    - `dashboard_screen.dart` contains `Widget _buildOperationalKpiCard(`
    - The existing `_buildKpiCard` method signature is UNCHANGED (still has 4 params: title, value, icon, color)
  </acceptance_criteria>
  <done>DashboardScreen has _kpiStats state, fetches stats once on load, has color threshold helpers, and has the new _buildOperationalKpiCard widget method — all ready for body integration in Task 2.</done>
</task>

<task type="auto">
  <name>Task 2: Insert KPIs OPERACIONALES section and Sala de Servidores section into DashboardScreen body</name>
  <files>Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart</files>
  <read_first>
    - Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart — read again after Task 1 changes; specifically find the exact lines of the body ScrollView/Column to identify the insertion point BETWEEN the OT PENDIENTES row and the INCIDENCIAS ACTIVAS section
    - .planning/phases/01-kpi-dashboard-pdf-export/01-PATTERNS.md lines 30–56 — shows the exact insertion point comment block with surrounding code context
    - .planning/phases/01-kpi-dashboard-pdf-export/01-UI-SPEC.md Surface 1 (lines 131–165) — card labels, icons, value formats, and insertion point description
    - .planning/phases/01-kpi-dashboard-pdf-export/01-UI-SPEC.md Surface 3 (lines 218–270) — Sala de Servidores section title and insertion point
  </read_first>
  <action>
Find the body widget tree in DashboardScreen. Locate the section that ends with:
```dart
Row(children: [
  _buildKpiCard("TOTAL TAREAS", ...),
  const SizedBox(width: 12),
  _buildKpiCard("OT PENDIENTES", ...),
]),
```
...followed by something like `SizedBox(height: 30)` and the INCIDENCIAS ACTIVAS section header.

Insert the following block BETWEEN the OT PENDIENTES row and the SizedBox that precedes INCIDENCIAS ACTIVAS:

```dart
const SizedBox(height: 20),
// KPIs OPERACIONALES section header (no icon — plain text header style)
const Text(
  'KPIs OPERACIONALES',
  style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.1,
    color: Colors.white70,
  ),
),
const SizedBox(height: 12),
// 4 KPI cards — only render when stats are loaded
if (_kpiStats != null) ...[
  Row(children: [
    _buildOperationalKpiCard(
      'OEE',
      '${((_kpiStats!['oeeGlobal'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%',
      'Eficiencia Global Equipos',
      Icons.speed,
      _oeeColor((_kpiStats!['oeeGlobal'] as num?)?.toDouble() ?? 0),
    ),
    const SizedBox(width: 12),
    _buildOperationalKpiCard(
      'MTBF',
      '${((_kpiStats!['mtbfHoras'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}h',
      'Tiempo Medio Entre Fallos',
      Icons.av_timer,
      _mtbfColor((_kpiStats!['mtbfHoras'] as num?)?.toDouble() ?? 0),
    ),
  ]),
  const SizedBox(height: 12),
  Row(children: [
    _buildOperationalKpiCard(
      'MTTR',
      '${((_kpiStats!['mttrHoras'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}h',
      'Tiempo Medio de Reparación',
      Icons.build_circle_outlined,
      _mttrColor((_kpiStats!['mttrHoras'] as num?)?.toDouble() ?? 0),
    ),
    const SizedBox(width: 12),
    _buildOperationalKpiCard(
      'DISPONIB.',
      '${((_kpiStats!['disponibilidadPct'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%',
      'Disponibilidad de Planta',
      Icons.precision_manufacturing,
      _dispColor((_kpiStats!['disponibilidadPct'] as num?)?.toDouble() ?? 0),
    ),
  ]),
],
const SizedBox(height: 20),
// SALA DE SERVIDORES section header
const Text(
  'SALA DE SERVIDORES',
  style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.1,
    color: Colors.white70,
  ),
),
const SizedBox(height: 12),
const SalaServidoresWidget(),
// Keep the existing SizedBox(height: 30) + INCIDENCIAS ACTIVAS section below unchanged
```

CRITICAL: Do NOT modify any existing widgets above or below this insertion point. The 4 original _buildKpiCard calls (ESTADO PLANTA, ALERTAS CRÍTICAS, TOTAL TAREAS, OT PENDIENTES) must remain exactly as-is. Only ADD content between OT PENDIENTES row and INCIDENCIAS ACTIVAS section.

After adding, verify the drawer entry for KPI-02: search for "INDICADORES KPI" in dashboard_screen.dart to confirm it already points to `/kpis` route. If found, KPI-02 is done (no change needed).
  </action>
  <verify>
    <automated>grep -n "KPIs OPERACIONALES\|SALA DE SERVIDORES\|SalaServidoresWidget\|_buildOperationalKpiCard\|INDICADORES KPI" "Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart"</automated>
  </verify>
  <acceptance_criteria>
    - `dashboard_screen.dart` contains `'KPIs OPERACIONALES'`
    - `dashboard_screen.dart` contains `'SALA DE SERVIDORES'`
    - `dashboard_screen.dart` contains `const SalaServidoresWidget()`
    - `dashboard_screen.dart` contains `_buildOperationalKpiCard(` at least 4 times (one per KPI card)
    - `dashboard_screen.dart` contains `if (_kpiStats != null)` as a guard around the 4 KPI card rows
    - `dashboard_screen.dart` contains `Icons.speed` (OEE card icon)
    - `dashboard_screen.dart` contains `Icons.av_timer` (MTBF card icon)
    - `dashboard_screen.dart` contains `Icons.build_circle_outlined` (MTTR card icon)
    - `dashboard_screen.dart` contains `Icons.precision_manufacturing` (DISPONIB. card icon)
    - `dashboard_screen.dart` contains `'Eficiencia Global Equipos'`
    - `dashboard_screen.dart` contains `'Tiempo Medio Entre Fallos'`
    - `dashboard_screen.dart` contains `'Tiempo Medio de Reparación'`
    - `dashboard_screen.dart` contains `'Disponibilidad de Planta'`
    - `dashboard_screen.dart` contains `'INDICADORES KPI'` (KPI-02 already wired — confirm present)
    - `flutter analyze Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart` produces no errors
  </acceptance_criteria>
  <done>DashboardScreen body contains the KPIs OPERACIONALES section with 4 stats-based mini-cards and the SALA DE SERVIDORES section with SalaServidoresWidget. Existing operational cards are unchanged. KPI-02 drawer entry confirmed present.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Flutter client → /api/stats/dashboard | Authenticated HTTP GET. Same boundary as all existing DashboardScreen API calls. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-1C-01 | Tampering | Stats map key access (_kpiStats!['oeeGlobal'] as num?) | mitigate | Safe cast with `?? 0` fallback on all value extractions. If backend returns unexpected type, card shows 0.0 instead of crashing |
| T-1C-02 | Denial | fetchDashboardStats failure blocks dashboard render | mitigate | Stats fetch is wrapped in separate try/catch. Failure is non-fatal — dashboard renders operational cards normally, KPI section simply doesn't appear (if (_kpiStats != null) guard) |
| T-1C-03 | Information Disclosure | KPI business data displayed in UI | accept | Data is displayed to the authenticated user — the same user who loaded the app via login. No new disclosure surface |
| T-1C-04 | Spoofing | N/A — no new auth logic | accept | Bearer token via AppSession.instance.authHeaders is the established pattern. Unchanged |
</threat_model>

<verification>
After both tasks complete:

1. `grep -c "_buildOperationalKpiCard" Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart` — must return >= 5 (1 definition + 4 calls)
2. `grep -n "SalaServidoresWidget" Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart` — must show 2 lines (import + widget usage)
3. `grep -n "fetchDashboardStats" Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart` — must return 1 match
4. `grep -n "INDICADORES KPI" Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart` — must return 1 match (KPI-02 verification)
5. `flutter analyze Frontend/meltic_gmao_app/lib/screens/dashboard_screen.dart` — no errors
</verification>

<success_criteria>
- DashboardScreen shows KPIs OPERACIONALES section with 4 cards (OEE, MTBF, MTTR, DISPONIB.) loaded from /api/stats/dashboard
- DashboardScreen shows SALA DE SERVIDORES section embedding SalaServidoresWidget
- Stats fetch runs only once on initState, not on the 5-second refresh
- KPI-02 confirmed: drawer entry 'INDICADORES KPI' pointing to /kpis route is present
- All existing DashboardScreen functionality unchanged (maquinas, ordenes, incidencias sections)
- flutter analyze passes with no errors
</success_criteria>

<output>
After completion, create `.planning/phases/01-kpi-dashboard-pdf-export/01-C-SUMMARY.md` with:
- Lines where new sections were inserted
- KPI-02 drawer confirmation (existing or needs fix)
- Any adjustments to insertion point
- flutter analyze result
</output>
