package com.meltic.gmao.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.meltic.gmao.model.Usuario;
import com.meltic.gmao.repository.sql.OrdenTrabajoRepository;
import com.meltic.gmao.repository.sql.UsuarioRepository;

@RestController
@RequestMapping("/api/usuarios")
@CrossOrigin(origins = "*")
public class UsuarioController {

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private OrdenTrabajoRepository ordenTrabajoRepository;

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    // ── Listar todos ────────────────────────────────────────────────────────────
    @GetMapping
    public List<Usuario> obtenerTodos() {
        return usuarioRepository.findAll();
    }

    // ── Crear usuario (genera email corporativo automáticamente) ────────────────
    @PostMapping
    public ResponseEntity<Usuario> crear(@RequestBody Usuario usuario) {
        // Generar email corporativo: inicial_nombre + apellido1 + @meltic.com
        String emailCorp = generarEmailCorporativo(usuario.getNombre(), usuario.getApellido1());
        usuario.setEmail(emailCorp);

        // Si no viene username, usar el email corporativo
        if (usuario.getUsername() == null || usuario.getUsername().isBlank()) {
            usuario.setUsername(emailCorp);
        }

        // Cifrar contraseña
        if (usuario.getPassword() != null && !usuario.getPassword().isBlank()) {
            usuario.setPassword(encoder.encode(usuario.getPassword()));
        }

        usuario.setActivo(true);
        return ResponseEntity.ok(usuarioRepository.save(usuario));
    }

    // ── Actualizar usuario ──────────────────────────────────────────────────────
    @PutMapping("/{id}")
    public ResponseEntity<Usuario> actualizar(@PathVariable Long id, @RequestBody Usuario datos) {
        return usuarioRepository.findById(id)
                .map(u -> {
                    u.setNombre(datos.getNombre());
                    u.setApellido1(datos.getApellido1());
                    u.setApellido2(datos.getApellido2());
                    u.setTelefonoPersonal(datos.getTelefonoPersonal());
                    u.setTelefonoProfesional(datos.getTelefonoProfesional());
                    u.setEmailPersonal(datos.getEmailPersonal());
                    u.setRol(datos.getRol());
                    u.setActivo(datos.isActivo());
                    u.setRfidTag(datos.getRfidTag());

                    // Re-generar email corporativo si cambian nombre/apellido
                    String emailCorp = generarEmailCorporativo(datos.getNombre(), datos.getApellido1());
                    u.setEmail(emailCorp);
                    u.setUsername(emailCorp);

                    // Sólo actualizar contraseña si viene una nueva
                    if (datos.getPassword() != null && !datos.getPassword().isBlank()) {
                        u.setPassword(encoder.encode(datos.getPassword()));
                    }

                    return ResponseEntity.ok(usuarioRepository.save(u));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Eliminar usuario ────────────────────────────────────────────────────────
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        if (!usuarioRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        // Desasignar al técnico de todas sus OTs antes de borrarlo (evita FK
        // constraint)
        ordenTrabajoRepository.findByTecnicoId(id).forEach(ot -> {
            ot.setTecnico(null);
            ordenTrabajoRepository.save(ot);
        });
        usuarioRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // ── Cambiar estado activo/inactivo ──────────────────────────────────────────
    @PatchMapping("/{id}/estado")
    public ResponseEntity<Usuario> cambiarEstado(@PathVariable Long id, @RequestParam boolean activo) {
        return usuarioRepository.findById(id)
                .map(u -> {
                    u.setActivo(activo);
                    return ResponseEntity.ok(usuarioRepository.save(u));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Buscar por RFID ─────────────────────────────────────────────────────────
    @GetMapping("/rfid/{tag}")
    public ResponseEntity<Usuario> obtenerPorRfid(@PathVariable String tag) {
        return usuarioRepository.findByRfidTag(tag)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Helper: genera email corporativo ────────────────────────────────────────
    private String generarEmailCorporativo(String nombre, String apellido1) {
        if (nombre == null || nombre.isBlank() || apellido1 == null || apellido1.isBlank())
            return "usuario@meltic.com";
        String inicial = nombre.trim().substring(0, 1);
        String ap1 = apellido1.trim().replaceAll("\\s+", "");
        return (inicial + ap1).toLowerCase() + "@meltic.com";
    }
}