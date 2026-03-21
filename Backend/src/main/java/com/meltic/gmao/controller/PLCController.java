package com.meltic.gmao.controller;

import com.meltic.gmao.model.nosql.Telemetria;
import com.meltic.gmao.service.TelemetriaService;
import com.meltic.gmao.service.PLCPollingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/plc")
@CrossOrigin(origins = "*")
public class PLCController {

    @Autowired
    private TelemetriaService telemetriaService;

    @Autowired
    private PLCPollingService plcPollingService;

    @PostMapping("/data")
    public ResponseEntity<Telemetria> recibirTelemetria(@RequestBody Telemetria telemetria) {
        Telemetria guardada = telemetriaService.guardar(telemetria);
        System.out.println("Telemetría recibida de máquina: " + guardada.getMaquinaId());
        return ResponseEntity.ok(guardada);
    }

    @GetMapping("/last-rfid")
    public ResponseEntity<Map<String, Object>> obtenerUltimoRfid() {
        Map<String, Object> response = new HashMap<>();
        response.put("rfid", plcPollingService.getLastRfidRead());
        response.put("timestamp", plcPollingService.getLastRfidTimestamp());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/maquina/{maquinaId}")
    public ResponseEntity<List<Telemetria>> obtenerHistorial(@PathVariable Long maquinaId) {
        List<Telemetria> historial = telemetriaService.obtenerPorMaquina(maquinaId);
        return ResponseEntity.ok(historial);
    }
}
