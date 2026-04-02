import 'package:flutter/material.dart';
import '../models/orden_trabajo.dart';
import '../models/usuario.dart';
import '../services/orden_trabajo_service.dart';
import '../services/usuario_service.dart';
import '../services/maquina_service.dart';
import '../models/maquina.dart';
import '../services/app_session.dart';
import 'ot_detail_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/industrial_theme.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../utils/pdf_generator.dart';

class OrdenesScreen extends StatefulWidget {
  const OrdenesScreen({super.key});

  @override
  State<OrdenesScreen> createState() => _OrdenesScreenState();
}

class _OrdenesScreenState extends State<OrdenesScreen> {
  final _maquinaService = MaquinaService();
  final _otService = OrdenTrabajoService();

  List<OrdenTrabajo> _ordenes = [];
  List<Maquina> _maquinas = [];
  bool _loading = true;
  String? _error;
  final _session = AppSession.instance;

  // Estado de filtros
  String _searchQuery = "";
  int? _selectedMaquinaId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<OrdenTrabajo> data;
      if (_session.isJefe) {
        data = await _otService.fetchOrdenes();
      } else {
        data = await _otService.fetchOrdenesPorTecnico(_session.userId!);
      }

      final List<Maquina> maq = await _maquinaService.fetchMaquinas();

      setState(() {
        _ordenes = data;
        _maquinas = maq;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<OrdenTrabajo> get _filteredOrdenes {
    return _ordenes.where((ot) {
      // Filtrar por ID (Contiene búsqueda parcial)
      final bool matchesId =
          _searchQuery.isEmpty || ot.id.toString().contains(_searchQuery);

      // Filtrar por Máquina
      final bool matchesMaquina =
          _selectedMaquinaId == null || ot.maquinaId == _selectedMaquinaId;

      // Filtrar por Fecha (solo día/mes/año)
      bool matchesDate = true;
      if (_selectedDate != null && ot.fechaCreacion != null) {
        final date = DateTime.tryParse(ot.fechaCreacion!);
        if (date != null) {
          matchesDate =
              date.year == _selectedDate!.year &&
              date.month == _selectedDate!.month &&
              date.day == _selectedDate!.day;
        } else {
          matchesDate = false;
        }
      }

      return matchesId && matchesMaquina && matchesDate;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = "";
      _selectedMaquinaId = null;
      _selectedDate = null;
    });
  }

  Future<void> _verReportePdf(OrdenTrabajo ot) async {
    if (ot.reportePdfBase64 != null) {
      await PdfGenerator.viewLocalPdf(
        ot.reportePdfBase64!,
        'Reporte_OT_${ot.id}.pdf',
      );
    } else {
      // Si no existe el PDF, lo generamos al vuelo. Decodificamos checklists.
      Map<String, bool> checklists = {};
      if (ot.checklists != null && ot.checklists!.isNotEmpty) {
        try {
          checklists = Map<String, bool>.from(json.decode(ot.checklists!));
        } catch (_) {}
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generando reporte PDF instantáneo...'),
          duration: Duration(seconds: 1),
        ),
      );
      await PdfGenerator.generarYVerPdf(ot, checklists);
    }
  }

  Future<void> _eliminar(OrdenTrabajo ot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: IndustrialTheme.claudCloud,
        title: const Text(
          'BAJA DE ORDEN',
          style: TextStyle(letterSpacing: 1.2),
        ),
        content: Text(
          '¿Confirmar eliminación de la OT #${ot.id}? El registro se perderá permanentemente.',
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
              'ELIMINAR TAREA',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _otService.eliminarOT(ot.id);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fallo: $e'),
              backgroundColor: IndustrialTheme.criticalRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _abrirCrear() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CrearOTDialog(),
    );
    if (result == true) _load();
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'EN_PROCESO':
        return IndustrialTheme.warningOrange;
      case 'CERRADA':
        return IndustrialTheme.operativeGreen;
      default:
        return IndustrialTheme.electricBlue;
    }
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case 'EN_PROCESO':
        return 'EN CURSO';
      case 'CERRADA':
        return 'FINALIZADA';
      default:
        return 'PENDIENTE';
    }
  }

  Color _prioridadColor(String p) {
    switch (p) {
      case 'ALTA':
        return IndustrialTheme.criticalRed;
      case 'MEDIA':
        return IndustrialTheme.warningOrange;
      default:
        return IndustrialTheme.slateGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GESTIÓN DE ÓRDENES (OT)',
          style: TextStyle(letterSpacing: 2, fontSize: 16),
        ),
        centerTitle: false,
        actions: [IconButton(icon: const Icon(Icons.sync), onPressed: _load)],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: IndustrialTheme.neonCyan),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 64,
                      color: IndustrialTheme.slateGray.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SERVIDOR NO DISPONIBLE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Comprueba la conexión de red\ny que el servidor esté activo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white30),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('REINTENTAR'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                _buildSummaryBar(),
                _buildFilterSection(),
                Expanded(
                  child: _filteredOrdenes.isEmpty
                      ? const Center(
                          child: Text(
                            'SIN RESULTADOS CON LOS FILTROS ACTUALES',
                            style: TextStyle(
                              color: IndustrialTheme.slateGray,
                              fontSize: 9,
                              letterSpacing: 1.5,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _filteredOrdenes.length + 1,
                            itemBuilder: (_, i) {
                              if (i == _filteredOrdenes.length) {
                                return const SizedBox(height: 80);
                              }
                              return _buildOTCard(_filteredOrdenes[i]);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: _session.isJefe
          ? FloatingActionButton.extended(
              onPressed: _abrirCrear,
              backgroundColor: IndustrialTheme.neonCyan,
              icon: Icon(
                Icons.assignment_add,
                color: IndustrialTheme.spaceCadet,
              ),
              label: Text(
                'NUEVA OT',
                style: TextStyle(
                  color: IndustrialTheme.spaceCadet,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSummaryBar() {
    final pendientes = _ordenes.where((o) => o.estado == 'PENDIENTE').length;
    final enProceso = _ordenes.where((o) => o.estado == 'EN_PROCESO').length;
    final cerradas = _ordenes.where((o) => o.estado == 'CERRADA').length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _summaryItem(
              'HOLD',
              '$pendientes',
              Icons.hourglass_top,
              IndustrialTheme.slateGray,
            ),
          ),
          Expanded(
            child: _summaryItem(
              'ACTIVE',
              '$enProceso',
              Icons.settings_input_component,
              IndustrialTheme.warningOrange,
            ),
          ),
          Expanded(
            child: _summaryItem(
              'DONE',
              '$cerradas',
              Icons.verified,
              IndustrialTheme.operativeGreen,
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.5, end: 0);
  }

  Widget _summaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: IndustrialTheme.slateGray,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: IndustrialTheme.spaceCadet.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 60) * 0.4,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 14),
                    hintText: "ID...",
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 60) * 0.55,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedMaquinaId,
                      isExpanded: true,
                      dropdownColor: IndustrialTheme.claudCloud,
                      icon: const Icon(
                        Icons.filter_list,
                        size: 14,
                        color: IndustrialTheme.neonCyan,
                      ),
                      hint: const Text(
                        "MÁQUINA",
                        style: TextStyle(
                          color: IndustrialTheme.slateGray,
                          fontSize: 9,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            "TODAS",
                            style: TextStyle(fontSize: 9),
                          ),
                        ),
                        ..._maquinas.map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(
                              m.nombre.toUpperCase(),
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedMaquinaId = v),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: IndustrialTheme.neonCyan,
                          surface: IndustrialTheme.spaceCadet,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedDate != null
                        ? IndustrialTheme.neonCyan.withValues(alpha: 0.1)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedDate != null
                          ? IndustrialTheme.neonCyan
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: _selectedDate != null
                            ? IndustrialTheme.neonCyan
                            : IndustrialTheme.slateGray,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDate == null
                            ? "FILTRAR FECHA"
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate != null
                              ? IndustrialTheme.neonCyan
                              : IndustrialTheme.slateGray,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty ||
                  _selectedMaquinaId != null ||
                  _selectedDate != null)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(
                    Icons.filter_alt_off,
                    size: 14,
                    color: IndustrialTheme.criticalRed,
                  ),
                  label: const Text(
                    "LIMPIAR",
                    style: TextStyle(
                      color: IndustrialTheme.criticalRed,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOTCard(OrdenTrabajo ot) {
    final estadoColor = _estadoColor(ot.estado);
    final prioColor = _prioridadColor(ot.prioridad);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => OTDetailScreen(ot: ot)),
          );
          if (changed == true) _load();
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'TICKET #${ot.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: IndustrialTheme.slateGray,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: estadoColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      _estadoLabel(ot.estado),
                      style: TextStyle(
                        color: estadoColor,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ot.descripcion,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.priority_high, color: prioColor, size: 14),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (ot.maquinaNombre != null)
                        _infoLabel(
                          Icons.precision_manufacturing,
                          ot.maquinaNombre!,
                        ),
                      if (ot.tecnicoNombre != null)
                        _infoLabel(Icons.engineering, ot.tecnicoNombre!),
                      if (ot.fechaInicio != null)
                        _infoLabel(
                          Icons.access_time,
                          _formatDate(ot.fechaInicio!),
                          color: IndustrialTheme.neonCyan,
                        ),
                    ],
                  ),
                  if (_session.isJefe) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (ot.estado == 'CERRADA')
                          IconButton(
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              color: IndustrialTheme.neonCyan,
                            ),
                            onPressed: () => _verReportePdf(ot),
                            tooltip: "Ver Reporte",
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _eliminar(ot),
                          child: const Text(
                            'BORRAR',
                            style: TextStyle(
                              color: IndustrialTheme.criticalRed,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OTDetailScreen(ot: ot),
                              ),
                            );
                            if (changed == true) _load();
                          },
                          child: const Text('GESTIONAR'),
                        ),
                      ],
                    ),
                  ] else if (ot.estado == 'CERRADA') ...[
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _verReportePdf(ot),
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text(
                            "REPORTE PDF",
                            style: TextStyle(fontSize: 10),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: IndustrialTheme.electricBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _infoLabel(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color ?? IndustrialTheme.slateGray),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color ?? IndustrialTheme.slateGray,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dt) {
    try {
      final date = DateTime.parse(dt);
      return DateFormat.yMMMd('es_ES').format(date);
    } catch (_) {
      return dt;
    }
  }
}

class _CrearOTDialog extends StatefulWidget {
  const _CrearOTDialog();
  @override
  State<_CrearOTDialog> createState() => _CrearOTDialogState();
}

class _CrearOTDialogState extends State<_CrearOTDialog> {
  final _formKey = GlobalKey<FormState>();
  final _otService = OrdenTrabajoService();
  final _usuarioService = UsuarioService();
  final _maquinaService = MaquinaService();
  final _desc = TextEditingController();
  String _prioridad = 'MEDIA';
  String _tipo = 'CORRECTIVA';
  int? _tecnicoId;
  int? _maquinaId;
  bool _saving = false;
  List<Usuario> _tecnicos = [];
  List<Maquina> _maquinas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final users = await _usuarioService.fetchUsuarios();
      final maq = await _maquinaService.fetchMaquinas();
      setState(() {
        _tecnicos = users
            .where((u) => u.rol == 'TECNICO' || u.rol == 'JEFE_MANTENIMIENTO')
            .toList();
        _maquinas = maq;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: IndustrialTheme.spaceCadet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "GENERAR ORDEN DE TRABAJO",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _desc,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "DESCRIPCIÓN DE LA AVERÍA",
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _prioridad,
                  decoration: const InputDecoration(
                    labelText: "GRAVIDAD / PRIORIDAD",
                    prefixIcon: Icon(Icons.priority_high),
                  ),
                  items: ['ALTA', 'MEDIA', 'BAJA']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _prioridad = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(
                    labelText: "TIPO DE MANTENIMIENTO",
                    prefixIcon: Icon(Icons.build_circle_outlined),
                  ),
                  items: ['CORRECTIVA', 'PREVENTIVA']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _tipo = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: _tecnicoId,
                  decoration: const InputDecoration(
                    labelText: "ASIGNAR OPERARIO",
                    prefixIcon: Icon(Icons.person_search),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("SIN ASIGNAR"),
                    ),
                    ..._tecnicos.map(
                      (u) => DropdownMenuItem(
                        value: u.id,
                        child: Text(u.nombreCompleto),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _tecnicoId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: _maquinaId,
                  decoration: const InputDecoration(
                    labelText: "ACTIVO AFECTADO",
                    prefixIcon: Icon(Icons.precision_manufacturing),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("GENERAL/OTRO"),
                    ),
                    ..._maquinas.map(
                      (m) =>
                          DropdownMenuItem(value: m.id, child: Text(m.nombre)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _maquinaId = v),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCELAR"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saving ? null : _guardar,
                      child: _saving
                          ? const CircularProgressIndicator()
                          : const Text("CARGAR ORDEN"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final ot = OrdenTrabajo(
        id: 0,
        descripcion: _desc.text.trim(),
        prioridad: _prioridad,
        estado: 'PENDIENTE',
        tipo: _tipo,
      );
      await _otService.crearOrden(
        ot,
        tecnicoId: _tecnicoId,
        maquinaId: _maquinaId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
    }
  }
}
