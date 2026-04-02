package com.meltic.gmao.model.nosql;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document(collection = "telemetria")
public class Telemetria {

    @Id
    private String id;
    
    private Long maquinaId;
    private Double temperatura;
    private Double humedad;
    private Double vibracion;
    private Double presion;
    private Double voltaje;
    private Double intensidad;
    private String rfidTag;
    private String usuarioNombre;
    private Boolean motorOn;
    private String alarma;
    private LocalDateTime timestamp;

    public Telemetria() {
        this.timestamp = LocalDateTime.now();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public Long getMaquinaId() { return maquinaId; }
    public void setMaquinaId(Long maquinaId) { this.maquinaId = maquinaId; }

    public Double getTemperatura() { return temperatura; }
    public void setTemperatura(Double temperatura) { this.temperatura = temperatura; }

    public Double getHumedad() { return humedad; }
    public void setHumedad(Double humedad) { this.humedad = humedad; }

    public Double getVibracion() { return vibracion; }
    public void setVibracion(Double vibracion) { this.vibracion = vibracion; }

    public Double getPresion() { return presion; }
    public void setPresion(Double presion) { this.presion = presion; }

    public Double getVoltaje() { return voltaje; }
    public void setVoltaje(Double voltaje) { this.voltaje = voltaje; }

    public Double getIntensidad() { return intensidad; }
    public void setIntensidad(Double intensidad) { this.intensidad = intensidad; }

    public String getRfidTag() { return rfidTag; }
    public void setRfidTag(String rfidTag) { this.rfidTag = rfidTag; }

    public String getUsuarioNombre() { return usuarioNombre; }
    public void setUsuarioNombre(String usuarioNombre) { this.usuarioNombre = usuarioNombre; }

    public Boolean getMotorOn() { return motorOn; }
    public void setMotorOn(Boolean motorOn) { this.motorOn = motorOn; }

    public String getAlarma() { return alarma; }
    public void setAlarma(String alarma) { this.alarma = alarma; }

    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }
}
