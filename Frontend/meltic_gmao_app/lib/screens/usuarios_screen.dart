import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/usuario_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/industrial_theme.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final UsuarioService _service = UsuarioService();
  List<Usuario> _usuarios = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchUsuarios();
      setState(() {
        _usuarios = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _eliminar(Usuario u) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: IndustrialTheme.claudCloud,
        title: const Text('CONFIRMAR BAJA'),
        content: Text(
          '¿Desea desvincular al operario ${u.nombreCompleto} del sistema?',
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
              'ELIMINAR ACCESO',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && u.id != null) {
      try {
        await _service.eliminarUsuario(u.id!);
        _loadUsuarios();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro eliminado.'),
              backgroundColor: IndustrialTheme.operativeGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fallo en la operación: $e'),
              backgroundColor: IndustrialTheme.criticalRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _abrirFormulario({Usuario? usuario}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UserFormDialog(service: _service, usuario: usuario),
    );
    if (result == true) _loadUsuarios();
  }

  Color _rolColor(String rol) {
    switch (rol) {
      case 'ADMIN':
        return Colors.purpleAccent;
      case 'JEFE_MANTENIMIENTO':
        return IndustrialTheme.electricBlue;
      default:
        return IndustrialTheme.neonCyan;
    }
  }

  String _rolLabel(String rol) {
    switch (rol) {
      case 'ADMIN':
        return 'ADMIN';
      case 'JEFE_MANTENIMIENTO':
        return 'JEFE MANT.';
      default:
        return 'TÉCNICO';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GESTIÓN DE PERSONAL INDUST.'),
        actions: [
          IconButton(icon: const Icon(Icons.sync), onPressed: _loadUsuarios),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: IndustrialTheme.neonCyan),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off,
                    size: 40,
                    color: IndustrialTheme.criticalRed,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'LINK FAILURE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: IndustrialTheme.slateGray,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadUsuarios,
                    child: const Text('REINTENTAR LINK'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUsuarios,
              child: Column(
                children: [
                  _buildSummaryBar(),
                  Expanded(
                    child: _usuarios.isEmpty
                        ? const Center(
                            child: Text(
                              "NO HAY OPERARIOS REGISTRADOS",
                              style: TextStyle(
                                color: IndustrialTheme.slateGray,
                                fontSize: 10,
                                letterSpacing: 2,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _usuarios.length,
                            itemBuilder: (_, i) => _buildUserCard(_usuarios[i]),
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: IndustrialTheme.neonCyan,
        icon: const Icon(
          Icons.person_add_alt_1,
          color: IndustrialTheme.spaceCadet,
        ),
        label: const Text(
          'NUEVO OPERARIO',
          style: TextStyle(
            color: IndustrialTheme.spaceCadet,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final total = _usuarios.length;
    final activos = _usuarios.where((u) => u.activo).length;
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
          _summaryItem('TOTAL_REG', '$total', Icons.badge_outlined),
          _summaryItem('ACTIVOS', '$activos', Icons.check_circle_outline),
          _summaryItem('OFFLINE', '${total - activos}', Icons.cancel_outlined),
        ],
      ),
    ).animate().slideY(begin: -0.5, end: 0);
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: IndustrialTheme.neonCyan, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
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

  Widget _buildUserCard(Usuario u) {
    final rolColor = _rolColor(u.rol);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: rolColor.withOpacity(0.1),
                  child: Text(
                    u.nombre.isNotEmpty ? u.nombre[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: rolColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.nombreCompleto,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        u.email ?? "n/a",
                        style: const TextStyle(
                          color: IndustrialTheme.slateGray,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: rolColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: rolColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    _rolLabel(u.rol),
                    style: TextStyle(
                      color: rolColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (u.telefonoProfesional != null)
                  _infoLabel(Icons.phone_android, u.telefonoProfesional!),
                _infoLabel(
                  u.activo ? Icons.verified : Icons.do_not_disturb_on,
                  u.activo ? 'ACCESO OK' : 'BLOQUEADO',
                  color: u.activo
                      ? IndustrialTheme.operativeGreen
                      : IndustrialTheme.criticalRed,
                ),
                if (u.rfidTag != null)
                  _infoLabel(
                    Icons.nfc,
                    "NFCID: ${u.rfidTag}",
                    color: IndustrialTheme.electricBlue,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _abrirFormulario(usuario: u),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('EDITAR'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _eliminar(u),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 14,
                    color: IndustrialTheme.criticalRed,
                  ),
                  label: const Text(
                    'BORRAR',
                    style: TextStyle(color: IndustrialTheme.criticalRed),
                  ),
                ),
              ],
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
}

class _UserFormDialog extends StatefulWidget {
  final UsuarioService service;
  final Usuario? usuario;
  const _UserFormDialog({required this.service, this.usuario});
  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late final TextEditingController _nombre,
      _apellido1,
      _apellido2,
      _telProfesional,
      _password,
      _rfid;
  String _rol = 'TECNICO';
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombre = TextEditingController(text: u?.nombre ?? '');
    _apellido1 = TextEditingController(text: u?.apellido1 ?? '');
    _apellido2 = TextEditingController(text: u?.apellido2 ?? '');
    _telProfesional = TextEditingController(text: u?.telefonoProfesional ?? '');
    _password = TextEditingController();
    _rfid = TextEditingController(text: u?.rfidTag ?? '');
    _rol = u?.rol ?? 'TECNICO';
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
                Text(
                  widget.usuario == null
                      ? "ALTA DE PERSONAL"
                      : "MODIFICAR PERFIL",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(
                    labelText: "NOMBRE",
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _apellido1,
                        decoration: const InputDecoration(
                          labelText: "1er APELLIDO",
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _apellido2,
                        decoration: const InputDecoration(
                          labelText: "2do APELLIDO",
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telProfesional,
                  decoration: const InputDecoration(
                    labelText: "TLF. CORPORATIVO",
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _rol,
                  decoration: const InputDecoration(
                    labelText: "RANGO OPERATIVO",
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items:
                      [
                            {'value': 'ADMIN', 'label': 'ADMINISTRADOR'},
                            {
                              'value': 'JEFE_MANTENIMIENTO',
                              'label': 'JEFE DE MANT.',
                            },
                            {'value': 'TECNICO', 'label': 'TÉCNICO DE CAMPO'},
                          ]
                          .map(
                            (r) => DropdownMenuItem(
                              value: r['value'],
                              child: Text(r['label']!),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _rol = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "PASSWORD ACCESO",
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "VINCULACIÓN HARDWARE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: IndustrialTheme.neonCyan,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rfid,
                        decoration: const InputDecoration(
                          labelText: "UID TAG RFID",
                          prefixIcon: Icon(Icons.nfc),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: _isScanning ? null : _scanRfid,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sensors),
                      style: IconButton.styleFrom(
                        backgroundColor: IndustrialTheme.claudCloud,
                        foregroundColor: IndustrialTheme.neonCyan,
                      ),
                    ),
                  ],
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
                          : const Text("GUARDAR REGISTRO"),
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

  Future<void> _scanRfid() async {
    setState(() => _isScanning = true);
    try {
      final data = await widget.service.fetchLastRfid();
      String r = data['rfid'] ?? '';
      if (r.isNotEmpty && r != "Ninguna tarjeta detectada") {
        setState(() => _rfid.text = r);
      }
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final u = Usuario(
        nombre: _nombre.text.trim(),
        apellido1: _apellido1.text.trim(),
        apellido2: _apellido2.text.trim().isEmpty
            ? null
            : _apellido2.text.trim(),
        telefonoProfesional: _telProfesional.text.trim().isEmpty
            ? null
            : _telProfesional.text.trim(),
        password: _password.text.isEmpty ? null : _password.text,
        rol: _rol,
        activo: true,
        rfidTag: _rfid.text.isEmpty ? null : _rfid.text,
      );
      if (widget.usuario != null)
        await widget.service.actualizarUsuario(widget.usuario!.id!, u);
      else
        await widget.service.crearUsuario(u);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
    }
  }
}
