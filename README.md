# Mèltic GMAO — Industrial 4.0 Management System

Mèltic GMAO es una solución de Gestión de Mantenimiento Asistido por Ordenador (GMAO) diseñada para entornos de **Industria 4.0**. Combina la gestión tradicional de activos y mantenimiento preventivo con integración en tiempo real de telemetría industrial mediante PLCs.

Desarrollado como **Trabajo de Fin de Grado Superior (TFGS)** por Santiago Moratalla — DAM2 2025/26.

---

## Características principales

- **Dashboard Industrial 4.0**: Panel de control con KPIs en tiempo real (OEE, MTBF, MTTR) y alarmas activas.
- **Integración PLC en tiempo real**: Comunicación directa con controladores industriales (estados LIVE/SIM/DOWN) y telemetría de campo.
- **Gestión de Órdenes de Trabajo (OT)**: Ciclo de vida completo de mantenimiento correctivo y preventivo con firma digital y generación de reportes PDF.
- **Calendario Preventivo**: Planificación visual de OTs preventivas con vista mensual integrada.
- **Autenticación RFID**: Acceso rápido por tarjeta/lector RFID vinculado a usuarios del sistema.
- **Push Notifications (Firebase)**: Alertas críticas enviadas en tiempo real al dispositivo Android del técnico.
- **Sala de Servidores Virtual**: Visualización técnica del estado de la infraestructura de backend y bases de datos.

---

## Stack tecnológico

### Frontend — Flutter
- Multi-plataforma: Web, Windows y Android.
- Theme engine industrial personalizado (`IndustrialTheme`).

### Backend — Java Spring Boot
- RBAC (Operario / Técnico / Jefe de Mantenimiento).
- **MySQL**: Persistencia relacional (activos, usuarios, órdenes de trabajo).
- **MongoDB**: Logs de telemetría e histórico de sensores.
- Historian Service: buffer circular de alta eficiencia para tendencias en tiempo real.

### Infraestructura
- **Docker & Docker Compose**: Orquestación de todos los servicios.
- **Nginx**: Servidor web de producción y proxy inverso.
- Compatible con Controllino (PLC) y lectores RFID.

---

## Instalación y despliegue

### Prerrequisitos
- [Docker Desktop](https://www.docker.com/products/docker-desktop) instalado y en ejecución.
- Python 3.x (solo para los scripts de utilidad).

### Levantar el entorno completo

```bash
docker-compose up -d --build
```

Servicios que se inician automáticamente:

| Servicio | Descripción | Puerto |
|---|---|---|
| `meltic-mysql` | Base de datos relacional | 3307 (interno) |
| `meltic-mongo` | Base de datos NoSQL | 27017 |
| `meltic-backend` | API REST + servicios PLC | http://localhost:8080 |
| `meltic-frontend` | Interfaz web (Nginx) | http://localhost:8081 |

### Credenciales por defecto

| Usuario | Email | Contraseña | Rol |
|---|---|---|---|
| Admin | `admin@meltic.com` | `Meltic@2024!` | ADMIN |
| Jefe | `jefe@meltic.com` | `Jefe@Meltic2024!` | JEFE_MANTENIMIENTO |
| Técnico | `tecnico@meltic.com` | `Tecnico@Meltic2024!` | TECNICO |

---

## Documentación de la API (Swagger)

Una vez el backend esté en ejecución:

- **Swagger UI**: http://localhost:8080/swagger-ui/index.html
- **OpenAPI spec**: http://localhost:8080/v3/api-docs

---

## Scripts de utilidad

Ubicados en `/scripts`. Requieren que el entorno Docker esté activo.

```bash
# Poblar la base de datos con datos industriales de prueba
python scripts/seed_industrial_data.py

# Verificar el estado de la API y conectividad con las bases de datos
python scripts/verify_api.py
```

| Script | Descripción |
|---|---|
| `seed_industrial_data.py` | Genera activos, usuarios y órdenes de trabajo con datos industriales realistas |
| `verify_api.py` | Test de salud de la API y conectividad con base de datos |
| `seed_data.ps1` | Versión PowerShell del seed para entornos Windows |

---

## Documentación del proyecto

| Documento | Descripción |
|---|---|
| `50% memoria Santiago Moratalla.pdf` | Memoria de seguimiento al 50% |
| `TFGS Santiago Moratalla 80%.pdf` | Memoria de seguimiento al 80% |
| `MEMORIA_FINAL_TFGS_Santiago_Moratalla.pdf` | Memoria final entregada |
