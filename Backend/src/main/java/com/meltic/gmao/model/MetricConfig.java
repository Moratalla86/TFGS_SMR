package com.meltic.gmao.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

@Entity
@Table(name = "metric_configs")
public class MetricConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String nombreMetrica; // ej: "temperatura", "humedad", "presion"
    private String unidadSeleccionada; // ej: "°C", "°F", "Bar", "PSI"
    
    private Double limiteMB; // Muy Bajo
    private Double limiteB;  // Bajo
    private Double limiteA;  // Alto
    private Double limiteMA; // Muy Alto
    
    private boolean habilitado = true;

    @ManyToOne
    @JoinColumn(name = "maquina_id")
    @JsonIgnore
    private Maquina maquina;

    public MetricConfig() {}

    public MetricConfig(String nombreMetrica, String unidadSeleccionada, Double mb, Double b, Double a, Double ma) {
        this.nombreMetrica = nombreMetrica;
        this.unidadSeleccionada = unidadSeleccionada;
        this.limiteMB = mb;
        this.limiteB = b;
        this.limiteA = a;
        this.limiteMA = ma;
    }

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNombreMetrica() { return nombreMetrica; }
    public void setNombreMetrica(String nombreMetrica) { this.nombreMetrica = nombreMetrica; }

    public String getUnidadSeleccionada() { return unidadSeleccionada; }
    public void setUnidadSeleccionada(String unidadSeleccionada) { this.unidadSeleccionada = unidadSeleccionada; }

    public Double getLimiteMB() { return limiteMB; }
    public void setLimiteMB(Double limiteMB) { this.limiteMB = limiteMB; }

    public Double getLimiteB() { return limiteB; }
    public void setLimiteB(Double limiteB) { this.limiteB = limiteB; }

    public Double getLimiteA() { return limiteA; }
    public void setLimiteA(Double limiteA) { this.limiteA = limiteA; }

    public Double getLimiteMA() { return limiteMA; }
    public void setLimiteMA(Double limiteMA) { this.limiteMA = limiteMA; }

    public boolean isHabilitado() { return habilitado; }
    public void setHabilitado(boolean habilitado) { this.habilitado = habilitado; }

    public Maquina getMaquina() { return maquina; }
    public void setMaquina(Maquina maquina) { this.maquina = maquina; }
}
