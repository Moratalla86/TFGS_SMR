package com.meltic.gmao.controller;

import com.meltic.gmao.model.Maquina;
import com.meltic.gmao.repository.sql.MaquinaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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
        Maquina nuevaMaquina = maquinaRepository.save(maquina);
        return ResponseEntity.ok(nuevaMaquina);
    }

    // Opcional: Obtener una por ID
    @GetMapping("/{id}")
    public ResponseEntity<Maquina> obtenerPorId(@PathVariable Long id) {
        return maquinaRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}