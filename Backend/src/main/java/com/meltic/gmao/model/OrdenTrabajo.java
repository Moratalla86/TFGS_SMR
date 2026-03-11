package com.meltic.gmao.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "ordenes_trabajo")
public class OrdenTrabajo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String descripcion;
    private String prioridad; // ALTA, MEDIA, BAJA
    private String estado;    // PENDIENTE, EN_PROCESO, CERRADA
    private LocalDateTime fechaCreacion;

    // ── Nuevos campos de ejecución ─────────────────────────────────────────────
    private LocalDateTime fechaInicio;
    private LocalDateTime fechaFin;

    @Lob
    @Column(columnDefinition = "TEXT")
    private String trabajosRealizados;

    @Lob
    @Column(columnDefinition = "MEDIUMTEXT")
    private String firmaTecnico;   // Base64 de la firma del técnico

    @Lob
    @Column(columnDefinition = "MEDIUMTEXT")
    private String firmaCliente;   // Base64 de la firma del cliente

    // ── Relaciones ─────────────────────────────────────────────────────────────
    @ManyToOne
    @JoinColumn(name = "maquina_id")
    private Maquina maquina;

    @ManyToOne
    @JoinColumn(name = "tecnico_id")
    private Usuario tecnico;

    public OrdenTrabajo() {
        this.fechaCreacion = LocalDateTime.now();
    }

    // ── Getters y Setters ──────────────────────────────────────────────────────
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }

    public String getPrioridad() { return prioridad; }
    public void setPrioridad(String prioridad) { this.prioridad = prioridad; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

    public LocalDateTime getFechaCreacion() { return fechaCreacion; }
    public void setFechaCreacion(LocalDateTime fechaCreacion) { this.fechaCreacion = fechaCreacion; }

    public LocalDateTime getFechaInicio() { return fechaInicio; }
    public void setFechaInicio(LocalDateTime fechaInicio) { this.fechaInicio = fechaInicio; }

    public LocalDateTime getFechaFin() { return fechaFin; }
    public void setFechaFin(LocalDateTime fechaFin) { this.fechaFin = fechaFin; }

    public String getTrabajosRealizados() { return trabajosRealizados; }
    public void setTrabajosRealizados(String trabajosRealizados) { this.trabajosRealizados = trabajosRealizados; }

    public String getFirmaTecnico() { return firmaTecnico; }
    public void setFirmaTecnico(String firmaTecnico) { this.firmaTecnico = firmaTecnico; }

    public String getFirmaCliente() { return firmaCliente; }
    public void setFirmaCliente(String firmaCliente) { this.firmaCliente = firmaCliente; }

    public Maquina getMaquina() { return maquina; }
    public void setMaquina(Maquina maquina) { this.maquina = maquina; }

    public Usuario getTecnico() { return tecnico; }
    public void setTecnico(Usuario tecnico) { this.tecnico = tecnico; }
}