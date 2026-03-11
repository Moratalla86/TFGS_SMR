import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/usuario_service.dart';

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
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.fetchUsuarios();
      setState(() { _usuarios = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _eliminar(Usuario u) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar a ${u.nombreCompleto}? Esta acción no se puede deshacer.'),
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
    if (confirmed == true && u.id != null) {
      try {
        await _service.eliminarUsuario(u.id!);
        _loadUsuarios();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Usuario ${u.nombreCompleto} eliminado.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
      case 'ADMIN': return Colors.purple;
      case 'JEFE_MANTENIMIENTO': return Colors.blue[800]!;
      default: return Colors.teal;
    }
  }

  String _rolLabel(String rol) {
    switch (rol) {
      case 'ADMIN': return 'Admin';
      case 'JEFE_MANTENIMIENTO': return 'Jefe Mant.';
      default: return 'Técnico';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestión de Usuarios', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsuarios),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: 60, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error de conexión', style: TextStyle(color: Colors.grey[700], fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: _loadUsuarios, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
                    ],
                  ),
                )
              : _usuarios.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_off, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('No hay usuarios registrados', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsuarios,
                      child: Column(
                        children: [
                          _buildSummaryBar(),
                          Expanded(
                            child: ListView.builder(
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
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Usuario'),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final total = _usuarios.length;
    final activos = _usuarios.where((u) => u.activo).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total', '$total', Icons.people),
          _summaryItem('Activos', '$activos', Icons.check_circle_outline),
          _summaryItem('Inactivos', '${total - activos}', Icons.cancel_outlined),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildUserCard(Usuario u) {
    final rolColor = _rolColor(u.rol);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row Cabecera ─────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: rolColor.withValues(alpha: 0.12),
                  child: Text(
                    u.nombre.isNotEmpty ? u.nombre[0].toUpperCase() : '?',
                    style: TextStyle(color: rolColor, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(u.email ?? u.emailCorporativoPreview, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                // Chip de rol
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: rolColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(_rolLabel(u.rol), style: TextStyle(color: rolColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // ── Detalles ─────────────────────────────────────
            Wrap(
              spacing: 20,
              runSpacing: 6,
              children: [
                if (u.telefonoProfesional != null && u.telefonoProfesional!.isNotEmpty)
                  _infoChip(Icons.phone_outlined, u.telefonoProfesional!),
                if (u.telefonoPersonal != null && u.telefonoPersonal!.isNotEmpty)
                  _infoChip(Icons.smartphone_outlined, u.telefonoPersonal!),
                if (u.emailPersonal != null && u.emailPersonal!.isNotEmpty)
                  _infoChip(Icons.alternate_email, u.emailPersonal!),
                _infoChip(
                  u.activo ? Icons.check_circle : Icons.cancel,
                  u.activo ? 'Activo' : 'Inactivo',
                  color: u.activo ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Botones de acción ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _abrirFormulario(usuario: u),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[800],
                    side: BorderSide(color: Colors.blue[200]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _eliminar(u),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[200]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, {Color? color}) {
    final c = color ?? Colors.grey[600]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: c, fontSize: 12)),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Formulario de creación / edición
// ────────────────────────────────────────────────────────────────────────────
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

  late final TextEditingController _nombre;
  late final TextEditingController _apellido1;
  late final TextEditingController _apellido2;
  late final TextEditingController _telPersonal;
  late final TextEditingController _telProfesional;
  late final TextEditingController _emailPersonal;
  late final TextEditingController _password;
  String _rol = 'TECNICO';

  static const List<Map<String, String>> _roles = [
    {'value': 'ADMIN', 'label': 'Administrador'},
    {'value': 'JEFE_MANTENIMIENTO', 'label': 'Jefe de Mantenimiento'},
    {'value': 'TECNICO', 'label': 'Técnico'},
  ];

  bool get _esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombre        = TextEditingController(text: u?.nombre ?? '');
    _apellido1     = TextEditingController(text: u?.apellido1 ?? '');
    _apellido2     = TextEditingController(text: u?.apellido2 ?? '');
    _telPersonal   = TextEditingController(text: u?.telefonoPersonal ?? '');
    _telProfesional= TextEditingController(text: u?.telefonoProfesional ?? '');
    _emailPersonal = TextEditingController(text: u?.emailPersonal ?? '');
    _password      = TextEditingController();
    _rol           = u?.rol ?? 'TECNICO';

    // Actualizar preview en tiempo real
    _nombre.addListener(() => setState(() {}));
    _apellido1.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_nombre, _apellido1, _apellido2, _telPersonal, _telProfesional, _emailPersonal, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _emailPreview {
    if (_nombre.text.isNotEmpty && _apellido1.text.isNotEmpty) {
      final ini = _nombre.text.trim()[0].toLowerCase();
      final ap  = _apellido1.text.trim().toLowerCase().replaceAll(' ', '');
      return '$ini$ap@meltic.com';
    }
    return '—';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final u = Usuario(
        nombre:              _nombre.text.trim(),
        apellido1:           _apellido1.text.trim(),
        apellido2:           _apellido2.text.trim().isEmpty ? null : _apellido2.text.trim(),
        telefonoPersonal:    _telPersonal.text.trim().isEmpty ? null : _telPersonal.text.trim(),
        telefonoProfesional: _telProfesional.text.trim().isEmpty ? null : _telProfesional.text.trim(),
        emailPersonal:       _emailPersonal.text.trim().isEmpty ? null : _emailPersonal.text.trim(),
        password:            _password.text.trim().isEmpty ? null : _password.text.trim(),
        rol:                 _rol,
        activo:              true,
      );

      if (_esEdicion) {
        await widget.service.actualizarUsuario(widget.usuario!.id!, u);
      } else {
        await widget.service.crearUsuario(u);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Cabecera ─────────────────────────────────
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[50],
                      child: Icon(Icons.person, color: Colors.blue[900]),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _esEdicion ? 'Editar Usuario' : 'Nuevo Usuario',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[900]),
                    ),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, false)),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Email corporativo preview ─────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, color: Colors.blue[800], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email corporativo (generado automáticamente)',
                                style: TextStyle(color: Colors.blue[700], fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(_emailPreview, style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Datos personales ─────────────────────────
                _sectionTitle('Datos Personales'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_nombre, 'Nombre *', Icons.person, required: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_apellido1, 'Primer Apellido *', Icons.person_outline, required: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_apellido2, 'Segundo Apellido', Icons.person_outline),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(_telPersonal, 'Teléfono Personal', Icons.smartphone, keyboardType: TextInputType.phone)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_telProfesional, 'Teléfono Profesional', Icons.phone, keyboardType: TextInputType.phone)),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_emailPersonal, 'Email Personal', Icons.alternate_email, keyboardType: TextInputType.emailAddress),

                const SizedBox(height: 20),

                // ── Acceso y rol ─────────────────────────────
                _sectionTitle('Acceso y Rol'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _rol,
                  decoration: _inputDeco('Rol', Icons.badge_outlined),
                  items: _roles.map((r) => DropdownMenuItem(value: r['value'], child: Text(r['label']!))).toList(),
                  onChanged: (v) => setState(() => _rol = v!),
                  validator: (v) => v == null ? 'Selecciona un rol' : null,
                ),
                const SizedBox(height: 12),
                _field(
                  _password,
                  _esEdicion ? 'Nueva contraseña (vacío = sin cambios)' : 'Contraseña *',
                  Icons.lock_outline,
                  obscure: true,
                  required: !_esEdicion,
                ),
                const SizedBox(height: 24),

                // ── Botones ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _guardar,
                      icon: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: Text(_esEdicion ? 'Guardar cambios' : 'Crear usuario'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
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

  Widget _sectionTitle(String text) {
    return Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[700], letterSpacing: 0.5));
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: _inputDeco(label, icon),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null : null,
    );
  }
}
