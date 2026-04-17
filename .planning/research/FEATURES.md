# Feature Landscape: GMAO KPIs, Notificaciones, Calendario y PDF

**Domain:** Industrial CMMS (Computerized Maintenance Management System)
**Researched:** 2026-04-17
**Existing app context:** Flutter + Spring Boot. KpisScreen ya existe con datos reales (OEE, MTTR, MTBF, disponibilidad, ratio prev/corr, evolución mensual, ranking). PDF ya existe para cierre de OT individual. Dashboard ya muestra incidencias activas como lista. Packages disponibles: fl_chart, syncfusion_flutter_charts, pdf, printing.

---

## Feature 1: KPI Dashboard

### Contexto actual

La `KpisScreen` ya renderiza los datos que devuelve `/api/stats/dashboard`: tarjetas de OEE/MTBF/MTTR/disponibilidad, gráfica de barras de evolución mensual preventivo vs correctivo, ratio con barra de progreso, y ranking de incidencias por máquina. El `DashboardScreen` muestra 4 tarjetas operativas simples (estado planta, alertas críticas, total tareas, OT pendientes).

### Table Stakes (lo que un supervisor espera encontrar)

| Feature | Por qué se espera | Complejidad | Estado actual |
|---------|-------------------|-------------|---------------|
| MTTR y MTBF como cifras prominentes con unidad (horas) | Son las dos métricas universales de mantenimiento industrial | Baja | YA EXISTE en KpisScreen |
| Color semafórico (verde/naranja/rojo) según benchmark | El supervisor identifica de un vistazo si está en zona de riesgo | Baja | YA EXISTE con umbrales definidos |
| OEE global como porcentaje | Estándar ISO 22400; "world class" = 85% | Baja | YA EXISTE |
| Disponibilidad de planta en % | Complemento directo del OEE | Baja | YA EXISTE |
| Ratio preventivo vs correctivo con objetivo | El objetivo del sector es >80% preventivo | Baja | YA EXISTE con badge de cumplimiento |
| Evolución temporal de OTs (mínimo 6 meses) | Permite ver tendencia, no solo snapshot | Media | YA EXISTE como barras custom |
| Ranking de máquinas por número de incidencias | Identifica el activo más problemático ("Top Worst Assets") | Baja | YA EXISTE |
| Widget resumen de KPIs en DashboardScreen | El supervisor no debe ir a otra pantalla para ver el estado de hoy | Baja | FALTA — dashboard solo tiene contadores operativos simples |
| Entrada "INDICADORES KPI" en drawer | Acceso directo desde cualquier pantalla | Baja | YA EXISTE |
| Pull-to-refresh en KpisScreen | Datos en tiempo real son esenciales en entorno industrial | Baja | YA EXISTE |

### Diferenciadores (valor añadido visible en la defensa)

| Feature | Valor | Complejidad | Recomendación |
|---------|-------|-------------|---------------|
| Gráfica de línea de tendencia MTTR/MTBF mensual | Muestra evolución de fiabilidad, no solo estado actual | Media | CONSTRUIR — usa fl_chart o syncfusion ya instalados |
| Gráfica de dona o pie chart para OTs por estado | Visualización más impactante que barras de progreso para distribución | Baja | CONSTRUIR — complementa lo existente |
| Benchmark visual (línea de referencia "world class") | Contextualiza el valor; ej. línea roja en MTTR a 4h | Media | CONSTRUIR — solo requiere overlay en la gráfica |
| Período de filtro (semana/mes/trimestre) en KpisScreen | Permite comparar períodos | Alta | DIFERIR — endpoint no lo soporta hoy |
| OEE desglosado en Disponibilidad × Rendimiento × Calidad | Análisis profundo ISO 22400 | Alta | DIFERIR — requiere datos adicionales de producción |

### Anti-Features

| Anti-Feature | Por qué evitarlo | Alternativa |
|--------------|-----------------|-------------|
| Más de 6 KPI en la pantalla de resumen del Dashboard | Sobrecarga cognitiva; "data overload"; investigación del sector indica máximo 5 KPIs para supervisores | Mantener los 4 actuales del Dashboard + uno o dos nuevos con acceso a KpisScreen para detalle |
| Gráficas animadas con alta latencia | En pantallas de control industrial la respuesta <1s es expectativa, no lujo | Animar con flutter_animate (ya instalado) al cargar, no en cada frame |
| KPIs financieros (coste por hora, coste por avería) | Fuera de scope del TFG; requieren datos de coste que no existen en el seed | No implementar |
| Comparativa entre técnicos individual ("leaderboard") | Conflictivo laboralmente; no estándar en GMAO para demo de TFG | El ranking de máquinas es suficiente |

### Lo que el supervisor espera vs el técnico

- **Supervisor / Jefe de Mantenimiento:** Ve KpisScreen completa. Quiere el ratio prev/corr y la evolución mensual para justificar decisiones de presupuesto. El benchmark visual ("objetivo cumplido") es exactamente lo que esperan.
- **Técnico:** Ve DashboardScreen. Necesita únicamente el widget resumen — cuántas OT hay abiertas hoy y si hay alertas — no gráficas de tendencia.

---

## Feature 2: Notificaciones y Panel de Alertas

### Contexto actual

El `DashboardScreen` ya muestra la sección "INCIDENCIAS ACTIVAS" cuando hay máquinas con estado distinto a OK/Operativo, como lista con badge ALARMA. Refresco automático cada 5 segundos. No hay notificaciones push ni sistema de acknowledge.

### Table Stakes

| Feature | Por qué se espera | Complejidad | Estado actual |
|---------|-------------------|-------------|---------------|
| Lista de alarmas activas visible desde el Dashboard | El operario debe ver qué está fallando sin buscar | Baja | YA EXISTE (lista de incidencias activas) |
| Timestamp de cuándo se activó la alarma | El MTTR empieza desde la detección, no desde el cierre | Media | FALTA — actualmente solo muestra nombre de máquina |
| Acción directa desde la alerta ("Crear OT" o "Ver máquina") | Reduce tiempo de respuesta; estándar en CMMS móvil | Media | PARCIAL — hay arrow_forward_ios pero navega a detalle de máquina, no crea OT |
| Contador de alarmas en la AppBar o badge en el drawer | El usuario sabe de un vistazo si hay algo urgente | Baja | FALTA — el contador existe en el Dashboard pero no como badge persistente |
| Diferenciación visual por severidad (crítica vs advertencia) | No todas las alarmas tienen la misma urgencia | Baja | PARCIAL — solo hay criticalRed, sin distinción de nivel |
| Notificación in-app (banner/snackbar) al detectar nueva alarma | Alerta sin que el usuario tenga el Dashboard abierto | Media | FALTA |
| Push notification Android vía Firebase | Estándar de facto para apps industriales móviles | Alta | FALTA — definida en PROJECT.md como feature activa |

### Diferenciadores

| Feature | Valor | Complejidad | Recomendación |
|---------|-------|-------------|---------------|
| Botón "RECONOCER" (acknowledge) en cada alerta | Permite trazar quién vio la alarma y cuándo; estándar IEC 62682 | Media | CONSTRUIR — es la interacción esperada en SCADA/GMAO |
| Historial de alarmas reconocidas | Auditoría; trazabilidad | Alta | DIFERIR — requiere tabla backend |
| Creación automática de OT correctiva desde alerta | Cierra el ciclo alerta → OT → cierre | Media | CONSTRUIR si el tiempo lo permite — alto impacto visual en defensa |
| Sonido o vibración en alarma crítica | Captación de atención en entorno ruidoso de fábrica | Baja | OPCIONAL — fácil con flutter, diferenciador visual en demo |

### Anti-Features

| Anti-Feature | Por qué evitarlo | Alternativa |
|--------------|-----------------|-------------|
| Push notifications en Web/Windows | Muy compleja (VAPID, service workers); no es el target del TFG | In-app banner/overlay es suficiente para Web/Windows |
| Alertas sin filtro que muestran el 100% del histórico | En plantas con sensores, pueden generarse miles de alarmas; "alert fatigue" | Mostrar solo alarmas activas (estado != OK) y las últimas N reconocidas |
| Modal bloqueante para cada alarma | Interrumpe el flujo de trabajo del técnico | Banner no intrusivo o SnackBar con acción |

### UX esperada por rol

- **Técnico (Android):** Recibe push de Firebase cuando se le asigna una OT o cuando su máquina entra en alarma. Tap en la notificación abre la OT o el detalle de máquina directamente.
- **Jefe de Mantenimiento (Web/Windows):** Ve banner in-app cuando llega alarma nueva durante su sesión. Puede reconocerla o crear OT desde el mismo banner.
- **Ambos roles en Dashboard:** El badge/contador de alarmas es siempre visible; la lista de incidencias activas es scrollable si hay más de 3.

---

## Feature 3: Calendario de Planificación de OTs Preventivas

### Contexto actual

No existe ningún calendario. Las OTs preventivas se listan en la `OrdenesScreen` junto con las correctivas. El modelo `OrdenTrabajo` ya tiene campos `fechaCreacion` y `fechaPrevista` (o equivalentes), y el tipo distingue PREVENTIVA vs CORRECTIVA.

### Table Stakes

| Feature | Por qué se espera | Complejidad | Estado actual |
|---------|-------------------|-------------|---------------|
| Vista de calendario mensual con OTs preventivas como eventos | Es la interacción principal de cualquier planificador de mantenimiento | Media | FALTA |
| Distinción visual entre OTs preventivas y correctivas en el calendario | El planificador necesita separar lo programado de lo reactivo | Baja | FALTA |
| Tap en una OT del calendario abre su detalle | Navegación natural; equivalente al tap en lista | Baja | FALTA |
| Indicador de carga de trabajo por día (1/2/3+ tareas) | Permite balancear la agenda | Baja | FALTA |
| Crear nueva OT preventiva desde el calendario (tap en día vacío o FAB) | Cierra el ciclo planificación → ejecución sin salir de la pantalla | Media | FALTA |
| Navegación mes anterior / mes siguiente | Permite planificar a futuro o revisar histórico | Baja | FALTA |

### Diferenciadores

| Feature | Valor | Complejidad | Recomendación |
|---------|-------|-------------|---------------|
| Vista semana además de mes | Planificación detallada de la semana activa | Media | CONSTRUIR si el tiempo lo permite — tabla_calendar lo soporta nativamente |
| Color por máquina o por técnico asignado | Identifica conflictos de agenda | Baja | CONSTRUIR — es un simple mapeo de colores, alto impacto visual |
| Badge de OT vencida (fecha pasada, estado != CERRADA) | Alerta visual de incumplimiento | Baja | CONSTRUIR — filter sobre OTs con fechaPrevista < hoy y estado abierto |
| Filtro por técnico (JEFE ve todos, TECNICO ve solo los suyos) | RBAC aplicado al calendario | Media | CONSTRUIR — el RBAC ya existe en el backend |

### Anti-Features

| Anti-Feature | Por qué evitarlo | Alternativa |
|--------------|-----------------|-------------|
| Drag-and-drop para mover OTs en el calendario | Muy compleja en Flutter móvil; requiere backend PATCH; riesgo alto para TFG | Crear nueva OT con fecha seleccionada es suficiente |
| Calendario de OTs correctivas | Las correctivas no se planifican; mezclarlas confunde al planificador | Mostrar OTs correctivas solo como referencia (color diferente, no editables desde calendario) |
| Sincronización con Google Calendar / Outlook | Integración externa fuera de scope | No implementar |
| Generación automática de OTs recurrentes (cada N días) | Requiere sistema de recurrencia en backend; alta complejidad | Diferir; para la demo basta con crear OTs manuales desde el calendario |

### Package recomendado

`table_calendar` (pub.dev) es el estándar de facto en Flutter para calendarios. Soporta marcadores, eventos múltiples por día, vistas mes/semana/día, y tiene excelente rendimiento en mobile y Web. No está instalado todavía — requiere añadir al pubspec. Alternativa con más visual pero más pesado: `syncfusion_flutter_calendar` (ya tienes syncfusion instalado como `syncfusion_flutter_charts`; podrías añadir el módulo de calendario del mismo proveedor).

### Flujo de planificación esperado

```
Jefe abre Calendario → ve mes actual con OTs preventivas marcadas
→ tap en día futuro vacío → formulario de nueva OT preventiva
  (máquina, técnico, descripción, prioridad) → guardar
→ OT aparece en el calendario y en OrdenesScreen
```

---

## Feature 4: Exportación de Informes KPI y OTs a PDF

### Contexto actual

El `PdfGenerator` ya existe y genera el informe de cierre de OT individual (hoja de intervención técnica) con cabecera, datos del activo, checklist, trabajos realizados, evidencia fotográfica y firmas. Usa los packages `pdf` y `printing` ya instalados. Lo que falta es un PDF de tipo "informe de gestión" — resumen de KPIs y listado de OTs para el supervisor.

### Table Stakes (lo que un supervisor espera encontrar en el PDF)

| Sección | Por qué se espera | Complejidad |
|---------|-------------------|-------------|
| Cabecera corporativa con nombre del sistema, fecha de generación y período del informe | Identifica el documento para archivar y auditar | Baja |
| Resumen ejecutivo de KPIs: OEE, MTTR, MTBF, disponibilidad con sus valores numéricos | El supervisor imprime esto para la reunión de dirección | Baja |
| Ratio preventivo vs correctivo con porcentaje y estado vs objetivo | Justifica la estrategia de mantenimiento | Baja |
| Listado de OTs del período con columnas: ID, máquina, tipo, estado, técnico, fecha | Auditoría y trazabilidad regulatoria | Media |
| Ranking de incidencias por máquina (Top 5) | Identifica activos problema para inversión en mejora | Baja |
| Pie de página con número de página y sello de generación | Estándar en documentación industrial | Baja |

### Diferenciadores

| Feature | Valor | Complejidad | Recomendación |
|---------|-------|-------------|---------------|
| Gráfica de barras de evolución mensual renderizada en el PDF | Transforma el informe de tabla en análisis visual | Alta | CONSTRUIR — el package `pdf` soporta canvas; copiar la lógica de barras de KpisScreen |
| Código de color en el PDF para semáforo de KPIs (verde/naranja/rojo en las celdas) | El supervisor identifica de un vistazo el estado | Baja | CONSTRUIR — PdfColors ya disponible |
| Botón "Exportar PDF" directamente en KpisScreen | UX directa; no hay pantalla intermedia innecesaria | Baja | CONSTRUIR |
| Selector de período antes de exportar (últimos 30/90/180 días) | El supervisor necesita informes para reuniones periódicas | Media | DIFERIR — requiere parámetro en el endpoint |
| Exportar listado completo de OTs (no solo las del Dashboard) | Auditoría completa | Media | CONSTRUIR — OrdenTrabajoService.fetchOrdenes() ya existe |

### Anti-Features

| Anti-Feature | Por qué evitarlo | Alternativa |
|--------------|-----------------|-------------|
| Exportación a Excel | Explícitamente fuera de scope en PROJECT.md ("complejidad extra sin valor diferencial para la defensa") | PDF es suficiente |
| Envío por email desde la app | Requiere configuración SMTP o servicio externo; riesgo alto | El visor nativo (Printing.layoutPdf) permite compartir desde el propio SO |
| PDF interactivo con hipervínculos y campos rellenables | Complejidad desproporcionada para el TFG | PDF estático de solo lectura |
| Regenerar el PDF en cada scroll o interacción | Generación de PDF es síncrona y pesada — bloquearía el hilo UI | Generar bajo demanda en tap de botón, con indicador de carga |

### Estructura de PDF recomendada (informe KPI)

```
[Página 1]
CABECERA: Logo / "INFORME DE MANTENIMIENTO - GMAO SMR" / Período / Fecha generación
───────────────────────────────────────────────
SECCIÓN 1: KPIs GLOBALES (2x2 grid: OEE | MTTR / MTBF | Disponibilidad)
  → Valor numérico grande + label + indicador semafórico (color)

SECCIÓN 2: DISTRIBUCIÓN (Ratio prev/corr + badge objetivo)

SECCIÓN 3: EVOLUCIÓN MENSUAL (gráfica de barras en canvas PDF — 6 meses)

SECCIÓN 4: RANKING DE INCIDENCIAS (Top 5 máquinas con barra proporcional)

[Página 2 — si hay OTs]
SECCIÓN 5: LISTADO DE ÓRDENES DE TRABAJO
  Tabla: ID | Máquina | Tipo | Prioridad | Estado | Técnico | Fecha
  (coloreado por estado: verde=CERRADA, naranja=EN_PROCESO, rojo=PENDIENTE)

PIE DE PÁGINA: "Informe generado por GMAO INDUSTRIAL SMR 4.0 - Página N de M"
```

### Reutilización de código existente

El `PdfGenerator` ya establece el patrón: `pw.Document()` + `pw.MultiPage` + header/footer + `Printing.layoutPdf`. La nueva función `generarInformeKpiPdf(Map<String, dynamic> stats, List<OrdenTrabajo> ots)` sigue exactamente el mismo patrón. No hay que introducir dependencias nuevas.

---

## Dependencias entre Features

```
KPI Dashboard (datos en KpisScreen) ──────────→ PDF Export (lee los mismos datos del StatsService)
                                                         ↑
Dashboard Widget (resumen en DashboardScreen) ──────────┘

Notificaciones (alarmas de máquinas) ─────────→ Calendario (OT creada desde alarma = entrada al calendario)
                                ↓
                       Firebase Push (Android)
```

## MVP para la Defensa (orden de prioridad)

Dado el constraint de < 2 semanas y que la demo debe impresionar visualmente:

1. **Widget KPI en DashboardScreen** — alta visibilidad, baja complejidad. El supervisor ve el OEE y MTTR al entrar.
2. **PDF de informe KPI** — el jefe imprime esto para la reunión. Misma tecnología que ya funciona.
3. **Gráfica de tendencia adicional en KpisScreen** — fl_chart o syncfusion ya instalados; añadir línea de MTTR mensual.
4. **Calendario de OTs preventivas** — requiere nuevo package (table_calendar); impacto visual alto para la demo.
5. **Panel de alertas con acknowledge + timestamp** — mejora lo que ya existe; riesgo bajo.
6. **Firebase Push Android** — más complejo (requiere google-services.json, configuración Firebase); implementar último o simplificar a in-app notifications si el tiempo aprieta.

## Fuentes

- [CMMS KPI Dashboards: Top 10 for Maintenance Teams (2026)](https://eworkorders.com/cmms-kpi-dashboards-guide/)
- [Maintenance KPIs: The Most Important Metrics to Track in 2026](https://www.getmaintainx.com/blog/beginners-guide-maintenance-kpis)
- [6 CMMS Reports To Optimize Your Industrial Maintenance](https://tractian.com/en/blog/6-cmms-reports-to-optimize-your-industrial-maintenance)
- [Preventive Maintenance Scheduling: The Complete Guide to Reducing Equipment Downtime](https://oxmaint.com/blog/post/preventive-maintenance-scheduling-guide-reduce-downtime)
- [Alert Notification in CMMS - Guide Ti](https://guideti.com/cmms-solutions/alert-notification-in-cmms/)
- [CMMS Reporting: Key Maintenance Metrics and KPIs to Track](https://worktrek.com/blog/cmms-reporting-key-metrics-and-kpis-to-track/)
- [Automated Notifications - Accruent](https://www.accruent.com/products/maintenance-connection/automated-notification)
