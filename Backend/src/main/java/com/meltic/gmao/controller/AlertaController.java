package com.meltic.gmao.controller;

import com.meltic.gmao.model.Alerta;
import com.meltic.gmao.service.AlertaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/alertas")
public class AlertaController {

    @Autowired
    private AlertaService alertaService;

    @GetMapping("/activas")
    public List<Alerta> obtenerActivas() {
        return alertaService.getAlertasActivas();
    }

    @GetMapping("/activas/count")
    public ResponseEntity<?> obtenerCount() {
        return ResponseEntity.ok(Map.of("count", alertaService.getCountActivas()));
    }

    @PostMapping("/forzar")
    public ResponseEntity<?> forzarAlerta(@RequestBody Map<String, Object> body) {
        Long maquinaId = ((Number) body.get("maquinaId")).longValue();
        String maquinaNombre = (String) body.getOrDefault("maquinaNombre", "Máquina desconocida");
        String severidad     = (String) body.getOrDefault("severidad",    "CRITICAL");
        String descripcion   = (String) body.getOrDefault("descripcion",  "Alarma forzada manualmente [DEMO]");
        alertaService.registrarAlerta(maquinaId, maquinaNombre, severidad, descripcion);
        return ResponseEntity.ok(Map.of("message", "Alarma forzada correctamente"));
    }
}
