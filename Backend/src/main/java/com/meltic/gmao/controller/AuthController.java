package com.meltic.gmao.controller;

import com.meltic.gmao.repository.sql.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    @Autowired
    private UsuarioRepository usuarioRepo;

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        final String email = credentials.get("email");
        final String password = credentials.get("password");

        logger.info("Tentativa de login para email: {}", email);

        return usuarioRepo.findByEmail(email)
                .map(user -> {
                    boolean matches = encoder.matches(password, user.getPassword());
                    if (matches) {
                        logger.info("Login exitoso para: {}", email);
                        return ResponseEntity.ok(user);
                    } else {
                        logger.warn("Contraseña incorrecta para: {}", email);
                        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
                    }
                })
                .orElseGet(() -> {
                    logger.warn("Usuario no encontrado: {}", email);
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
                });
    }

    @PostMapping("/rfid-login")
    public ResponseEntity<?> loginWithRfid(@RequestBody Map<String, String> body) {
        String rawTag = body.get("rfidTag");
        final String rfidTag = (rawTag != null) ? rawTag.trim() : "";
        
        logger.info("Tentativa de login RFID para tag: {}", rfidTag);
        
        if (rfidTag.isEmpty()) {
            return ResponseEntity.badRequest().body("RFID tag is required");
        }

        return usuarioRepo.findByRfidTag(rfidTag)
                .map(user -> {
                    logger.info("Login RFID exitoso para usuario: {}", user.getEmail());
                    return ResponseEntity.ok(user);
                })
                .orElseGet(() -> {
                    logger.warn("Tarjeta RFID no vinculada: {}", rfidTag);
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
                });
    }
}