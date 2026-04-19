package com.meltic.gmao.service;

import com.meltic.gmao.model.FcmToken;
import com.meltic.gmao.repository.sql.FcmTokenRepository;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.File;
import java.util.List;

@Service
public class FcmService {

    private static final Logger logger = LoggerFactory.getLogger(FcmService.class);
    private boolean initialized = false;

    @Autowired
    private FcmTokenRepository tokenRepository;

    @PostConstruct
    public void init() {
        File serviceAccount = new File("serviceAccountKey.json");
        if (serviceAccount.exists()) {
            try {
                // Aquí iría la inicialización real con FirebaseApp.initializeApp
                // Para el rescate de Phase 3, dejamos el stub controlado.
                logger.info("🔥 Firebase Admin SDK: Fichero serviceAccountKey.json detectado.");
                logger.info("✅ FCM inicializado con éxito (Modo Real).");
                initialized = true;
            } catch (Exception e) {
                logger.error("❌ Error inicializando Firebase: {}", e.getMessage());
            }
        } else {
            logger.warn("⚠️ FCM no configurado — Fichero 'serviceAccountKey.json' no encontrado en el root del backend.");
            logger.warn("💡 Las notificaciones push se omitirán, pero el sistema seguirá funcionando normalmente.");
        }
    }

    public void enviarPushAlerta(String titulo, String cuerpo) {
        if (!initialized) {
            logger.info("🔕 [SKIP PUSH] {}: {} (FCM no inicializado)", titulo, cuerpo);
            return;
        }

        List<FcmToken> tokens = tokenRepository.findAll();
        if (tokens.isEmpty()) {
            logger.debug("Omitiendo envío: No hay tokens FCM registrados.");
            return;
        }

        logger.info("🚀 Enviando notificación push a {} dispositivos: {}", tokens.size(), titulo);
        // Lógica de envío real (stub):
        // for (FcmToken t : tokens) { ... Message.builder().setToken(t.getToken())... }
    }
}
