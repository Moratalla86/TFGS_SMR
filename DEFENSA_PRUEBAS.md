# 📚 Guion de Pruebas: Defensa del TFG (Mèltic GMAO)

Este documento contiene los pasos recomendados para realizar una demostración técnica impecable ante el tribunal.

## 🛡️ Escenario 1: Seguridad y Acceso (Biometría Industrial)
**Objetivo**: Demostrar el control de acceso mediante RFID y la gestión de usuarios.

1.  **Login Manual**: Entrar con `admin@meltic.com` / `Meltic@2024!`.
2.  **Login RFID**: Cerrar sesión y usar una tarjeta física (o el simulador) para entrar instantáneamente.
3.  **Bloqueo de Seguridad**:
    *   Ir a la gestión de usuarios.
    *   Desactivar el check "Activo" de un usuario de prueba.
    *   Intentar logar con ese usuario y mostrar que el sistema deniega el acceso (Error 403).

## 📡 Escenario 2: Gemelo Digital e IoT (Módulo SCADA)
**Objetivo**: Mostrar la ingesta de datos en tiempo real y la detección de fallos.

1.  **Visualización Live**: Abrir el detalle de una máquina (ej: Torno X1).
2.  **Simulación de Alarma**:
    *   En la configuración de métricas, bajar el umbral "Muy Alto" de temperatura hasta que esté por debajo del valor actual (ej: ponerlo a 15°C).
    *   Volver a la vista de detalle y observar cómo el indicador cambia a rojo (**ERROR**) y la gráfica muestra la anomalía.
3.  **Persistencia Políglota**: Explicar que los puntos de la gráfica se recuperan de **MongoDB** para no saturar la base de datos principal.

## 📋 Escenario 3: Flujo Paperless (Orden de Trabajo)
**Objetivo**: Demostrar el ciclo de vida completo de una reparación digital.

1.  **Creación**: Crear una OT de tipo "Correctiva" para una máquina en estado de error.
2.  **Ejecución**:
    *   Entrar como técnico.
    *   Pulsar "INICIAR TRABAJO" (el cronómetro empieza a contar).
    *   Añadir fotos de la avería (usar la cámara del dispositivo).
3.  **Cierre y Firma**:
    *   Escribir los trabajos realizados.
    *   Solicitar **firma digital** en pantalla (Técnico y Cliente).
4.  **Generación de Acta**: Pulsar "GENERAR PDF" y mostrar el documento final con logos, datos técnicos y firmas incrustadas.

---

> [!TIP]
> **Punto Extra de Defensa**: Menciona que el sistema tiene un modo **Failsafe** que permite seguir funcionando en simulación si detecta que el hardware del PLC está desconectado, garantizando que el mantenimiento nunca se detiene.
