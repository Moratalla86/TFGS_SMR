# Anexo de Código: Desarrollo Técnico Frontend (Flutter)

Este documento contiene los fragmentos de código estructurales de la App Móvil para la redacción del capítulo "Desarrollo Técnico" (Sección Interfaces y Diagramas de Clase).

---

## 1. Configuración de API e Inversión de Control (`api_config.dart`)
La configuración de punto de enlace centraliza las llamadas a la red y permite la resiliencia en desarrollo o producción detectando la plataforma automáticamente.

```dart
// Archivo: lib/services/api_config.dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Retorna la URL del backend dinámicamente según la plataforma de ejecución
  static String get baseUrl {
    // IP del entorno de despliegue principal (VLAN IT)
    const String hotspotIp = "192.168.1.50"; 
    
    if (kIsWeb) return "http://$hotspotIp:8080"; 
    
    // Si corre en simulador local de Windows usa localhost, sino usa la IP real del servidor
    return (defaultTargetPlatform == TargetPlatform.windows) 
        ? "http://localhost:8080" 
        : "http://$hotspotIp:8080";
  }
}
```

---

## 2. Consumo de Telemetría RAW y Sincronización Temporal (`telemetria_service.dart`)
Este servicio conecta el Frontend con MongoDB (a través del Backend) y corrige el "Drift" temporal (desfase) entre el reloj de la máquina, el servidor y el cliente móvil.

```dart
// Archivo: lib/services/telemetria_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'api_config.dart';
import '../models/telemetria.dart';

class TelemetriaService {
  Duration _serverOffset = Duration.zero;

  Future<List<Telemetria>> fetchPorMaquina(int maquinaId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/plc/maquina/$maquinaId'),
    );

    if (response.statusCode == 200) {
      // 1. Detección de Desfase Temporal del Servidor (Drift Correction)
      final serverDateStr = response.headers['date'];
      if (serverDateStr != null) {
        try {
          final serverDate = HttpDate.parse(serverDateStr);
          _serverOffset = DateTime.now().difference(serverDate);
        } catch (_) {}
      }

      // 2. Mapeo del JSON a Objetos Dart y Corrección de TimeStamps
      List<dynamic> body = json.decode(response.body);
      return body.map((item) {
        final t = Telemetria.fromJson(item);
        // Ajustamos la telemetría con el offset calculado para fluidez en las curvas gráficas
        return _applyOffset(t);
      }).toList();
      
    } else {
      throw Exception('Error al cargar telemetría: ${response.statusCode}');
    }
  }

  Telemetria _applyOffset(Telemetria t) {
    return Telemetria(
      id: t.id,
      maquinaId: t.maquinaId,
       // Los datos mecánicos/eléctricos viajan en un Mapa clave-valor (Dictionary)
      sensores: t.sensores, 
      temperatura: t.temperatura,
      // Aplicar corrección de Drift
      timestamp: t.timestamp.add(_serverOffset),
      // Atributos obligatorios
      humedad: t.humedad, rfidTag: t.rfidTag, 
      usuarioNombre: t.usuarioNombre, motorOn: t.motorOn, alarma: t.alarma
    );
  }
}
```

---

## 3. Lógica IoT de Pantalla: El Bucle de Refresco Gráfico (`machine_detail_screen.dart`)
La pantalla interactúa con el `TelemetriaService` instalando un `Timer` en segundo plano que actualiza la gráfica cada pocos segundos, actuando como cliente reactivo del PLC.

```dart
// Fragmento Clave de: lib/screens/machine_detail_screen.dart

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  final TelemetriaService _telemetriaService = TelemetriaService();
  Timer? _timer;
  List<Telemetria> _playbackHistory = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Iniciar poller cliente para generar el efecto de gráfica LIVE
    if (_timer == null) {
      _refreshData();
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        // Solo refrescamos si no estamos en modo "Playback" histórico
        if (mounted && !_isPaused && _analysisStart == null) {
          _refreshData();
        }
      });
    }
  }

  void _refreshData() async {
    try {
      final realDataRaw = await _telemetriaService.fetchPorMaquina(widget.maquina.id);
      
      // Enriquecimiento de Datos: Carga de valores al array para renderizado local
      if (mounted) {
        setState(() {
          // Extraemos los últimos 200 registros de la base de datos para dibujar la curva
          _playbackHistory = _enrichData(realDataRaw); 
          _isUsingDigitalTwin = realDataRaw.isEmpty; // Failsafe (Motor Simulado)
        });
      }
    } catch (e) {
      // Manejo de Desconexión de Red: Activar gemelo digital puramente simulado
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // IMPORTANTE: Prevenir fugas de memoria (Memory Leaks) en la App.
    super.dispose();
  }
}
```
