package com.meltic.gmao.service;

import com.meltic.gmao.model.Usuario;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class TokenService {
    // Mapa de Token -> Usuario
    private final Map<String, Usuario> tokens = new ConcurrentHashMap<>();

    public String generateToken(Usuario usuario) {
        String token = UUID.randomUUID().toString();
        tokens.put(token, usuario);
        return token;
    }

    public Usuario getUsuarioByToken(String token) {
        return tokens.get(token);
    }

    public void removeToken(String token) {
        tokens.remove(token);
    }
}
