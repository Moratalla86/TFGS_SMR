package com.meltic.gmao.model;

import java.util.ArrayList;
import java.util.List;
import jakarta.persistence.*;

@Entity
@Table(name = "maquinas")
public class Maquina {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String nombre;
    private String modelo; 
    private String descripcion;
    private String ubicacion;
    private String estado; // OK, WARNING, ERROR

    @OneToMany(mappedBy = "maquina", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<MetricConfig> configs = new ArrayList<>();

    public Maquina() {}

    public void addConfig(MetricConfig config) {
        configs.add(config);
        config.setMaquina(this);
    }

    public void removeConfig(MetricConfig config) {
        configs.remove(config);
        config.setMaquina(null);
    }

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getModelo() { return modelo; }
    public void setModelo(String modelo) { this.modelo = modelo; }

    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }

    public String getUbicacion() { return ubicacion; }
    public void setUbicacion(String ubicacion) { this.ubicacion = ubicacion; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

    public List<MetricConfig> getConfigs() { return configs; }
    public void setConfigs(List<MetricConfig> configs) { this.configs = configs; }
}