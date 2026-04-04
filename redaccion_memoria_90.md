# Memoria Técnica MelticGmao: Especificación y Desarrollo (Avance 90%)

Este documento consolida la redacción técnica final, integrando los nuevos Casos de Uso y las métricas industriales extendidas.

---

## CAPÍTULO 4: ANÁLISIS DE REQUISITOS (ESPECIFICACIÓN EXHAUSTIVA)

### 4.1. Requisitos Funcionales Ampliados (RF)
*   **RF02 - Telemetría Multivariable de Proceso**: El sistema monitoriza en tiempo real seis variables industriales críticas: **Temperatura (ºC), Humedad (%), Vibración (mm/s²), Presión (bar), Voltaje (V) e Intensidad (A)**. Esto permite una monitorización de la fatiga mecánica y eléctrica del activo.
*   **RF05 - Certificación Digital de Intervenciones**: Generación de reportes PDF oficiales al cierre de cada Orden de Trabajo (OT). Estos documentos incluyen el historial de acciones, checklists de seguridad, fotos de evidencia y firmas digitalizadas del técnico y responsable de planta.

### 4.2. Casos de Uso (CU) - Rigor de Negocio
Se han definido los siguientes flujos críticos para la operativa de planta:

#### CU-01: Autenticación Industrial Mediante RFID
*   **Actores**: Operario / Jefe de Mantenimiento.
*   **Precondición**: El terminal móvil está vinculado a la red WLAN de la planta.
*   **Flujo Principal**:
    1. El usuario acerca su tag físico a la antena NFC del PLC Controllino.
    2. El PLC detecta el UID y lo envía al Backend vía HTTP Polling (15s).
    3. El Backend valida el UID contra la base de datos MySQL.
    4. El sistema notifica a la aplicación móvil el cambio de sesión.
*   **Postcondición**: Acceso autorizado a las funciones de monitorización y gestión de OTs.

#### CU-02: Gestión Dinámica de Umbrales (Gemelo Digital)
*   **Actores**: Jefe de Mantenimiento.
*   **Flujo Principal**:
    1. El usuario selecciona un activo industrial desde el Dashboard.
    2. Accede a la configuración avanzada de umbrales.
    3. Ajusta los límites de alarma (M. Bajo, Bajo, Alto, M. Alto) para variables críticas.
    4. Los cambios se sincronizan en MySQL y afectan al motor de alertas en tiempo real.
*   **Postcondición**: Alertas predictivas recalibradas según el estado de la máquina.

#### CU-04: Cierre de Intervención con Evidencia y Firma
*   **Actores**: Operario Técnico.
*   **Flujo Principal**:
    1. El técnico completa el log de acciones y el protocolo de revisión.
    2. Captura una fotografía del trabajo realizado como evidencia técnica.
    3. Se habilitan los paneles de firma manuscrita para el técnico y el cliente.
    4. Se genera el reporte PDF único para la intervención.
*   **Postcondición**: OT en estado 'CERRADA' y reporte de mantenimiento archivado en MongoDB.

---

## CAPÍTULO 5: DISEÑO DE LA SOLUCIÓN (ARQUITECTURA 90%)

### 5.1. Topología de Red y Segmentación Industrial
La infraestructura se ha segmentado para garantizar la seguridad y el rendimiento:
*   **VLAN 10 (Planta/OT)**: Segmento dedicado al PLC Controllino (`192.168.1.11`), sensores industriales y lector RFID.
*   **VLAN 20 (Gestión/IT)**: Segmento para el Servidor Central (`192.168.1.50`) que aloja el Backend Spring Boot y los motores de base de datos MySQL y MongoDB.
*   **Comunicación**: El intercambio de datos se realiza mediante un ciclo de **polling optimizado a 15 segundos**, garantizando la estabilidad del buffer Ethernet del hardware industrial.

### 5.2. Modelo de Persistencia Dual
*   **MySQL**: Gestión relacional para entidades de negocio como Usuarios, Máquinas y Órdenes de Trabajo (ACID).
*   **MongoDB**: Almacenamiento NoSQL para series temporales de sensores, permitiendo consultas masivas de tendencias históricas.

---

## CAPÍTULO 6: DESARROLLO Y MITIGACIÓN DE RIESGOS

### 6.1. Generación de Reportes PDF y Certificación
Se ha desarrollado un motor de reportes basado en `PdfGenerator` que garantiza la trazabilidad:
*   **Firmas Vectoriales**: Captura de trazos manuales como `Uint8List` para renderizado en PDF.
*   **Prueba Visual**: Inserción de imágenes de evidencia (Base64) procesadas desde la cámara del dispositivo móvil.

### 6.2. Tratamiento de Ruido RFID en Entorno Industrial
Durante el desarrollo se identificó ruido electromagnético en el bus RFID. Se implementó:
*   **Debouncing por Software**: Filtrado de lecturas erráticas.
*   **Polling Control**: Cancelación de redundancia de red al detectar un proceso de autenticación en curso.

---
© 2026 MèlticGmao - Ingeniería en Mantenimiento Industrial.
