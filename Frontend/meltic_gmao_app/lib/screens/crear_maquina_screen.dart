import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/maquina.dart';
import '../models/metric_config.dart';
import '../services/maquina_service.dart';
import '../theme/industrial_theme.dart';
import '../utils/metric_definitions.dart';

class CrearMaquinaScreen extends StatefulWidget {
  const CrearMaquinaScreen({super.key});

  @override
  State<CrearMaquinaScreen> createState() => _CrearMaquinaScreenState();
}

class _CrearMaquinaScreenState extends State<CrearMaquinaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _maquinaService = MaquinaService();

  final _nombreController = TextEditingController();
  final _modeloController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _descripcionController = TextEditingController();

  // Mapa para trackear qué métricas están activas y sus valores
  final Map<String, MetricConfig> _selectedMetrics = {};

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Por defecto, añadimos temperatura como métrica sugerida
    _toggleMetric('temperatura', true);
  }

  void _toggleMetric(String metricId, bool? value) {
    setState(() {
      if (value == true) {
        final def = MetricDefinition.getById(metricId);
        _selectedMetrics[metricId] = MetricConfig(
          nombreMetrica: metricId,
          unidadSeleccionada: def.supportedUnits.isNotEmpty ? def.supportedUnits[0] : def.unit,
          limiteMB: 10.0,
          limiteB: 15.0,
          limiteA: 45.0,
          limiteMA: 60.0,
        );
      } else {
        _selectedMetrics.remove(metricId);
      }
    });
  }

  void _onUnitChanged(String metricId, String newUnit) {
    setState(() {
      final config = _selectedMetrics[metricId];
      if (config != null) {
        final oldUnit = config.unidadSeleccionada;
        
        // OPCIÓN B: Conversión automática de límites
        config.limiteMB = MetricDefinition.convert(config.limiteMB ?? 0, oldUnit, newUnit, metricId);
        config.limiteB = MetricDefinition.convert(config.limiteB ?? 0, oldUnit, newUnit, metricId);
        config.limiteA = MetricDefinition.convert(config.limiteA ?? 0, oldUnit, newUnit, metricId);
        config.limiteMA = MetricDefinition.convert(config.limiteMA ?? 0, oldUnit, newUnit, metricId);
        
        // Actualizar unidad
        _selectedMetrics[metricId] = config.copyWith(unidadSeleccionada: newUnit);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ALTA DE ACTIVO INDUSTRIAL', style: TextStyle(letterSpacing: 1.5, fontSize: 14)),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: IndustrialTheme.neonCyan))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("DATOS TÉCNICOS BÁSICOS"),
                  const SizedBox(height: 15),
                  _buildTextField(_nombreController, "NOMBRE DE MÁQUINA (EJ: TORNO X1)", Icons.precision_manufacturing),
                  _buildTextField(_modeloController, "MODELO / SERIE", Icons.badge),
                  _buildTextField(_ubicacionController, "UBICACIÓN (PLANTA / SECCIÓN)", Icons.location_on),
                  _buildTextField(_descripcionController, "DESCRIPCIÓN ADICIONAL", Icons.description, maxLines: 2),

                  const SizedBox(height: 30),
                  _buildSectionHeader("CONFIGURACIÓN DE SENSORES Y MÉTRICAS"),
                  const SizedBox(height: 10),
                  const Text(
                    "Selecciona los parámetros que este activo enviará al sistema:",
                    style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 12),
                  ),
                  const SizedBox(height: 15),

                  // Lista de métricas disponibles
                  ...MetricDefinition.all.map((def) => _buildMetricTile(def)),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveMachine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: IndustrialTheme.neonCyan,
                        foregroundColor: IndustrialTheme.spaceCadet,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("GUARDAR E INICIALIZAR ACTIVO", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: IndustrialTheme.neonCyan,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Divider(color: Colors.white10),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: IndustrialTheme.neonCyan, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: IndustrialTheme.neonCyan),
          ),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Campo obligatorio" : null,
      ),
    );
  }

  Widget _buildMetricTile(MetricDefinition def) {
    final bool isSelected = _selectedMetrics.containsKey(def.id);
    final config = _selectedMetrics[def.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? def.color.withOpacity(0.5) : Colors.transparent),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: isSelected,
            onChanged: (v) => _toggleMetric(def.id, v),
            title: Text(def.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            secondary: Icon(def.icon, color: isSelected ? def.color : IndustrialTheme.slateGray),
            activeColor: def.color,
            subtitle: Text(isSelected ? "Configurando límites..." : "Click para habilitar", 
                           style: TextStyle(fontSize: 11, color: IndustrialTheme.slateGray)),
          ),
          if (isSelected && config != null) 
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(color: Colors.white10),
                  Row(
                    children: [
                      const Text("UNIDAD:", style: TextStyle(fontSize: 11, color: IndustrialTheme.slateGray)),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: config.unidadSeleccionada,
                        dropdownColor: IndustrialTheme.spaceCadet,
                        style: TextStyle(color: def.color, fontSize: 13, fontWeight: FontWeight.bold),
                        onChanged: (v) => _onUnitChanged(def.id, v!),
                        items: def.supportedUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildLimitInput("M. BAJO", config.limiteMB, (v) => config.limiteMB = v),
                      const SizedBox(width: 10),
                      _buildLimitInput("BAJO", config.limiteB, (v) => config.limiteB = v),
                      const SizedBox(width: 10),
                      _buildLimitInput("ALTO", config.limiteA, (v) => config.limiteA = v),
                      const SizedBox(width: 10),
                      _buildLimitInput("M. ALTO", config.limiteMA, (v) => config.limiteMA = v),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLimitInput(String label, double? value, Function(double) onChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: IndustrialTheme.slateGray)),
          const SizedBox(height: 4),
          SizedBox(
            height: 35,
            child: TextFormField(
              initialValue: value?.toStringAsFixed(1),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                fillColor: IndustrialTheme.spaceCadet,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
              ),
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null) onChanged(d);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMachine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMetrics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona al menos una métrica para monitorear")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final nuevaMaquina = Maquina(
        id: 0, // El backend asignará el ID
        nombre: _nombreController.text,
        ubicacion: _ubicacionController.text,
        estado: 'OK',
        modelo: _modeloController.text,
        descripcion: _descripcionController.text,
        configs: _selectedMetrics.values.toList(),
      );

      final success = await _maquinaService.crearMaquina(nuevaMaquina);

      if (success) {
        if (mounted) Navigator.pop(context, true);
      } else {
        throw "Error en la respuesta del servidor";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e"), backgroundColor: IndustrialTheme.criticalRed),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
