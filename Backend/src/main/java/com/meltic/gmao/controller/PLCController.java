package com.meltic.gmao.controller;

import com.meltic.gmao.model.nosql.Telemetria;
import com.meltic.gmao.service.TelemetriaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/plc")
@CrossOrigin(origins = "*")
public class PLCController {

    @Autowired
    private TelemetriaService telemetriaService;

    @PostMapping("/data")
    public ResponseEntity<Telemetria> recibirTelemetria(@RequestBody Telemetria telemetria) {
        Telemetria guardada = telemetriaService.guardar(telemetria);
        System.out.println("Telemetría recibida de máquina: " + guardada.getMaquinaId());
        return ResponseEntity.ok(guardada);
    }

    @GetMapping("/maquina/{maquinaId}")
    public ResponseEntity<List<Telemetria>> obtenerHistorial(@PathVariable Long maquinaId) {
        List<Telemetria> historial = telemetriaService.obtenerPorMaquina(maquinaId);
        return ResponseEntity.ok(historial);
    }
}
