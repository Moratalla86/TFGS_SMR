import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/maquina.dart';
import '../models/metric_config.dart';
import '../services/maquina_service.dart';
import '../theme/industrial_theme.dart';
import '../services/app_session.dart';
import '../utils/metric_definitions.dart';

class ActivosPLCScreen extends StatefulWidget {
  const ActivosPLCScreen({super.key});

  @override
  State<ActivosPLCScreen> createState() => _ActivosPLCScreenState();
}

class _ActivosPLCScreenState extends State<ActivosPLCScreen> {
  final MaquinaService _service = MaquinaService();
  List<Maquina> _maquinas = [];
  List<Maquina> _filteredMaquinas = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaquinas();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredMaquinas = _maquinas
          .where((m) =>
              (m.nombre.toLowerCase().contains(_searchController.text.toLowerCase())) ||
              (m.modelo?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
              (m.ubicacion.toLowerCase().contains(_searchController.text.toLowerCase())))
          .toList();
    });
  }

  Future<void> _loadMaquinas() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchMaquinas();
      setState(() {
        _maquinas = data;
        _filteredMaquinas = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _eliminar(Maquina m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: IndustrialTheme.claudCloud,
        title: const Text('CONFIRMAR ELIMINACIÓN'),
        content: Text(
          '¿Desea eliminar el activo ${m.nombre} (${m.modelo})?\nEsta acción no se puede deshacer.',
          style: const TextStyle(color: IndustrialTheme.slateGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: IndustrialTheme.criticalRed,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ELIMINAR ACTIVO',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && m.id != null) {
      try {
        await _service.eliminarMaquina(m.id!);
        _loadMaquinas();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activo eliminado del sistema.'),
              backgroundColor: IndustrialTheme.operativeGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: IndustrialTheme.criticalRed,
            ),
          );
        }
      }
    }
  }

  void _showForm({Maquina? maquina}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MaquinaFormDialog(
        maquina: maquina,
        onSaved: _loadMaquinas,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = AppSession.instance.canManageAssets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('INVENTARIO DE ACTIVOS PLC', style: TextStyle(letterSpacing: 1.5, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMaquinas,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: IndustrialTheme.neonCyan))
                : _error != null
                    ? _buildErrorPlaceholder()
                    : _filteredMaquinas.isEmpty
                        ? _buildEmptyPlaceholder()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredMaquinas.length,
                            itemBuilder: (context, index) {
                              final m = _filteredMaquinas[index];
                              return _buildMachineCard(m, canManage);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => _showForm(),
              backgroundColor: IndustrialTheme.neonCyan,
              child: const Icon(Icons.add, color: IndustrialTheme.spaceCadet),
            ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack)
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: IndustrialTheme.spaceCadet,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, modelo o ubicación...',
          hintStyle: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 12),
          prefixIcon: const Icon(Icons.search, color: IndustrialTheme.neonCyan),
          fillColor: IndustrialTheme.claudCloud,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildMachineCard(Maquina m, bool canManage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: IndustrialTheme.spaceCadet,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.precision_manufacturing, color: IndustrialTheme.neonCyan),
        ),
        title: Text(
          m.nombre.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('MODELO: ${m.modelo}', style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 11)),
            Text('UBICACIÓN: ${m.ubicacion}', style: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: m.estado == 'OK' ? IndustrialTheme.operativeGreen.withOpacity(0.2) : IndustrialTheme.criticalRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: m.estado == 'OK' ? IndustrialTheme.operativeGreen : IndustrialTheme.criticalRed),
                  ),
                  child: Text(
                    m.estado,
                    style: TextStyle(
                      color: m.estado == 'OK' ? IndustrialTheme.operativeGreen : IndustrialTheme.criticalRed,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${m.configs.length} SENSORES', style: const TextStyle(fontSize: 10, color: IndustrialTheme.slateGray)),
              ],
            ),
          ],
        ),
        trailing: canManage
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: IndustrialTheme.neonCyan),
                    onPressed: () => _showForm(maquina: m),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: IndustrialTheme.criticalRed),
                    onPressed: () => _eliminar(m),
                  ),
                ],
              )
            : const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () {
          Navigator.pushNamed(context, '/machine-detail', arguments: m.toJson());
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: IndustrialTheme.criticalRed),
          const SizedBox(height: 16),
          Text(
            'Error al sincronizar inventario\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: IndustrialTheme.slateGray),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadMaquinas,
            child: const Text('REINTENTAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 60, color: IndustrialTheme.slateGray),
          const SizedBox(height: 16),
          const Text(
            'No se han encontrado activos industriales',
            style: TextStyle(color: IndustrialTheme.slateGray),
          ),
        ],
      ),
    );
  }
}

class _MaquinaFormDialog extends StatefulWidget {
  final Maquina? maquina;
  final VoidCallback onSaved;

  const _MaquinaFormDialog({this.maquina, required this.onSaved});

  @override
  State<_MaquinaFormDialog> createState() => _MaquinaFormDialogState();
}

class _MaquinaFormDialogState extends State<_MaquinaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final MaquinaService _service = MaquinaService();
  late TextEditingController _nombreController;
  late TextEditingController _modeloController;
  late TextEditingController _ubicacionController;
  late TextEditingController _descripcionController;
  final Map<String, MetricConfig> _selectedMetrics = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.maquina?.nombre);
    _modeloController = TextEditingController(text: widget.maquina?.modelo);
    _ubicacionController = TextEditingController(text: widget.maquina?.ubicacion);
    _descripcionController = TextEditingController(text: widget.maquina?.descripcion);
    
    if (widget.maquina != null) {
      for (var config in widget.maquina!.configs) {
        _selectedMetrics[config.nombreMetrica] = config;
      }
    } else {
      _toggleMetric('temperatura', true);
    }
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
        config.limiteMB = MetricDefinition.convert(config.limiteMB ?? 0, oldUnit, newUnit, metricId);
        config.limiteB = MetricDefinition.convert(config.limiteB ?? 0, oldUnit, newUnit, metricId);
        config.limiteA = MetricDefinition.convert(config.limiteA ?? 0, oldUnit, newUnit, metricId);
        config.limiteMA = MetricDefinition.convert(config.limiteMA ?? 0, oldUnit, newUnit, metricId);
        _selectedMetrics[metricId] = config.copyWith(unidadSeleccionada: newUnit);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: IndustrialTheme.spaceCadet,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.maquina == null ? 'ALTA DE ACTIVO' : 'EDITAR ACTIVO',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: IndustrialTheme.neonCyan),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: IndustrialTheme.slateGray),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(_nombreController, "NOMBRE (EJ: TORNO X1)", Icons.precision_manufacturing),
                      _buildTextField(_modeloController, "MODELO / SERIE", Icons.badge),
                      _buildTextField(_ubicacionController, "UBICACIÓN", Icons.location_on),
                      _buildTextField(_descripcionController, "DESCRIPCIÓN", Icons.description, maxLines: 2),
                      const SizedBox(height: 20),
                      const Text("SENSORES Y LÍMITES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IndustrialTheme.neonCyan)),
                      const SizedBox(height: 10),
                      ...MetricDefinition.all.map((def) => _buildMetricTile(def)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCELAR', style: TextStyle(color: IndustrialTheme.slateGray)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IndustrialTheme.neonCyan,
                      foregroundColor: IndustrialTheme.spaceCadet,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: IndustrialTheme.spaceCadet))
                        : Text(widget.maquina == null ? 'REGISTRAR ACTIVO' : 'GUARDAR CAMBIOS', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: IndustrialTheme.neonCyan, size: 18),
          labelText: label,
          labelStyle: const TextStyle(color: IndustrialTheme.slateGray, fontSize: 11),
          fillColor: IndustrialTheme.claudCloud,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
      ),
    );
  }

  Widget _buildMetricTile(MetricDefinition def) {
    final bool isSelected = _selectedMetrics.containsKey(def.id);
    final config = _selectedMetrics[def.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? def.color.withOpacity(0.3) : Colors.transparent),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            value: isSelected,
            onChanged: (v) => _toggleMetric(def.id, v),
            title: Text(def.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            secondary: Icon(def.icon, color: isSelected ? def.color : IndustrialTheme.slateGray, size: 20),
            activeColor: def.color,
          ),
          if (isSelected && config != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text("UNIDAD:", style: TextStyle(fontSize: 10, color: IndustrialTheme.slateGray)),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        isDense: true,
                        value: config.unidadSeleccionada,
                        dropdownColor: IndustrialTheme.spaceCadet,
                        style: TextStyle(color: def.color, fontSize: 12, fontWeight: FontWeight.bold),
                        onChanged: (v) => _onUnitChanged(def.id, v!),
                        items: def.supportedUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildLimitInput("M.B", config.limiteMB, (v) => config.limiteMB = v),
                      const SizedBox(width: 8),
                      _buildLimitInput("B", config.limiteB, (v) => config.limiteB = v),
                      const SizedBox(width: 8),
                      _buildLimitInput("A", config.limiteA, (v) => config.limiteA = v),
                      const SizedBox(width: 8),
                      _buildLimitInput("M.A", config.limiteMA, (v) => config.limiteMA = v),
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
          SizedBox(
            height: 30,
            child: TextFormField(
              initialValue: value?.toStringAsFixed(1),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 11, color: Colors.white),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                fillColor: IndustrialTheme.spaceCadet,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMetrics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleccione al menos una métrica")));
      return;
    }

    setState(() => _loading = true);
    try {
      final data = Maquina(
        id: widget.maquina?.id ?? 0,
        nombre: _nombreController.text,
        modelo: _modeloController.text,
        ubicacion: _ubicacionController.text,
        descripcion: _descripcionController.text,
        estado: widget.maquina?.estado ?? 'OK',
        configs: _selectedMetrics.values.toList(),
      );

      bool success;
      if (widget.maquina == null) {
        success = await _service.crearMaquina(data);
      } else {
        success = await _service.update(data);
      }

      if (success) {
        widget.onSaved();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: IndustrialTheme.criticalRed));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
