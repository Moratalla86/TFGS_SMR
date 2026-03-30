package com.meltic.gmao.service;

import java.time.LocalDateTime;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

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

    @Value("${meltic.plc.url:http://192.168.1.177}")
    private String plcUrl;

    private String lastRfidRead = "";
    private LocalDateTime lastRfidTimestamp;

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

    private final RestTemplate restTemplate = new RestTemplate(); // Nota: En producción sería un @Bean inyectado
    private final ObjectMapper objectMapper = new ObjectMapper();

    public String getLastRfidRead() {
        return lastRfidRead;
    }

    public LocalDateTime getLastRfidTimestamp() {
        return lastRfidTimestamp;
    }

    public void registrarLecturaRfid(String rfid) {
        if (rfid != null && !rfid.isEmpty() && !rfid.equalsIgnoreCase("Ninguna tarjeta detectada")) {
            this.lastRfidRead = rfid;
            this.lastRfidTimestamp = LocalDateTime.now();
        }
    }

    // Default to 10 seconds if not configured
    @Scheduled(fixedRateString = "${meltic.plc.polling.rate:10000}")
    public void pollPLCData() {
        try {
            logger.debug("Consultando PLC en URL: {}", plcUrl);
            String response = restTemplate.getForObject(plcUrl, String.class);

            if (response != null && !response.isEmpty()) {
                JsonNode root = objectMapper.readTree(response);

                double temperatura = root.has("temperatura") ? root.get("temperatura").asDouble() : 0.0;
                double humedad = root.has("humedad") ? root.get("humedad").asDouble() : 0.0;
                boolean motorOn = root.has("motorOn") && root.get("motorOn").asBoolean();

                if (motorOnSimulated) {
                    motorOn = true;
                    currentSimulatedTemp += (45.0 - currentSimulatedTemp) * 0.1 + (random.nextDouble() - 0.5) * 2.0;
                    temperatura = currentSimulatedTemp;
                    if (humedad == 0)
                        humedad = 40.0 + (random.nextDouble() - 0.5) * 5.0;
                }

                String rfid = root.has("rfid") ? root.get("rfid").asText() : "";
                registrarLecturaRfid(rfid);

                Telemetria t = new Telemetria();
                t.setMaquinaId(DEFAULT_MAQUINA_ID);
                t.setTemperatura(temperatura);
                t.setHumedad(humedad);
                t.setMotorOn(motorOn);
                t.setTimestamp(LocalDateTime.now());

                if (rfid != null && !rfid.isEmpty() && !rfid.equalsIgnoreCase("Ninguna tarjeta detectada")) {
                    t.setRfidTag(rfid);
                    Optional<Usuario> userOpt = usuarioRepository.findByRfidTag(rfid);
                    if (userOpt.isPresent()) {
                        Usuario u = userOpt.get();
                        String nombreCompleto = u.getNombre() + " " + u.getApellido1();
                        t.setUsuarioNombre(nombreCompleto);
                        logger.info("📡 TÉCNICO DETECTADO EN MÁQUINA {}: {} (RFID: {})", DEFAULT_MAQUINA_ID,
                                nombreCompleto, rfid);
                    } else {
                        logger.warn("⚠️ TARJETA DESCONOCIDA DETECTADA: {}", rfid);
                        t.setUsuarioNombre("Desconocido (" + rfid + ")");
                    }
                }

                // --- Lógica de Alertas y Límites ---
                procesarAlertas(t);
                telemetriaService.guardar(t);

                logger.debug("Telemetría procesada y guardada: Temp {} C, Hum {} %", temperatura, humedad);
            }
        } catch (RestClientException e) {
            logger.error("❌ Error de conexión con el PLC en {}: {}", plcUrl, e.getMessage());
        } catch (Exception e) {
            logger.error("❌ Error procesando datos del PLC: {}", e.getMessage());
        }
    }

    public void procesarAlertas(Telemetria t) {
        Optional<com.meltic.gmao.model.Maquina> maquinaOpt = maquinaRepository.findById(t.getMaquinaId());
        if (maquinaOpt.isPresent()) {
            com.meltic.gmao.model.Maquina m = maquinaOpt.get();
            String alarmaDetectada = null;

            if (forcedAlarm != null) {
                alarmaDetectada = forcedAlarm;
                forcedAlarm = null; // Se consume
            } else if (m.getLimiteMA() != null && t.getTemperatura() >= m.getLimiteMA()) {
                alarmaDetectada = "MUY ALTA";
            } else if (m.getLimiteA() != null && t.getTemperatura() >= m.getLimiteA()) {
                alarmaDetectada = "ALTA";
            } else if (m.getLimiteMB() != null && t.getTemperatura() <= m.getLimiteMB()) {
                alarmaDetectada = "MUY BAJA";
            } else if (m.getLimiteB() != null && t.getTemperatura() <= m.getLimiteB()) {
                alarmaDetectada = "BAJA";
            }

            if (alarmaDetectada != null) {
                t.setAlarma(alarmaDetectada);
                m.setEstado(
                        "ERROR".equals(alarmaDetectada) || "MUY ALTA".equals(alarmaDetectada) ? "ERROR" : "WARNING");
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
