# SUMMARY: Phase 4 - Calendario Mantenimiento Preventivo

Se ha implementado el módulo de planificación temporal y gestión de mantenimiento preventivo.

## Estado de la Implementación
- [x] **Backend**: Extensión del modelo `OrdenTrabajo` con `fechaPlanificada` (LocalDate).
- [x] **API**: Nuevos endpoints para filtrado y obtención de tareas programadas.
- [x] **Frontend**: Pantalla `CalendarioScreen` con `TableCalendar`.
- [x] **Internacionalización**: Localización completa al español (`es_ES`) y configuración de `intl`.
- [x] **UX**: Flujo de creación de OT Preventiva con DatePicker y selector de máquinas.

## Archivos Principales
- Backend: `OrdenTrabajo.java`, `OrdenTrabajoController.java`.
- Frontend: `calendario_screen.dart`, `main.dart` (init locales).
