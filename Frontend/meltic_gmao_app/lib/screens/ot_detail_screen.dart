import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/orden_trabajo.dart';
import '../services/orden_trabajo_service.dart';
import '../services/app_session.dart';

class OTDetailScreen extends StatefulWidget {
  final OrdenTrabajo ot;
  const OTDetailScreen({super.key, required this.ot});

  @override
  State<OTDetailScreen> createState() => _OTDetailScreenState();
}

class _OTDetailScreenState extends State<OTDetailScreen> {
  final _otService = OrdenTrabajoService();
  final _session = AppSession.instance;
  late OrdenTrabajo _ot;
  bool _saving = false;
  bool _changed = false;

  final _accionesCtrl = TextEditingController();

  // Firma del técnico
  final _firmaTecnicoKey = GlobalKey();
  final List<List<Offset?>> _firmaStrokeTec = [];
  bool _firmaTecDirty = false;

  // Firma del cliente
  final _firmaClienteKey = GlobalKey();
  final List<List<Offset?>> _firmaStrokeCli = [];
  bool _firmaCliDirty = false;

  @override
  void initState() {
    super.initState();
    _ot = widget.ot;
    _accionesCtrl.text = _ot.trabajosRealizados ?? '';
  }

  @override
  void dispose() {
    _accionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    setState(() => _saving = true);
    try {
      final updated = await _otService.iniciarOT(_ot.id);
      setState(() { _ot = updated; _changed = true; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OT iniciada'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _guardarAcciones() async {
    setState(() => _saving = true);
    try {
      final updated = await _otService.actualizarAcciones(_ot.id, _accionesCtrl.text.trim());
      setState(() { _ot = updated; _changed = true; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acciones guardadas'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<String?> _capturarFirma(List<List<Offset?>> strokes, GlobalKey key) async {
    if (strokes.isEmpty) return null;
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      return base64Encode(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<void> _cerrar() async {
    setState(() => _saving = true);
    try {
      final firmaTec = _firmaTecDirty ? await _capturarFirma(_firmaStrokeTec, _firmaTecnicoKey) : null;
      final firmaCli = _firmaCliDirty ? await _capturarFirma(_firmaStrokeCli, _firmaClienteKey) : null;
      final updated = await _otService.cerrarOT(
        _ot.id,
        trabajos: _accionesCtrl.text.trim(),
        firmaTecnico: firmaTec,
        firmaCliente: firmaCli,
      );
      setState(() { _ot = updated; _changed = true; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ OT cerrada correctamente'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _saving = false);
    }
  }

  Color _estadoColor(String e) {
    switch (e) {
      case 'EN_PROCESO': return Colors.orange;
      case 'CERRADA': return Colors.green;
      default: return Colors.blue[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCerrada = _ot.estado == 'CERRADA';
    final esTecnico = _session.isTecnico;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text('OT #${_ot.id}', style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context, _changed)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tarjeta de información ──────────────────────────────────
              _card(children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_ot.descripcion, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 16, runSpacing: 6, children: [
                      _infoItem(Icons.flag_outlined, _ot.prioridad),
                      _infoItem(Icons.precision_manufacturing_outlined, _ot.maquinaNombre ?? '—'),
                      _infoItem(Icons.engineering_outlined, _ot.tecnicoNombre ?? 'Sin asignar'),
                    ]),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _estadoColor(_ot.estado).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_ot.estado, style: TextStyle(color: _estadoColor(_ot.estado), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ]),
                const Divider(height: 20),
                Wrap(spacing: 20, runSpacing: 4, children: [
                  if (_ot.fechaCreacion != null) _infoItem(Icons.calendar_today_outlined, 'Creada: ${_formatDate(_ot.fechaCreacion!)}'),
                  if (_ot.fechaInicio != null) _infoItem(Icons.play_arrow_outlined, 'Inicio: ${_formatDate(_ot.fechaInicio!)}', color: Colors.orange),
                  if (_ot.fechaFin != null) _infoItem(Icons.check_circle_outlined, 'Fin: ${_formatDate(_ot.fechaFin!)}', color: Colors.green),
                ]),
              ]),

              const SizedBox(height: 16),

              // ── Botón Iniciar (si PENDIENTE y no cerrada) ────────────────
              if (_ot.estado == 'PENDIENTE' && !esCerrada)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _iniciar,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('INICIAR ORDEN DE TRABAJO'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),

              // ── Trabajos realizados (editable si no cerrada o jefe) ──────
              if (!esCerrada || !esTecnico) ...[
                const SizedBox(height: 16),
                _sectionTitle('📋 Trabajos realizados'),
                const SizedBox(height: 8),
                _card(children: [
                  TextFormField(
                    controller: _accionesCtrl,
                    maxLines: 6,
                    enabled: !esCerrada,
                    decoration: const InputDecoration(
                      hintText: 'Describe aquí las acciones realizadas, materiales usados, observaciones...',
                      border: InputBorder.none,
                    ),
                  ),
                  if (!esCerrada)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _guardarAcciones,
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: const Text('Guardar acciones'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                      ),
                    ),
                ]),
              ],

              // ── Sección de firmas (solo si EN_PROCESO o se muestra info) ─
              if (_ot.estado == 'EN_PROCESO' || esCerrada) ...[
                const SizedBox(height: 16),
                _sectionTitle('✍️ Firmas'),
                const SizedBox(height: 8),
                _card(children: [
                  if (esCerrada && _ot.firmaTecnico != null) ...[
                    Text('Firma del técnico:', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(base64Decode(_ot.firmaTecnico!), height: 100),
                    ),
                  ] else if (!esCerrada) ...[
                    Text('Firma del técnico:', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _buildSignaturePad(_firmaStrokeTec, _firmaTecnicoKey, () => setState(() { _firmaStrokeTec.clear(); _firmaTecDirty = false; }), onDirty: () => setState(() => _firmaTecDirty = true)),
                  ],
                  const SizedBox(height: 16),
                  if (esCerrada && _ot.firmaCliente != null) ...[
                    Text('Firma del cliente:', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(base64Decode(_ot.firmaCliente!), height: 100),
                    ),
                  ] else if (!esCerrada) ...[
                    Text('Firma del cliente (opcional):', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _buildSignaturePad(_firmaStrokeCli, _firmaClienteKey, () => setState(() { _firmaStrokeCli.clear(); _firmaCliDirty = false; }), onDirty: () => setState(() => _firmaCliDirty = true)),
                  ],
                ]),
              ],

              // ── Botón cerrar ──────────────────────────────────────────────
              if (_ot.estado == 'EN_PROCESO') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _cerrar,
                    icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.lock_outlined),
                    label: const Text('CERRAR ORDEN DE TRABAJO'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey[700]));

  Widget _infoItem(IconData icon, String label, {Color? color}) {
    final c = color ?? Colors.grey[600]!;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: c),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: c, fontSize: 13)),
    ]);
  }

  Widget _buildSignaturePad(
    List<List<Offset?>> strokes,
    GlobalKey key,
    VoidCallback onClear, {
    required VoidCallback onDirty,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepaintBoundary(
          key: key,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GestureDetector(
              onPanStart: (d) { strokes.add([d.localPosition]); onDirty(); setState(() {}); },
              onPanUpdate: (d) { strokes.last.add(d.localPosition); setState(() {}); },
              onPanEnd: (_) { strokes.last.add(null); setState(() {}); },
              child: CustomPaint(
                painter: _SignaturePainter(strokes),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.clear, size: 14),
          label: const Text('Limpiar'),
          style: TextButton.styleFrom(foregroundColor: Colors.red[400], padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }

  String _formatDate(String dt) {
    try { return dt.split('T')[0]; } catch (_) { return dt; }
  }
}

// ── Painter de firma ──────────────────────────────────────────────────────────
class _SignaturePainter extends CustomPainter {
  final List<List<Offset?>> strokes;
  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[900]!
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        if (stroke[i] != null && stroke[i + 1] != null) {
          canvas.drawLine(stroke[i]!, stroke[i + 1]!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
