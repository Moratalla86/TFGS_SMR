# State: Mèltic GMAO

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-17)

**Core value:** El técnico puede gestionar el mantenimiento industrial completo desde el móvil.
**Current focus:** Roadmap defined, ready for Phase 1

## Current Position

Phase: Phase 1 — KPI Dashboard + PDF Export
Plan: TBD (pending /gsd-plan-phase 1)
Status: Roadmap defined, ready for Phase 1
Last activity: 2026-04-17 — Roadmap v1.0 TFG Final Sprint created (15 requirements, 4 phases)

Progress: [----------] 0% — Phase 1 not started

## Performance Metrics

- Phases total: 4
- Phases complete: 0
- Requirements total: 15
- Requirements delivered: 0

## Accumulated Context

- REVIEW.md completo resuelto (3 CRITICAL, 9 HIGH, 8 MEDIUM, 8 LOW)
- Bug RFID corregido: /api/plc/last-rfid requeria auth desde login screen -> añadido permitAll
- Bug timestamp RFID corregido: PLCController devolvía LocalDateTime.now() en vez del timestamp real del escaneo
- Credenciales movidas a .env (docker-compose + application.properties)
- KpisScreen existe pero sin datos reales ni gráficas
- Endpoint /api/stats/dashboard ya implementado con seed industrial
- Branch: tfg-rescate
- EXP-01 agrupado en Phase 1 (misma infraestructura PDF que KPI-06)
- Phase 3 (Firebase) depende de Phase 2 (AlertaService backend)
- Phase 4 (Calendario) es independiente — puede construirse en paralelo si el tiempo aprieta
- Cut decision: si el tiempo aprieta, recortar Phase 3 (Firebase push). Demo sigue completo con Phases 1+2+4.

## Key Risks Active

- Firebase applicationId mismatch en build.gradle.kts — verificar ANTES de flutterfire configure
- Background FCM handler necesita @pragma('vm:entry-point') — falla silenciosamente en release
- table_calendar LocaleDataException — añadir initializeDateFormatting('es_ES') en main()

## Session Continuity

Next action: Run /gsd-plan-phase 1 to decompose Phase 1 into executable plans.
Roadmap file: .planning/ROADMAP.md
Requirements file: .planning/REQUIREMENTS.md

---
*Last updated: 2026-04-17 — Roadmap defined*
