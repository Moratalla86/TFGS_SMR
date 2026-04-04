# TRABAJO DE FIN DE GRADO: MÈLTIC GMAO - SISTEMA INTEGRAL DE MANTENIMIENTO E IoT
*(Borrador Extenso)*

## CAPÍTULO 1. INTRODUCCIÓN
En el contexto actual de la Cuarta Revolución Industrial (Industria 4.0), la digitalización de los procesos de mantenimiento ha pasado de ser una ventaja competitiva a una necesidad crítica para la supervivencia de las empresas manufactureras. Los sistemas tradicionales basados en papel o en hojas de cálculo estáticas resultan ineficientes, propensos a errores humanos y, lo más importante, carecen de la capacidad de proporcionar información en tiempo real sobre el estado de la planta. 

Mèltic GMAO (Gestión de Mantenimiento Asistido por Ordenador) nace como una respuesta tecnológica avanzada a esta problemática. Este proyecto no es simplemente una base de datos de gestión, sino un ecosistema ciberfísico completo. Integra telemetría en tiempo real mediante hardware IoT industrial (PLC Controllino), un servidor centralizado altamente escalable desarrollado en Java Spring Boot, y una aplicación cliente móvil desarrollada en Flutter, permitiendo a los técnicos y jefes de planta monitorizar, predecir y gestionar incidencias desde la palma de su mano.

El presente documento detalla de manera exhaustiva el proceso de ingeniería de software, arquitectura de red, integración de hardware y diseño de interfaces que conforman el 80% funcional y estructural del proyecto Mèltic GMAO.

## CAPÍTULO 2. OBJETIVOS DEL PROYECTO
### 2.1 Objetivo General
Desarrollar e implantar un sistema de Gestión de Mantenimiento Asistido por Ordenador (GMAO) integrado con telemetría IoT, capaz de monitorizar parámetros críticos de maquinaria industrial en tiempo real, gestionar el ciclo de vida de las Órdenes de Trabajo (OT) y garantizar la trazabilidad de las intervenciones mediante validación presencial (RFID) y certificación documental (PDF).

### 2.2 Objetivos Específicos
*   **Diseño de Arquitectura**: Diseñar una arquitectura híbrida y segmentada, separando la red de operaciones (OT) de la red de tecnologías de la información (IT) para maximizar la seguridad.
*   **Persistencia de Alto Rendimiento**: Implementar un modelo de "Polyglot Persistence", utilizando MySQL para la integridad relacional de los procesos de negocio y MongoDB para el almacenamiento masivo (Big Data) de las series temporales generadas por los sensores.
*   **Monitorización IoT**: Programar un PLC industrial (Controllino/Arduino) capaz de leer sensores mecánicos y eléctricos (vibración, presión, temperatura, intensidad) y transmitirlos mediante HTTP Polling evitando colisiones TCP/IP.
*   **Desarrollo Backend**: Construir una API RESTful segura en Spring Boot implementando capas lógicas diferenciadas (Controladores, Servicios, Repositorios) y protegida mediante JSON Web Tokens (JWT).
*   **Desarrollo Frontend Móvil**: Crear una aplicación en Flutter con estado reactivo, gráficos interactivos de telemetría y capacidades offline-first para técnicos en planta.
*   **Seguridad Biométrica**: Integrar un lector RFID en el hardware para asegurar que el cambio de estado de las máquinas y el cierre de las intervenciones se realiza "in situ".
*   **Generación de Evidencias**: Desarrollar un módulo de generación dinámica de PDFs inviolables que incluyan fotografías del daño, lista de verificación y firmas trazadas digitalmente.

## CAPÍTULO 3. JUSTIFICACIÓN Y ESTADO DEL ARTE
El mantenimiento reactivo (reparar al romper) genera las mayores pérdidas de la industria logística y manufacturera. Cuando una cinta transportadora falla repentinamente, toda la cadena logística se detiene. El mantenimiento preventivo clásico alivia esto, pero sigue siendo ineficiente al cambiar piezas que aún tienen vida útil solo porque "toca revisión".

La gran justificación de Mèltic GMAO es facilitar la transición al **Mantenimiento Predictivo**. Al proveer telemetría constante (Gemelo Digital), el jefe de planta puede observar que el motor #4 está consumiendo más amperaje de lo normal y su vibración axial está aumentando. Esto indica desgaste de rodamientos de forma predictiva. La intervención se planifica para el fin de semana, evitando detener la producción.

A nivel tecnológico, el proyecto justifica las competencias adquiridas en el ciclo formativo al exigir una integración full-stack compleja, saltando la barrera del software puramente lógico para internarse en el control de hardware físico.

## CAPÍTULO 4. METODOLOGÍA Y PLANIFICACIÓN
Se ha seguido un modelo de desarrollo ágil basado en **Scrum** adaptado a un solo desarrollador, dividiendo el trabajo en Sprints bisemanales.

1.  **Fase de Toma de Requisitos (Sprints 1-2)**: Entrevistas simuladas con jefes de planta, definición de Casos de Uso y creación de diagramas de dominio.
2.  **Fase Arquitectónica (Sprints 3-4)**: Diseño del modelo Entidad-Relación en MySQL y estructuración de documentos BSON para MongoDB. Setup de redes y VLANs simuladas.
3.  **Fase Backend & Hardware (Sprints 5-8)**: Configuración del microcontrolador C++ (Controllino) e implementación del servidor Spring Boot. Pruebas conjuntas de estruendo de red.
4.  **Fase Frontend (Sprints 9-12)**: Desarrollo UI/UX en Flutter, gestión del estado de la app mediante Providers o GetX, integración de gráficas y PDFs.

*(Nota: En el documento de Word, aquí se recomienda insertar el Diagrama de Gantt y la tabla de horas trabajadas)*

## CAPÍTULO 5. ANÁLISIS DE REQUISITOS DEL SISTEMA
### 5.1 Requisitos Funcionales (RF)
*   **RF01 (Gestión de Usuarios)**: El sistema debe permitir operaciones CRUD sobre los operadores y jefes de planta, asignando perfiles de permisos estibados (Admin, Operario).
*   **RF02 (Gestión de Activos)**: Catálogo de la maquinaria existente, incluyendo sus especificaciones técnicas y el identificador de conexión lógica al PLC.
*   **RF03 (Telemetría)**: Captura a 15 segundos de: Temp. Ambiente, Humedad, RPM, Presión, Vibración, Consumo y Voltaje.
*   **RF04 (Gestión de OTs)**: Todo trabajo de mantenimiento debe registrarse como Orden de Trabajo con estados: PENDIENTE, EN_PROCESO, CERRADA.
*   **RF05 (Generación Reporte)**: Cierre de OT genera PDF adjuntando fotos y firma.

### 5.2 Requisitos No Funcionales (RNF)
*   **RNF01 (Seguridad)**: Toda petición HTTP a excepción del /login debe llevar cabecera de Autorización Bearer Token válida.
*   **RNF02 (Resiliencia IoT)**: En caso de desconexión del PLC, el sistema no debe bloquearse (timeout controlado) y el Frontend debe instanciar un modo de simulación "Failsafe" para mantener la experiencia UX.
*   **RNF03 (Escalabilidad)**: La telemetría no debe interceder con el motor transaccional SQL; se exige aislamiento físico y lógico mediante MongoDB.

### 5.3 Casos de Uso Críticos
*(Nota: Añadir aquí los Diagramas de Casos de uso e integrar el contenido de la tabla XLS)*
Destaca el **CU-06: Visualización Avanzada del Gemelo Digital**, donde el jefe de mantenimiento consulta el buffer de los últimos 200 registros de los sensores, aplicando conversores matemáticos de unidad en tiempo real en la UI móvil. El **CU-04: Cierre con Evidencia** obliga al operario presencialidad mediante tecnología NFC y captura de evidencia fotográfica legal del daño.

## CAPÍTULO 6. DISEÑO DE ARQUITECTURA E INFRAESTRUCTURA
El ecosistema no se despliega en una máquina genérica, sino que imita una planta industrial:

*   **Segmentación VLAN**: 
    *   **VLAN 10 (OT - Operations Technology)**: Subred crítica cableada donde reside el PLC (192.168.1.11) y los sensores analógicos de 24V. Solo emite tráfico IoT.
    *   **VLAN 20 (IT - Information Technology)**: Red del servidor (192.168.1.50) e infraestructura inalámbrica WPA2-Enterprise para las tablets de los operadores.
*   **Persistencia Políglota**:
    *   **Base de Datos Relacional (MySQL)**: Garantiza transacciones ACID para OTs, evitando que un fallo del servidor corrompa el historial legal de reparaciones.
    *   **Base de Datos Documental (MongoDB)**: Soporta ráfagas masivas de lectura/escritura (BSON) procedentes de los sensores.

*(Nota: Tienes que insertar la imagen generada sobre la "Arquitectura de red detallada" y "Diagrama Entidad-Relación")*

## CAPÍTULO 7. DESARROLLO: MÓDULO IoT (HARDWARE)
El núcleo captador es un PLC **Controllino** (basado en arquitectura Arduino MEGA).
*   **Lectura Analógica/Digital**: Se sondean las entradas integradas del PLC que captan la variación de 0-10V o 4-20mA de transductores industriales reales de precisión.
*   **Autenticación NFC/RFID**: Conectado por protocolo SPI/I2C. Al acercar el tag de empleado, se extrae el UID único. 
*   **Gestión del Ruido Magnético (Debouncing)**: En un entorno de alto voltaje existen interferencias que el hardware lee como "micro toques" del RFID. Se ha desarrollado por código un "Debounce", exigiendo que un estado cambie sustancialmente y permanezca durante `X` ciclos antes de validarse, evitando que el Backend colapse por repeticiones de login.

## CAPÍTULO 8. DESARROLLO: SISTEMA CENTRAL (BACKEND SPRING BOOT)
El núcleo de Mèltic GMAO se desarrolla con Spring Boot 3 y Java 21, siguiendo un patrón Modelo-Vista-Controlador estricto para APIs.

### 8.1 Seguridad Perimetral y JWT
Se implementó `Spring Security`. Cuando un usuario se autentica correctamente (o desliza su RFID por el lector y es validado en MySQL), el AuthenticationManager expide un **Token JWT** firmado mediante algoritmo HMAC256. La aplicación móvil inyecta este JWT en las cabeceras HTTP de futuras peticiones, validando rol y permisos de forma apátrida (Stateless).

### 8.2 Ingestión de Datos y Poller Service
El `PLCPollingService.java` ejecuta peticiones de bajo nivel hacia el Controllino limitando la cadencia a 15000ms. Si recibe los datos satisfactoriamente:
1. Deserializa el JSON bruto del PLC.
2. Cruza los valores térmicos/mecánicos con el objeto `MetricConfig` ajustado por el jefe de planta.
3. Si un valor supera el umbral "Muy Alto", despacha una notificación de alerta asíncrona.
4. Genera el documento BSON y lo persiste en Mongo mediante `TelemetriaRepository`.

### 8.3 Documentación Automática
El backend integra `springdoc-openapi` exponiendo en la ruta `/swagger-ui.html` un contrato estricto interoperable de la API permitiendo testeo sin Postman de forma visual.

*(Nota: Adjuntar pantallazo del Swagger UI y fragmentos de código del "Anexo de Código Técnico")*

## CAPÍTULO 9. DESARROLLO: CLIENTE MÓVIL (FLUTTER)
La toma de decisiones de la interfaz está guiada por la filosofía **Industrial Design**: contrastes altos, operabilidad con un solo dedo (o con guantes), y evitar menús anidados.

### 9.1 Estructura del Estado
Se hace uso del proveedor de estado y dependencias. Al arrancar `main.dart`, se instancian `UsuarioService`, `TelemetriaService` y `OrdenTrabajoService`. 
Las URLs no están 'quemadas' en el código; la clase `ApiConfig` detecta automáticamente si se ejecuta en Windows o Android, inyectando la IP estática correspondiente de la red IT.

### 9.2 El Gemelo Digital (Industrial Chart)
La "Estación de Análisis" de Flutter es la funcionalidad del 80% más puntera visualmente.
*   Se carga el perfil y configs del activo.
*   El `Timer` arranca y solicita por GET los últimos 200 puntos.
*   El `TelemetriaService` detecta la cabecera `Date` del servidor y aplica el **Drift Correction**, alineando milisegundos entre el teléfono y el servidor de forma que el motor de pintado (charts) deslice las gráficas sin "saltos fantasma".

### 9.3 Paperless: Generación Oficial de Reportes
El `pdf_generator.dart` revoluciona el cierre de las OTs. La clase construye en memoria el layout A4:
*   Incrusta el logotipo de Mèltic.
*   Recorre el listado de fallos.
*   Toma los *bytes* nativos procedentes de la cámara (foto de la pieza rota) convertidos previamente.
*   Capta a pantalla completa el trazado manual (Widget de Firma) y lo vectoriza directamente sobre el pie de página del documento.
*   El PDF se envía en base64 al servidor o se guarda localmente en almacenamiento privado para inspecciones legales.

## CAPÍTULO 10. PRUEBAS DE RESILIENCIA Y VERIFICACIÓN
El entorno industrial no perdona fallos informáticos; las pruebas realizadas corroboran su fiabilidad:

1.  **Tests de Desconexión Física**: Se apagó forzosamente el PLC durante el Polling. El hilo HTTP capturó y resolvió la excepción `ConnectTimeoutException`, desencadenando la activación del Motor de Simulación en el móvil, garantizando que la App no hiciese *Crash*.
2.  **Validación de OTs (verify_ot_flow.py)**: Se programó un pequeño script en Python que auditó las bases SQL verificando restricciones de llaves foráneas y asegurando que no era posible crear una OT para una máquina en estado de "Baja".

## CONCLUSIÓN PRELIMINAR (AL 80%)
El desarrollo actual del trabajo confirma que la barrera entre las Tecnologías de la Información (oficinas) y las Tecnologías de Operación (planta) se ha diluido con éxito. Mèltic GMAO es plenamente funcional en su núcleo duro: la comunicación bi-direccional IoT fluye sin fugas de memoria, las persistencias en las bases de datos resuelven las colisiones de cardinalidad correctamente y la gestión documental mediante Flutter PDF marca una evolución clara frente al mantenimiento estándar.

Los siguientes hitos para concluir tratarán las opciones de distribución del ejecutable, pruebas exhaustivas en hardware físico de diferentes fabricantes de tabletas y la puesta a punto de los manuales de usuario.
