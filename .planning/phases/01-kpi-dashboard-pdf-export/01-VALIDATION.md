---
phase: 1
slug: kpi-dashboard-pdf-export
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-17
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK built-in) — manual smoke tests only |
| **Config file** | none — default Flutter test runner |
| **Quick run command** | `flutter test` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds (no unit tests — compile check only) |

> Note: REQUIREMENTS.md explicitly marks automated tests as Out of Scope for this TFG.
> All phase verification is manual smoke testing via the running app.

---

## Sampling Rate

- **After every task commit:** Visual inspection in running app
- **After every plan wave:** Full manual smoke of all success criteria
- **Before `/gsd-verify-work`:** All 5 success criteria must pass manually
- **Max feedback latency:** ~60 seconds (hot reload + visual check)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-xx-01 | 01 | 1 | KPI-01 | — | N/A | smoke | manual — open DashboardScreen | ❌ W0 | ⬜ pending |
| 1-xx-02 | 01 | 1 | KPI-02 | — | N/A | smoke | manual — open drawer | ❌ W0 | ⬜ pending |
| 1-xx-03 | 01 | 1 | KPI-03 | — | N/A | smoke | manual — open KpisScreen | ❌ W0 | ⬜ pending |
| 1-xx-04 | 01 | 1 | KPI-04 | — | N/A | smoke | manual — open KpisScreen | ❌ W0 | ⬜ pending |
| 1-xx-05 | 01 | 1 | KPI-05 | — | N/A | smoke | manual — DashboardScreen, wait 5s | ❌ W0 | ⬜ pending |
| 1-xx-06 | 01 | 1 | KPI-06 | — | N/A | smoke | manual — tap "Exportar PDF" in KpisScreen | ❌ W0 | ⬜ pending |
| 1-xx-07 | 02 | 2 | EXP-01 | — | N/A | smoke | manual — tap export button in OrdenesScreen | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

> No new test stubs needed — REQUIREMENTS.md explicitly excludes automated tests for TFG scope.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 4 KPI mini-cards appear in DashboardScreen | KPI-01 | No widget tests in scope | Open app → Dashboard → verify OEE/MTBF/MTTR/disponibilidad cards show realistic values |
| Drawer shows "KPIs" entry | KPI-02 | Visual only | Open drawer → verify "INDICADORES" or "KPIs" entry exists and navigates to KpisScreen |
| Bar chart renders monthly evolution | KPI-03 | fl_chart rendering | Open KpisScreen → verify bar chart shows 6-12 months of data |
| OTs metrics table/list visible | KPI-04 | Visual only | Open KpisScreen → verify OTs by state/type/machine section |
| Sala de Servidores shows temp+humidity | KPI-05 | Requires polling runtime | Open DashboardScreen → wait 5s → verify temperature and humidity values update |
| KPI PDF generates and opens | KPI-06 | PDF viewer integration | Open KpisScreen → tap "Exportar PDF" → verify PDF viewer opens with KPI data |
| OT list PDF generates and opens | EXP-01 | PDF viewer integration | Open OrdenesScreen → tap export icon → verify PDF viewer opens with OT table |

---

## Validation Sign-Off

- [ ] All tasks have manual verify instructions
- [ ] All 5 ROADMAP success criteria covered above
- [ ] Wave 0 — no automated stubs needed (TFG out of scope)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s (hot reload)
- [ ] `nyquist_compliant: true` set in frontmatter when executor completes

**Approval:** pending
