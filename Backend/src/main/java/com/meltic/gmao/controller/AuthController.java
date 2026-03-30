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

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.responses.ApiResponse;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
@Tag(name = "Seguridad - Autenticación", description = "Endpoints para el control de acceso mediante credenciales y RFID")
public class AuthController {

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    @Autowired
    private UsuarioRepository usuarioRepo;

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @Operation(summary = "Login con Credenciales", description = "Permite el acceso al sistema mediante email y contraseña (bcrypt)")
    @ApiResponse(responseCode = "200", description = "Usuario autenticado con éxito")
    @ApiResponse(responseCode = "401", description = "Credenciales inválidas")
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

    @Operation(summary = "Login mediante RFID", description = "Permite el acceso rápido escaneando una tarjeta física vinculada a un usuario")
    @ApiResponse(responseCode = "200", description = "Usuario identificado con éxito")
    @ApiResponse(responseCode = "401", description = "Tarjeta no vinculada o inválida")
    @PostMapping("/rfid-login")
    public ResponseEntity<?> loginWithRfid(@RequestBody Map<String, String> body) {
        String rawTag = body.get("rfidTag");
        final String rfidTag = (rawTag != null) ? rawTag.trim().toUpperCase() : "";

        // --- Validación de seguridad server-side ---
        // Rechazar valores vacíos, placeholders del firmware y tags sin formato hex (xx:xx:xx...)
        final java.util.Set<String> INVALID_TAGS = java.util.Set.of(
            "", "N/A", "NULL", "NINGUNA TARJETA DETECTADA", "UNDEFINED"
        );
        if (INVALID_TAGS.contains(rfidTag) || !rfidTag.contains(":")) {
            logger.warn("Intento de login RFID con tag inválido o de firmware: '{}'", rfidTag);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("RFID tag inválido");
        }

        logger.info("Tentativa de login RFID para tag: {}", rfidTag);

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