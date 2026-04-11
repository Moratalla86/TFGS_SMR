package com.meltic.gmao.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.meltic.gmao.model.Maquina;
import com.meltic.gmao.model.Usuario;
import com.meltic.gmao.model.nosql.Telemetria;
import com.meltic.gmao.repository.sql.MaquinaRepository;
import com.meltic.gmao.repository.sql.UsuarioRepository;

@Service
public class PLCPollingService {

    private static final Logger logger = LoggerFactory.getLogger(PLCPollingService.class);

    @Value("${meltic.plc.url:http://192.168.1.11}")
    private String defaultPlcUrl;

    private final java.util.Map<Long, String> machineRfidBuffer = new ConcurrentHashMap<>();
    private final java.util.Map<Long, LocalDateTime> machineRfidPresence = new ConcurrentHashMap<>();

    private final Random random = new Random();

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
        factory.setConnectTimeout(10000); // 10 segundos
        factory.setReadTimeout(10000);    // 10 segundos
        this.restTemplate = new RestTemplate(factory);
    }

    public String getLastRfidRead(Long machineId) {
        return machineRfidBuffer.getOrDefault(machineId, "");
    }

    public void registrarLecturaRfid(Long machineId, String rfid) {
        if (rfid != null && !rfid.trim().isEmpty() && !rfid.equalsIgnoreCase("Ninguna tarjeta detectada") && !rfid.equalsIgnoreCase("N/A")) {
            String cleanRfid = rfid.trim();
            String lastRead = machineRfidBuffer.getOrDefault(machineId, "");
            if (!cleanRfid.equals(lastRead)) {
                machineRfidBuffer.put(machineId, cleanRfid);
                logger.info("📡 NUEVA TARJETA DETECTADA (PLC {}): {}", machineId, cleanRfid);
            }
            machineRfidPresence.put(machineId, LocalDateTime.now()); 
        } else {
            LocalDateTime lastPresence = machineRfidPresence.get(machineId);
            // Si han pasado más de 45 segundos sin detectar tarjeta (3 ciclos de 15s), limpiamos el buffer
            if (lastPresence != null && java.time.Duration.between(lastPresence, LocalDateTime.now()).getSeconds() >= 45) {
                if (machineRfidBuffer.containsKey(machineId) && !"".equals(machineRfidBuffer.get(machineId))) {
                    machineRfidBuffer.put(machineId, "");
                    logger.debug("Buffer RFID máquina {} liberado por ausencia prolongada", machineId);
                }
            }
        }
    }

    private final java.util.Map<Long, LocalDateTime> lastOnDemandPoll = new ConcurrentHashMap<>();

    public Telemetria pollMachineNow(Long machineId) {
        if (machineId == null) return null;
        Optional<com.meltic.gmao.model.Maquina> maquinaOpt = maquinaRepository.findById(machineId);
        if (maquinaOpt.isPresent()) {
            com.meltic.gmao.model.Maquina m = maquinaOpt.get();
            if (m.isSimulado()) return null;

            // Throttling: Máximo 1 petición manual por segundo
            LocalDateTime last = lastOnDemandPoll.get(machineId);
            if (last != null && java.time.Duration.between(last, LocalDateTime.now()).toMillis() < 1000) {
                return null; 
            }
            lastOnDemandPoll.put(machineId, LocalDateTime.now());

            String finalUrl = m.getPlcUrl();
            if ((finalUrl == null || finalUrl.isEmpty()) && m.getId() == 1L) {
                finalUrl = defaultPlcUrl;
            }

            try {
                if (finalUrl != null && !finalUrl.isEmpty()) {
                    if (!finalUrl.toLowerCase().startsWith("http")) finalUrl = "http://" + finalUrl;
                    
                    String response = restTemplate.getForObject(finalUrl, String.class);
                    if (response != null && !response.isEmpty()) {
                        JsonNode root = objectMapper.readTree(response);
                        Telemetria t = objectMapper.treeToValue(root, Telemetria.class);
                        t.setMaquinaId(m.getId());
                        t.setTimestamp(java.time.Instant.now());
                        
                        registrarLecturaRfid(m.getId(), t.getRfidTag());
                        procesarAlertas(t);
                        return telemetriaService.guardar(t);
                    }
                }
            } catch (Exception e) {
                logger.error("❌ Fallo en polling on-demand para máquina {}: {}", machineId, e.getMessage());
            }
        }
        return null;
    }

    @Scheduled(fixedRateString = "${meltic.plc.polling.rate:5000}")
    @Transactional
    public void pollPLCData() {
        List<Maquina> maquinas = maquinaRepository.findAll();
        for (Maquina m : maquinas) {
            pollMachineNow(m);
        }
    }

    @Transactional
    public void pollMachineNow(Maquina m) {
        String finalUrl = "SIMULADO";
        try {
            Telemetria t = new Telemetria();
                t.setMaquinaId(m.getId());
                t.setTimestamp(java.time.Instant.now());

                // Fallback a simulación si no hay URL o si la marca está activa (para asegurar histórico en TFG)
                boolean forcedSimulation = m.isSimulado() || (m.getPlcUrl() == null || m.getPlcUrl().trim().isEmpty());

                if (forcedSimulation) {
                    t.setMotorOn(true);
                    // Lógica de fluctuación para simulación
                    t.setTemperatura(20.0 + random.nextDouble() * 10.0 + (m.getId() % 5));
                    t.setHumedad(40.0 + random.nextDouble() * 20.0);
                    t.setVibracion(1.0 + random.nextDouble() * 2.0);
                    t.setPresion(5.0 + random.nextDouble() * 2.0);
                    t.setVoltaje(230.0 + (random.nextDouble() - 0.5) * 5.0);
                    t.setIntensidad(10.0 + random.nextDouble() * 5.0);
                    t.setRfidTag(""); 
                } else {
                    finalUrl = m.getPlcUrl();
                    if ((finalUrl == null || finalUrl.isEmpty()) && m.getId() == 1L) {
                        finalUrl = defaultPlcUrl;
                    }

                    if (finalUrl != null && !finalUrl.isEmpty()) {
                        if (!finalUrl.toLowerCase().startsWith("http")) {
                            finalUrl = "http://" + finalUrl;
                        }

                        logger.debug("Consultando PLC (Máquina {}) en URL: {}", m.getId(), finalUrl);
                        String response = restTemplate.getForObject(finalUrl, String.class);

                        if (response != null && !response.isEmpty()) {
                            JsonNode root = objectMapper.readTree(response);
                            t = objectMapper.treeToValue(root, Telemetria.class);
                            t.setMaquinaId(m.getId());
                            t.setTimestamp(java.time.Instant.now());
                            
                            registrarLecturaRfid(m.getId(), t.getRfidTag());
                        } else {
                            // Si el PLC responde vacío, no guardamos para evitar ruido
                            return;
                        }
                    } else {
                        // Este caso ya no debería darse por el forcedSimulation de arriba, pero por seguridad:
                        return;
                    }
                }

                // --- Enriquecimiento con Usuario ---
                String rfid = t.getRfidTag();
                if (rfid != null && !rfid.trim().isEmpty() && !rfid.equalsIgnoreCase("Ninguna tarjeta detectada")) {
                    Optional<Usuario> userOpt = usuarioRepository.findByRfidTagIgnoreCase(rfid.trim());
                    if (userOpt.isPresent()) {
                        Usuario u = userOpt.get();
                        t.setUsuarioNombre(u.getNombre() + " " + u.getApellido1());
                    } else {
                        t.setUsuarioNombre("Desconocido (" + rfid.trim() + ")");
                    }
                }

                procesarAlertas(t);
                telemetriaService.guardar(t);

            } catch (RestClientException e) {
                logger.error("❌ Error de conexión con máquina {} ({}) en {}: {}", 
                    m.getId(), m.getNombre(), finalUrl, e.getMessage());
                if (!"DESCONECTADO".equals(m.getEstado())) {
                    m.setEstado("DESCONECTADO");
                    maquinaRepository.save(m);
                }
            } catch (Exception e) {
                logger.error("❌ Error procesando máquina {}: {}", m.getId(), e.getMessage());
            }
    }

    public void procesarAlertas(Telemetria t) {
        Long machineId = t.getMaquinaId();
        if (machineId == null) return;
        Optional<com.meltic.gmao.model.Maquina> maquinaOpt = maquinaRepository.findById(machineId);
        if (maquinaOpt.isPresent()) {
            com.meltic.gmao.model.Maquina m = maquinaOpt.get();
            String alarmaDetectada = null;

            for (com.meltic.gmao.model.MetricConfig config : m.getConfigs()) {
                if (!config.isHabilitado()) continue;

                Double valorActual = null;
                String nm = config.getNombreMetrica().toLowerCase();
                if ("temperatura".equals(nm)) valorActual = t.getTemperatura();
                else if ("humedad".equals(nm)) valorActual = t.getHumedad();
                else if ("vibracion".equals(nm)) valorActual = t.getVibracion();
                else if ("presion".equals(nm)) valorActual = t.getPresion();
                else if ("voltaje".equals(nm)) valorActual = t.getVoltaje();
                else if ("intensidad".equals(nm)) valorActual = t.getIntensidad();

                if (valorActual != null) {
                    if (config.getLimiteMA() != null && valorActual >= config.getLimiteMA()) alarmaDetectada = "MUY ALTA (" + nm.toUpperCase() + ")";
                    else if (config.getLimiteA() != null && valorActual >= config.getLimiteA()) alarmaDetectada = "ALTA (" + nm.toUpperCase() + ")";
                    else if (config.getLimiteMB() != null && valorActual <= config.getLimiteMB()) alarmaDetectada = "MUY BAJA (" + nm.toUpperCase() + ")";
                    else if (config.getLimiteB() != null && valorActual <= config.getLimiteB()) alarmaDetectada = "BAJA (" + nm.toUpperCase() + ")";
                    if (alarmaDetectada != null) break;
                }
            }

            if (alarmaDetectada != null) {
                t.setAlarma(alarmaDetectada);
                m.setEstado(alarmaDetectada.contains("MUY") ? "ERROR" : "WARNING");
                maquinaRepository.save(m);
            } else if (!"OK".equals(m.getEstado())) {
                m.setEstado("OK");
                maquinaRepository.save(m);
            }
        }
    }
}
