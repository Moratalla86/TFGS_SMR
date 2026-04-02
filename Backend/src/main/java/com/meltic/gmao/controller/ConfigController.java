package com.meltic.gmao.controller;

import java.util.Map;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.meltic.gmao.model.Maquina;
import com.meltic.gmao.repository.sql.MaquinaRepository;
import com.meltic.gmao.service.PLCPollingService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/config")
@CrossOrigin(origins = "*")
@Tag(name = "IoT - Configuración de Consignas", description = "Gestión de los umbrales de alarmas del Gemelo Digital (Módulo de Control Activo)")
public class ConfigController {

    private static final Logger logger = LoggerFactory.getLogger(ConfigController.class);

    @Autowired
    private MaquinaRepository maquinaRepository;

    @Autowired
    private PLCPollingService plcPollingService;

    @Operation(summary = "Actualizar Configuración Meltic", description = "Sincroniza los límites Muy Alto, Alto, Bajo, Muy Bajo y fuerza el relé de control para una máquina.")
    @PutMapping("/{maquinaId}")
    public ResponseEntity<Maquina> updateConfig(
            @PathVariable Long maquinaId,
            @RequestBody Map<String, Object> payload) {

        if (maquinaId == null) return ResponseEntity.badRequest().build();
        Optional<Maquina> optMaquina = maquinaRepository.findById(maquinaId);
        if (optMaquina.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Maquina maquina = optMaquina.get();

        // Si hay cambios en los límites, los aplicamos a la métrica "temperatura" por defecto
        if (payload.containsKey("muyAlto") || payload.containsKey("alto") || 
            payload.containsKey("bajo") || payload.containsKey("muyBajo")) {
            
            maquina.getConfigs().stream()
                .filter(c -> "temperatura".equals(c.getNombreMetrica()))
                .findFirst()
                .ifPresent(config -> {
                    if (payload.containsKey("muyAlto")) config.setLimiteMA(safeParseDouble(payload.get("muyAlto")));
                    if (payload.containsKey("alto")) config.setLimiteA(safeParseDouble(payload.get("alto")));
                    if (payload.containsKey("bajo")) config.setLimiteB(safeParseDouble(payload.get("bajo")));
                    if (payload.containsKey("muyBajo")) config.setLimiteMB(safeParseDouble(payload.get("muyBajo")));
                });
        }

        if (payload.containsKey("releForzado")) {
            boolean rele = Boolean.parseBoolean(payload.get("releForzado").toString());
            // Transmitir al PLC usando el servicio real
            plcPollingService.setMotorOnSimulated(rele);
        }

        java.util.Optional.ofNullable(maquinaRepository.save(maquina))
                .orElseThrow(() -> new RuntimeException("Error al guardar la configuración de la máquina"));
        logger.info("Sincronización Meltic 4.0 aplicada en equipo: {}", maquina.getNombre());

        return ResponseEntity.ok(maquina);
    }

    private Double safeParseDouble(Object value) {
        if (value == null)
            return null;
        try {
            return Double.valueOf(value.toString());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
