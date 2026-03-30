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

        Optional<Maquina> optMaquina = maquinaRepository.findById(maquinaId);
        if (optMaquina.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Maquina maquina = optMaquina.get();

        if (payload.containsKey("muyAlto")) {
            maquina.setLimiteMA(safeParseDouble(payload.get("muyAlto")));
        }
        if (payload.containsKey("alto")) {
            maquina.setLimiteA(safeParseDouble(payload.get("alto")));
        }
        if (payload.containsKey("bajo")) {
            maquina.setLimiteB(safeParseDouble(payload.get("bajo")));
        }
        if (payload.containsKey("muyBajo")) {
            maquina.setLimiteMB(safeParseDouble(payload.get("muyBajo")));
        }
        if (payload.containsKey("releForzado")) {
            boolean rele = Boolean.parseBoolean(payload.get("releForzado").toString());
            // Transmitir al PLC usando el servicio real
            plcPollingService.setMotorOnSimulated(rele);
        }

        maquinaRepository.save(maquina);
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
