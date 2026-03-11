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

    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }
}
