import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/orden_trabajo.dart';
import '../services/orden_trabajo_service.dart';
import '../services/app_session.dart';
import '../theme/industrial_theme.dart';
import '../utils/pdf_generator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/usuario_service.dart';
import '../models/usuario.dart';
import 'package:intl/intl.dart';

class OTDetailScreen extends StatefulWidget {
  final OrdenTrabajo ot;
  const OTDetailScreen({super.key, required this.ot});

  @override
  State<OTDetailScreen> createState() => _OTDetailScreenState();
}

class _OTDetailScreenState extends State<OTDetailScreen> {
  final _otService = OrdenTrabajoService();
  final _usuarioService = UsuarioService();
  final _session = AppSession.instance;
  late OrdenTrabajo _ot;
  bool _saving = false;
  bool _changed = false;

  int? _tecnicoId;
  List<Usuario> _tecnicos = [];

  final _accionesCtrl = TextEditingController();

  // Firma del técnico
  final _firmaTecnicoKey = GlobalKey();
  final List<List<Offset?>> _firmaStrokeTec = [];
  bool _firmaTecDirty = false;

  // Firma del cliente
  final _firmaClienteKey = GlobalKey();
  final List<List<Offset?>> _firmaStrokeCli = [];
  bool _firmaCliDirty = false;

  // Evidencia
  String? _fotoBase64;
  final ImagePicker _picker = ImagePicker();

  // Checklists
  Map<String, bool> _checklists = {};

  @override
  void initState() {
    super.initState();
    _ot = widget.ot;
    _accionesCtrl.text = _ot.trabajosRealizados ?? '';
    if (_ot.checklists != null && _ot.checklists!.isNotEmpty) {
      try {
        _checklists = Map<String, bool>.from(json.decode(_ot.checklists!));
      } catch (_) {}
    } else if (_ot.tipo == 'PREVENTIVA') {
      _checklists = {
        'Engrase rodamientos sec. A': false,
        'Verificación apriete regletas': false,
        'Limpieza de filtros de aspiración': false,
        'Calibrado de sensor de vibración': false,
        'Inspección cuadro eléctrico general': false,
      };
    }
    _cargarTecnicos();
  }

  Future<void> _cargarTecnicos() async {
    if (_session.isJefe && _ot.estado == 'SOLICITADA') {
      try {
        final users = await _usuarioService.fetchUsuarios();
        setState(() {
          _tecnicos = users
              .where((u) => u.rol == 'TECNICO' || u.rol == 'JEFE_MANTENIMIENTO')
              .toList();
        });
      } catch (_) {}
    }
  }

  Future<void> _autorizar() async {
    if (_tecnicoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un operario para asignar')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      // Usamos el servicio para actualizar la OT
      final updated = await _otService.actualizarEstado(_ot.id, 'PENDIENTE');
      // Luego asignamos el técnico (podríamos haber hecho un endpoint de 'autorizar' pero reutilizamos)
      final withTech = await _otService.asignar(_ot.id, tecnicoId: _tecnicoId!);
      setState(() {
        _ot = withTech;
        _changed = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: IndustrialTheme.criticalRed),
      );
    } finally {
      setState(() => _saving = false);
    }
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
      setState(() {
        _ot = updated;
        _changed = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fallo: $e'),
            backgroundColor: IndustrialTheme.criticalRed,
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _guardarAcciones() async {
    setState(() => _saving = true);
    try {
      final updated = await _otService.actualizarAcciones(
        _ot.id,
        _accionesCtrl.text.trim(),
      );
      setState(() {
        _ot = updated;
        _changed = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fallo: $e'),
            backgroundColor: IndustrialTheme.criticalRed,
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<String?> _capturarFirma(
    List<List<Offset?>> strokes,
    GlobalKey key,
  ) async {
    if (strokes.isEmpty) return null;
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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
    if (!_firmaTecDirty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firma del técnico obligatoria para cierre'),
          backgroundColor: IndustrialTheme.warningOrange,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final firmaTec = await _capturarFirma(_firmaStrokeTec, _firmaTecnicoKey);
      final firmaCli = _firmaCliDirty
          ? await _capturarFirma(_firmaStrokeCli, _firmaClienteKey)
          : null;

      final String checksJson = json.encode(_checklists);
      final pdfB64 = await PdfGenerator.generarReporteCierreBase64(
        _ot,
        _accionesCtrl.text.trim(),
        _checklists,
        _fotoBase64,
        firmaTec,
        firmaCli,
      );

      final updated = await _otService.cerrarOT(
        _ot.id,
        trabajos: _accionesCtrl.text.trim(),
        firmaTecnico: firmaTec,
        firmaCliente: firmaCli,
        checklists: checksJson,
        fotoBase64: _fotoBase64,
        reportePdfBase64: pdfB64,
      );

      setState(() {
        _ot = updated;
        _changed = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ORDEN CERRADA Y REGISTRADA'),
            backgroundColor: IndustrialTheme.operativeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fallo: $e'),
            backgroundColor: IndustrialTheme.criticalRed,
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCerrada = _ot.estado == 'CERRADA';
    final esTecnico = _session.isTecnico;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'TICKET #${_ot.id}',
            style: const TextStyle(letterSpacing: 2, fontSize: 14),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          actions: [
            if (!esCerrada)
              IconButton(
                icon: const Icon(Icons.save, color: IndustrialTheme.neonCyan),
                onPressed: _guardarAcciones,
              ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernStepper(),
              const SizedBox(height: 24),
              _buildMainInfoCard(),
              const SizedBox(height: 24),
              if (_ot.estado == 'SOLICITADA') ...[
                if (_session.isJefe) _buildAutorizacionPanel() else _buildWaitingStatus(),
                const SizedBox(height: 24),
              ],
              if (_ot.estado == 'PENDIENTE' && !esCerrada) _buildStartAction(),
              if (!esCerrada || !esTecnico) ...[
                const Text(
                  "TRABAJOS Y RESOLUCIÓN",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionLogField(esCerrada),
              ],
              if (_checklists.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildChecklistSection(esCerrada),
              ],
              if (_ot.estado == 'EN_PROCESO' || esCerrada) ...[
                const SizedBox(height: 24),
                _buildCameraSection(esCerrada),
                const SizedBox(height: 24),
                const Text(
                  "CERTIFICACIÓN Y FIRMAS",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSignatureSection(esCerrada),
              ],
              if (_ot.estado == 'EN_PROCESO') ...[
                const SizedBox(height: 32),
                _buildCloseButton(),
              ],
              if (esCerrada) ...[
                const SizedBox(height: 32),
                _buildVerPdfButton(),
              ],
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildModernStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stepItem("REGISTRO", true, Icons.assignment_turned_in),
          _stepLine(active: _ot.estado != 'PENDIENTE' && _ot.estado != 'SOLICITADA'),
          _stepItem("EN CURSO", _ot.estado != 'PENDIENTE' && _ot.estado != 'SOLICITADA' && _ot.estado != 'CERRADA', Icons.sync),
          _stepLine(
            active: _ot.estado == 'CERRADA',
            esCerrada: _ot.estado == 'CERRADA',
          ),
          _stepItem("CIERRE", _ot.estado == 'CERRADA', Icons.verified),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _stepItem(String label, bool active, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: active ? IndustrialTheme.neonCyan : IndustrialTheme.slateGray,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : IndustrialTheme.slateGray,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _stepLine({bool active = false, bool esCerrada = false}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: (active || esCerrada)
            ? IndustrialTheme.neonCyan
            : Colors.white10,
      ),
    );
  }

  Widget _buildMainInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IndustrialTheme.spaceCadet,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _ot.descripcion,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          _infoRow(
            Icons.precision_manufacturing,
            "ACTIVO",
            _ot.maquinaNombre ?? "PLANTA GENERAL",
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.flag,
            "PRIORIDAD",
            _ot.prioridad,
            color: _ot.prioridad == 'ALTA'
                ? IndustrialTheme.criticalRed
                : IndustrialTheme.warningOrange,
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.calendar_today,
            "APERTURA",
            _formatDate(_ot.fechaCreacion!),
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.person,
            "SOLICITANTE",
            _ot.solicitanteNombre ?? "SISTEMA / AUTO",
            color: IndustrialTheme.neonCyan,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _infoRow(IconData icon, String label, String val, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: IndustrialTheme.slateGray),
        const SizedBox(width: 8),
        Text(
          "$label:",
          style: const TextStyle(
            color: IndustrialTheme.slateGray,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          val,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistSection(bool disabled) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PROTOCOLO DE REVISIÓN",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          ..._checklists.entries
              .map(
                (e) => CheckboxListTile(
                  title: Text(
                    e.key,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  value: e.value,
                  activeColor: IndustrialTheme.neonCyan,
                  checkColor: IndustrialTheme.spaceCadet,
                  onChanged: disabled
                      ? null
                      : (val) {
                          setState(() {
                            _checklists[e.key] = val ?? false;
                            _changed = true;
                          });
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              )
              ,
        ],
      ),
    );
  }

  Widget _buildCameraSection(bool esCerrada) {
    String? currentImage = esCerrada ? _ot.fotoBase64 : _fotoBase64;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "EVIDENCIA FOTOGRÁFICA",
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (currentImage != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: MemoryImage(base64Decode(currentImage)),
                fit: BoxFit.cover,
              ),
            ),
          )
        else if (!esCerrada)
          InkWell(
            onTap: () async {
              final XFile? image = await _picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 50,
              );
              if (image != null) {
                final bytes = await image.readAsBytes();
                setState(() {
                  _fotoBase64 = base64Encode(bytes);
                });
              }
            },
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: IndustrialTheme.claudCloud,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: IndustrialTheme.neonCyan,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    color: IndustrialTheme.neonCyan,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "CAPTURAR AHORA",
                    style: TextStyle(
                      color: IndustrialTheme.neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const Text(
            "Sin evidencia capturada",
            style: TextStyle(
              color: IndustrialTheme.slateGray,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildVerPdfButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        // Si ya tiene PDF guardado, lo muestra directamente
        if (_ot.reportePdfBase64 != null) {
          await PdfGenerator.viewLocalPdf(
            _ot.reportePdfBase64!,
            'Reporte_OT_${_ot.id}.pdf',
          );
        } else {
          // OT antigua sin PDF: genera al vuelo desde los datos disponibles
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Generando reporte PDF...'),
              duration: Duration(seconds: 2),
            ),
          );
          await PdfGenerator.generarYVerPdf(_ot, _checklists);
        }
      },
      icon: const Icon(Icons.picture_as_pdf),
      label: Text(
        _ot.reportePdfBase64 != null
            ? 'VER REPORTE PDF OFICIAL'
            : 'GENERAR REPORTE PDF',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: IndustrialTheme.electricBlue,
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildStartAction() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _iniciar,
        icon: const Icon(Icons.play_arrow),
        label: const Text("INICIAR INTERVENCIÓN TÉCNICA"),
        style: ElevatedButton.styleFrom(
          backgroundColor: IndustrialTheme.warningOrange,
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  Widget _buildAutorizacionPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IndustrialTheme.electricBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: IndustrialTheme.electricBlue, size: 18),
              SizedBox(width: 10),
              Text(
                "AUTORIZACIÓN DE MANTENIMIENTO",
                style: TextStyle(
                  color: IndustrialTheme.electricBlue,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Revisa la solicitud y asigna un técnico para que la orden sea visible para el equipo de planta.",
            style: TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int?>(
            value: _tecnicoId,
            dropdownColor: IndustrialTheme.claudCloud,
            decoration: const InputDecoration(
              labelText: "SELECCIONAR OPERARIO",
              prefixIcon: Icon(Icons.engineering),
            ),
            items: _tecnicos.map((u) => DropdownMenuItem(
              value: u.id,
              child: Text(u.nombreCompleto, style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: (v) => setState(() => _tecnicoId = v),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _saving ? null : _autorizar,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("AUTORIZAR Y ASIGNAR TICKET"),
            style: ElevatedButton.styleFrom(
              backgroundColor: IndustrialTheme.electricBlue,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: IndustrialTheme.spaceCadet,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IndustrialTheme.slateGray.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty, color: IndustrialTheme.slateGray, size: 32),
          const SizedBox(height: 12),
          const Text(
            "SOLICITUD ENVIADA",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tu petición está siendo revisada por el Jefe de Mantenimiento. Recibirás una notificación cuando sea asignada.",
            textAlign: TextAlign.center,
            style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildActionLogField(bool disabled) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _accionesCtrl,
        maxLines: 5,
        enabled: !disabled,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: const InputDecoration(
          hintText: "Protocolo de actuación, materiales, repuestos...",
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildSignatureSection(bool disabled) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _signaturePad(
            "FIRMA DEL RESPONSABLE TÉCNICO",
            _firmaStrokeTec,
            _firmaTecnicoKey,
            _ot.firmaTecnico,
            disabled,
            () => setState(() {
              _firmaStrokeTec.clear();
              _firmaTecDirty = false;
            }),
            () => setState(() => _firmaTecDirty = true),
          ),
          const SizedBox(height: 24),
          _signaturePad(
            "VALIDACIÓN CLIENTE / PRODUCCIÓN (OPCIONAL)",
            _firmaStrokeCli,
            _firmaClienteKey,
            _ot.firmaCliente,
            disabled,
            () => setState(() {
              _firmaStrokeCli.clear();
              _firmaCliDirty = false;
            }),
            () => setState(() => _firmaCliDirty = true),
          ),
        ],
      ),
    );
  }

  Widget _signaturePad(
    String title,
    List<List<Offset?>> strokes,
    GlobalKey key,
    String? existing,
    bool disabled,
    VoidCallback onClear,
    VoidCallback onDirty,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: IndustrialTheme.slateGray,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: IndustrialTheme.spaceCadet,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: existing != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(existing),
                    fit: BoxFit.contain,
                    color: IndustrialTheme.neonCyan,
                  ),
                )
              : RepaintBoundary(
                  key: key,
                  child: GestureDetector(
                    onPanStart: disabled
                        ? null
                        : (d) {
                            FocusScope.of(context).unfocus();
                            strokes.add([d.localPosition]);
                            onDirty();
                            setState(() {});
                          },
                    onPanUpdate: disabled
                        ? null
                        : (d) {
                            strokes.last.add(d.localPosition);
                            setState(() {});
                          },
                    onPanEnd: disabled
                        ? null
                        : (_) {
                            strokes.last.add(null);
                            setState(() {});
                          },
                    child: CustomPaint(
                      painter: _SignaturePainter(strokes),
                      size: Size.infinite,
                    ),
                  ),
                ),
        ),
        if (!disabled && existing == null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onClear,
              child: const Text(
                "LIMPIAR",
                style: TextStyle(
                  color: IndustrialTheme.criticalRed,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return ElevatedButton.icon(
      onPressed: _saving ? null : _cerrar,
      icon: _saving
          ? const CircularProgressIndicator()
          : const Icon(Icons.verified),
      label: const Text("CLOSE TICKET & SYNC REPORT"),
      style: ElevatedButton.styleFrom(
        backgroundColor: IndustrialTheme.operativeGreen,
        minimumSize: const Size(double.infinity, 54),
      ),
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

class _SignaturePainter extends CustomPainter {
  final List<List<Offset?>> strokes;
  _SignaturePainter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = IndustrialTheme.neonCyan
      ..strokeWidth = 2.0
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
