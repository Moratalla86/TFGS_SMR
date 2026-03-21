package com.meltic.gmao.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.meltic.gmao.model.Usuario;
import com.meltic.gmao.model.nosql.Telemetria;
import com.meltic.gmao.repository.sql.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.RestClientException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class PLCPollingService {

    private static final Logger logger = LoggerFactory.getLogger(PLCPollingService.class);

    @Value("${meltic.plc.url:http://192.168.1.177}")
    private String plcUrl;

    private String lastRfidRead = "";
    private LocalDateTime lastRfidTimestamp;

    @Autowired
    private TelemetriaService telemetriaService;

    @Autowired
    private UsuarioRepository usuarioRepository;

    public String getLastRfidRead() {
        return lastRfidRead;
    }

    public LocalDateTime getLastRfidTimestamp() {
        return lastRfidTimestamp;
    }

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

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
                String rfid = root.has("rfid") ? root.get("rfid").asText() : "";
                
                // Actualizar el último RFID leído para la vinculación
                if (rfid != null && !rfid.isEmpty() && !rfid.equalsIgnoreCase("Ninguna tarjeta detectada")) {
                    this.lastRfidRead = rfid;
                    this.lastRfidTimestamp = LocalDateTime.now();
                }

                // Only save telemetry if values are somewhat valid
                Telemetria t = new Telemetria();
                t.setMaquinaId(1L); // Default maquina id
                t.setTemperatura(temperatura);
                t.setHumedad(humedad);
                t.setTimestamp(LocalDateTime.now());
                
                // Handle RFID Logic
                if (rfid != null && !rfid.isEmpty() && !rfid.equalsIgnoreCase("Ninguna tarjeta detectada")) {
                    t.setRfidTag(rfid);
                    Optional<Usuario> userOpt = usuarioRepository.findByRfidTag(rfid);
                    if (userOpt.isPresent()) {
                        Usuario u = userOpt.get();
                        String nombreCompleto = u.getNombre() + " " + u.getApellido1();
                        t.setUsuarioNombre(nombreCompleto);
                        logger.info("📡 TÉCNICO DETECTADO EN MÁQUINA 1: {} (RFID: {})", nombreCompleto, rfid);
                    } else {
                        logger.warn("⚠️ TARJETA DESCONOCIDA DETECTADA: {}", rfid);
                        t.setUsuarioNombre("Desconocido (" + rfid + ")");
                    }
                }

                telemetriaService.guardar(t);
                logger.debug("Telemetría guardada: Temp {} C, Hum {} %", temperatura, humedad);
            }
        } catch (RestClientException e) {
            logger.error("❌ Error de conexión con el PLC en {}: {}", plcUrl, e.getMessage());
        } catch (Exception e) {
            logger.error("❌ Error procesando datos del PLC: {}", e.getMessage());
        }
    }
}
