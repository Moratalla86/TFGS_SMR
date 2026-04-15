import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/telemetria.dart';
import '../models/maquina.dart';
import 'telemetria_service.dart';

/// Servicio Singleton que gestiona la recolección de telemetría en segundo plano
/// para todas las máquinas. Mantiene buffers circulares en memoria para 
/// visualización instantánea.
class GlobalTelemetryHistorian extends ChangeNotifier {
  GlobalTelemetryHistorian._internal();
  static final GlobalTelemetryHistorian instance = GlobalTelemetryHistorian._internal();

  final TelemetriaService _service = TelemetriaService();
  
  // Buffers: maquinaId -> SplayTreeMap (timestamp -> Telemetria)
  final Map<int, SplayTreeMap<int, Telemetria>> _buffers = {};
  
  Timer? _pollingTimer;
  List<Maquina> _trackedMaquinas = [];
  bool _isPolling = false;

  // Configuración de retención
  // 7200 puntos (~2 horas a 1s de tasa en PLC, o ~10 horas a 5s de tasa)
  static const int maxBufferSize = 7200;

  /// Inicia el seguimiento de un conjunto de máquinas
  void startTracking(List<Maquina> maquinas) {
    _trackedMaquinas = maquinas;
    
    // Inicializar buffers para máquinas nuevas
    for (var m in maquinas) {
      if (m.id != null && !_buffers.containsKey(m.id)) {
        _buffers[m.id!] = SplayTreeMap<int, Telemetria>();
      }
    }

    if (_pollingTimer == null) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _pollAll();
      });
      // Primera ejecución inmediata
      _pollAll();
    }
  }

  void stopTracking() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Obtiene el buffer actual para una máquina
  SplayTreeMap<int, Telemetria>? getBuffer(int maquinaId) {
    return _buffers[maquinaId];
  }

  /// Fuerza una carga inicial si el buffer está vacío
  Future<void> ensureInitialLoad(int maquinaId) async {
    final buffer = _buffers[maquinaId];
    if (buffer == null || buffer.isEmpty) {
      try {
        final initialData = await _service.fetchPorMaquina(maquinaId);
        if (buffer != null) {
          for (var t in initialData) {
            final ts = t.timestamp.millisecondsSinceEpoch;
            buffer[ts] = t;
          }
          _trimBuffer(maquinaId);
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error en carga inicial global para máquina $maquinaId: $e');
      }
    }
  }

  Future<void> _pollAll() async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      final futures = _trackedMaquinas.where((m) => m.id != null).map((m) async {
        final id = m.id!;
        final buffer = _buffers[id];
        
        DateTime? since;
        if (buffer != null && buffer.isNotEmpty) {
          since = DateTime.fromMillisecondsSinceEpoch(buffer.lastKey()!);
        }

        try {
          if (since == null) {
            // Primera carga del poller de background: pedir solo los últimos 30 segundos
            // para no transferir 3600 registros innecesariamente (la carga inicial completa
            // la hace MachineDetailScreen con fetchPorMaquina directamente).
            final lightSince = DateTime.now().subtract(const Duration(seconds: 30));
            final data = await _service.fetchDesde(id, lightSince);
            if (data.isNotEmpty) {
              _addAllToBuffer(id, data);
            }
          } else {
            final newPoints = await _service.fetchDesde(id, since);
            if (newPoints.isNotEmpty) {
              _addAllToBuffer(id, newPoints);
            }
          }
        } catch (e) {
          debugPrint('Error polling background máquina $id: $e');
        }
      });

      await Future.wait(futures);
      notifyListeners();
    } finally {
      _isPolling = false;
    }
  }

  void _addAllToBuffer(int id, List<Telemetria> points) {
    final buffer = _buffers[id];
    if (buffer == null) return;

    for (var p in points) {
      final ts = p.timestamp.millisecondsSinceEpoch;
      buffer[ts] = p;
    }

    _trimBuffer(id);
  }

  void _trimBuffer(int id) {
    final buffer = _buffers[id];
    if (buffer == null) return;

    while (buffer.length > maxBufferSize) {
      buffer.remove(buffer.firstKey());
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
