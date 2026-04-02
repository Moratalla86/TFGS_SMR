package com.meltic.gmao.controller;

import com.meltic.gmao.model.Maquina;
import com.meltic.gmao.repository.sql.MaquinaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/maquinas")
@CrossOrigin(origins = "*")
public class MaquinaController {

    @Autowired
    private MaquinaRepository maquinaRepository;

    // Obtener todas las máquinas (Para el listado en Flutter)
    @GetMapping
    public List<Maquina> obtenerTodas() {
        return maquinaRepository.findAll();
    }

    // Crear una nueva máquina
    @PostMapping
    public ResponseEntity<Maquina> crear(@RequestBody Maquina maquina) {
        if (maquina == null) return ResponseEntity.badRequest().build();
        Maquina nuevaMaquina = maquinaRepository.save(maquina);
        return ResponseEntity.ok(nuevaMaquina);
    }

    // Opcional: Obtener una por ID
    @GetMapping("/{id}")
    public ResponseEntity<Maquina> obtenerPorId(@PathVariable Long id) {
        if (id == null) return ResponseEntity.badRequest().build();
        Optional<Maquina> opt = maquinaRepository.findById(id);
        return opt
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<Maquina> actualizar(@PathVariable Long id, @RequestBody Maquina maquinaDetalles) {
        if (id == null || maquinaDetalles == null) return ResponseEntity.badRequest().build();
        return maquinaRepository.findById(id)
                .map(maquina -> {
                    maquina.setEstado(maquinaDetalles.getEstado());
                    
                    // Actualizar configuraciones de métricas (Deep Update)
                    if (maquina.getConfigs() != null) {
                        maquina.getConfigs().clear();
                    }
                    if (maquinaDetalles.getConfigs() != null) {
                        for (com.meltic.gmao.model.MetricConfig config : maquinaDetalles.getConfigs()) {
                            maquina.addConfig(config);
                        }
                    }
                    
                    Maquina actualizada = maquinaRepository.save(maquina);
                    return ResponseEntity.ok(actualizada);
                })
                .orElse(ResponseEntity.notFound().build());
    }
}