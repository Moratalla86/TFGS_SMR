package com.meltic.gmao.controller;

import com.meltic.gmao.model.Maquina;
import com.meltic.gmao.repository.sql.MaquinaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/maquinas")
public class MaquinaController {

    @Autowired
    private MaquinaRepository maquinaRepository;

    // Obtener todas las máquinas (Lo usaremos en Flutter para el listado)
    @GetMapping
    public List<Maquina> obtenerTodas() {
        return maquinaRepository.findAll();
    }

    // Crear una nueva máquina (Para pruebas iniciales)
    @PostMapping
    public Maquina crear(@RequestBody Maquina maquina) {
        return maquinaRepository.save(maquina);
    }
}