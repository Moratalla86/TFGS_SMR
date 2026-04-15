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
import com.meltic.gmao.model.MetricConfig;
import com.meltic.gmao.repository.sql.MaquinaRepository;

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

    @Operation(summary = "Actualizar Configuración Meltic", description = "Sincroniza los límites Muy Alto, Alto, Bajo, Muy Bajo para una máquina.")
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

        if (payload.containsKey("muyAlto") || payload.containsKey("alto") ||
            payload.containsKey("bajo") || payload.containsKey("muyBajo")) {

            Double muyAlto = safeParseDouble(payload.get("muyAlto"));
            Double alto    = safeParseDouble(payload.get("alto"));
            Double bajo    = safeParseDouble(payload.get("bajo"));
            Double muyBajo = safeParseDouble(payload.get("muyBajo"));

            if (!esConfigValida(muyBajo, bajo, alto, muyAlto)) {
                return ResponseEntity.badRequest().build();
            }

            maquina.getConfigs().stream()
                .filter(c -> "temperatura".equals(c.getNombreMetrica()))
                .findFirst()
                .ifPresent(config -> {
                    if (muyAlto != null) config.setLimiteMA(muyAlto);
                    if (alto != null)    config.setLimiteA(alto);
                    if (bajo != null)    config.setLimiteB(bajo);
                    if (muyBajo != null) config.setLimiteMB(muyBajo);
                });
        }

        if (payload.containsKey("releForzado")) {
            logger.debug("Rele forzado recibido pero ignorado en modo multi-simulación");
        }

        maquinaRepository.save(maquina);
        logger.info("Sincronización Meltic 4.0 aplicada en equipo: {}", maquina.getNombre());
        return ResponseEntity.ok(maquina);
    }

    /** Valida que los umbrales sean coherentes: muyBajo <= bajo <= alto <= muyAlto */
    private boolean esConfigValida(Double muyBajo, Double bajo, Double alto, Double muyAlto) {
        if (muyBajo != null && bajo != null && muyBajo > bajo) return false;
        if (bajo != null && alto != null && bajo > alto) return false;
        if (alto != null && muyAlto != null && alto > muyAlto) return false;
        return true;
    }

    private Double safeParseDouble(Object value) {
        if (value == null) return null;
        try {
            return Double.valueOf(value.toString());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
