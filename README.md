# Mèltic GMAO — Industrial 4.0 Management System

Mèltic GMAO es una solución avanzada de Gestión de Mantenimiento Asistido por Ordenador (GMAO) diseñada específicamente para entornos de **Industria 4.0**. El sistema combina la gestión tradicional de activos y mantenimiento preventivo con la integración en tiempo real de telemetría industrial mediante PLCs.

## 🚀 Características Principales

*   **Dashboard Industrial 4.0**: Panel de control con diseño premium "Space Cadet" optimizado para la monitorización de activos críticos, KPIs en tiempo real (OEE, MTBF, MTTR) y alarmas activas.
*   **Integración PLC en Tiempo Real**: Comunicación directa con controladores industriales para monitorizar estados operativos (LIVE/SIM/DOWN) y telemetría de campo.
*   **Gestión de Órdenes de Trabajo (OT)**: Ciclo de vida completo de mantenimiento (Correctivo y Preventivo) con firma digital y generación de reportes PDF.
*   **Calendario Preventivo**: Planificación visual de OTs preventivas con vista mensual integrada.
*   **Autenticación RFID**: Acceso rápido por tarjeta/lector RFID vinculado a usuarios del sistema.
*   **Push Notifications (Firebase)**: Alertas críticas enviadas en tiempo real al dispositivo Android del técnico.
*   **Sala de Servidores Virtual**: Visualización técnica del estado de la infraestructura de backend y bases de datos.
*   **Arquitectura Escalable**: Despliegue mediante contenedores Docker para asegurar la portabilidad y robustez en entornos de producción.

## 🏗️ Stack Tecnológico

### Frontend (Flutter)
*   **Multi-plataforma**: Web, Windows y Android.
*   **Theme Engine**: Sistema de temas "Industrial 4.0" (IndustrialTheme) personalizado.
*   **Animaciones**: Integración fluida con `flutter_animate`.

### Backend (Java Spring Boot)
*   **Seguridad**: RBAC (Role-Based Access Control) para Operarios, Técnicos y Jefes de Mantenimiento.
*   **Bases de Datos**:
    *   **MySQL**: Persistencia relacional para activos, usuarios y órdenes de trabajo.
    *   **MongoDB**: Logs de telemetría e histórico de sensores.
    *   **Historian Service**: Buffer circular de alta eficiencia para tendencias en tiempo real.

### Infraestructura
*   **Docker & Docker Compose**: Orquestación de servicios.
*   **Nginx**: Servidor web de producción y proxy inverso.
*   **Hardware compatible**: Integración optimizada para controladores Controllino (PLC) y lectores RFID.

## 📦 Instalación y Despliegue

### Prerrequisitos
*   [Docker Desktop](https://www.docker.com/products/docker-desktop) instalado y en ejecución.

### Pasos para iniciar el entorno completo
Desde la raíz del proyecto, ejecuta:

```bash
docker-compose up -d --build
```

Esto levantará automáticamente:
1.  **meltic-mysql**: Base de datos SQL (puerto interno 3307).
2.  **meltic-mongo**: Base de datos NoSQL (puerto 27017).
3.  **meltic-backend**: API REST y servicios PLC → `http://localhost:8080`
4.  **meltic-frontend**: Interfaz web (Nginx) → `http://localhost:8081`

### Credenciales por defecto

| Usuario | Email | Contraseña | Rol |
|---|---|---|---|
| Admin | `admin@meltic.com` | `Meltic@2024!` | ADMIN |
| Jefe | `jefe@meltic.com` | `Jefe@Meltic2024!` | JEFE_MANTENIMIENTO |
| Técnico | `tecnico@meltic.com` | `Tecnico@Meltic2024!` | TECNICO |

## 🔌 Documentación de la API (Swagger)

El backend está totalmente documentado con **OpenAPI 3 / Swagger**. Una vez en ejecución:

*   **Swagger UI**: [http://localhost:8080/swagger-ui/index.html](http://localhost:8080/swagger-ui/index.html)
*   **Definición OpenAPI**: [http://localhost:8080/v3/api-docs](http://localhost:8080/v3/api-docs)

## 📊 Scripts de Utilidad

Incluidos en la carpeta `/scripts` para pruebas y validación:

```bash
# Poblar la base de datos con datos industriales de prueba
python scripts/seed_industrial_data.py

# Verificar el estado de la API y conectividad con las bases de datos
python scripts/verify_api.py
```

*   `seed_industrial_data.py`: Genera activos, usuarios y órdenes de trabajo realistas.
*   `verify_api.py`: Test de salud de la API y conectividad con base de datos.
*   `seed_data.ps1`: Versión PowerShell del seed para entornos Windows.

---
**Mèltic GMAO** — *Desarrollado como Proyecto Final de Grado (TFG) por Santiago Moratalla.*
