package com.meltic.gmao.controller;

import com.meltic.gmao.repository.sql.UsuarioRepository;
import com.meltic.gmao.service.TokenService;
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
@Tag(name = "Seguridad - Autenticación", description = "Endpoints para el control de acceso mediante credenciales y RFID")
public class AuthController {

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    @Autowired
    private UsuarioRepository usuarioRepo;

    @Autowired
    private TokenService tokenService;

    @Autowired
    private BCryptPasswordEncoder encoder;

    /** DTO para la respuesta de login — no expone password ni rfidTag */
    record UserResponseDto(Long id, String nombre, String apellido1, String email, String rol, boolean activo) {}

    @Operation(summary = "Login con Credenciales", description = "Permite el acceso al sistema mediante email y contraseña (bcrypt)")
    @ApiResponse(responseCode = "200", description = "Usuario autenticado con éxito")
    @ApiResponse(responseCode = "401", description = "Credenciales inválidas o usuario inactivo")
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        final String email = credentials.get("email");
        final String password = credentials.get("password");

        logger.info("Tentativa de login para email: {}", email);

        return usuarioRepo.findByEmail(email)
                .map(user -> {
                    if (!user.isActivo()) {
                        logger.warn("Login denegado para usuario inactivo: {}", email);
                        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
                    }
                    boolean matches = encoder.matches(password, user.getPassword());
                    if (matches) {
                        logger.info("Login exitoso para: {}", email);
                        String token = tokenService.generateToken(user);
                        UserResponseDto dto = new UserResponseDto(
                            user.getId(), user.getNombre(), user.getApellido1(),
                            user.getEmail(), user.getRol(), user.isActivo());
                        return ResponseEntity.ok(Map.of("user", dto, "token", token));
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
    @ApiResponse(responseCode = "401", description = "Tarjeta no vinculada, inválida o usuario inactivo")
    @PostMapping("/rfid-login")
    public ResponseEntity<?> loginWithRfid(@RequestBody Map<String, String> body) {
        String rawTag = body.get("rfidTag");
        final String rfidTag = (rawTag != null) ? rawTag.trim().toUpperCase() : "";

        final java.util.Set<String> INVALID_TAGS = java.util.Set.of(
            "", "N/A", "NULL", "NINGUNA TARJETA DETECTADA", "UNDEFINED"
        );
        if (INVALID_TAGS.contains(rfidTag) || !rfidTag.contains(":")) {
            logger.warn("Intento de login RFID con tag inválido o de firmware: '{}'", rfidTag);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("RFID tag inválido");
        }

        logger.info("Tentativa de login RFID para tag: {}", rfidTag);

        return usuarioRepo.findByRfidTagIgnoreCase(rfidTag)
                .map(user -> {
                    if (!user.isActivo()) {
                        logger.warn("Login RFID denegado para usuario inactivo: {}", user.getEmail());
                        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
                    }
                    logger.info("Login RFID exitoso para usuario: {}", user.getEmail());
                    String token = tokenService.generateToken(user);
                    UserResponseDto dto = new UserResponseDto(
                        user.getId(), user.getNombre(), user.getApellido1(),
                        user.getEmail(), user.getRol(), user.isActivo());
                    return ResponseEntity.ok(Map.of("user", dto, "token", token));
                })
                .orElseGet(() -> {
                    logger.warn("Tarjeta RFID no vinculada: {}", rfidTag);
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
                });
    }
}
