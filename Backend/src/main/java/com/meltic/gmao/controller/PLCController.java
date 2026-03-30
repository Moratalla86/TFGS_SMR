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

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/plc")
@CrossOrigin(origins = "*")
@Tag(name = "IoT - PLC Controller", description = "Monitorización y control de telemetría de máquinas en tiempo real")
public class PLCController {

    private static final Logger logger = LoggerFactory.getLogger(PLCController.class);

    @Autowired
    private TelemetriaService telemetriaService;

    @Autowired
    private PLCPollingService plcPollingService;

    @Operation(summary = "Recepción de Telemetría", description = "Endpoint crítico donde el Hardware (Controllino) envía los datos de sensores y estado. Los datos se almacenan en MongoDB.")
    @ApiResponse(responseCode = "200", description = "Telemetría procesada y almacenada satisfactoriamente")
    @PostMapping("/data")
    public ResponseEntity<Telemetria> recibirTelemetria(@RequestBody Telemetria telemetria) {
        // Sincronizar estado de la máquina y registrar datos históricos
        plcPollingService.procesarAlertas(telemetria);
        Telemetria guardada = telemetriaService.guardar(telemetria);

        if (guardada.getRfidTag() != null && !guardada.getRfidTag().isEmpty()) {
            plcPollingService.registrarLecturaRfid(guardada.getRfidTag());
        }

        logger.info("Telemetría recibida de máquina: {}", guardada.getMaquinaId());
        return ResponseEntity.ok(guardada);
    }

    @Operation(summary = "Obtener último ID RFID", description = "Devuelve la última lectura de tarjeta capturada por el sensor RFID del PLC")
    @GetMapping("/last-rfid")
    public ResponseEntity<Map<String, Object>> obtenerUltimoRfid() {
        Map<String, Object> response = new HashMap<>();
        response.put("rfid", plcPollingService.getLastRfidRead());
        response.put("timestamp", plcPollingService.getLastRfidTimestamp());
        return ResponseEntity.ok(response);
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
