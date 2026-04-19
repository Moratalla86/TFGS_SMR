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
}
