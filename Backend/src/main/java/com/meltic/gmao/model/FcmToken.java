package com.meltic.gmao.model;

import jakarta.persistence.*;

@Entity
@Table(name = "fcm_tokens")
public class FcmToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long usuarioId;
    
    @Column(unique = true, length = 512)
    private String token;

    public FcmToken() {}

    public FcmToken(Long usuarioId, String token) {
        this.usuarioId = usuarioId;
        this.token = token;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUsuarioId() { return usuarioId; }
    public void setUsuarioId(Long usuarioId) { this.usuarioId = usuarioId; }

    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }
}
