import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/telemetria_service.dart';
import '../models/telemetria.dart';
import '../models/maquina.dart';
import '../models/metric_config.dart';
import '../widgets/industrial_chart.dart';
import '../services/maquina_service.dart';
import '../theme/industrial_theme.dart';
import '../utils/metric_definitions.dart';
import 'package:intl/intl.dart';
import '../services/global_telemetry_historian.dart';

class MachineDetailScreen extends StatefulWidget {
  const MachineDetailScreen({super.key});

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  final TelemetriaService _telemetriaService = TelemetriaService();
  final MaquinaService _maquinaService = MaquinaService();
  Timer? _uiTimer;
  Map<String, dynamic>? _machineMap;
  String _timeUnitKey = 'min';

  // ───────────────────────────────────────────────
  //  SCADA HISTORIAN SYNC
  //  Ahora usamos el buffer global de GlobalTelemetryHistorian
  // ───────────────────────────────────────────────
  
  // Vista derivada del buffer (ordenada por tiempo, lista para el chart)
  List<Telemetria> get _playbackHistory {
    if (_machineMap == null) return [];
    final id = _machineMap!['id'] as int?;
    if (id == null) return [];
    final buffer = GlobalTelemetryHistorian.instance.getBuffer(id);
    return buffer?.values.toList() ?? [];
  }

  bool _isPaused = false;

  DateTime? _analysisStart;
  DateTime? _analysisEnd;

  double _timeWindowValue = 1.0;

  // MODO HISTÓRICO (ventana > 1 día)
  List<Telemetria>? _historicalData;
  bool _isHistoricalMode = false;
  bool _isLoadingHistoric = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_machineMap == null) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Map<String, dynamic>) {
        _machineMap = args;
      } else if (args is String) {
        try {
          _machineMap = jsonDecode(args) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Error decoding machine JSON: $e');
        }
      }
      
      if (_machineMap != null) {
        final id = _machineMap!['id'] as int?;
        if (id != null) {
          // Asegurar carga inicial en el historiador global
          GlobalTelemetryHistorian.instance.ensureInitialLoad(id);
          // Escuchar cambios del historiador
          GlobalTelemetryHistorian.instance.addListener(_onHistorianUpdate);
        }

        _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted || _isPaused || _analysisStart != null || _isHistoricalMode) {
            return;
          }
          if (mounted) {
            setState(() {});
          }
        });
      }
    }
  }

  void _onHistorianUpdate() {
    if (mounted && !_isPaused && !_isHistoricalMode) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    GlobalTelemetryHistorian.instance.removeListener(_onHistorianUpdate);
    super.dispose();
  }

  void _refreshData() {
    final id = _machineMap?['id'] as int?;
    if (id != null) {
      GlobalTelemetryHistorian.instance.getBuffer(id)?.clear();
      GlobalTelemetryHistorian.instance.ensureInitialLoad(id);
    }
  }

  Future<void> _selectTimeRange() async {
    final TimeOfDay? start = await showTimePicker(context: context, initialTime: TimeOfDay.now(), helpText: "HORA INICIO");
    if (start == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    final TimeOfDay? end = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 30))), helpText: "HORA FIN");
    if (end == null) {
      return;
    }
    final now = DateTime.now();
    setState(() {
      _analysisStart = DateTime(now.year, now.month, now.day, start.hour, start.minute);
      _analysisEnd = DateTime(now.year, now.month, now.day, end.hour, end.minute);
      _isPaused = true;
      if (_playbackHistory.isEmpty) _refreshData();
    });
  }

  void _clearAnalysis() {
    setState(() {
      _analysisStart = null;
      _analysisEnd = null;
      _isPaused = false;
    });
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    if (_machineMap == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final Maquina maquina = Maquina.fromJson(_machineMap!);

    return Scaffold(
      backgroundColor: IndustrialTheme.spaceCadet,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(maquina.nombre.toUpperCase(), style: const TextStyle(letterSpacing: 2, fontSize: 13, fontWeight: FontWeight.bold)),
            Text("ESTACIÓN DE ANÁLISIS", style: TextStyle(color: IndustrialTheme.neonCyan.withValues(alpha: 0.7), fontSize: 8, letterSpacing: 1)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.tune, color: IndustrialTheme.neonCyan), onPressed: () => _showIndustrialConfigDialog(maquina)),
          IconButton(
            icon: Icon(_analysisStart != null ? Icons.history_toggle_off : Icons.more_time, color: _analysisStart != null ? IndustrialTheme.warningOrange : IndustrialTheme.slateGray),
            onPressed: _analysisStart != null ? _clearAnalysis : _selectTimeRange,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: _playbackHistory.isEmpty
            ? const Center(child: CircularProgressIndicator(color: IndustrialTheme.neonCyan))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAnalysisHeader(),
                    const SizedBox(height: 10),
                    _buildAnomalyTracker(maquina, _playbackHistory.last),
                    const SizedBox(height: 10),
                    _buildTimeRangeSelector(),
                    const SizedBox(height: 10),
                    _buildMainChart(maquina),
                    const SizedBox(height: 20),
                    _buildPlaybackBar(),
                    const SizedBox(height: 32),
                    _buildBottomMetadata(maquina),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAnalysisHeader() {
    String status = _isPaused ? "MODO ANÁLISIS" : "MONITORIZACIÓN LIVE";
    Color col = _isPaused ? IndustrialTheme.warningOrange : IndustrialTheme.operativeGreen;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
              if (_analysisStart != null)
                Text("${DateFormat.Hm().format(_analysisStart!)} - ${DateFormat.Hm().format(_analysisEnd!)}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: IndustrialTheme.claudCloud, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [const Icon(Icons.query_stats, color: IndustrialTheme.neonCyan, size: 14), const SizedBox(width: 8), Text("${_playbackHistory.length} REGISTROS", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))]),
        ),
      ],
    );
  }

  Widget _buildAnomalyTracker(Maquina m, Telemetria lastData) {
    String? level;
    for (var config in m.configs) {
      if (!config.habilitado) continue;
      final sid = config.nombreMetrica;
      double? val;
      if (sid == 'temperatura') {
        val = lastData.temperatura;
      } else if (sid == 'humedad') {
        val = lastData.humedad;
      } else if (sid == 'vibracion') {
        val = lastData.vibracion;
      } else if (sid == 'presion') {
        val = lastData.presion;
      } else if (sid == 'voltaje') {
        val = lastData.voltaje;
      } else if (sid == 'intensidad') {
        val = lastData.intensidad;
      } else {
        val = lastData.sensores[sid];
      }

      if (val != null) {
        if (config.limiteMA != null && val >= config.limiteMA!) {
          level = "🚨 CRÍTICO: ${sid.toUpperCase()} FUERA DE RANGO M.A.";
        } else if (config.limiteA != null && val >= config.limiteA!) {
          level = "⚠️ ADVERTENCIA: ${sid.toUpperCase()} NIVEL ALTO";
        } else if (config.limiteMB != null && val <= config.limiteMB!) {
          level = "🚨 CRÍTICO: ${sid.toUpperCase()} NIVEL M. BAJO";
        }
      }
      if (level != null) {
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: level == null ? Colors.transparent : level.contains('🚨') ? IndustrialTheme.criticalRed : IndustrialTheme.warningOrange),
      ),
      child: Row(
        children: [
          Icon(level == null ? Icons.check_circle : Icons.warning_rounded, color: level == null ? IndustrialTheme.operativeGreen : level.contains('🚨') ? IndustrialTheme.criticalRed : IndustrialTheme.warningOrange),
          const SizedBox(width: 12),
          Expanded(child: Text(level ?? "DETECTOR DE ANOMALÍAS: ESTADO NOMINAL", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isHistoricalMode ? IndustrialTheme.warningOrange.withValues(alpha: 0.4) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _isHistoricalMode ? Icons.history_edu : Icons.live_tv,
                color: _isHistoricalMode ? IndustrialTheme.warningOrange : IndustrialTheme.neonCyan,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                _isHistoricalMode ? "MODO HISTÓRICO" : "MODO LIVE",
                style: TextStyle(
                  color: _isHistoricalMode ? IndustrialTheme.warningOrange : IndustrialTheme.neonCyan,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (_isHistoricalMode && _historicalData != null) ...[
                const Spacer(),
                Text(
                  "${_historicalData!.length} PTS MUESTREADOS",
                  style: const TextStyle(color: Colors.white38, fontSize: 8),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                "VENTANA:",
                style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 8, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Slider(
                  value: _timeWindowValue.clamp(_minWindowValue, _maxWindowValue),
                  min: _minWindowValue,
                  max: _maxWindowValue,
                  divisions: (_maxWindowValue - _minWindowValue).round(),
                  activeColor: _isHistoricalMode ? IndustrialTheme.warningOrange : IndustrialTheme.neonCyan,
                  inactiveColor: Colors.white10,
                  label: _timeWindowValue.round().toString(),
                  onChanged: (val) => setState(() => _timeWindowValue = val),
                  onChangeEnd: (_) => _onWindowChanged(),
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  _timeWindowValue.round().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: IndustrialTheme.spaceCadet,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _timeUnitKey,
                    dropdownColor: IndustrialTheme.spaceCadet,
                    icon: const Icon(Icons.arrow_drop_down, color: IndustrialTheme.neonCyan),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    items: const [
                      DropdownMenuItem(value: 'min', child: Text('MIN')),
                      DropdownMenuItem(value: 'h', child: Text('H')),
                      DropdownMenuItem(value: 'd', child: Text('DÍAS')),
                      DropdownMenuItem(value: 'w', child: Text('SEM.')),
                      DropdownMenuItem(value: 'm', child: Text('MESES')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _timeUnitKey = val);
                        _onWindowChanged();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_isLoadingHistoric)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(color: IndustrialTheme.warningOrange, backgroundColor: Colors.white10),
            ),
        ],
      ),
    );
  }

  double get _minWindowValue {
    return 1;
  }

  double get _maxWindowValue {
    switch (_timeUnitKey) {
      case 'min': return 60;
      case 'h': return 24;
      case 'd': return 30;
      case 'w': return 26;
      case 'm': return 12;
      default: return 60;
    }
  }

  Duration get _windowDuration {
    final n = _timeWindowValue.round();
    switch (_timeUnitKey) {
      case 'min': return Duration(minutes: n);
      case 'h': return Duration(hours: n);
      case 'd': return Duration(days: n);
      case 'w': return Duration(days: n * 7);
      case 'm': return Duration(days: n * 30);
      default: return Duration(minutes: n);
    }
  }

  DateTimeIntervalType get _timeWindowMagnitude {
    switch (_timeUnitKey) {
      case 'min': return DateTimeIntervalType.minutes;
      case 'h': return DateTimeIntervalType.hours;
      case 'd': return DateTimeIntervalType.days;
      case 'w': return DateTimeIntervalType.days;
      case 'm': return DateTimeIntervalType.months;
      default: return DateTimeIntervalType.minutes;
    }
  }

  void _onWindowChanged() {
    final dur = _windowDuration;
    final isLong = dur.inHours > 24;
    if (isLong && !_isHistoricalMode) {
      _activateHistoricalMode();
    } else if (!isLong && _isHistoricalMode) {
      setState(() {
        _isHistoricalMode = false;
        _historicalData = null;
      });
    } else if (isLong) {
      _activateHistoricalMode();
    }
  }

  Future<void> _activateHistoricalMode() async {
    if (_machineMap == null) {
      return;
    }
    final maquina = Maquina.fromJson(_machineMap!);
    final hasta = DateTime.now();
    final desde = hasta.subtract(_windowDuration);

    setState(() {
      _isHistoricalMode = true;
      _isLoadingHistoric = true;
    });

    try {
      final data = await _telemetriaService.fetchHistorico(maquina.id ?? 0, desde, hasta);
      if (mounted) {
        setState(() {
          _historicalData = data;
          _isLoadingHistoric = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistoric = false);
      }
      debugPrint('Error cargando histórico: $e');
    }
  }

  Widget _buildMainChart(Maquina maquina) {
    if (_isHistoricalMode) {
      if (_isLoadingHistoric) {
        return Container(
          height: 200,
          decoration: BoxDecoration(color: IndustrialTheme.claudCloud, borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: IndustrialTheme.warningOrange),
              SizedBox(height: 12),
              Text("CARGANDO HISTÓRICO...", style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 10, letterSpacing: 1.5)),
            ],
          )),
        );
      }
      if (_historicalData != null) {
        final hasta = DateTime.now();
        final desde = hasta.subtract(_windowDuration);
        return IndustrialChart(
          telemetria: _historicalData!,
          maquina: maquina,
          isVirtual: false,
          timeRange: _timeWindowValue,
          timeMagnitude: _timeWindowMagnitude,
          staticXMin: desde,
          staticXMax: hasta,
        );
      }
    }

    List<Telemetria> viewData = _playbackHistory;
    if (_analysisStart != null && _analysisEnd != null) {
      viewData = _playbackHistory.where((t) =>
        (t.timestamp.isAfter(_analysisStart!) || t.timestamp.isAtSameMomentAs(_analysisStart!)) &&
        (t.timestamp.isBefore(_analysisEnd!) || t.timestamp.isAtSameMomentAs(_analysisEnd!))
      ).toList();
    }

    return IndustrialChart(
      telemetria: viewData,
      maquina: maquina,
      isVirtual: false,
      timeRange: _timeWindowValue,
      timeMagnitude: _timeWindowMagnitude,
    );
  }

  Widget _buildPlaybackBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: IndustrialTheme.claudCloud, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => setState(() { _isPaused = true; })),
          GestureDetector(onTap: () => setState(() { _isPaused = !_isPaused; if (!_isPaused) { _analysisStart = null; _refreshData(); } }),
            child: CircleAvatar(backgroundColor: _isPaused ? IndustrialTheme.warningOrange : IndustrialTheme.neonCyan, child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: IndustrialTheme.spaceCadet))),
          IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 18), onPressed: () => setState(() { })),
        ],
      ),
    );
  }

  Widget _buildBottomMetadata(Maquina maquina) {
    return Column(
      children: [
        ListTile(leading: const Icon(Icons.sensors, color: IndustrialTheme.neonCyan), title: const Text("CONFIGURAR MÉTRICAS", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)), trailing: const Icon(Icons.chevron_right, color: IndustrialTheme.slateGray), onTap: () => _showIndustrialConfigDialog(maquina)),
        ListTile(leading: const Icon(Icons.settings, color: IndustrialTheme.neonCyan), title: const Text("IP PLC / CONFIGURACIÓN", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)), subtitle: Text(maquina.plcUrl ?? "Por defecto (ID1)", style: const TextStyle(fontSize: 9, color: IndustrialTheme.slateGray)), trailing: const Icon(Icons.chevron_right, color: IndustrialTheme.slateGray), onTap: () => _showIndustrialConfigDialog(maquina)),
      ],
    );
  }

  void _showIndustrialConfigDialog(Maquina maquina) {
    final allMetrics = MetricDefinition.all;
    List<MetricConfig> tempConfigs = List.from(maquina.configs);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: IndustrialTheme.claudCloud,
          title: const Text("GESTIÓN DE MÉTRICAS", style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 14)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allMetrics.length,
              itemBuilder: (context, i) {
                final def = allMetrics[i];
                final configIndex = tempConfigs.indexWhere((c) => c.nombreMetrica == def.id);
                final bool isEnabled = configIndex != -1 && tempConfigs[configIndex].habilitado;

                return CheckboxListTile(
                  title: Text(def.label, style: const TextStyle(fontSize: 12, color: Colors.white)),
                  secondary: Icon(def.icon, color: isEnabled ? def.color : IndustrialTheme.slateGray),
                  value: isEnabled,
                  activeColor: IndustrialTheme.neonCyan,
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) {
                        if (configIndex == -1) {
                          tempConfigs.add(MetricConfig(
                            nombreMetrica: def.id,
                            unidadSeleccionada: def.unit,
                            habilitado: true,
                            limiteMB: 10.0, limiteB: 15.0, limiteA: 45.0, limiteMA: 60.0,
                          ));
                        } else {
                          tempConfigs[configIndex] = tempConfigs[configIndex].copyWith(habilitado: true);
                        }
                      } else {
                        if (configIndex != -1) {
                          tempConfigs[configIndex] = tempConfigs[configIndex].copyWith(habilitado: false);
                        }
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
            ElevatedButton(
              onPressed: () async {
                final n = maquina.copyWith(configs: tempConfigs);
                await _maquinaService.update(n);
                if (!mounted) {
                  return;
                }
                setState(() => _machineMap = n.toJson());
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                _refreshData();
              },
              child: const Text("GUARDAR"),
            ),
          ],
        ),
      ),
    );
  }
}
