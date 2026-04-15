# Revisión de Código — TFG GMAO Meltic 4.0 (SMR)

**Fecha de revisión:** 2026-04-15  
**Profundidad:** Deep (análisis completo backend + frontend + infraestructura)  
**Archivos revisados:** 49  
**Estado general:** Issues encontrados

---

## Resumen Ejecutivo

El proyecto demuestra un nivel técnico muy sólido para un TFG de grado SMR. La arquitectura general es correcta (Spring Boot + MongoDB/MySQL dual, Flutter Web/Android, Docker Compose), el sistema RBAC está implementado, y hay funcionalidades avanzadas como telemetría SCADA en tiempo real, generación de PDF con firmas digitales, y autenticación RFID. Eso es mucho trabajo bien estructurado.

Sin embargo, se han detectado **3 problemas CRÍTICOS de seguridad** y **9 problemas HIGH** que afectarían seriamente a la aplicación en producción. Se describen a continuación con correcciones concretas.

---

## Problemas CRÍTICOS

### CR-01: Credenciales de base de datos hardcodeadas en docker-compose y application.properties

**Archivos:**
- `docker-compose.yml` líneas 6, 47
- `Backend/src/main/resources/application.properties` líneas 12-13

**Problema:**  
Las contraseñas de MySQL (`root`/`root`) están en texto plano en archivos versionados. Cualquier persona con acceso al repositorio obtiene acceso completo a las bases de datos. El usuario de base de datos es `root`, lo que da privilegios máximos.

**Corrección:**

En `docker-compose.yml` usar variables de entorno sin valor por defecto inseguro:
```yaml
environment:
  MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
  MYSQL_DATABASE: meltic_gmao
  MYSQL_USER: ${MYSQL_USER}
  MYSQL_PASSWORD: ${MYSQL_PASSWORD}
```

Crear un fichero `.env` (NO commitear) con las contraseñas reales. Añadir `.env` al `.gitignore`. Crear `.env.example` con valores de ejemplo vacíos para documentación.

En `application.properties`, el patrón de variable de entorno ya existe pero el fallback es `root`:
```properties
# ACTUAL (inseguro):
spring.datasource.password=${MYSQL_PASSWORD:root}

# CORRECTO (sin fallback inseguro):
spring.datasource.password=${MYSQL_PASSWORD}
```

---

### CR-02: El endpoint /api/plc/** está completamente desprotegido — permite inyección de telemetría sin autenticación

**Archivo:** `Backend/src/main/java/com/meltic/gmao/config/SecurityConfig.java` línea 33

**Problema:**  
```java
.requestMatchers("/api/plc/**").permitAll()
```
Esto permite que cualquier cliente externo sin token envíe datos de telemetría falsos al endpoint `POST /api/plc/data`, lo que puede:
1. Contaminar la base de datos MongoDB con datos fraudulentos.
2. Disparar falsas alarmas y cambiar el estado de las máquinas (ERROR/WARNING).
3. El endpoint `GET /api/plc/simulate/{tag}` permite a cualquier anónimo simular una lectura RFID y potencialmente logar con un usuario conocido si se conoce su tag.

**Corrección:**  
El PLC físico (Controllino) sí necesita enviar datos sin autenticación JWT, pero se puede proteger con una API key fija en cabecera, o al menos restringir por IP. Como mínimo para el TFG:
```java
// Permitir solo el endpoint de datos del PLC con una comprobación de secret header
.requestMatchers(HttpMethod.POST, "/api/plc/data").permitAll()
// El endpoint de simulación NUNCA debería estar en producción sin autenticación
.requestMatchers("/api/plc/simulate/**").hasRole("ADMIN")
// El historial sí necesita auth
.requestMatchers("/api/plc/maquina/**").authenticated()
.requestMatchers("/api/plc/last-rfid").authenticated()
```

---

### CR-03: El token de autenticación se almacena en memoria sin expiración — pérdida de datos en reinicio

**Archivo:** `Backend/src/main/java/com/meltic/gmao/service/TokenService.java` líneas 13-27

**Problema:**  
```java
private final Map<String, Usuario> tokens = new ConcurrentHashMap<>();
```
1. Los tokens no tienen fecha de expiración. Un token válido lo es para siempre hasta reinicio del servidor.
2. Al reiniciar el backend (algo habitual en Docker), **todos los usuarios quedan desconectados** y reciben errores 403 hasta que vuelven a iniciar sesión. En un sistema de planta industrial, esto es inaceptable.
3. Un token robado es válido indefinidamente.
4. La memoria crece sin límite si hay muchos logins (no hay limpieza de tokens antiguos).

**Corrección mínima para TFG:**
```java
@Service
public class TokenService {
    private static final long TOKEN_EXPIRY_HOURS = 8; // Turno de trabajo

    private record TokenEntry(Usuario usuario, Instant expiry) {}
    private final Map<String, TokenEntry> tokens = new ConcurrentHashMap<>();

    public String generateToken(Usuario usuario) {
        String token = UUID.randomUUID().toString();
        tokens.put(token, new TokenEntry(usuario, Instant.now().plus(TOKEN_EXPIRY_HOURS, ChronoUnit.HOURS)));
        return token;
    }

    public Usuario getUsuarioByToken(String token) {
        TokenEntry entry = tokens.get(token);
        if (entry == null) return null;
        if (Instant.now().isAfter(entry.expiry())) {
            tokens.remove(token); // Limpiar token expirado
            return null;
        }
        return entry.usuario();
    }

    // Tarea de limpieza periódica (evita memory leak)
    @Scheduled(fixedRate = 3600000) // cada hora
    public void limpiarTokensExpirados() {
        tokens.entrySet().removeIf(e -> Instant.now().isAfter(e.getValue().expiry()));
    }
}
```
La alternativa correcta en producción sería usar JWT con firma criptográfica, pero para el TFG la solución anterior es suficiente y correcta.

---

## Problemas HIGH

### HI-01: Contraseñas débiles hardcodeadas en DataInitializer (expuestas en logs)

**Archivo:** `Backend/src/main/java/com/meltic/gmao/config/DataInitializer.java` líneas 48-79

**Problema:**  
Las contraseñas de inicialización (`admin`, `jefe`, `tecnico`) son trivialmente adivinables y se imprimen en los logs de la aplicación:
```java
System.out.println("👤 Usuario Admin creado: admin@meltic.com / admin");
```
Esto expone las credenciales en los logs de Docker/Kubernetes. Cualquiera con acceso a los logs puede autenticarse.

**Corrección:**
```java
// 1. Usar contraseñas más fuertes (o mejor, leerlas de variables de entorno)
adminUser.setPassword(encoder.encode(System.getenv().getOrDefault("ADMIN_INITIAL_PASSWORD", "Meltic@2024!")));

// 2. NUNCA imprimir contraseñas en logs
System.out.println("👤 Usuario Admin creado: admin@meltic.com"); // Sin contraseña
```

---

### HI-02: Usuario con `activo=false` puede autenticarse (no se verifica el estado)

**Archivo:** `Backend/src/main/java/com/meltic/gmao/controller/AuthController.java` líneas 44-59

**Problema:**  
El login comprueba email y contraseña, pero no verifica si el usuario está activo (`activo=true`). Un empleado que ha sido bloqueado (`activo=false`) puede seguir iniciando sesión.

```java
// ACTUAL: Solo comprueba contraseña
return usuarioRepo.findByEmail(email)
    .map(user -> {
        boolean matches = encoder.matches(password, user.getPassword());
        if (matches) { // ← No comprueba user.isActivo()
            ...
        }
    })
```

**Corrección:**
```java
.map(user -> {
    if (!user.isActivo()) {
        logger.warn("Login denegado para usuario inactivo: {}", email);
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }
    boolean matches = encoder.matches(password, user.getPassword());
    ...
})
```
Lo mismo aplica al login RFID en la línea 82.

---

### HI-03: La respuesta de login devuelve el objeto completo de Usuario (incluyendo el hash bcrypt de la contraseña)

**Archivo:** `Backend/src/main/java/com/meltic/gmao/controller/AuthController.java` línea 50

**Problema:**  
```java
return ResponseEntity.ok(Map.of("user", user, "token", token));
```
El objeto `user` incluye el campo `password` (el hash bcrypt). Aunque no es la contraseña en texto claro, exponer hashes facilita ataques offline. Además, el RFID tag real del usuario se expone en la respuesta.

**Corrección:**  
Crear un DTO de respuesta que excluya campos sensibles:
```java
// DTO
record UserResponseDto(Long id, String nombre, String apellido1, String email, String rol, boolean activo) {}

// En el controlador
UserResponseDto dto = new UserResponseDto(user.getId(), user.getNombre(), 
    user.getApellido1(), user.getEmail(), user.getRol(), user.isActivo());
return ResponseEntity.ok(Map.of("user", dto, "token", token));
```
Alternativamente, anotar el campo `password` en `Usuario.java` con `@JsonIgnore`.

---

### HI-04: La eliminación de OT no verifica existencia antes de responder 204

**Archivo:** `Backend/src/main/java/com/meltic/gmao/controller/OrdenTrabajoController.java` líneas 154-158

**Problema:**  
```java
@DeleteMapping("/{id}")
public ResponseEntity<Void> eliminar(@PathVariable Long id) {
    mantenimientoService.eliminarOrden(id);
    return ResponseEntity.noContent().build(); // Siempre 204, aunque no existiera
}
```
Siempre devuelve 204 aunque el ID no exista. El frontend no puede distinguir si la OT fue eliminada o si nunca existió. Esto puede enmascarar bugs de sincronización.

**Corrección:**
```java
@DeleteMapping("/{id}")
public ResponseEntity<Void> eliminar(@PathVariable Long id) {
    if (!ordenTrabajoRepository.existsById(id)) {
        return ResponseEntity.notFound().build();
    }
    mantenimientoService.eliminarOrden(id);
    return ResponseEntity.noContent().build();
}
```

---

### HI-05: Potencial NullPointerException en TokenAuthFilter con roles que contienen espacios

**Archivo:** `Backend/src/main/java/com/meltic/gmao/config/TokenAuthFilter.java` línea 45

**Problema:**  
```java
.roles(usuario.getRol().replace(" ", "_").toUpperCase())
```
Si `usuario.getRol()` devuelve `null` (campo sin restricción `@NotNull` en el modelo), se lanza un `NullPointerException` no controlado que corrompe la petición en curso. El modelo `Usuario.java` no tiene `@NotNull` en el campo `rol`.

**Corrección:**
```java
String rol = usuario.getRol() != null ? usuario.getRol().replace(" ", "_").toUpperCase() : "TECNICO";
UserDetails userDetails = User.withUsername(usuario.getEmail())
    .password("")
    .roles(rol)
    .build();
```

---

### HI-06: PLCPollingService usa `new Random()` con estado compartido entre hilos — posible condición de carrera en simulación

**Archivo:** `Backend/src/main/java/com/meltic/gmao/service/PLCPollingService.java` línea 39

**Problema:**  
```java
private final Random random = new Random();
```
`java.util.Random` no es thread-safe. El método `@Scheduled` `pollPLCData()` itera sobre todas las máquinas, y si en el futuro el scheduler usa múltiples hilos, los accesos concurrentes a `random` producen valores repetidos o comportamiento indefinido.

**Corrección:**
```java
// Usar ThreadLocalRandom (thread-safe y más eficiente)
import java.util.concurrent.ThreadLocalRandom;

// En uso (sin necesidad de campo):
t.setTemperatura(20.0 + ThreadLocalRandom.current().nextDouble() * 10.0 + (m.getId() % 5));
```

---

### HI-07: Sintaxis Dart inválida en plc_service.dart — el proyecto no compilará

**Archivo:** `Frontend/meltic_gmao_app/lib/services/plc_service.dart` línea 11

**Problema:**  
```dart
body: jsonEncode({'accion': accion, 'tipo': ?tipo}),
```
La sintaxis `?tipo` dentro de un map literal no es Dart válido. La expresión correcta para incluir condicionalmente una clave es usar `if`. Este error impide la compilación del proyecto.

**Corrección:**
```dart
body: jsonEncode({
    'accion': accion,
    if (tipo != null) 'tipo': tipo,
}),
```

---

### HI-08: NullPointerException en OTDetailScreen al acceder a fechaCreacion sin comprobación de nulo

**Archivo:** `Frontend/meltic_gmao_app/lib/screens/ot_detail_screen.dart` línea 440

**Problema:**  
```dart
_infoRow(Icons.calendar_today, "APERTURA", _formatDate(_ot.fechaCreacion!)),
```
El operador `!` fuerza el desreferenciado de un valor nullable. El modelo `OrdenTrabajo` declara `fechaCreacion` como `String?`. Si el backend devuelve una OT sin fecha (posible en el estado `SOLICITADA` inicial según el constructor del modelo), la aplicación lanzará una excepción en tiempo de ejecución y mostrará pantalla de error.

**Corrección:**
```dart
_infoRow(Icons.calendar_today, "APERTURA", _formatDate(_ot.fechaCreacion ?? 'Sin fecha')),
```

---

### HI-09: El Dockerfile de Flutter descarga Flutter vía `git clone` en cada build — rompe reproducibilidad y es lento

**Archivo:** `Frontend/meltic_gmao_app/Dockerfile` líneas 11-13

**Problema:**  
```dockerfile
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
```
Este enfoque:
1. Descarga la versión `stable` más reciente en el momento del build, que puede diferir entre builds.
2. El build tarda 10-20 minutos solo en clonar Flutter.
3. Si GitHub no está disponible, el build falla completamente.
4. Introduce cambios no controlados en la versión de Flutter usada.

**Corrección:**  
Usar la imagen oficial de Flutter con versión fija:
```dockerfile
FROM ghcr.io/cirruslabs/flutter:3.24.0 AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release --no-tree-shake-icons

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## Problemas MEDIUM

### ME-01: Múltiples instancias de BCryptPasswordEncoder creadas — desperdicio de recursos

**Archivos:**
- `AuthController.java` línea 32
- `DataInitializer.java` línea 13
- `UsuarioController.java` línea 35

**Problema:**  
Cada clase crea su propio `new BCryptPasswordEncoder()`. BCrypt es computacionalmente costoso por diseño (y eso es bueno para la seguridad). La instancia debería compartirse como bean de Spring.

**Corrección:**  
Añadir en `SecurityConfig.java`:
```java
@Bean
public BCryptPasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}
```
E inyectar con `@Autowired` en los controladores que lo necesiten.

---

### ME-02: El endpoint GET /api/plc/simulate/{tag} acepta cualquier string como path variable sin validación

**Archivo:** `Backend/src/main/java/com/meltic/gmao/controller/PLCController.java` líneas 81-85

**Problema:**  
```java
@GetMapping("/simulate/{tag}")
public ResponseEntity<String> simularRfid(@PathVariable String tag) {
    plcPollingService.registrarLecturaRfid(1L, tag);
    return ResponseEntity.ok("Lectura simulada: " + tag);
}
```
Este endpoint (ya marcado con DEMO) permite inyectar cualquier tag RFID arbitrario. Si un atacante conoce el tag RFID de un administrador, puede simularlo y quedar autenticado automáticamente en cualquier cliente que esté sondeando `/api/plc/last-rfid`.

Como mínimo, este endpoint debe requerir autenticación (ver CR-02). En producción real debe eliminarse.

---

### ME-03: AppSession almacena el token solo en memoria — se pierde al recargar la app web

**Archivo:** `Frontend/meltic_gmao_app/lib/services/app_session.dart`

**Problema:**  
El token de autenticación y los datos de sesión se almacenan solo en memoria del proceso Flutter. Al recargar la pestaña del navegador (Flutter Web), el usuario debe volver a iniciar sesión. Esto es especialmente problemático en un sistema de planta industrial donde se espera persistencia de sesión.

**Corrección:**  
Para Flutter Web, persistir el token en `localStorage` / `sessionStorage` usando `shared_preferences` o `flutter_secure_storage`:
```dart
// Al hacer login exitoso:
await SharedPreferences.getInstance().then((prefs) {
    prefs.setString('auth_token', authToken!);
    prefs.setString('user_rol', userRol!);
    // etc.
});

// Al iniciar la app, restaurar la sesión si existe token guardado
```

---

### ME-04: La lógica de alerta en procesarAlertas hace una consulta a BD por cada mensaje de telemetría recibido

**Archivo:** `Backend/src/main/java/com/meltic/gmao/service/PLCPollingService.java` líneas 217-254

**Problema:**  
```java
public void procesarAlertas(Telemetria t) {
    Optional<com.meltic.gmao.model.Maquina> maquinaOpt = maquinaRepository.findById(machineId); // BD query
    ...
    maquinaRepository.save(m); // otra BD query
}
```
Con polling a 1000ms (según `application.properties`), esto son 2 queries a MySQL por segundo por máquina. Con 10 máquinas, son 20 queries/segundo solo en actualizaciones de estado. Esto puede saturar la conexión.

**Corrección:**  
Cachear el estado de las máquinas en memoria con un `ConcurrentHashMap` y solo hacer la query a BD cuando el estado cambia realmente:
```java
private final Map<Long, String> machineStateCache = new ConcurrentHashMap<>();

// Solo guardar si el estado cambió
String newState = alarmaDetectada != null ? (alarmaDetectada.contains("MUY") ? "ERROR" : "WARNING") : "OK";
if (!newState.equals(machineStateCache.get(machineId))) {
    m.setEstado(newState);
    maquinaRepository.save(m);
    machineStateCache.put(machineId, newState);
}
```

---

### ME-05: El endpoint PUT /api/config/{maquinaId} tiene código muerto — la comprobación `if (maquina != null)` es siempre true en ese punto

**Archivo:** `Backend/src/main/java/com/meltic/gmao/controller/ConfigController.java` líneas 69-74

**Problema:**  
```java
Maquina maquina = optMaquina.get(); // ← maquina nunca es null aquí
...
if (maquina != null) { // ← Esta comprobación es siempre true
    maquinaRepository.save(maquina);
    ...
    return ResponseEntity.ok(maquina);
}
return ResponseEntity.notFound().build(); // ← Código inalcanzable
```
La línea `return ResponseEntity.notFound().build()` al final es inalcanzable. Este es código muerto que puede confundir al revisor.

**Corrección:**
```java
Maquina maquina = optMaquina.get();
// ... actualizar campos ...
maquinaRepository.save(maquina);
return ResponseEntity.ok(maquina);
```

---

### ME-06: Los endpoints GET de usuarios, máquinas y config están completamente sin autenticación

**Archivo:** `Backend/src/main/java/com/meltic/gmao/config/SecurityConfig.java` línea 37

**Problema:**  
```java
.requestMatchers(org.springframework.http.HttpMethod.GET, "/api/maquinas/**", "/api/usuarios/**", "/api/config/**").permitAll()
```
Cualquier persona puede listar todos los usuarios del sistema (con sus emails, teléfonos, tags RFID) sin ningún token. Esto es una fuga de datos personales significativa.

**Corrección:**  
```java
.requestMatchers(org.springframework.http.HttpMethod.GET, "/api/maquinas/**").authenticated()
.requestMatchers(org.springframework.http.HttpMethod.GET, "/api/usuarios/**").hasAnyRole("ADMIN", "JEFE_MANTENIMIENTO")
.requestMatchers(org.springframework.http.HttpMethod.GET, "/api/config/**").authenticated()
```

---

### ME-07: No hay ningún índice MongoDB en el campo timestamp de telemetría — las consultas históricas serán lentas

**Archivo:** `Backend/src/main/java/com/meltic/gmao/model/nosql/Telemetria.java`

**Problema:**  
Las queries de telemetría (como `findByMaquinaIdAndTimestampAfterOrderByTimestampAsc`) hacen full collection scan sin índice. Con volúmenes grandes (miles de registros por día por máquina), esto se vuelve muy lento.

**Corrección:**  
Añadir anotaciones de índice compuesto en la entidad:
```java
@Document(collection = "telemetria")
@CompoundIndexes({
    @CompoundIndex(name = "maquina_timestamp_idx", def = "{'maquinaId': 1, 'timestamp': -1}")
})
public class Telemetria {
```

---

### ME-08: Error silencioso en _guardar() de OrdenesScreen y UsuariosScreen — el usuario no recibe feedback de errores

**Archivos:**
- `Frontend/meltic_gmao_app/lib/screens/ordenes_screen.dart` líneas 1029-1032
- `Frontend/meltic_gmao_app/lib/screens/usuarios_screen.dart` línea 702

**Problema:**  
```dart
} catch (e) {
    setState(() => _saving = false); // Solo resetea el estado
    // ← No muestra mensaje de error al usuario
}
```
Si la creación de una OT o un usuario falla (error de red, validación del servidor), el diálogo simplemente deja de girar sin indicar qué salió mal. El usuario no sabe si la operación se completó o falló.

**Corrección:**
```dart
} catch (e) {
    setState(() => _saving = false);
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: IndustrialTheme.criticalRed),
        );
    }
}
```

---

## Problemas LOW

### LO-01: CrearMaquinaScreen es código duplicado de _MaquinaFormDialog en ActivosPLCScreen

**Archivos:**
- `Frontend/meltic_gmao_app/lib/screens/crear_maquina_screen.dart`
- `Frontend/meltic_gmao_app/lib/screens/activos_plc_screen.dart` (líneas 316-683)

**Problema:**  
Ambas clases implementan exactamente la misma funcionalidad (formulario de creación de máquina con métricas y límites configurables). `CrearMaquinaScreen` aparenta no estar registrada en el router de `main.dart` y nunca se usa. Mantener dos implementaciones duplicadas aumenta el coste de mantenimiento.

**Recomendación:**  
Eliminar `crear_maquina_screen.dart` y usar exclusivamente `_MaquinaFormDialog`. Si se necesita una pantalla completa (no diálogo), refactorizar `_MaquinaFormDialog` a un widget reutilizable.

---

### LO-02: La URL del PLC está duplicada entre application.properties y docker-compose

**Archivos:**
- `Backend/src/main/resources/application.properties` línea 22: `meltic.plc.url=http://192.168.1.11`
- `application.properties` también tiene `meltic.plc.polling.rate=1000` (polling cada 1 segundo)

**Problema:**  
La IP del PLC físico está hardcodeada en el fichero de propiedades. En un despliegue Docker, esta IP puede no ser accesible. Debería ser configurable como variable de entorno.

Además, `polling.rate=1000` (1 segundo) combinado con el volumen de datos MongoDB y las queries MySQL de `procesarAlertas` puede ser excesivo. En el TFG con simulación está bien, pero documentarlo es importante.

**Recomendación:**
```properties
meltic.plc.url=${PLC_URL:http://192.168.1.11}
meltic.plc.polling.rate=${PLC_POLLING_RATE:5000}
```

---

### LO-03: La IP del hotspot está hardcodeada en el cliente Flutter

**Archivo:** `Frontend/meltic_gmao_app/lib/services/api_config.dart` línea 5

**Problema:**  
```dart
const String hotspotIp = "192.168.137.1";
```
Esta IP específica de Windows Mobile Hotspot es la dirección de la máquina del alumno. En cualquier otro entorno de demostración (otro portátil, red del instituto), la app Android no encontrará el servidor.

**Recomendación:**  
Hacer la IP configurable desde un campo de texto en la pantalla de login (o mejor, en una pantalla de configuración), persistiéndola con `SharedPreferences`. Esto también es más profesional para la defensa del TFG.

---

### LO-04: Uso de @Autowired sobre campo en lugar de inyección por constructor

**Archivos:**  
Múltiples controladores y servicios: `AuthController.java`, `MaquinaController.java`, `OrdenTrabajoController.java`, `UsuarioController.java`, `ConfigController.java`, `MantenimientoService.java`, `TelemetriaService.java`

**Problema:**  
```java
@Autowired
private UsuarioRepository usuarioRepo;
```
La inyección de campo con `@Autowired` dificulta los tests unitarios (no se puede inyectar mocks sin reflexión) y oculta las dependencias de la clase. La práctica recomendada en Spring moderno es inyección por constructor.

**Recomendación:**
```java
// En lugar de @Autowired en campo:
private final UsuarioRepository usuarioRepo;
private final TokenService tokenService;

public AuthController(UsuarioRepository usuarioRepo, TokenService tokenService) {
    this.usuarioRepo = usuarioRepo;
    this.tokenService = tokenService;
}
```
Spring Boot detecta automáticamente el constructor único y no necesita `@Autowired`.

---

### LO-05: La validación de thresholds de alarmas no verifica coherencia lógica (MB < B < A < MA)

**Archivo:** `Backend/src/main/java/com/meltic/gmao/service/PLCPollingService.java` líneas 237-242

**Problema:**  
No se valida que `limiteMB <= limiteB <= limiteA <= limiteMA`. Si un usuario configura `alto=20, muyAlto=10`, el sistema lanzará alarmas MUY ALTA antes que ALTA, lo cual es un bug lógico silencioso.

**Recomendación:**  
Añadir validación en `ConfigController.updateConfig()` o en el setter del modelo:
```java
private boolean esConfigValida(MetricConfig config) {
    if (config.getLimiteMB() != null && config.getLimiteB() != null 
        && config.getLimiteMB() > config.getLimiteB()) return false;
    if (config.getLimiteB() != null && config.getLimiteA() != null 
        && config.getLimiteB() > config.getLimiteA()) return false;
    if (config.getLimiteA() != null && config.getLimiteMA() != null 
        && config.getLimiteA() > config.getLimiteMA()) return false;
    return true;
}
```

---

### LO-06: Ningún endpoint tiene paginación — respuestas ilimitadas

**Archivos:** `MaquinaController.java`, `OrdenTrabajoController.java`, `UsuarioController.java`

**Problema:**  
`maquinaRepository.findAll()`, `ordenTrabajoRepository.findAll()`, `usuarioRepository.findAll()` devuelven todos los registros sin límite. En un sistema real con cientos de OTs, esto genera respuestas lentas y posibles timeouts.

**Recomendación:**  
Añadir paginación con `Pageable`:
```java
@GetMapping
public Page<OrdenTrabajo> listarTodas(
    @RequestParam(defaultValue = "0") int page,
    @RequestParam(defaultValue = "20") int size) {
    return ordenTrabajoRepository.findAll(PageRequest.of(page, size, Sort.by("fechaCreacion").descending()));
}
```

---

### LO-07: Los errores de `catch (_) {}` en el frontend silencian fallos importantes

**Archivos:**  
- `login_screen.dart` línea 83: `} catch (_) {}`
- `ot_detail_screen.dart` líneas 87, 181, etc.
- `usuarios_screen.dart` líneas 85, 653, etc.

**Problema:**  
Los bloques `catch (_) {}` vacíos silencian completamente errores. Si hay un bug, no hay manera de saberlo durante desarrollo ni producción. Al menos añadir `debugPrint`.

**Recomendación:**
```dart
} catch (e, stackTrace) {
    debugPrint('Error en [contexto]: $e\n$stackTrace');
}
```

---

### LO-08: La lógica de polling de telemetría en GlobalTelemetryHistorian tiene un race condition menor

**Archivo:** `Frontend/meltic_gmao_app/lib/services/global_telemetry_historian.dart` líneas 94-98

**Problema:**  
```dart
if (since == null) {
    final data = await _service.fetchPorMaquina(id); // Carga 3600 registros
    _addAllToBuffer(id, data.take(10).toList()); // Solo guarda 10
}
```
El poller de background siempre carga 3600 registros del servidor pero solo usa 10. Esto genera una transferencia de datos innecesaria de ~3590 registros en cada arranque de poller sin carga inicial previa.

**Recomendación:**  
Añadir un endpoint `GET /api/plc/maquina/{id}/last?limit=10` en el backend, o usar `fetchDesde` con un `since` de hace 30 segundos para la primera carga ligera del poller.

---

## Análisis de Arquitectura

### Lo que está bien hecho

1. **Separación en capas:** El proyecto usa correctamente Controller → Service → Repository, aunque los controladores de máquinas y usuarios acceden directamente al repositorio (sin capa de servicio). Esto es aceptable para el alcance del TFG pero es algo a corregir.

2. **Dual database (SQL + NoSQL):** La decisión de usar MySQL para datos relacionales (usuarios, OTs, máquinas) y MongoDB para telemetría de series temporales es arquitectónicamente correcta y demuestra comprensión del problema.

3. **SCADA Historian pattern:** La implementación de `GlobalTelemetryHistorian` con `SplayTreeMap` como buffer circular ordenado por timestamp es una solución elegante y eficiente para visualización en tiempo real.

4. **Downsampling estadístico:** El uso de `$sample` de MongoDB en `TelemetriaService.obtenerHistorico()` para limitar a 2000 puntos es una buena solución pragmática para gráficas históricas.

5. **Workflow completo de OT:** El ciclo SOLICITADA → PENDIENTE → EN_PROCESO → CERRADA con firmas digitales, checklists, foto y PDF es un flujo de trabajo profesional bien implementado.

6. **Docker Compose con healthchecks:** El uso de `condition: service_healthy` para esperar a que las bases de datos estén listas antes de arrancar el backend es una práctica correcta.

7. **RFID login con validación server-side:** La validación del tag RFID en `AuthController.rfidLogin()` (formato con `:`, lista de valores inválidos) es una medida de seguridad correcta.

### Deuda técnica notable

1. **Sin tests:** No hay ningún test unitario ni de integración. Para un TFG de SMR es comprensible, pero mencionarlo demuestra madurez técnica.

2. **Sin gestión de errores globales:** No hay `@ControllerAdvice` / `@ExceptionHandler` global en el backend. Las excepciones no controladas devuelven stack traces al cliente.

3. **Valores de estado como strings mágicos:** Estados como "PENDIENTE", "EN_PROCESO", "CERRADA" están duplicados entre backend y frontend sin un contrato compartido (enum). Un cambio de nombre en uno no se detecta en compilación.

---

## Resumen de Conteo

| Severidad | Cantidad |
|-----------|----------|
| CRITICAL  | 3        |
| HIGH      | 9        |
| MEDIUM    | 8        |
| LOW       | 8        |
| **TOTAL** | **28**   |

---

## Conclusión para el TFG

Este es un proyecto técnicamente ambicioso y bien ejecutado para el nivel SMR. La mayoría de los problemas detectados son comunes en proyectos reales y académicos cuando la seguridad y la robustez no son el foco principal del desarrollo. Los problemas **CRITICAL** y **HIGH** son los que deberías abordar antes de la defensa para demostrar que comprendes las implicaciones de seguridad de tu propio sistema.

**Para la defensa, recomiendo especialmente:**
1. Explicar el problema CR-02 (PLC sin autenticación) y por qué en producción real se usaría una API key o mTLS.
2. Comentar que los tokens sin expiración (CR-03) se resolverían con JWT en producción.
3. Mencionar que las contraseñas hardcodeadas (CR-01, HI-01) se gestionarían con secrets de Kubernetes o HashiCorp Vault.

Demostrar que sabes que estos problemas existen y por qué no los corregiste en el TFG (tiempo, alcance, hardware de TFG) es mucho mejor que no haberlos visto.

---

_Revisado: 2026-04-15_  
_Revisor: Claude Code (gsd-code-reviewer)_  
_Profundidad: Deep_
