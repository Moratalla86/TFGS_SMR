package com.meltic.gmao.model;

import jakarta.persistence.*;

@Entity
@Table(name = "usuarios")
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String username;

    @Column(unique = true, nullable = false)
    private String email;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(nullable = false)
    private String password;

    @Column(name = "rfid_tag", unique = true)
    private String rfidTag;

    private String nombre;

    private String apellido1;

    private String apellido2;
    private String telefonoPersonal;
    private String telefonoProfesional;
    private String emailPersonal;

    private String rol; // ADMIN, JEFE DE MANTENIMIENTO, TECNICO
    private boolean activo;

    public Usuario() {}

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getRfidTag() { return rfidTag; }
    public void setRfidTag(String rfidTag) { this.rfidTag = rfidTag; }

    public String getRol() { return rol; }
    public void setRol(String rol) { this.rol = rol; }

    public boolean isActivo() { return activo; }
    public void setActivo(boolean activo) { this.activo = activo; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getApellido1() { return apellido1; }
    public void setApellido1(String apellido1) { this.apellido1 = apellido1; }

    public String getApellido2() { return apellido2; }
    public void setApellido2(String apellido2) { this.apellido2 = apellido2; }

    public String getTelefonoPersonal() { return telefonoPersonal; }
    public void setTelefonoPersonal(String telefonoPersonal) { this.telefonoPersonal = telefonoPersonal; }

    public String getTelefonoProfesional() { return telefonoProfesional; }
    public void setTelefonoProfesional(String telefonoProfesional) { this.telefonoProfesional = telefonoProfesional; }

    public String getEmailPersonal() { return emailPersonal; }
    public void setEmailPersonal(String emailPersonal) { this.emailPersonal = emailPersonal; }
}