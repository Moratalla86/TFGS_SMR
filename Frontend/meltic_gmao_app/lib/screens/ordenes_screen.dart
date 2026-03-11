import 'package:flutter/material.dart';
import '../models/orden_trabajo.dart';
import '../models/usuario.dart';
import '../services/orden_trabajo_service.dart';
import '../services/usuario_service.dart';
import '../services/maquina_service.dart';
import '../models/maquina.dart';
import '../services/app_session.dart';
import 'ot_detail_screen.dart';

class OrdenesScreen extends StatefulWidget {
  const OrdenesScreen({super.key});

  @override
  State<OrdenesScreen> createState() => _OrdenesScreenState();
}

class _OrdenesScreenState extends State<OrdenesScreen> {
  final _otService = OrdenTrabajoService();
  List<OrdenTrabajo> _ordenes = [];
  bool _loading = true;
  String? _error;

  final _session = AppSession.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      List<OrdenTrabajo> data;
      if (_session.isJefe) {
        data = await _otService.fetchOrdenes();
      } else {
        // Técnico: solo sus OTs
        data = await _otService.fetchOrdenesPorTecnico(_session.userId!);
      }
      setState(() { _ordenes = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _eliminar(OrdenTrabajo ot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar OT #${ot.id}? Esta acción es irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _otService.eliminarOT(ot.id);
        _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
      case 'EN_PROCESO': return Colors.orange;
      case 'CERRADA': return Colors.green;
      default: return Colors.blue[700]!;
    }
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case 'EN_PROCESO': return 'En Proceso';
      case 'CERRADA': return 'Cerrada';
      default: return 'Pendiente';
    }
  }

  Color _prioridadColor(String p) {
    switch (p) {
      case 'ALTA': return Colors.red;
      case 'MEDIA': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_session.isJefe ? 'Gestión de OTs' : 'Mis Órdenes de Trabajo'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.wifi_off, size: 60, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('Error de conexión', style: TextStyle(color: Colors.grey[700], fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
                  ]),
                )
              : Column(children: [
                  _buildSummaryBar(),
                  Expanded(
                    child: _ordenes.isEmpty
                        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('No hay órdenes de trabajo', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                          ]))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _ordenes.length,
                              itemBuilder: (_, i) => _buildOTCard(_ordenes[i]),
                            ),
                          ),
                  ),
                ]),
      floatingActionButton: _session.isJefe
          ? FloatingActionButton.extended(
              onPressed: _abrirCrear,
              backgroundColor: Colors.blue[900],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task),
              label: const Text('Nueva OT'),
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
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Pendientes', '$pendientes', Icons.hourglass_empty, Colors.white70),
          _summaryItem('En Proceso', '$enProceso', Icons.play_circle_outlined, Colors.orangeAccent),
          _summaryItem('Cerradas', '$cerradas', Icons.check_circle_outlined, Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildOTCard(OrdenTrabajo ot) {
    final estadoColor = _estadoColor(ot.estado);
    final prioColor = _prioridadColor(ot.prioridad);
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => OTDetailScreen(ot: ot)));
        if (changed == true) _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // ── Cabecera ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Text('OT #${ot.id}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: estadoColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(_estadoLabel(ot.estado), style: TextStyle(color: estadoColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: prioColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(ot.prioridad, style: TextStyle(color: prioColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // ── Contenido ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ot.descripcion, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Wrap(spacing: 16, runSpacing: 4, children: [
                    if (ot.maquinaNombre != null) _chip(Icons.precision_manufacturing_outlined, ot.maquinaNombre!),
                    if (ot.tecnicoNombre != null) _chip(Icons.engineering_outlined, ot.tecnicoNombre!),
                    if (ot.fechaInicio != null) _chip(Icons.play_arrow_outlined, 'Inicio: ${_formatDate(ot.fechaInicio!)}', color: Colors.orange),
                    if (ot.fechaFin != null) _chip(Icons.stop_circle_outlined, 'Fin: ${_formatDate(ot.fechaFin!)}', color: Colors.green),
                  ]),
                ],
              ),
            ),
            // ── Acciones rápidas ────────────────────────────────────
            if (_session.isJefe)
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => OTDetailScreen(ot: ot)));
                        if (changed == true) _load();
                      },
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('Ver / Editar'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.blue[800], side: BorderSide(color: Colors.blue[200]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _eliminar(ot),
                      icon: const Icon(Icons.delete_outline, size: 14),
                      label: const Text('Eliminar'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red[700], side: BorderSide(color: Colors.red[200]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                    ),
                  ],
                ),
              )
            else if (ot.estado == 'PENDIENTE')
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => OTDetailScreen(ot: ot)));
                      if (changed == true) _load();
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Iniciar OT'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                  ),
                ),
              )
            else if (ot.estado == 'EN_PROCESO')
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => OTDetailScreen(ot: ot)));
                      if (changed == true) _load();
                    },
                    icon: const Icon(Icons.edit_document, size: 16),
                    label: const Text('Ver / Cerrar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, {Color? color}) {
    final c = color ?? Colors.grey[600]!;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: c),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: c, fontSize: 12)),
    ]);
  }

  String _formatDate(String dt) {
    try {
      final parts = dt.split('T');
      return parts[0];
    } catch (_) {
      return dt;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diálogo de creación de OT (Jefe)
// ─────────────────────────────────────────────────────────────────────────────
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
        _tecnicos = users.where((u) => u.rol == 'TECNICO' || u.rol == 'JEFE_MANTENIMIENTO').toList();
        _maquinas = maq;
      });
    } catch (_) {}
  }

  @override
  void dispose() { _desc.dispose(); super.dispose(); }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final ot = OrdenTrabajo(id: 0, descripcion: _desc.text.trim(), prioridad: _prioridad, estado: 'PENDIENTE');
      await _otService.crearOrden(ot, tecnicoId: _tecnicoId, maquinaId: _maquinaId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label, prefixIcon: Icon(icon, size: 18),
    filled: true, fillColor: Colors.grey[50],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Cabecera
              Row(children: [
                CircleAvatar(backgroundColor: Colors.blue[50], child: Icon(Icons.add_task, color: Colors.blue[900])),
                const SizedBox(width: 12),
                Text('Nueva Orden de Trabajo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[900])),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, false)),
              ]),
              const SizedBox(height: 20),
              // Descripción
              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: _deco('Descripción del trabajo *', Icons.description_outlined),
                validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              // Prioridad
              DropdownButtonFormField<String>(
                value: _prioridad,
                decoration: _deco('Prioridad', Icons.flag_outlined),
                items: ['ALTA', 'MEDIA', 'BAJA'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _prioridad = v!),
              ),
              const SizedBox(height: 12),
              // Técnico
              DropdownButtonFormField<int?>(
                value: _tecnicoId,
                decoration: _deco('Asignar Técnico', Icons.engineering_outlined),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Sin asignar')),
                  ..._tecnicos.map((u) => DropdownMenuItem<int?>(value: u.id, child: Text(u.nombreCompleto))),
                ],
                onChanged: (v) => setState(() => _tecnicoId = v),
              ),
              const SizedBox(height: 12),
              // Máquina
              DropdownButtonFormField<int?>(
                value: _maquinaId,
                decoration: _deco('Máquina afectada', Icons.precision_manufacturing_outlined),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Sin especificar')),
                  ..._maquinas.map((m) => DropdownMenuItem<int?>(value: m.id, child: Text(m.nombre))),
                ],
                onChanged: (v) => setState(() => _maquinaId = v),
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancelar')),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _guardar,
                  icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
                  label: const Text('Crear OT'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
