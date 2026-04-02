import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/api_config.dart';
import '../services/app_session.dart';
import '../services/usuario_service.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../theme/industrial_theme.dart';

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
    bool initialized = false;

    _rfidTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isLoading) return;
      try {
        final data = await UsuarioService().fetchLastRfid();
        final rfid = (data['rfid'] ?? '') as String;
        final timestamp = data['timestamp']?.toString();

        // --- Filtros de seguridad ---
        // 1. Ignorar valores vacíos, el placeholder del firmware y el valor N/A por defecto
        // 2. Exigir formato hex RFID (debe contener ':')
        final bool esRfidValido =
            rfid.isNotEmpty &&
            rfid != 'Ninguna tarjeta detectada' &&
            rfid != 'N/A' &&
            rfid.contains(':');

        if (!esRfidValido || timestamp == null) {
          // Sin tarjeta válida: inicializar el baseline de timestamp igualmente
          // para no quedar bloqueado en estado no-inicializado
          if (!initialized) {
            _lastRfidTimestamp = timestamp;
            initialized = true;
          }
          return;
        }

        if (!initialized) {
          // Primera lectura con tarjeta real: guardar baseline y NO logear
          _lastRfidTimestamp = timestamp;
          initialized = true;
          return;
        }

        // Solo proceder si el timestamp cambió (nueva pasada de tarjeta)
        if (timestamp != _lastRfidTimestamp) {
          _lastRfidTimestamp = timestamp;
          _handleRfidLogin(rfid);
        }
      } catch (_) {}
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
        
        // --- EVITAR CONFLICTO RFID ---
        // Cancelamos el timer inmediatamente al detectar éxito manual
        _rfidTimer?.cancel();
        
        AppSession.instance.fromJson(userData);
        if (!mounted) return;
        
        _showSuccess("Acceso concedido mediante credenciales");
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _showError("Email o contraseña incorrectos");
      }
    } catch (e) {
      _showError("Error de conexión con el servidor industrial");
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
        _showSuccess("Acceso concedido mediante RFID");
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _showError("Tarjeta RFID no reconocida");
      }
    } catch (e) {
      _showError("Error al validar tarjeta RFID");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: IndustrialTheme.criticalRed,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: IndustrialTheme.operativeGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo Decorativo Industrial
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [Color(0xFF112240), IndustrialTheme.spaceCadet],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: IndustrialTheme.claudCloud.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // LOGO CON FILTRO PARA QUITAR FONDO BLANCO
                          ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              1, 0, 0, 0, 0,
                              0, 1, 0, 0, 0,
                              0, 0, 1, 0, 0,
                              -1, -1, -1, 1, 2.55, // Filtro para hacer transparente el blanco puro
                            ]),
                            child: Image.asset(
                              'assets/images/logo_meltic_clean.png', // Probamos con la versión clean
                              height: 100,
                              width: 100,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => 
                                Image.asset('assets/images/logo_meltic.png', height: 100, width: 100),
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(),
                          ).shimmer(
                            duration: 2500.ms,
                            color: IndustrialTheme.electricBlue.withOpacity(0.4),
                          ),

                          const SizedBox(height: 24),
                          Text(
                            "Mèltic 4.0",
                            textAlign: TextAlign.center,
                            style: IndustrialTheme.dark.textTheme.displayLarge?.copyWith(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            "Gmao Industrial",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: IndustrialTheme.neonCyan,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),

                          const SizedBox(height: 40),

                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: "Identificador de Usuario",
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Código de Acceso",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _handleLogin(),
                          ),

                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: IndustrialTheme.neonCyan,
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _handleLogin,
                                    child: const Text("CONECTAR AL SISTEMA"),
                                  ),
                          ),

                          const SizedBox(height: 40),

                          // SECCIÓN RFID GLASS
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: IndustrialTheme.neonCyan.withOpacity(
                                  0.2,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.nfc,
                                      color: IndustrialTheme.neonCyan,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "SENSOR RFID ACTIVO",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Aproxime su credencial al lector externo",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: IndustrialTheme.slateGray,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fade(duration: 800.ms).slideY(begin: 0.1, end: 0),
            ),
          ),
        ],
      ),
    );
  }
}
