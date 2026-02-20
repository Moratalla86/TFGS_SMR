package com.meltic.gmao.controller;

import com.meltic.gmao.model.Usuario;
import com.meltic.gmao.repository.sql.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map; // Muy importante para el @RequestBody Map

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*") // Para que Flutter Web no de problemas
public class AuthController {

    @Autowired
    private UsuarioRepository usuarioRepo;

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        String email = credentials.get("email");
        String password = credentials.get("password");

        return usuarioRepo. findByEmail(email)
                .filter(user -> encoder.matches(password, user.getPassword())) // Compara Hash
                .map(user -> ResponseEntity.ok(user)) // Login correcto
                .orElse(ResponseEntity.status(HttpStatus.UNAUTHORIZED).build()); // Login fallo
    }
}