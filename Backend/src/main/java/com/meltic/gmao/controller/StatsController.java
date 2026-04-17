package com.meltic.gmao.controller;

import com.meltic.gmao.service.StatsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/stats")
@CrossOrigin(origins = "*")
@Tag(name = "Estadísticas GMAO", description = "KPIs industriales: OEE, MTBF, MTTR, disponibilidad, evolución mensual")
public class StatsController {

    @Autowired
    private StatsService statsService;

    @Operation(
        summary     = "KPIs del dashboard industrial",
        description = "Devuelve OEE, MTBF, MTTR, disponibilidad, ratio preventivo/correctivo, " +
                      "distribución de OTs por estado, ranking de incidencias y evolución mensual"
    )
    @GetMapping("/dashboard")
    public ResponseEntity<Map<String, Object>> getDashboardStats() {
        return ResponseEntity.ok(statsService.getDashboardStats());
    }
}
