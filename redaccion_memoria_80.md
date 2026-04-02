# Contenido para la Memoria: MèlticGmao (Avance 80%)

Este documento contiene la redacción técnica estructurada para ser integrada en el esqueleto oficial de la memoria.

---

## CAPÍTULO 4: ANÁLISIS DE REQUISITOS (RA3)

### 4.1. Especificación de Requisitos Funcionales (RF)
El sistema se divide en cuatro módulos críticos que garantizan la operatividad del mantenimiento industrial:

*   **RF01 - Módulo de Autenticación Híbrida**: El sistema debe permitir el acceso mediante credenciales estándar (email/password) y mediante tags RFID físicos vinculados a la ficha del empleado.
*   **RF02 - Monitorización en Tiempo Real (Telemetría)**: Captura continua de temperatura, humedad y estado del motor desde el PLC Controllino, con visualización gráfica reactiva en la App.
*   **RF03 - Gestión de Órdenes de Trabajo (OT)**: Ciclo de vida completo de las intervenciones (Pendiente, En Proceso, Cerrada), permitiendo la asignación de tareas a técnicos específicos.
*   **RF04 - Gemelo Digital y Umbrales**: Configuración remota de los límites operativos de la maquinaria, permitiendo al administrador definir alarmas térmicas y de funcionamiento.

### 4.2. Requisitos No Funcionales (RNF)
*   **RNF01 - Resiliencia Industrial**: El backend debe gestionar desconexiones temporales del PLC mediante sistemas de timeout y reintento (Polling Rate: 15s).
*   **RNF02 - Persistencia Políglota**: Uso de MySQL para datos transaccionales (integridad ACID) y MongoDB para series temporales de sensores (escalabilidad horizontal).
*   **RNF03 - Diseño Responsivo**: La interfaz móvil debe ser operativa en dispositivos con orientaciones verticales y relaciones de aspecto variadas.

---

## CAPÍTULO 5: PROPUESTA DE SOLUCIÓN (RA4)

### 5.1. Arquitectura del Sistema
MèlticGmao emplea una arquitectura de tres capas hibridada con un nodo IoT periférico:
1.  **Capa de Adquisición (IoT)**: Basada en hardware Controllino, actúa como gateway de sensores y autenticación física.
2.  **Capa de Lógica y Persistencia (Backend)**: Microservicio en Java Spring Boot que centraliza la inteligencia del sistema.
3.  **Capa de Presentación (Frontend)**: Aplicación móvil en Flutter que consume la API REST.

### 5.2. Diseño de Datos (Modelo de Persistencia Dual)
La decisión de usar dos motores de base de datos se fundamenta en el principio de "Polyglot Persistence":

*   **MySQL**: Almacena las entidades con fuertes relaciones de integridad. La tabla `Usuario` se vincula `1:N` con `OrdenesTrabajo`. Se garantiza que ninguna OT quede huérfana y que los estados de las máquinas sean consistentes en todo momento.
*   **MongoDB**: Almacena documentos de la colección `telemetria`. Cada documento registra el `maquinaId`, `valor` y `timestamp`. Esta estructura permite consultas de series temporales de gran volumen sin impactar en el rendimiento de los informes de gestión en MySQL.

### 5.3. Casos de Uso Críticos
**CU-08: Cierre de Intervención con Validación RFID**
*   **Descripción**: El técnico finaliza su trabajo y debe validar su presencia física en la máquina para cerrar el ticket.
*   **Precondición**: OT en estado 'EN_PROCESO' y técnico logueado.
*   **Flujo**: El técnico acerca su tag al lector -> El PLC envía el ID al backend -> El backend valida que el tag coincide con el técnico asignado -> Se habilita el botón de firma y cierre en la App.
*   **Postcondición**: La OT pasa a estado 'CERRADA' y se genera el reporte PDF técnico.

---

## CAPÍTULO 6: DESARROLLO DE LA SOLUCIÓN (RA5)

### 6.1. Módulo IoT y Control de Flujo
El desarrollo del firmware en el PLC Controllino se ha centrado en la eficiencia del ciclo de captura. La lógica implementada realiza una lectura secuencial de los sensores (DHT11 y RFID) y empaqueta los resultados en un objeto JSON estándar.
*   **Sincronización**: Inicialmente el sistema operaba a 10s, pero se detectaron saturaciones en el buffer Ethernet del hardware. Se ha ajustado a un ciclo de polling de **15 segundos**, optimizando la estabilidad del enlace.

### 6.2. Módulo de Seguridad y Autenticación
La seguridad se ha abordado de forma multinivel:
1.  **JWT en Backend**: Protección de los endpoints REST.
2.  **Validación RFID**: Solo el personal con tarjeta registrada puede realizar cambios de estado en las máquinas.
3.  **Sistema Failsafe (Plan B)**: Se ha desarrollado un mecanismo de simulación mediante un gesto oculto (doble toque en login) para garantizar la continuidad de la demo ante posibles fallos de cobertura o hardware.

### 6.3. Interfaz de Usuario y Responsividad
En el desarrollo Frontend con Flutter, se han aplicado técnicas de diseño fluido:
*   **Layouts Flexibles**: Uso de widgets `Flexible` y `Expanded` para evitar errores de desbordamiento horizontal en terminales móviles pequeños.
*   **Interacción de Firma**: Implementación de gestores de foco que cierran el teclado virtual automáticamente al activar el panel de firma manuscrita.

---

## CAPÍTULO 7: METODOLOGÍA Y PLANIFICACIÓN (RA6)

### 7.1. Metodología de Trabajo
Se ha optado por una metodología **Ágil (Scrum/Kanban)** adaptada al desarrollo individual, con sprints semanales. La trazabilidad del proyecto se ha mantenido íntegra mediante el control de versiones con Git.

### 7.2. Planificación Temporal (Desglose de 200h)
El proyecto ha supuesto una inversión de tiempo estimada para un perfil junior de Desarrollo de Aplicaciones Multiplataforma:
1.  **Investigación y Selección de Hardware**: 20h.
2.  **Análisis y Especificación**: 15h.
3.  **Diseño de Arquitectura y Base de Datos**: 20h.
4.  **Desarrollo del Backend y Lógica IoT**: 55h.
5.  **Desarrollo de la App Móvil (Flutter)**: 45h.
6.  **Pruebas de Integración y Calibración**: 15h.
7.  **Documentación y Ajustes Finales**: 30h.

### 7.3. Gestión de Incidencias y Riesgos
Durante la fase de integración (80%) surgieron riesgos técnicos críticos asociados al entorno industrial:
*   **Incidencia IP**: El PLC cambió su direccionamiento de forma dinámica. Se resolvió mediante un escaneo de red y la asignación manual en los archivos de configuración (`application.properties`).
*   **Latencia de Red**: Se mitigó implementando timeouts técnicos de 5 segundos en el `RestTemplate` para evitar el bloqueo del hilo de ejecución del servidor.

---
© 2026 MèlticGmao - Innovación en Mantenimiento Industrial.
