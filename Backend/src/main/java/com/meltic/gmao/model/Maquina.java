package com.meltic.gmao.model;

import jakarta.persistence.*;

@Entity
@Table(name = "maquinas")
public class Maquina {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String nombre;
    private String modelo; // Campo necesario para el DataInitializer
    private String descripcion;
    private String ubicacion;
    private String estado; // OK, WARNING, ERROR [cite: 34]

    // Límites de temperatura
    private Double limiteMB; // Muy Bajo
    private Double limiteB;  // Bajo
    private Double limiteA;  // Alto
    private Double limiteMA; // Muy Alto

    public Maquina() {}

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

    public Double getLimiteMB() { return limiteMB; }
    public void setLimiteMB(Double limiteMB) { this.limiteMB = limiteMB; }

    public Double getLimiteB() { return limiteB; }
    public void setLimiteB(Double limiteB) { this.limiteB = limiteB; }

    public Double getLimiteA() { return limiteA; }
    public void setLimiteA(Double limiteA) { this.limiteA = limiteA; }

    public Double getLimiteMA() { return limiteMA; }
    public void setLimiteMA(Double limiteMA) { this.limiteMA = limiteMA; }
}