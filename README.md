<p align="center">
  <img src="Diagramas/Arquitectura.png" alt="Mèltic GMAO" width="200" />
</p>

# 🏭 Mèltic GMAO: Mantenimiento Industrial IoT (Industria 4.0)

> **Trabajo de Fin de Grado (DAM / SMR)**
>
> Sistema de Gestión de Mantenimiento Asistido por Ordenador (GMAO) integrado con telemetría en tiempo real y Gemelo Digital mediante hardware industrial.

---

## 📖 Descripción del Proyecto

**Mèltic GMAO** nace para resolver el problema del mantenimiento reactivo ineficiente y la gestión documental arcaica en la logística e industria manufacturera. 

La plataforma une dos mundos tradicionalmente separados: **Las Tecnologías de Operación (OT)** en planta baja, y las **Tecnologías de la Información (IT)** corporativas. A través de un PLC Industrial, el ecosistema captura hasta 15 variables críticas de telemetría (temperatura, presión, vibración axial, intensidad de fase) y sincroniza datos reales hacia una aplicación reactiva en manos del técnico u operario.

### 🌟 Funcionalidades Principales
*   **📡 Telemetría en Tiempo Real (Digital Twin):** Visualización interactiva de gráficas mediante ingesta masiva (Buffer de 200 registros a 15s) con corrección de latencia (Drift Correction).
*   **🔐 Autenticación IoT Biométrica:** Lectores RFID en máquina operan por interrupción. Los operarios fichan su intervención simplemente acercando su tarjeta física al hardware.
*   **📑 Paperless Industrial (Zero-Impact):** Cierre de Órdenes de Trabajo desde el móvil firmando manualmente en pantalla (Vector Rendering) y tomando capturas con la cámara. El sistema auto-genera un documento probatorio técnico en formato PDF oficial inviolable.
*   **⚙️ Failsafe & Debouncing Integrado:** El software filtra ruidos electromagnéticos del hardware físico implementando un buffer de seguridad para preservar los datos analógicos reales.

---

## 🛠️ Arquitectura Tecnológica & Stack

El sistema posee una topología de red aislada en dos VLANs y aplica **Persistencia Políglota** (*Polyglot Persistence*) según la demanda de los datos procesados.

### 🔌 1. Capa de Adquisición (Hardware / IoT)
*   **Microcontrolador:** PLC Industrial **Controllino** (Plataforma C++ Arduino Mega 2560).
*   **Interacciones:** Sensores de simulación multivariable (Temperatura, RPM, Caudal), Lector RFID RC522 protocolo SPI.
*   **Comunicaciones:** Red Industrial Activa emitiendo payload HTTP Polling.

### 🧠 2. Capa de Lógica y Microservicios (Backend)
*   **Framework Core:** Java **Spring Boot 3** bajo persistencia de JPA/Hibernate.
*   **Seguridad y Sesión:** Tokens auto-firmados Stateless **(JWT)**. Integración dual con RFID.
*   **Documentación de Contrato:** API RESTful trazada permanentemente mediante Swagger UI / OpenAPI 2.0.

### 💾 3. Capa de Persistencia Políglota
*   **MySQL (SQL Transactional):** Responsable estricto de la coherencia ACID para la lógica de Usuarios, Entidades de Activos y control de estados (Órdenes de Trabajo).
*   **MongoDB (NoSQL Time-Series):** Repositorio asíncrono para ingesta del Big Data de telemetría. Almacena objetos BSON brutos permitiendo escalabilidad en series de métricas sin entorpecer a la pasarela SQL de negocio.

### 📱 4. Capa Cliente (Frontend Mobile)
*   **Tecnología Central:** **Flutter Framework** asíncrono multiplataforma (Dart).
*   **Requerimientos Operativos:** Diseño de Alto Contraste (Industrial Readability), `pdf_generator` interno.

---

## 🚀 Despliegue Local Rápido

### Prerrequisitos
- JDK 21+ instalado de forma local o contenedor
- MySQL 8.x en el puerto `3306` (credenciales por defecto en `application.properties`: `root`/`root`)
- MongoDB corriendo de forma local en puerto `27017`
- SDK de Flutter.

### Instrucciones

1. **Clonar e Iniciar Backend:**
   Navegar al subdirectorio `Backend` y arrancar el servidor embebido.
   ```bash
   cd Backend
   ./mvnw spring-boot:run
   ```
   *El servidor inicializará las tablas en local y se pondrá a la escucha en el puerto `:8080`.*
   *Interfaz Swagger de debug: `http://localhost:8080/swagger-ui.html`*

2. **Capa Cliente:**
   En una terminal diferente, levantar el Frontend (Flutter App).
   ```bash
   cd Frontend/meltic_gmao_app
   flutter pub get
   flutter run -d chrome  # (o seleccionar el simulador móvil deseado)
   ```

---

## 📈 Trazabilidad Académica

El 100% de la arquitectura mostrada corresponde íntegramente a las demandas, metodologías e investigaciones llevadas a término para su presentación y defensa como **Trabajo Fi de Grau / Proyecto Final**. Todo el código ha sido refactorizado, filtrado y optimizado de cara al pase a grado de ingeniería de los perfiles DAM y SMR.

> **Autor:** Santiago Moratalla  
> **Fecha Presentación:** *Primavera 2026*  
> **Licencia:** Material Registrado para uso exclusivamente académico y demostrativo.
