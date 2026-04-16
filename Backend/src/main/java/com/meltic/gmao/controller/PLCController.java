package com.meltic.gmao.controller;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.meltic.gmao.model.nosql.Telemetria;
import com.meltic.gmao.service.PLCPollingService;
import com.meltic.gmao.service.TelemetriaService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.JsonProcessingException;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/plc")
@Tag(name = "IoT - PLC Controller", description = "Monitorización y control de telemetría de máquinas en tiempo real")
public class PLCController {

    private static final Logger logger = LoggerFactory.getLogger(PLCController.class);

    @Autowired
    private TelemetriaService telemetriaService;

    @Autowired
    private PLCPollingService plcPollingService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @PostMapping("/data")
    public ResponseEntity<?> recibirTelemetria(@RequestBody String rawJson) {
        logger.info("📦 [RAW PLC DATA]: {}", rawJson);
        
        try {
            Telemetria telemetria = objectMapper.readValue(rawJson, Telemetria.class);
            
            // Sincronizar estado de la máquina y registrar datos históricos
            plcPollingService.procesarAlertas(telemetria);
            Telemetria guardada = telemetriaService.guardar(telemetria);

            if (guardada.getRfidTag() != null && !guardada.getRfidTag().isEmpty()) {
                logger.info("📡 TAG RECONOCIDO (MAPPING OK): {}", guardada.getRfidTag());
                plcPollingService.registrarLecturaRfid(telemetria.getMaquinaId() != null ? telemetria.getMaquinaId() : 1L, guardada.getRfidTag());
            }

            return ResponseEntity.ok(guardada);
        } catch (JsonProcessingException e) {
            logger.error("❌ Error al procesar JSON del PLC: {}", e.getMessage());
            return ResponseEntity.badRequest().body("Error format: " + e.getMessage());
        }
    }

    @Operation(summary = "Obtener último ID RFID", description = "Devuelve la última lectura de tarjeta capturada por el sensor RFID del PLC para la máquina 1")
    @GetMapping("/last-rfid")
    public ResponseEntity<Map<String, Object>> obtenerUltimoRfid() {
        Map<String, Object> response = new HashMap<>();
        String rfid = plcPollingService.getLastRfidRead(1L);
        String maskedRfid = rfid.length() > 4 ? "****" + rfid.substring(rfid.length() - 4) : "****";
        response.put("rfid", rfid);
        response.put("timestamp", LocalDateTime.now()); // Timestamp simplificado
        logger.debug("Solicitud de último RFID: {} (Status: {})", maskedRfid, rfid.isEmpty() ? "VACÍO" : "DETECTADO");
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "SIMULADOR RFID (DEMO)", description = "Permite simular una lectura de tarjeta para la máquina 1")
    @GetMapping("/simulate/{tag}")
    public ResponseEntity<String> simularRfid(@PathVariable String tag) {
        logger.info("🛠️ SIMULACIÓN RFID ACTIVADA: {}", tag);
        plcPollingService.registrarLecturaRfid(1L, tag);
        return ResponseEntity.ok("Lectura simulada: " + tag);
    }

    @Operation(summary = "Historial por Máquina (SCADA Historian)",
               description = "Sin parámetros: devuelve los últimos 3600 registros (carga inicial). " +
                             "Con ?since=<epochMs>: devuelve solo los registros más nuevos que ese timestamp (polling incremental).")
    @GetMapping("/maquina/{maquinaId}")
    public ResponseEntity<List<Telemetria>> obtenerHistorial(
            @Parameter(description = "ID único de la máquina") @PathVariable Long maquinaId,
            @Parameter(description = "Epoch millis del último dato conocido. Si se provee, solo devuelve datos más nuevos.")
            @org.springframework.web.bind.annotation.RequestParam(required = false) Long since) {

        List<Telemetria> historial = (since != null)
                ? telemetriaService.obtenerDesde(maquinaId, java.time.Instant.ofEpochMilli(since))
                : telemetriaService.obtenerPorMaquina(maquinaId);

        return ResponseEntity.ok(historial);
    }

    @Operation(summary = "Histórico Multi-Escala",
               description = "Devuelve hasta 2000 puntos representativos de cualquier rango temporal (downsampling estadístico). " +
                             "Funciona para ventanas de 1 día hasta 6 meses o más. " +
                             "Equivalente al 'data compression' de PI System / Wonderware Historian.")
    @GetMapping("/maquina/{maquinaId}/historico")
    public ResponseEntity<List<Telemetria>> obtenerHistorico(
            @Parameter(description = "ID único de la máquina") @PathVariable Long maquinaId,
            @Parameter(description = "Inicio del rango en epoch millis UTC") 
            @org.springframework.web.bind.annotation.RequestParam Long desde,
            @Parameter(description = "Fin del rango en epoch millis UTC") 
            @org.springframework.web.bind.annotation.RequestParam Long hasta) {

        List<Telemetria> historico = telemetriaService.obtenerHistorico(
            maquinaId,
            java.time.Instant.ofEpochMilli(desde),
            java.time.Instant.ofEpochMilli(hasta)
        );
        return ResponseEntity.ok(historico);
    }


    @Operation(summary = "Mando de Control (IoT)", description = "Permite enviar comandos remotos como encendido/apagado de actuadores o forzado de alarmas")
    @PostMapping("/comando")
    public ResponseEntity<Map<String, String>> enviarComando(@RequestBody Map<String, String> payload) {
        String accion = payload.get("accion");
        logger.info("Comando recibido: {}", accion);

        if ("START_MOTOR".equals(accion)) {
            logger.info("Comando START_MOTOR recibido (No action taken in multi-machine model)");
        } else if ("STOP_MOTOR".equals(accion)) {
            logger.info("Comando STOP_MOTOR recibido (No action taken in multi-machine model)");
        } else if ("FORCE_ALARM".equals(accion)) {
            logger.info("Comando FORCE_ALARM recibido (No action taken in multi-machine model)");
        }

        Map<String, String> response = new HashMap<>();
        response.put("status", "ok");
        response.put("mensaje", "Comando " + accion + " procesado");
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "MOCK PLC (INTERNAL)", description = "Endpoint para simular un PLC físico para el TFG")
    @GetMapping("/mock")
    public ResponseEntity<Map<String, Object>> mockPlc() {
        Map<String, Object> data = new HashMap<>();
        data.put("maquinaId", 1);
        data.put("temperatura", 25.5 + Math.random() * 5);
        data.put("humedad", 45.0 + Math.random() * 10);
        data.put("vibracion", 0.5 + Math.random() * 1);
        data.put("rfidTag", "40:91:F3:61"); // Tag de ejemplo para el TFG
        data.put("motorOn", true);
        return ResponseEntity.ok(data);
    }
}
