import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/maquina.dart';
import '../models/telemetria.dart';
import '../services/maquina_service.dart';
import '../services/telemetria_service.dart';
import '../services/global_telemetry_historian.dart';
import '../widgets/industrial_chart.dart';
import '../theme/industrial_theme.dart';

class TelemetriaChartScreen extends StatefulWidget {
  const TelemetriaChartScreen({super.key});

  @override
  State<TelemetriaChartScreen> createState() => _TelemetriaChartScreenState();
}

class _TelemetriaChartScreenState extends State<TelemetriaChartScreen> {
  static const int _machineId = 1;

  final MaquinaService _maquinaService = MaquinaService();
  final TelemetriaService _telemetriaService = TelemetriaService();

  Maquina? _maquina;
  bool _loadingMaquina = true;

  Timer? _uiTimer;
  String _timeUnitKey = 'min';
  double _timeWindowValue = 5.0;
  bool _isHistoricalMode = false;
  List<Telemetria>? _historicalData;
  bool _isLoadingHistoric = false;

  List<Telemetria> get _liveData =>
      GlobalTelemetryHistorian.instance.getBuffer(_machineId)?.values.toList() ?? [];

  @override
  void initState() {
    super.initState();
    _loadMaquina();
    GlobalTelemetryHistorian.instance.ensureInitialLoad(_machineId);
    GlobalTelemetryHistorian.instance.addListener(_onUpdate);
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isHistoricalMode) setState(() {});
    });
  }

  void _onUpdate() {
    if (mounted && !_isHistoricalMode) setState(() {});
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    GlobalTelemetryHistorian.instance.removeListener(_onUpdate);
    super.dispose();
  }

  Future<void> _loadMaquina() async {
    try {
      final maquinas = await _maquinaService.fetchMaquinas();
      final m = maquinas.firstWhere(
        (m) => m.id == _machineId,
        orElse: () => maquinas.first,
      );
      if (mounted) setState(() { _maquina = m; _loadingMaquina = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMaquina = false);
    }
  }

  void _refresh() {
    GlobalTelemetryHistorian.instance.getBuffer(_machineId)?.clear();
    GlobalTelemetryHistorian.instance.ensureInitialLoad(_machineId);
    setState(() { _isHistoricalMode = false; _historicalData = null; });
  }

  Duration get _windowDuration {
    final n = _timeWindowValue.round();
    switch (_timeUnitKey) {
      case 'min': return Duration(minutes: n);
      case 'h':   return Duration(hours: n);
      case 'd':   return Duration(days: n);
      default:    return Duration(minutes: n);
    }
  }

  DateTimeIntervalType get _timeMagnitude {
    switch (_timeUnitKey) {
      case 'min': return DateTimeIntervalType.minutes;
      case 'h':   return DateTimeIntervalType.hours;
      case 'd':   return DateTimeIntervalType.days;
      default:    return DateTimeIntervalType.minutes;
    }
  }

  double get _minWindow => 1.0;
  double get _maxWindow {
    switch (_timeUnitKey) {
      case 'min': return 60;
      case 'h':   return 24;
      case 'd':   return 30;
      default:    return 60;
    }
  }

  void _onWindowChanged() {
    final isLong = _windowDuration.inHours > 24;
    if (isLong && !_isHistoricalMode) {
      _activateHistoricalMode();
    } else if (!isLong && _isHistoricalMode) {
      setState(() { _isHistoricalMode = false; _historicalData = null; });
    } else if (isLong) {
      _activateHistoricalMode();
    }
  }

  Future<void> _activateHistoricalMode() async {
    final hasta = DateTime.now();
    final desde = hasta.subtract(_windowDuration);
    setState(() { _isHistoricalMode = true; _isLoadingHistoric = true; });
    try {
      final data = await _telemetriaService.fetchHistorico(_machineId, desde, hasta);
      if (mounted) setState(() { _historicalData = data; _isLoadingHistoric = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistoric = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SALA DE SERVIDORES',
          style: TextStyle(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: IndustrialTheme.neonCyan),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: IndustrialTheme.neonCyan),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loadingMaquina
          ? const Center(child: CircularProgressIndicator(color: IndustrialTheme.neonCyan))
          : _maquina == null
              ? const Center(child: Text('No se pudo cargar el activo', style: TextStyle(color: Colors.white54)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTimeRangeSelector(),
                      const SizedBox(height: 12),
                      _buildChart(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isHistoricalMode
              ? IndustrialTheme.warningOrange.withValues(alpha: 0.4)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
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
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Text("VENTANA:", style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 8, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Slider(
                value: _timeWindowValue.clamp(_minWindow, _maxWindow),
                min: _minWindow,
                max: _maxWindow,
                divisions: (_maxWindow - _minWindow).round(),
                activeColor: _isHistoricalMode ? IndustrialTheme.warningOrange : IndustrialTheme.neonCyan,
                inactiveColor: Colors.white10,
                onChanged: (v) => setState(() => _timeWindowValue = v),
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
                    DropdownMenuItem(value: 'h',   child: Text('H')),
                    DropdownMenuItem(value: 'd',   child: Text('DÍAS')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _timeUnitKey = v);
                      _onWindowChanged();
                    }
                  },
                ),
              ),
            ),
          ]),
          if (_isLoadingHistoric)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(
                color: IndustrialTheme.warningOrange,
                backgroundColor: Colors.white10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_isHistoricalMode) {
      if (_isLoadingHistoric) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: IndustrialTheme.claudCloud,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: IndustrialTheme.warningOrange),
              SizedBox(height: 12),
              Text("CARGANDO HISTÓRICO...",
                  style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 10, letterSpacing: 1.5)),
            ]),
          ),
        );
      }
      if (_historicalData != null) {
        final hasta = DateTime.now();
        final desde = hasta.subtract(_windowDuration);
        return IndustrialChart(
          telemetria: _historicalData!,
          maquina: _maquina!,
          isVirtual: _maquina!.simulado,
          timeRange: _timeWindowValue,
          timeMagnitude: _timeMagnitude,
          staticXMin: desde,
          staticXMax: hasta,
        );
      }
    }

    final data = _liveData;
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: IndustrialTheme.neonCyan)),
      );
    }

    return IndustrialChart(
      telemetria: data,
      maquina: _maquina!,
      isVirtual: _maquina!.simulado,
      timeRange: _timeWindowValue,
      timeMagnitude: _timeMagnitude,
    );
  }
}
