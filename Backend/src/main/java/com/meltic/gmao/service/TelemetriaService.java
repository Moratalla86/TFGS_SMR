package com.meltic.gmao.service;

import com.meltic.gmao.model.nosql.Telemetria;
import com.meltic.gmao.repository.nosql.TelemetriaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class TelemetriaService {

    @Autowired
    private TelemetriaRepository telemetriaRepository;

    public Telemetria guardar(Telemetria telemetria) {
        if (telemetria.getTimestamp() == null) {
            telemetria.setTimestamp(LocalDateTime.now());
        }
        return telemetriaRepository.save(telemetria);
    }

    public List<Telemetria> obtenerPorMaquina(Long maquinaId) {
        return telemetriaRepository.findByMaquinaIdOrderByTimestampDesc(maquinaId);
    }
}
