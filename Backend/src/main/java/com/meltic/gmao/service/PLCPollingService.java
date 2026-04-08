package com.meltic.gmao.service;

import java.time.LocalDateTime;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.client.SimpleClientHttpRequestFactory;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.meltic.gmao.model.Usuario;
import com.meltic.gmao.model.nosql.Telemetria;
import com.meltic.gmao.repository.sql.MaquinaRepository;
import com.meltic.gmao.repository.sql.UsuarioRepository;

@Service
public class PLCPollingService {

    private static final Logger logger = LoggerFactory.getLogger(PLCPollingService.class);

    private static final Long DEFAULT_MAQUINA_ID = 1L;

    @Value("${meltic.plc.url:http://192.168.1.11}")
    private String plcUrl;

    private String lastRfidRead = "";
    private LocalDateTime lastRfidTimestamp;
    private LocalDateTime lastRfidReadTime; // Para persistencia de lectura (Sticky Buffer)

    // --- Simulación ---
    private boolean motorOnSimulated = false;
    private double currentSimulatedTemp = 22.0;
    private String forcedAlarm = null;
    private final java.util.Random random = new java.util.Random();

    @Autowired
    private MaquinaRepository maquinaRepository;

    @Autowired
    private TelemetriaService telemetriaService;

    @Autowired
    private UsuarioRepository usuarioRepository;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public PLCPollingService() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(5000); // 5 segundos para conectar
        factory.setReadTimeout(5000);    // 5 segundos para leer
        this.restTemplate = new RestTemplate(factory);
    }

    public String getLastRfidRead() {
        return lastRfidRead;
    }

    public LocalDateTime getLastRfidTimestamp() {
        return lastRfidTimestamp;
    }

    public void registrarLecturaRfid(String rfid) {
        if (rfid != null && !rfid.isEmpty() && !rfid.equalsIgnoreCase("Ninguna tarjeta detectada") && !rfid.equalsIgnoreCase("N/A")) {
            // Solo actualizar el timestamp si el TAG ha cambiado (Debounce)
            // Esto evita que el frontend intente logear repetidamente mientras se mantiene la tarjeta
            if (!rfid.equals(this.lastRfidRead)) {
                this.lastRfidRead = rfid;
                this.lastRfidTimestamp = LocalDateTime.now();
                logger.info("NUEVA TARJETA DETECTADA (PLC): {}", rfid);
            }
            this.lastRfidReadTime = LocalDateTime.now(); // Actualizar tiempo de última presencia real
        } else {
            // "STICKY BUFFER": Reducido a 2 segundos para mayor agilidad
            // Esto da tiempo al polling del frontend (1.5s) a capturar el dato
            if (this.lastRfidReadTime != null && 
                java.time.Duration.between(this.lastRfidReadTime, LocalDateTime.now()).getSeconds() >= 2) {
                
                if (!"".equals(this.lastRfidRead)) {
                    this.lastRfidRead = "";
                    logger.debug("Buffer RFID liberado tras 2s de inactividad");
                }
            }
        }
    }

    // Default to 10 seconds if not configured
    // Desactivado para evitar errores de conexión (El PLC ya envía datos por PUSH)
    @org.springframework.scheduling.annotation.Scheduled(fixedRateString = "${meltic.plc.polling.rate:10000}")
    public void pollPLCData() {
        String url = plcUrl != null ? plcUrl : "http://localhost:8080";
        try {
            logger.debug("Consultando PLC en URL: {}", url);
            String response = restTemplate.getForObject(url, String.class);

            if (response != null && !response.isEmpty()) {
                JsonNode root = objectMapper.readTree(response);

                double temperatura = root.has("temperatura") ? root.get("temperatura").asDouble() : 0.0;
                double humedad = root.has("humedad") ? root.get("humedad").asDouble() : 0.0;
                double vibracion = root.has("vibracion") ? root.get("vibracion").asDouble() : 0.0;
                double presion = root.has("presion") ? root.get("presion").asDouble() : 0.0;
                double voltaje = root.has("voltaje") ? root.get("voltaje").asDouble() : 0.0;
                double intensidad = root.has("intensidad") ? root.get("intensidad").asDouble() : 0.0;
                boolean motorOn = root.has("motorOn") && root.get("motorOn").asBoolean();

                if (motorOnSimulated) {
                    motorOn = true;
                    currentSimulatedTemp += (45.0 - currentSimulatedTemp) * 0.1 + (random.nextDouble() - 0.5) * 2.0;
                    temperatura = currentSimulatedTemp;
                    if (humedad <= 0) humedad = 40.0 + (random.nextDouble() - 0.5) * 5.0;
                    if (vibracion <= 0) vibracion = 2.5 + (random.nextDouble() - 0.5) * 0.5;
                    if (presion <= 0) presion = 6.2 + (random.nextDouble() - 0.5) * 0.3;
                    if (voltaje <= 0) voltaje = 230.0 + (random.nextDouble() - 0.5) * 2.0;
                    if (intensidad <= 0) intensidad = 12.4 + (random.nextDouble() - 0.5) * 1.5;
                }

                String rfid = root.has("rfid") ? root.get("rfid").asText() : "";
                registrarLecturaRfid(rfid);

                Telemetria t = new Telemetria();
                t.setMaquinaId(DEFAULT_MAQUINA_ID);
                t.setTemperatura(temperatura);
                t.setHumedad(humedad);
                t.setVibracion(vibracion);
                t.setPresion(presion);
                t.setVoltaje(voltaje);
                t.setIntensidad(intensidad);
                t.setMotorOn(motorOn);
                t.setTimestamp(LocalDateTime.now());

                if (rfid != null && !rfid.isEmpty() && !rfid.equalsIgnoreCase("Ninguna tarjeta detectada")) {
                    t.setRfidTag(rfid);
                    String maskedRfid = rfid.length() > 4 ? "****" + rfid.substring(rfid.length() - 4) : "****";
                    Optional<Usuario> userOpt = usuarioRepository.findByRfidTagIgnoreCase(rfid);
                    if (userOpt.isPresent()) {
                        Usuario u = userOpt.get();
                        String nombreCompleto = u.getNombre() + " " + u.getApellido1();
                        t.setUsuarioNombre(nombreCompleto);
                        logger.info("📡 TÉCNICO DETECTADO EN MÁQUINA {}: {} (RFID: {})", DEFAULT_MAQUINA_ID,
                                nombreCompleto, maskedRfid);
                    } else {
                        logger.warn("⚠️ TARJETA DESCONOCIDA DETECTADA: {}", maskedRfid);
                        t.setUsuarioNombre("Desconocido (" + maskedRfid + ")");
                    }
                }

                // --- Lógica de Alertas y Límites ---
                procesarAlertas(t);
                telemetriaService.guardar(t);

                logger.debug("Telemetría procesada y guardada: Temp {} C, Hum {} %", temperatura, humedad);
            }
        } catch (RestClientException e) {
            logger.error("❌ Error de conexión con el PLC en {}: {}", url, e.getMessage());
        } catch (Exception e) {
            logger.error("❌ Error procesando datos del PLC: {}", e.getMessage());
        }
    }

    public void procesarAlertas(Telemetria t) {
        if (t.getMaquinaId() == null) return;
        Long mId = t.getMaquinaId();
        if (mId == null) return;
        Optional<com.meltic.gmao.model.Maquina> maquinaOpt = maquinaRepository.findById(mId);
        if (maquinaOpt.isPresent()) {
            com.meltic.gmao.model.Maquina m = maquinaOpt.get();
            String alarmaDetectada = null;

            if (forcedAlarm != null) {
                alarmaDetectada = forcedAlarm;
                forcedAlarm = null; // Se consume
            } else {
                // Lógica dinámica por cada métrica configurada
                for (com.meltic.gmao.model.MetricConfig config : m.getConfigs()) {
                    if (!config.isHabilitado()) continue;

                    Double valorActual = null;
                    if ("temperatura".equalsIgnoreCase(config.getNombreMetrica())) {
                        valorActual = t.getTemperatura();
                    } else if ("humedad".equalsIgnoreCase(config.getNombreMetrica())) {
                        valorActual = t.getHumedad();
                    } else if ("vibracion".equalsIgnoreCase(config.getNombreMetrica())) {
                        valorActual = t.getVibracion();
                    } else if ("presion".equalsIgnoreCase(config.getNombreMetrica())) {
                        valorActual = t.getPresion();
                    } else if ("voltaje".equalsIgnoreCase(config.getNombreMetrica())) {
                        valorActual = t.getVoltaje();
                    } else if ("intensidad".equalsIgnoreCase(config.getNombreMetrica())) {
                        valorActual = t.getIntensidad();
                    }

                    if (valorActual != null) {
                        if (config.getLimiteMA() != null && valorActual >= config.getLimiteMA()) {
                            alarmaDetectada = "MUY ALTA (" + config.getNombreMetrica().toUpperCase() + ")";
                        } else if (config.getLimiteA() != null && valorActual >= config.getLimiteA()) {
                            alarmaDetectada = "ALTA (" + config.getNombreMetrica().toUpperCase() + ")";
                        } else if (config.getLimiteMB() != null && valorActual <= config.getLimiteMB()) {
                            alarmaDetectada = "MUY BAJA (" + config.getNombreMetrica().toUpperCase() + ")";
                        } else if (config.getLimiteB() != null && valorActual <= config.getLimiteB()) {
                            alarmaDetectada = "BAJA (" + config.getNombreMetrica().toUpperCase() + ")";
                        }

                        if (alarmaDetectada != null) break; // Detener en la primera alarma encontrada
                    }
                }
            }

            if (alarmaDetectada != null) {
                t.setAlarma(alarmaDetectada);
                // Si es "MUY ALTA" o contiene "MUY", lo consideramos ERROR, si no WARNING
                m.setEstado(alarmaDetectada.contains("MUY") ? "ERROR" : "WARNING");
                maquinaRepository.save(m);
                logger.warn("⚠️ ALARMA DETECTADA en máquina {}: {}", m.getId(), alarmaDetectada);
            } else {
                if (!"OK".equals(m.getEstado())) {
                    m.setEstado("OK");
                    maquinaRepository.save(m);
                }
            }
        }
    }

    public void setMotorOnSimulated(boolean on) {
        this.motorOnSimulated = on;
        logger.info("Simulación de motor: {}", on ? "INICIADA" : "DETENIDA");
    }

    public void forceAlarmSimulated(String tipo) {
        this.forcedAlarm = tipo;
        logger.warn("Simulación de alarma forzada: {}", tipo);
    }
}
