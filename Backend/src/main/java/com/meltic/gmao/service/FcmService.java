package com.meltic.gmao.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.meltic.gmao.model.FcmToken;
import com.meltic.gmao.repository.sql.FcmTokenRepository;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.FileInputStream;
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
                FileInputStream stream = new FileInputStream(serviceAccount);
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(stream))
                        .build();
                if (FirebaseApp.getApps().isEmpty()) {
                    FirebaseApp.initializeApp(options);
                }
                logger.info("✅ FCM inicializado con éxito.");
                initialized = true;
            } catch (Exception e) {
                logger.error("❌ Error inicializando Firebase: {}", e.getMessage());
            }
        } else {
            logger.warn("⚠️ FCM no configurado — 'serviceAccountKey.json' no encontrado en el root del backend.");
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

        for (FcmToken t : tokens) {
            try {
                Message message = Message.builder()
                        .setNotification(Notification.builder()
                                .setTitle(titulo)
                                .setBody(cuerpo)
                                .build())
                        .setToken(t.getToken())
                        .build();
                String response = FirebaseMessaging.getInstance().send(message);
                logger.info("✅ Push enviado (token ...{}): {}",
                        t.getToken().substring(Math.max(0, t.getToken().length() - 8)), response);
            } catch (Exception e) {
                logger.error("❌ Error enviando push al token ...{}: {}",
                        t.getToken().substring(Math.max(0, t.getToken().length() - 8)), e.getMessage());
            }
        }
    }
}
