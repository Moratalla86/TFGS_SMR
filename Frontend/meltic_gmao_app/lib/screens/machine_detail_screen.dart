import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/telemetria_service.dart';
import '../models/telemetria.dart';
import '../models/maquina.dart';
import '../widgets/industrial_chart.dart';
import '../services/plc_service.dart';
import '../services/maquina_service.dart';
import '../theme/industrial_theme.dart';
import '../utils/metric_definitions.dart';
import 'package:intl/intl.dart';

class MachineDetailScreen extends StatefulWidget {
  const MachineDetailScreen({super.key});

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  final TelemetriaService _telemetriaService = TelemetriaService();
  final MaquinaService _maquinaService = MaquinaService();
  Timer? _timer;
  Map<String, dynamic>? _machineMap;
  Telemetria? _currentTelemetria;

  List<Telemetria> _playbackHistory = [];
  bool _isUsingDigitalTwin = false;
  bool _isPaused = false;
  int _playbackOffset = 0;
  DateTimeRange? _selectedDateRange;

  DateTime? _analysisStart;
  DateTime? _analysisEnd;

  final math.Random _random = math.Random();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_machineMap == null) {
      _machineMap =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _refreshData();
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted && !_isPaused && _analysisStart == null) {
          _refreshData();
        }
      });
    }
  }

  void _refreshData() async {
    if (_machineMap == null) return;
    final Maquina maquina = Maquina.fromJson(_machineMap!);

    try {
      final realDataRaw = await _telemetriaService.fetchPorMaquina(maquina.id);
      // Sincronización Absoluta de Tiempo: Forzamos que los datos coincidan con el reloj local
      final List<Telemetria> realData = _syncToLocalClock(realDataRaw);

      if (mounted) {
        setState(() {
          _playbackHistory = _enrichData(realData, maquina);
          _isUsingDigitalTwin = realData.isEmpty;
          if (!_isPaused) _playbackOffset = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _playbackHistory = _enrichData([], maquina);
          _isUsingDigitalTwin = true;
          if (!_isPaused) _playbackOffset = 0;
        });
      }
    }
  }

  List<Telemetria> _syncToLocalClock(List<Telemetria> raw) {
    if (raw.isEmpty) return raw;

    // Identificamos el punto más reciente del servidor
    final latestRawTs = raw.last.timestamp;
    final now = DateTime.now();

    // Calculamos el desfase exacto respecto al dispositivo local
    final syncOffset = now.difference(latestRawTs);

    // Aplicamos la calibración a todos los puntos para consistencia total
    return raw
        .map(
          (t) => Telemetria(
            id: t.id,
            maquinaId: t.maquinaId,
            temperatura: t.temperatura,
            humedad: t.humedad,
            rfidTag: t.rfidTag,
            usuarioNombre: t.usuarioNombre,
            motorOn: t.motorOn,
            alarma: t.alarma,
            timestamp: t.timestamp.add(syncOffset),
            sensores: t.sensores,
          ),
        )
        .toList();
  }

  List<Telemetria> _enrichData(List<Telemetria> base, Maquina m) {
    List<Telemetria> enriched = List.from(base);
    if (enriched.isEmpty && _playbackHistory.isEmpty) {
      final now = DateTime.now();
      for (int i = 20; i >= 0; i--) {
        enriched.add(
          _generateVirtualPoint(now.subtract(Duration(minutes: i * 2)), m),
        );
      }
    } else if (enriched.isNotEmpty) {
      for (var i = 0; i < enriched.length; i++) {
        enriched[i] = _fillMissingSensors(enriched[i], m);
      }
    } else if (_playbackHistory.isNotEmpty) {
      enriched = List.from(_playbackHistory);
      if (DateTime.now().difference(enriched.last.timestamp).inSeconds > 10) {
        enriched.add(_generateVirtualPoint(DateTime.now(), m));
      }
    }
    if (enriched.length > 200)
      enriched = enriched.sublist(enriched.length - 200);
    return enriched;
  }

  Telemetria _fillMissingSensors(Telemetria t, Maquina m) {
    Map<String, double> newSensores = Map.from(t.sensores);
    for (String sensorId in m.sensoresConfigurados) {
      if (sensorId == 'temperatura' || sensorId == 'humedad') continue;
      if (!newSensores.containsKey(sensorId)) {
        newSensores[sensorId] = _generateRealisticValue(sensorId);
      }
    }
    return Telemetria(
      id: t.id,
      maquinaId: t.maquinaId,
      temperatura: t.temperatura == 0
          ? _generateRealisticValue('temperatura')
          : t.temperatura,
      humedad: t.humedad == 0 ? _generateRealisticValue('humedad') : t.humedad,
      rfidTag: t.rfidTag,
      usuarioNombre: t.usuarioNombre,
      motorOn: t.motorOn,
      alarma: t.alarma,
      timestamp: t.timestamp,
      sensores: newSensores,
    );
  }

  Telemetria _generateVirtualPoint(DateTime ts, Maquina m) {
    Map<String, double> extra = {};
    for (String id in m.sensoresConfigurados) {
      if (id != 'temperatura' && id != 'humedad') {
        extra[id] = _generateRealisticValue(id);
      }
    }
    return Telemetria(
      id: "v_${ts.millisecondsSinceEpoch}",
      maquinaId: m.id,
      temperatura: _generateRealisticValue('temperatura'),
      humedad: _generateRealisticValue('humedad'),
      rfidTag: "VIRTUAL-SIM",
      usuarioNombre: "GEMELO DIGITAL",
      motorOn: true,
      timestamp: ts,
      sensores: extra,
    );
  }

  double _generateRealisticValue(String id) {
    switch (id) {
      case 'temperatura':
        return 24.0 + _random.nextDouble() * 4.0;
      case 'humedad':
        return 42.0 + _random.nextDouble() * 8.0;
      case 'caudal':
        return 48.0 + _random.nextDouble() * 5.0;
      case 'presion':
        return 5.8 + _random.nextDouble() * 0.7;
      case 'rpm':
        return 1440.0 + _random.nextDouble() * 120.0;
      case 'consumo_electrico':
        return 4.2 + _random.nextDouble() * 1.5;
      case 'temp_motor':
        return 48.0 + _random.nextDouble() * 12.0;
      case 'temp_reductor':
        return 38.0 + _random.nextDouble() * 7.0;
      case 'temp_producto_entrada':
        return 18.0 + _random.nextDouble() * 3.0;
      case 'temp_producto_salida':
        return 75.0 + _random.nextDouble() * 10.0;
      case 'nivel_aceite':
        return 85.0 + _random.nextDouble() * 10.0;
      case 'vibracion_axial':
        return 0.2 + _random.nextDouble() * 0.4;
      case 'vibracion_radial':
        return 0.1 + _random.nextDouble() * 0.3;
      case 'voltaje_fase':
        return 398.0 + _random.nextDouble() * 5.0;
      case 'corriente_fase':
        return 12.5 + _random.nextDouble() * 2.0;
      default:
        return 10.0 + _random.nextDouble() * 50.0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _selectTimeRange() async {
    final TimeOfDay? start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: "HORA INICIO ANÁLISIS",
    );
    if (start == null) return;

    final TimeOfDay? end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(minutes: 30)),
      ),
      helpText: "HORA FIN ANÁLISIS",
    );
    if (end == null) return;

    final now = DateTime.now();
    setState(() {
      _analysisStart = DateTime(
        now.year,
        now.month,
        now.day,
        start.hour,
        start.minute,
      );
      _analysisEnd = DateTime(
        now.year,
        now.month,
        now.day,
        end.hour,
        end.minute,
      );
      _isPaused = true;
      if (_playbackHistory.isEmpty) _refreshData();
    });
  }

  void _clearAnalysis() {
    setState(() {
      _analysisStart = null;
      _analysisEnd = null;
      _isPaused = false;
      _playbackOffset = 0;
    });
    _refreshData(); // Volver al flujo real inmediatamente
  }

  @override
  Widget build(BuildContext context) {
    if (_machineMap == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final Maquina maquina = Maquina.fromJson(_machineMap!);

    return Scaffold(
      backgroundColor: IndustrialTheme.spaceCadet,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              maquina.nombre.toUpperCase(),
              style: const TextStyle(
                letterSpacing: 2,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "ESTACIÓN DE ANÁLISIS",
              style: TextStyle(
                color: IndustrialTheme.neonCyan.withValues(alpha: 0.7),
                fontSize: 8,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: IndustrialTheme.neonCyan),
            onPressed: () => _showIndustrialConfigDialog(maquina),
          ),
          IconButton(
            icon: Icon(
              _analysisStart != null
                  ? Icons.history_toggle_off
                  : Icons.more_time,
              color: _analysisStart != null
                  ? IndustrialTheme.warningOrange
                  : IndustrialTheme.slateGray,
            ),
            onPressed: _analysisStart != null
                ? _clearAnalysis
                : _selectTimeRange,
          ),
        ],
      ),
      body: _playbackHistory.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: IndustrialTheme.neonCyan),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAnalysisHeader(),
                  const SizedBox(height: 10),
                  _buildAnomalyTracker(
                    maquina,
                    _playbackHistory.isNotEmpty ? _playbackHistory.last : null,
                  ),
                  const SizedBox(height: 10),
                  _buildMainChart(maquina),
                  const SizedBox(height: 20),
                  _buildPlaybackBar(),
                  const SizedBox(height: 32),
                  _buildBottomMetadata(maquina),
                ],
              ),
            ),
    );
  }

  Widget _buildAnalysisHeader() {
    String status = _isPaused ? "MODO ANÁLISIS" : "MONITORIZACIÓN LIVE";
    Color col = _isPaused
        ? IndustrialTheme.warningOrange
        : IndustrialTheme.operativeGreen;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status,
              style: TextStyle(
                color: col,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            if (_analysisStart != null)
              Text(
                "${DateFormat.Hm().format(_analysisStart!)} - ${DateFormat.Hm().format(_analysisEnd!)}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: IndustrialTheme.claudCloud,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.query_stats,
                color: IndustrialTheme.neonCyan,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                "${_playbackHistory.length} REGISTROS",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainChart(Maquina maquina) {
    List<Telemetria> viewData;
    if (_analysisStart != null && _analysisEnd != null) {
      // Filtrado inclusivo para evitar gráficas vacías por milisegundos
      viewData = _playbackHistory
          .where(
            (t) =>
                (t.timestamp.isAfter(_analysisStart!) ||
                    t.timestamp.isAtSameMomentAs(_analysisStart!)) &&
                (t.timestamp.isBefore(_analysisEnd!) ||
                    t.timestamp.isAtSameMomentAs(_analysisEnd!)),
          )
          .toList();

      // Si no hay datos en el buffer real para ese tramo, mostramos los últimos para evitar pantalla vacía
      if (viewData.isEmpty && _playbackHistory.isNotEmpty) {
        viewData = _playbackHistory.sublist(
          math.max(0, _playbackHistory.length - 40),
        );
      }
    } else {
      int endIndex = _playbackHistory.length - _playbackOffset;
      if (endIndex < 10) endIndex = 10;
      int startIndex = endIndex - 30;
      if (startIndex < 0) startIndex = 0;
      viewData = _playbackHistory.sublist(startIndex, endIndex);
    }

    return Column(
      children: [
        IndustrialChart(
          telemetria: viewData,
          maquina: maquina,
          isVirtual: _isUsingDigitalTwin,
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildPlaybackBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _playbackIcon(
                Icons.keyboard_double_arrow_left,
                () => setState(() {
                  _isPaused = true;
                  _playbackOffset = math.min(
                    _playbackHistory.length - 30,
                    _playbackOffset + 10,
                  );
                }),
              ),
              _playbackIcon(
                Icons.arrow_back_ios_new,
                () => setState(() {
                  _isPaused = true;
                  _playbackOffset = math.min(
                    _playbackHistory.length - 30,
                    _playbackOffset + 2,
                  );
                }),
              ),

              GestureDetector(
                onTap: () => setState(() {
                  _isPaused = !_isPaused;
                  if (!_isPaused) {
                    _playbackOffset = 0;
                    _analysisStart = null;
                    _analysisEnd = null;
                    _refreshData(); // Salto inmediato al "ahora"
                  }
                }),
                child: CircleAvatar(
                  backgroundColor: _isPaused
                      ? IndustrialTheme.warningOrange
                      : IndustrialTheme.neonCyan,
                  radius: 24,
                  child: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    color: IndustrialTheme.spaceCadet,
                    size: 28,
                  ),
                ),
              ),

              _playbackIcon(
                Icons.arrow_forward_ios,
                () => setState(() {
                  if (_playbackOffset > 0)
                    _playbackOffset = math.max(0, _playbackOffset - 2);
                }),
              ),
              _playbackIcon(
                Icons.keyboard_double_arrow_right,
                () => setState(() {
                  _playbackOffset = 0;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "CONTROL DE NAVEGACIÓN TEMPORAL",
            style: TextStyle(
              color: IndustrialTheme.slateGray,
              fontSize: 8,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _playbackIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 20, color: Colors.white70),
      onPressed: onTap,
    );
  }

  Widget _buildBottomMetadata(Maquina maquina) {
    return Column(
      children: [
        _buildActionItem(
          Icons.settings_applications,
          "PANEL DE CONFIGURACIÓN AVANZADA",
          () => _showAdvancedConfigDialog(maquina),
        ),
        _buildActionItem(
          Icons.analytics,
          "ANÁLISIS DE EFICIENCIA OPERATIVA (OEE)",
          () {},
        ),
        _buildActionItem(
          Icons.file_download,
          "EXPORTAR REPORTE CRONOLÓGICO (CSV/PDF)",
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Exportando telemetría... El archivo se guardará en descargas.",
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          "TFGS_SMR // GMAO INDUSTRIAL v1.6.2",
          style: TextStyle(
            color: IndustrialTheme.slateGray.withOpacity(0.5),
            fontSize: 7,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: IndustrialTheme.neonCyan, size: 18),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward,
        color: IndustrialTheme.slateGray,
        size: 14,
      ),
      onTap: onTap,
    );
  }

  void _showIndustrialConfigDialog(Maquina maquina) {
    final allMetrics = MetricDefinition.all;
    List<String> tempSelection = List.from(maquina.sensoresConfigurados);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: IndustrialTheme.claudCloud,
          title: const Text(
            "CONFIGURACIÓN DE SENSORES",
            style: TextStyle(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allMetrics.length,
              itemBuilder: (context, i) {
                final m = allMetrics[i];
                final isSelected = tempSelection.contains(m.id);
                return CheckboxListTile(
                  title: Text(
                    m.label,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  subtitle: Text(
                    "${m.unit}",
                    style: const TextStyle(
                      fontSize: 10,
                      color: IndustrialTheme.slateGray,
                    ),
                  ),
                  secondary: Icon(
                    m.icon,
                    color: isSelected ? m.color : IndustrialTheme.slateGray,
                  ),
                  value: isSelected,
                  activeColor: IndustrialTheme.neonCyan,
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) {
                        tempSelection.add(m.id);
                      } else {
                        tempSelection.remove(m.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              onPressed: () async {
                final n = Maquina(
                  id: maquina.id,
                  nombre: maquina.nombre,
                  ubicacion: maquina.ubicacion,
                  estado: maquina.estado,
                  limiteA: maquina.limiteA,
                  limiteMA: maquina.limiteMA,
                  sensoresConfigurados: tempSelection,
                );
                await _maquinaService.update(n);
                setState(() => _machineMap = n.toJson());
                Navigator.pop(context);
                _refreshData();
              },
              child: const Text("APLICAR CAMBIOS"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvancedConfigDialog(Maquina maquina) {
    final cMA = TextEditingController(
      text: (maquina.limiteMA ?? 0.0).toStringAsFixed(1),
    );
    final cA = TextEditingController(
      text: (maquina.limiteA ?? 0.0).toStringAsFixed(1),
    );
    final cB = TextEditingController(
      text: (maquina.limiteB ?? 0.0).toStringAsFixed(1),
    );
    final cMB = TextEditingController(
      text: (maquina.limiteMB ?? 0.0).toStringAsFixed(1),
    );
    bool rf = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: IndustrialTheme.claudCloud,
          title: const Text(
            "CONSIGNAS GEMELO DIGITAL",
            style: TextStyle(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThresholdField(
                  "Límite MUY ALTO (HH)",
                  cMA,
                  IndustrialTheme.criticalRed,
                ),
                _buildThresholdField(
                  "Límite ALTO (H)",
                  cA,
                  IndustrialTheme.warningOrange,
                ),
                _buildThresholdField(
                  "Límite BAJO (L)",
                  cB,
                  IndustrialTheme.neonCyan,
                ),
                _buildThresholdField(
                  "Límite MUY BAJO (LL)",
                  cMB,
                  Colors.deepPurple,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text(
                    "Forzar Relé Virtual",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  subtitle: const Text(
                    "Ignora límites físicos temporales",
                    style: TextStyle(
                      color: IndustrialTheme.slateGray,
                      fontSize: 8,
                    ),
                  ),
                  value: rf,
                  activeColor: IndustrialTheme.neonCyan,
                  onChanged: (v) => setDialogState(() => rf = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              onPressed: () async {
                final payload = {
                  "muyAlto": double.tryParse(cMA.text) ?? 0.0,
                  "alto": double.tryParse(cA.text) ?? 0.0,
                  "bajo": double.tryParse(cB.text) ?? 0.0,
                  "muyBajo": double.tryParse(cMB.text) ?? 0.0,
                  "releForzado": rf,
                };
                await _maquinaService.updateConfig(maquina.id, payload);
                Navigator.pop(context);
                _refreshData();
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Consignas actualizadas en servidor central",
                      ),
                    ),
                  );
              },
              child: const Text("APLICAR CONFIG"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdField(
    String label,
    TextEditingController ctrl,
    Color c,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: c, fontSize: 10, letterSpacing: 1),
          suffixText: '°C',
          suffixStyle: TextStyle(color: c, fontSize: 12),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: c.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: c, width: 2),
          ),
          filled: true,
          fillColor: c.withValues(alpha: 0.07),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildAnomalyTracker(Maquina maquina, Telemetria? lastData) {
    if (lastData == null) return const SizedBox();
    double temp = lastData.temperatura;

    // Evaluador de Consignas
    String level = 'NORMAL';
    Color alertColor = IndustrialTheme.operativeGreen;
    if (maquina.limiteMA != null && temp >= maquina.limiteMA!) {
      level = 'MUY ALTO';
      alertColor = IndustrialTheme.criticalRed;
    } else if (maquina.limiteA != null && temp >= maquina.limiteA!) {
      level = 'ALTO';
      alertColor = IndustrialTheme.warningOrange;
    } else if (maquina.limiteMB != null && temp <= maquina.limiteMB!) {
      level = 'MUY BAJO';
      alertColor = Colors.deepPurple;
    } else if (maquina.limiteB != null && temp <= maquina.limiteB!) {
      level = 'BAJO';
      alertColor = IndustrialTheme.neonCyan;
    }

    if (level == 'NORMAL') return const SizedBox();

    return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: IndustrialTheme.claudCloud,
            border: Border.all(color: alertColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: alertColor),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ANOMALÍA: \$level",
                        style: TextStyle(
                          color: alertColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const Text(
                        "Umbral de seguridad rebasado.",
                        style: TextStyle(color: Colors.white70, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: alertColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Aviso de anomalía creado: Diríjase a 'OTs' para gestionarlo.",
                      ),
                    ),
                  );
                },
                child: const Text(
                  "GEN. AVISO",
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
        .shimmer(duration: 2.seconds, color: alertColor.withValues(alpha: 0.3));
  }
}
