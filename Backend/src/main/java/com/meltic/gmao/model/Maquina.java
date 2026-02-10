package com.meltic.gmao.model;

import jakarta.persistence.*;
import lombok.Data; // <--- Asegúrate de que esta línea esté

@Entity
@Table(name = "maquinas")
@Data // <--- Esta anotación es la que genera los "setNombre", etc.
public class Maquina {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String nombre;
    private String modelo;
    private String ubicacion;
    private String estado;
}