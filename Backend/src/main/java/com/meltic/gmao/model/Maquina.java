package com.meltic.gmao.model;

import jakarta.persistence.*;

@Entity
@Table(name = "maquinas")
public class Maquina {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String nombre;
    private String descripcion;
    private String ubicacion;
    private String estado; // OK, WARNING, ERROR

    // Constructor vacío NECESARIO para que Spring/Hibernate funcionen
    public Maquina() {}

    // Constructor para crear objetos rápidamente
    public Maquina(String nombre, String descripcion, String ubicacion, String estado) {
        this.nombre = nombre;
        this.descripcion = descripcion;
        this.ubicacion = ubicacion;
        this.estado = estado;
    }

    // Getters y Setters (Sin esto, el JSON llegará vacío o dará error)
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }

    public String getUbicacion() { return ubicacion; }
    public void setUbicacion(String ubicacion) { this.ubicacion = ubicacion; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }
}