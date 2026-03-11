import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_config.dart';
import '../services/app_session.dart';

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
        // Guardar sesión del usuario
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
