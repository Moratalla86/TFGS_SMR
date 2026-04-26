package com.meltic.gmao.controller;

import com.meltic.gmao.model.FcmToken;
import com.meltic.gmao.repository.sql.FcmTokenRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/fcm")
public class FcmTokenController {

    @Autowired
    private FcmTokenRepository tokenRepository;

    @PostMapping("/token")
    public ResponseEntity<?> registrarToken(@RequestBody Map<String, Object> body) {
        Object rawId = body.get("usuarioId");
        if (rawId == null) return ResponseEntity.badRequest().body("usuarioId requerido");
        Long usuarioId = ((Number) rawId).longValue();
        String token = (String) body.get("token");

        if (token == null || token.isEmpty()) {
            return ResponseEntity.badRequest().body("Token inválido");
        }

        Optional<FcmToken> existing = tokenRepository.findByToken(token);
        if (existing.isPresent()) {
            FcmToken f = existing.get();
            f.setUsuarioId(usuarioId);
            tokenRepository.save(f);
        } else {
            tokenRepository.save(new FcmToken(usuarioId, token));
        }

        return ResponseEntity.ok(Map.of("message", "Token registrado correctamente"));
    }

    @DeleteMapping("/token")
    public ResponseEntity<?> eliminarToken(@RequestBody Map<String, String> body) {
        String token = body.get("token");
        tokenRepository.findByToken(token).ifPresent(t -> tokenRepository.delete(java.util.Objects.requireNonNull(t)));
        return ResponseEntity.ok().build();
    }
}
