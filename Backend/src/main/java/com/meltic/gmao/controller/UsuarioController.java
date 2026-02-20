package com.meltic.gmao.controller;

import com.meltic.gmao.model.Usuario;
import com.meltic.gmao.repository.sql.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/usuarios")
@CrossOrigin(origins = "*")
public class UsuarioController {

    @Autowired
    private UsuarioRepository usuarioRepository;

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    // Listar todos los usuarios
    @GetMapping
    public List<Usuario> obtenerTodos() {
        return usuarioRepository.findAll();
    }

    // Crear un nuevo usuario (Cifrando la contraseña)
    @PostMapping
    public ResponseEntity<Usuario> crear(@RequestBody Usuario usuario) {
        // Ciframos la contraseña antes de guardar
        usuario.setPassword(encoder.encode(usuario.getPassword()));

        Usuario nuevoUsuario = usuarioRepository.save(usuario);
        return ResponseEntity.ok(nuevoUsuario);
    }

    // Buscar usuario por RFID (Clave para el Controllino/App)
    @GetMapping("/rfid/{tag}")
    public ResponseEntity<Usuario> obtenerPorRfid(@PathVariable String tag) {
        return usuarioRepository.findByRfidTag(tag)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Actualizar estado (Activo/Inactivo)
    @PatchMapping("/{id}/estado")
    public ResponseEntity<Usuario> cambiarEstado(@PathVariable Long id, @RequestParam boolean activo) {
        return usuarioRepository.findById(id)
                .map(usuario -> {
                    usuario.setActivo(activo);
                    return ResponseEntity.ok(usuarioRepository.save(usuario));
                })
                .orElse(ResponseEntity.notFound().build());
    }
}