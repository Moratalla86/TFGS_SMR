import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/api_config.dart';
import '../services/app_session.dart';
import '../services/usuario_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  Timer? _rfidTimer;
  String? _lastRfidTimestamp;

  @override
  void initState() {
    super.initState();
    _startRfidPolling();
  }

  @override
  void dispose() {
    _rfidTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startRfidPolling() {
    // Poll cada 2 segundos buscando una tarjeta nueva
    _rfidTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isLoading) return; 

      try {
        final data = await UsuarioService().fetchLastRfid();
        final rfid = data['rfid'] ?? '';
        final timestamp = data['timestamp']?.toString();

        // Si hay una tarjeta y el timestamp ha cambiado desde la última vez que logueamos/vimos
        if (rfid.isNotEmpty && 
            rfid != "Ninguna tarjeta detectada" && 
            timestamp != null && 
            timestamp != _lastRfidTimestamp) {
          
          _lastRfidTimestamp = timestamp;
          _handleRfidLogin(rfid);
        }
      } catch (e) {
        // En el login automático somos silenciosos con los errores de red
      }
    });
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Por favor, rellena todos los campos");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        AppSession.instance.fromJson(userData);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _showError("Email o contraseña incorrectos");
      }
    } catch (e) {
      _showError("Error de conexión: comprueba que el Backend esté encendido");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRfidLogin(String rfidTag) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/rfid-login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"rfidTag": rfidTag}),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        AppSession.instance.fromJson(userData);
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acceso concedido mediante RFID'), backgroundColor: Colors.green),
        );
        
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // Solo mostramos error si el login falla (ej. tarjeta no vinculada)
        _showError("Tarjeta RFID no reconocida o usuario inactivo");
      }
    } catch (e) {
      _showError("Error al validar tarjeta RFID");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                // ── Logo ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.settings_suggest, size: 60, color: Colors.blue[800]),
                ),
                const SizedBox(height: 20),
                Text(
                  "MELTIC GMAO",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text("Sistema de Gestión de Mantenimiento", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 40),

                // ── Campo Email ───────────────────────────────
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: "usuario@meltic.com",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Campo Contraseña con toggle ───────────────
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey[500],
                      ),
                      tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 30),

                // ── Botón Entrar ──────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: const Text("ENTRAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                ),
                const SizedBox(height: 30),
                
                // ── Login Automático RFID ────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.nfc, color: Colors.blue[900], size: 30),
                      const SizedBox(height: 8),
                      const Text(
                        "Identificación por RFID",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Pasa tu tarjeta por el lector para entrar automáticamente",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
