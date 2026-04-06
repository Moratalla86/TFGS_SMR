package com.meltic.gmao.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
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
import io.swagger.v3.oas.annotations.responses.ApiResponse;
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
                plcPollingService.registrarLecturaRfid(guardada.getRfidTag());
            }

            return ResponseEntity.ok(guardada);
        } catch (JsonProcessingException e) {
            logger.error("❌ Error al procesar JSON del PLC: {}", e.getMessage());
            return ResponseEntity.badRequest().body("Error format: " + e.getMessage());
        }
    }

    @Operation(summary = "Obtener último ID RFID", description = "Devuelve la última lectura de tarjeta capturada por el sensor RFID del PLC")
    @GetMapping("/last-rfid")
    public ResponseEntity<Map<String, Object>> obtenerUltimoRfid() {
        Map<String, Object> response = new HashMap<>();
        String rfid = plcPollingService.getLastRfidRead();
        String maskedRfid = rfid.length() > 4 ? "****" + rfid.substring(rfid.length() - 4) : "****";
        response.put("rfid", rfid);
        response.put("timestamp", plcPollingService.getLastRfidTimestamp());
        logger.debug("Solicitud de último RFID: {} (Status: {})", maskedRfid, rfid.isEmpty() ? "VACÍO" : "DETECTADO");
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "SIMULADOR RFID (DEMO)", description = "Permite simular una lectura de tarjeta sin necesidad del hardware PLC")
    @GetMapping("/simulate/{tag}")
    public ResponseEntity<String> simularRfid(@PathVariable String tag) {
        logger.info("🛠️ SIMULACIÓN RFID ACTIVADA: {}", tag);
        plcPollingService.registrarLecturaRfid(tag);
        return ResponseEntity.ok("Lectura simulada: " + tag);
    }

    @Operation(summary = "Historial por Máquina", description = "Obtiene la serie temporal de telemetrías (MongoDB) para una máquina específica")
    @GetMapping("/maquina/{maquinaId}")
    public ResponseEntity<List<Telemetria>> obtenerHistorial(
            @Parameter(description = "ID único de la máquina (Relacional)") @PathVariable Long maquinaId) {
        List<Telemetria> historial = telemetriaService.obtenerPorMaquina(maquinaId);
        return ResponseEntity.ok(historial);
    }

    @Operation(summary = "Mando de Control (IoT)", description = "Permite enviar comandos remotos como encendido/apagado de actuadores o forzado de alarmas")
    @PostMapping("/comando")
    public ResponseEntity<Map<String, String>> enviarComando(@RequestBody Map<String, String> payload) {
        String accion = payload.get("accion");
        logger.info("Comando recibido: {}", accion);

        if ("START_MOTOR".equals(accion)) {
            plcPollingService.setMotorOnSimulated(true);
        } else if ("STOP_MOTOR".equals(accion)) {
            plcPollingService.setMotorOnSimulated(false);
        } else if ("FORCE_ALARM".equals(accion)) {
            plcPollingService.forceAlarmSimulated(payload.get("tipo"));
        }

        Map<String, String> response = new HashMap<>();
        response.put("status", "ok");
        response.put("mensaje", "Comando " + accion + " procesado");
        return ResponseEntity.ok(response);
    }
}
