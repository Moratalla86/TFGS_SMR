# MEMORIA TÉCNICA DEL PROYECTO: MÈLTIC GMAO
**Sistema Integral de Gestión de Mantenimiento Asistido por Ordenador bajo el paradigma de la Industria 4.0**

---

## CAPÍTULO I: INTRODUCCIÓN Y OBJETIVOS

### 1.1. Abstract (EN)
The transition towards Industry 4.0 demands robust, scalable, and highly interoperable software ecosystems capable of bridging the gap between Field-Level hardware (PLCs, sensors) and Enterprise-Level management interfaces (ERP/CMMS). Mèltic GMAO represents a holistic approach to Computerized Maintenance Management Systems (CMMS), combining traditional asset and work order management with real-time telemetry processing. By leveraging a microservices-oriented backend architecture built on Java Spring Boot, a hybrid database persistence layer (MySQL for relational data, MongoDB for time-series telemetry), and a cross-platform frontend engineered with Flutter, the system delivers a comprehensive Digital Twin experience. A critical differentiator is the implementation of a high-performance Historian Service utilizing circular buffers, alongside an autonomous hardware authentication node via RFID technology and Controllino Mega microcontrollers. The result is a highly secure, Role-Based Access Control (RBAC) governed environment that minimizes Mean Time To Repair (MTTR) while maximizing Overall Equipment Effectiveness (OEE).

### 1.2. Resumen (ES)
La transición hacia la Industria 4.0 exige ecosistemas de software robustos, escalables y altamente interoperables capaces de cerrar la brecha entre el hardware de campo (sensores, autómatas) y las interfaces de gestión corporativa. Mèltic GMAO representa un enfoque holístico para los Sistemas de Gestión de Mantenimiento Asistido por Ordenador (GMAO), combinando la gestión tradicional de activos y órdenes de trabajo (OT) con el procesamiento de telemetría en tiempo real. Apoyándose en una arquitectura orientada a servicios construida sobre Java Spring Boot, una capa de persistencia híbrida (MySQL para datos transaccionales, MongoDB para series temporales) y un cliente multiplataforma desarrollado en Flutter, el sistema ofrece una experiencia de Gemelo Digital integral. Un factor diferenciador crítico es la implementación de un Servicio Historiador de alto rendimiento mediante buffers circulares y SplayTreeMaps, junto a un nodo de autenticación hardware autónomo a través de tecnología RFID y microcontroladores Controllino Mega industrializados. El resultado es un entorno altamente seguro, gobernado por Control de Acceso Basado en Roles (RBAC), diseñado para minimizar el Tiempo Medio de Reparación (MTTR) y maximizar la Eficiencia General de los Equipos (OEE).

> *TUTOR TIP - PARA LA DEFENSA:* Durante la exposición del Abstract/Resumen, no leas la diapositiva. Capta la atención del tribunal exponiendo directamente el problema del sector ("hoy en día, las fábricas pierden millones por paradas imprevistas") y luego presenta a Mèltic GMAO como el "puente" entre la maquinaria física y la toma de decisiones gerencial.

### 1.3. Justificación Tecnológica e Industrial
La gestión del mantenimiento industrial ha padecido históricamente de un desajuste tecnológico provocado por el aislamiento entre los sistemas de Tecnología de la Información (IT) y la Tecnología de Operaciones (OT). Los sistemas GMAO tradicionales operan bajo un paradigma reactivo o, en el mejor de los casos, preventivo basado en calendarios estáticos, ignorando la condición real del activo (Mantenimiento Basado en Condición o CBM). 

La principal justificación para la creación de Mèltic GMAO radica en la necesidad de democratizar el acceso al mantenimiento predictivo e inteligente. Al pasar del papel y los calendarios rígidos de Excel a un sistema digital integrado, se logra la hiperconectividad. La elección tecnológica no es casual:
*   **Por qué Java / Spring Boot en el Backend:** La fiabilidad en entornos industriales es innegociable. Spring Boot proporciona un marco de inyección de dependencias robusto, multithreading eficiente para procesos de "polling" continuo de múltiples PLCs (a través del `PLCPollingService`), y una integración nativa de seguridad multicapa (Spring Security con JWT). Alternativas como Node.js/Express podrían sufrir cuellos de botella bajo carga de CPU intensiva al procesar telemetría de cientos de sensores, debido a su naturaleza mono-hilo (Single-threaded event loop).
*   **Por qué Base de Datos Híbrida (MySQL + MongoDB):** La persistencia en Industria 4.0 tiene naturaleza dual. Las credenciales de usuarios, perfiles RBAC, y el ciclo de vida de una Orden de Trabajo requieren garantías ACID absolutas, justificando el motor relacional de MySQL (InnoDB). Sin embargo, un PLC escupiendo datos de temperatura, presión y vibración cada 200 ms generaría graves bloqueos de escritura (locks) en un modelo SQL. Por ello, delegamos la telemetría masiva y de series temporales (Time-Series) a MongoDB, una base de datos documental que absorbe picos de inserción (Write-heavy workloads) con extrema solvencia.
*   **Por qué Flutter en el Frontend:** En la planta de producción convergen diversos perfiles operativos. El Jefe de Planta utiliza un monitor Desktop Windows; el operario de máquina interactúa con un panel táctil (HMI/Web); y el Técnico SAT (Servicio Asistencia Técnica) requiere movilidad total en un smartphone Android. Construir tres bases de código nativas (WPF, React Web, Kotlin) sería ineficiente y propenso a inconsistencias. Flutter y su motor de renderizado Skia/CanvasKit permiten ofrecer una única base de código en lenguaje Dart que compila a binarios nativos para ARM/x64, asegurando mantener la consistencia de la identidad corporativa "Space Cadet" a 60/120 FPS sin los típicos retardos del DOM web.

---

## CAPÍTULO II: ANÁLISIS Y ESPECIFICACIÓN (Nomenclatura RFTP)

Para trazar la calidad del software desde su concepción académica hasta su despliegue Dockerizado, se define la Matriz de Trazabilidad RFTP (Requisito, Función, Tarea, Prueba).

| ID | REQUISITO | FUNCIÓN TÉCNICA (Backend/Frontend) | TAREA / IMPLEMENTACIÓN DE CÓDIGO | PRUEBA DE VALIDACIÓN |
| :--- | :--- | :--- | :--- | :--- |
| **RFTP-01** | Segregación de roles de usuario | Implementación de RBAC con filtrado por rol y JWT Stateless. | Desarrollo de `JwtAuthenticationFilter` en Spring Security. Roles: ADMIN, JEFE_MANTENIMIENTO, TECNICO. | Intento de acceso a `/api/usuarios` (CRUD) con token de TÉCNICO. Retorno esperado: Estado `403 Forbidden`. |
| **RFTP-02** | Autenticación física mediante hardware | Interfaz bidireccional Backend-Hardware vía polling o eventos para mapeo UID-Usuario. | Firmware en Controllino Mega. API Endpoint `/api/auth/rfid`. Mecanismo de debouncing en el Polling para evitar colisiones de red. | Deslizar tarjeta MIFARE sobre RC522. Generación automática y retorno de Bearer Token JWT en < 1 segundo. |
| **RFTP-03** | Visualización en vivo sin parpadeos | Gestión de estados en frontend e Historian Service en backend mediante buffers circulares en memoria. | Implementación de `SplayTreeMap` limitando a N muestras por sensor en el backend. En Dart, uso de arquitecturas de componentes limpios sin setState global repetitivo. | Observación visual del `DashboardScreen`. Inserción continua artificial a 10 Hz. Renderizado suave, 0 parpadeos, métrica de 60fps estable en DevTools. |
| **RFTP-04** | Alertas operativas "Push" móviles | Integración con servicio cloud escalable y Worker asíncrono para colas. | Implementación del Módulo Firebase Cloud Messaging (FCM). Empleo de `flutter_local_notifications` y librería Desugaring en Gradle. | Simulación de rotura (DOWN) mediante `seed_industrial_data.py`. Recepción inmediata de notificación push "Alerta Crítica" en dispositivo físico Android. |
| **RFTP-05** | Trazabilidad documental inmutable | Firma digital y generación de PDF estandarizados con base64 integrados. | Endpoint de cierre de OT con payload de `Base64 String` para la firma. Librería `pdf` y `printing` en Flutter para exportación visual. | Aprobación en app móvil con trazado táctil; generación transparente de fichero bytes de PDF y verificación de la validación checksum del estado. |
| **RFTP-06** | Rendimiento y despliegue agnóstico | Empaquetado del backend, BBDD y proxies en arquitecturas de contenedores aislados de Sistema Operativo. | Redacción de `docker-compose.yml`. Configuración de reglas `nginx.conf` como Reverse Proxy (Puerto 8081). | Ejecución del comando `docker-compose up -d --build` en Windows bare-metal. Sistema al 100% operativo sin dependencias externas preinstaladas. |

> *TUTOR TIP - PARA LA DEFENSA:* Cuando menciones la matriz RFTP, no te detengas a explicar todas las filas. Escoge el *RFTP-03 (Historian)* y el *RFTP-02 (RFID)* como casos de éxito. Destaca cómo gracias al SplayTreeMap en Java salvaste el rendimiento de la aplicación al evitar saturar la base de datos de disco en el renderizado en tiempo real.

---

## CAPÍTULO III: DISEÑO DE INTERFACES Y EXPERIENCIA DE USUARIO (UX/UI)

La estética y el comportamiento interactivo de un GMAO deben huir de los diseños aburridos "estilo formulario gris" propios del software de los años 2000. Mèltic GMAO adopta un diseño denominado **"Space Cadet - Neo Industrial"**, focalizado en Dark Mode nativo. Esta decisión técnica no persigue únicamente la estética premium; en entornos industriales (cabinas de control semioscuras, tablets de operarios), la reducción de la emisión de luz azul perimetral disminuye drásticamente la fatiga visual tras jornadas de 8 horas observando KPIs fluctuantes.

Se aplicaron principios de Diseño Responsivo y *Fluid Layouts*, eliminando contenedores rígidos (`Container` fijos en Dart) sustituidos por estructuras elásticas (`Expanded`, `Flexible`, `Wrap`) garantizando que los "RenderFlex Overflow" (típicos errores de 0.6 píxeles en Flutter) queden mitigados desde el árbol de compilación geométrico.

### 3.1. Arquitectura Visual de la Aplicación Desktop (Windows/Tablet HMI)

La interfaz de monitorización general está regida por la pantalla principal (`DashboardScreen`), diseñada como un Command Center.

**Componentes Técnicos Principales:**
1.  **Sidebar de Navegación Constante:** Permite cambiar contextualidades sin perder noción de estado, mitigando la carga cognitiva del Jefe de Mantenimiento.
2.  **Grid de Layout Asimétrico (KPIs Principales):** La vista se fracciona priorizando el **OEE Estructurado** (Disponibilidad x Rendimiento x Calidad). Se utilizan indicadores semafóricos (Verde para `OPERATIVE`, Rojo para `CRITICAL DOWN`) procesados directamente en la paleta cromática nativa (`IndustrialTheme.operativeGreen`).
3.  **Gráficos Vectoriales por Canvas (Skia/CanvasKit):** Al monitorizar curvas de telemetría (temperaturas > 120°C, vibraciones motoras), las métricas se deben repintar sin recalcular el árbol de widgets de la aplicación entera. Para ello se aísla el contexto usando CustomPainters o librerías de fl_chart, proveyendo animaciones que "suavizan" el escalamiento del eje Y matemáticamente.

![Mockup - Interfaz del Tablero Principal (Dashboard)](/C:/Users/Santi/.gemini/antigravity/brain/47b45b69-8c34-4f62-8e73-5ca55ce30797/existing_dashboard_page_1776436330426.png)
*Figura 1. Interfaz del Command Center. Obsérvese la jerarquía de tipografías condensadas (Outfit/Inter) y el fondo de absorción lumínica profunda (Space Cadet).*

### 3.2. Experiencia de Usuario Móvil (Android Técnico SAT)

El contexto de uso del técnico es drásticamente distinto al del Jefe de Planta. El operario interactúa con la aplicación en movimiento, equipado posiblemente con EPIS (Equipos de Protección Individual) como guantes, y en zonas con conectividad 4G oscilante.

**Estrategia UX para Android:**
*   **Botoneras Sobredimensionadas:** Eliminación de enlaces y de textos minúsculos asumiendo la "Fat Finger Zone". Todo CTA (Call to Action) cuenta con un padding de impacto grande en diseño.
*   **Contraste Alto y Transiciones de Estado Evidentes:** Si existe una alarma, el panel no se actualiza tímidamente; utiliza animaciones `flutter_animate` de destello para romper ceguera por desatención (Inattentional blindness).
*   **Captura de Firmas Nativas:** El módulo de Gestión de Órdenes integra un lienzo digital escalado donde la firma matemática no sufre "clipping" o recortes espaciales, generando el buffer PNG directamente hacia el sistema documental.

### 3.3. Logotipo y Branding Transparente de la Entidad Mèltic

La identidad de la marca está implementada como un asset rasterizado digital (PNG true-transparency) eliminando esquinas o fondos sólidos. El isotipo actúa simbióticamente con el fondo general del Scaffold tanto en la pantalla de "Login" como en los reportes auto-generados.

![Visualización de la pantalla de autenticación y carga segura](file:///C:/Users/Santi/.gemini/antigravity/brain/47b45b69-8c34-4f62-8e73-5ca55ce30797/login_page_verify_1776455592828.png)
*Figura 2. Pantalla de Autenticación, donde se materializa la integración de software biométrico / analógico (RFID) permitiendo Bypass de contraseñas si el autómata subyacente envía la señal Wiegand al Backend REST de Spring Boot.*

> *TUTOR TIP - PARA LA DEFENSA:* Durante la defensa de estos capítulos, si el tribunal te pregunta "Por qué Flutter y no React o una PWA de navegador", tu argumento debe ser contundente: "El rendimiento del hardware. La app debe dibujar gráficos de señales de máquinas y gestionar notificaciones push en segundo plano de redondear sin asfixiar la RAM del móvil del operario ni el TCO de la empresa, lo cual logré compilando con C++ y CanvasKit para escritorio mediante Dart."

---
*(Fin del Bloque 1 - Esperando su confirmación para generar Bloque 2: Capítulos IV, V, VI y diagramas Mermaid).*
