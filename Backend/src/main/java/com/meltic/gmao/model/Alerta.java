package com.meltic.gmao.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "alertas")
public class Alerta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long maquinaId;
    private String maquinaNombre;
    private String severidad; // INFO, WARNING, CRITICAL
    private String descripcion;
    private LocalDateTime timestamp;
    private boolean activa;

    public Alerta() {}

    public Alerta(Long maquinaId, String maquinaNombre, String severidad, String descripcion) {
        this.maquinaId = maquinaId;
        this.maquinaNombre = maquinaNombre;
        this.severidad = severidad;
        this.descripcion = descripcion;
        this.timestamp = LocalDateTime.now();
        this.activa = true;
    }

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getMaquinaId() { return maquinaId; }
    public void setMaquinaId(Long maquinaId) { this.maquinaId = maquinaId; }

    public String getMaquinaNombre() { return maquinaNombre; }
    public void setMaquinaNombre(String maquinaNombre) { this.maquinaNombre = maquinaNombre; }

    public String getSeveridad() { return severidad; }
    public void setSeveridad(String severidad) { this.severidad = severidad; }

    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }

    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }

    public boolean isActiva() { return activa; }
    public void setActiva(boolean activa) { this.activa = activa; }
}
