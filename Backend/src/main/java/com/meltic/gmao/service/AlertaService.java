package com.meltic.gmao.service;

import com.meltic.gmao.model.Alerta;
import com.meltic.gmao.repository.sql.AlertaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class AlertaService {

    private static final Logger logger = LoggerFactory.getLogger(AlertaService.class);

    @Autowired
    private AlertaRepository alertaRepository;

    @Autowired
    private FcmService fcmService;

    public List<Alerta> getAlertasActivas() {
        return alertaRepository.findByActivaTrueOrderByTimestampDesc();
    }

    public long getCountActivas() {
        return alertaRepository.countByActivaTrue();
    }

    @Transactional
    public void registrarAlerta(Long maquinaId, String maquinaNombre, String severidad, String descripcion) {
        // Evitar duplicados activos de la misma máquina con la misma descripción en un lapso corto
        List<Alerta> existentes = alertaRepository.findByMaquinaIdAndActivaTrue(maquinaId);
        boolean duplicada = existentes.stream().anyMatch(a -> a.getDescripcion().equals(descripcion));
        
        if (!duplicada) {
            Alerta alerta = new Alerta(maquinaId, maquinaNombre, severidad, descripcion);
            alertaRepository.save(alerta);
            logger.info("🚨 ALERTA REGISTRADA: [{}] en máquina {}", severidad, maquinaNombre);
            
            // Aquí se integrará el envío de Push en Phase 3
            enviarNotificacionPush(alerta);
        }
    }

    @Transactional
    public void desactivarAlertasMaquina(Long maquinaId) {
        List<Alerta> activas = alertaRepository.findByMaquinaIdAndActivaTrue(maquinaId);
        if (!activas.isEmpty()) {
            activas.forEach(a -> a.setActiva(false));
            alertaRepository.saveAll(activas);
            logger.info("✅ Alertas desactivadas para máquina ID: {}", maquinaId);
        }
    }

    private void enviarNotificacionPush(Alerta alerta) {
        String titulo = "🚨 Alerta Mèltic: " + alerta.getMaquinaNombre();
        String cuerpo = alerta.getSeveridad() + ": " + alerta.getDescripcion();
        fcmService.enviarPushAlerta(titulo, cuerpo);
    }
}
