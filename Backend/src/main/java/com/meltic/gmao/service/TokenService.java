package com.meltic.gmao.service;

import com.meltic.gmao.model.Usuario;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class TokenService {

    private static final long TOKEN_EXPIRY_HOURS = 8; // Duración de un turno de trabajo

    private record TokenEntry(Usuario usuario, Instant expiry) {}

    private final Map<String, TokenEntry> tokens = new ConcurrentHashMap<>();

    public String generateToken(Usuario usuario) {
        String token = UUID.randomUUID().toString();
        tokens.put(token, new TokenEntry(usuario, Instant.now().plus(TOKEN_EXPIRY_HOURS, ChronoUnit.HOURS)));
        return token;
    }

    public Usuario getUsuarioByToken(String token) {
        TokenEntry entry = tokens.get(token);
        if (entry == null) return null;
        if (Instant.now().isAfter(entry.expiry())) {
            tokens.remove(token);
            return null;
        }
        return entry.usuario();
    }

    public void removeToken(String token) {
        tokens.remove(token);
    }

    // Limpieza periódica para evitar memory leak con tokens expirados
    @Scheduled(fixedRate = 3_600_000) // cada hora
    public void limpiarTokensExpirados() {
        tokens.entrySet().removeIf(e -> Instant.now().isAfter(e.getValue().expiry()));
    }
}
