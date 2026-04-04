# Justificación del Proyecto: MèlticGmao

La justificación de este Trabajo de Fin de Grado (TFG) se fundamenta en tres pilares esenciales: la necesidad industrial, el salto cualitativo hacia la Industria 4.0 y la madurez tecnológica adquirida durante el ciclo formativo.

### 1. Contexto y Oportunidad de Mercado (La Necesidad Industrial)
Históricamente, el mantenimiento industrial se ha regido por modelos **reactivos** (reparar cuando se rompe) o **preventivos estáticos** (revisiones periódicas independientemente del desgaste real). Estas metodologías presentan ineficiencias críticas: 
*   **Paradas no planificadas**: Los fallos mecánicos inesperados detienen la cadena de producción, generando enormes pérdidas económicas.
*   **Gestión Documental Arcaica**: Las Órdenes de Trabajo (OT) en papel sufren extravíos, dificultan la trazabilidad y retrasan el volcado de datos.
*   **Aislamiento de la Maquinaria**: Los tableros de control tradicionales obligan al técnico a estar presencialmente frente a la máquina para leer su estado.

Ante este panorama, las fábricas modernas exigen sistemas informatizados para la Gestión del Mantenimiento Asistido por Ordenador (GMAO) que no dependan del papel y que ofrezcan datos fiables.

### 2. Propuesta de Valor y Solución (MèlticGmao)
MèlticGmao nace con el objetivo de democratizar el acceso al **Mantenimiento Predictivo** y resolver las carencias mencionadas mediante una plataforma híbrida (Hardware + Software). La solución propuesta aporta:

1.  **Monitorización Continua y Ubicua (Digital Twin)**: La integración con un PLC Controllino permite recoger telemetría crítica (Temperatura, Vibración, Presión, Intensidad Eléctrica) y transmitirla en tiempo real. Esto permite a los jefes de mantenimiento visualizar el estado de la planta desde cualquier lugar mediante la app móvil.
2.  **Transición Paperless**: Al generar, gestionar certificaciones y firmar digitalmente reportes en PDF directamente en el smartphone, se elimina la huella de carbono del papel y se asegura una trazabilidad inviolable.
3.  **Seguridad Biométrica e IoT**: La inclusión de validación presencial mediante tarjetas RFID asegura que los técnicos están físicamente frente a la máquina al cerrar una intervención, erradicando los "cierres falsos".

### 3. Relevancia Tecnológica y Académica
Desde el punto de vista académico, este proyecto justifica la culminación de los estudios al requerir la integración arquitectónica de tecnologías punteras impartidas y auto-aprendidas a lo largo de los estudios:

*   **Persistencia Dual (Polyglot Persistence)**: Se demuestra una capacidad avanzada de arquitectura de software al separar datos transaccionales de alta fiabilidad (MySQL) del Big Data de series temporales de sensores (MongoDB).
*   **Arquitectura de Microservicios y API REST**: El uso de **Spring Boot** para orquestar la lógica de negocio y exponerla bajo estándares de documentación (Swagger/OpenAPI).
*   **Movilidad Empresarial**: Demostración de destrezas en Front-End multiplataforma utilizando **Flutter**, gestionando estados asíncronos y flujos reactivos complejos.
*   **Electrónica e IoT**: Supone un reto añadido al interconectar el software con el mundo físico, tratando con el "ruido" de sensórica y gestionando buffers de red industrial mediante `HTTP Polling`.

### Conclusión
Se justifica la viabilidad e importancia de MèlticGmao al ser una respuesta técnica rigurosa a un problema del mundo real. No es simplemente un software de gestión clásico (CRUD), sino un sistema de integración ciberfísica representativo de las fábricas del futuro. 
