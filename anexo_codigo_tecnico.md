# Anexo de Código: Desarrollo Técnico Backend

Este documento contiene los fragmentos de código estructurales solicitados para la redacción del capítulo "Desarrollo Técnico" de la Memoria del TFG.

---

## 1. El Controlador de Activos/Sensores (`PLCController.java`)
Este componente actúa como la puerta de enlace (`Gateway`) entre el hardware de la planta y la lógica de negocio del servidor. Se expone como un API RESTful.

```java
@RestController
@RequestMapping("/api/plc")
@CrossOrigin(origins = "*")
@Tag(name = "IoT - PLC Controller", description = "Monitorización y control de telemetría en tiempo real")
public class PLCController {

    @Autowired
    private TelemetriaService telemetriaService;

    @Autowired
    private PLCPollingService plcPollingService;

    @Operation(summary = "Recepción de Telemetría HTTP PUSH")
    @PostMapping("/data")
    public ResponseEntity<Telemetria> recibirTelemetria(@RequestBody Telemetria telemetria) {
        // 1. Validar alertas cruzando datos con los umbrales configurados
        plcPollingService.procesarAlertas(telemetria);
        
        // 2. Persistir datos en MongoDB para histórico
        Telemetria guardada = telemetriaService.guardar(telemetria);

        // 3. Registrar acceso biométrico si hay tag NFC
        if (guardada.getRfidTag() != null && !guardada.getRfidTag().isEmpty()) {
            plcPollingService.registrarLecturaRfid(guardada.getRfidTag());
        }

        return ResponseEntity.ok(guardada);
    }
    
    @Operation(summary = "Mando de Control IoT Remoto")
    @PostMapping("/comando")
    public ResponseEntity<Map<String, String>> enviarComando(@RequestBody Map<String, String> payload) {
        // Enrutamiento de comandos (Ej. START_MOTOR o FORCE_ALARM) hacia el PLC
        String accion = payload.get("accion");
        // Lógica interna...
        return ResponseEntity.ok(Collections.singletonMap("status", "Comando " + accion + " ejecutado"));
    }
}
```

---

## 2. La Entidad de Base de Datos (`Telemetria.java` - MongoDB)
El modelado de datos para sensores se ha implementado mediante una base de datos documental (`NoSQL`) optimizada para series temporales. 

```java
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Document(collection = "telemetria")
public class Telemetria {

    @Id
    private String id;
    
    // Relación lógica con MySQL
    private Long maquinaId;
    
    // Métricas Industriales
    private Double temperatura;
    private Double humedad;
    private Double vibracion;
    private Double presion;
    private Double voltaje;
    private Double intensidad;
    
    // Lógica de Estado y Seguridad
    private String rfidTag;
    private String usuarioNombre;
    private Boolean motorOn;
    private String alarma;
    private LocalDateTime timestamp;

    public Telemetria() {
        this.timestamp = LocalDateTime.now();
    }

    // (Getter y Setters estándar omitidos por brevedad en redacción)
}
```

---

## 3. Lógica del PLC y Debouncing RFID (`PLCPollingService.java`)
Este servicio es el corazón del motor de recolección de datos y la mitigación de errores generados por el hardware físico.

```java
@Service
public class PLCPollingService {
    
    private String lastRfidRead = "";
    private LocalDateTime lastRfidTimestamp = null;
    
    // Método centralizado para procesar lecturas brutas de antena NFC
    public synchronized void registrarLecturaRfid(String rfid) {
        if (rfid != null && !rfid.isEmpty() && !rfid.equalsIgnoreCase("Ninguna tarjeta detectada")) {
            
            // LÓGICA DE DEBOUNCING (FILTRO DE RUIDO REBOTE)
            // Solo actualiza el estado interno si el TAG ha cambiado respecto a la última lectura.
            // Esto evita que el frontend colapse intentando hacer login 5 veces por segundo
            // mientras el técnico mantiene la tarjeta apoyada en el lector.
            if (!rfid.equals(this.lastRfidRead)) {
                this.lastRfidRead = rfid;
                this.lastRfidTimestamp = LocalDateTime.now();
                logger.info("NUEVA TARJETA DETECTADA (PLC): {}", rfid);
            }
        } else {
            // Resetear estado al retirar la tarjeta para permitir re-lecturas limpias
            if (!"".equals(this.lastRfidRead)) {
                this.lastRfidRead = "";
            }
        }
    }

    // NOTA: El sistema se diseñó inicialmente para ejecutar polling 
    // mediante @Scheduled(fixedRateString = "${meltic.plc.polling.rate:15000}") 
    // pero evolucionó hacia un modelo HTTP Push + Failsafe Simulator.
}
```
