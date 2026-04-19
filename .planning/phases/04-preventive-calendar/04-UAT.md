---
status: complete
phase: 04-preventive-calendar
source: [SUMMARY.md]
started: 2026-04-19T11:50:00Z
updated: 2026-04-19T13:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Kill any running backend/Docker services. Clear ephemeral state. Start the application from scratch (docker-compose up or equivalent). Backend boots without errors, database migrations complete, and a basic API call (e.g. GET /api/ordenes) returns a valid response.
result: pass

### 2. CalendarioScreen Loads
expected: Navigating to the calendar section shows a full monthly calendar in Spanish (e.g. "abril 2026", days labelled lun mar mié...). No crash, no English text visible.
result: pass

### 3. Navigate Calendar Months
expected: Tapping the forward/back arrows (or swipe) changes the displayed month. The header updates (e.g. "mayo 2026") and the grid reflects the correct days for that month.
result: issue
reported: "si, pero las semanas tienen que empezar en lunes, no en domingo"
severity: minor

### 4. Scheduled OTs Appear on Calendar
expected: An OT Preventiva that has a fechaPlanificada set shows a marker (dot or highlight) on its scheduled date in the calendar. Tapping that date shows the OT(s) planned for that day.
result: pass

### 5. Create Preventive OT with DatePicker and Machine Selector
expected: Opening the "Nueva OT Preventiva" flow shows a DatePicker to choose fechaPlanificada and a machine selector. After filling in and saving, the new OT appears on the correct date in the calendar.
result: pass

### 6. Spanish Localization Throughout
expected: All calendar labels, month names, weekday abbreviations, and date-picker text are in Spanish (es_ES). No English strings visible anywhere in the calendar or OT creation flow.
result: pass

## Summary

total: 6
passed: 5
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Calendar weeks start on Monday (lunes) as per es_ES locale"
  status: failed
  reason: "User reported: las semanas tienen que empezar en lunes, no en domingo"
  severity: minor
  test: 3
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
