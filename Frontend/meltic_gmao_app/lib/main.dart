import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/machine_detail_screen.dart';
import 'screens/usuarios_screen.dart';
import 'screens/ordenes_screen.dart';

void main() => runApp(MelticApp());

class MelticApp extends StatelessWidget {
  const MelticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meltic GMAO',
      initialRoute: '/', // Pantalla de inicio
      routes: {
        '/': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/machine-detail': (context) => MachineDetailScreen(),
        '/usuarios': (context) => const UsuariosScreen(),
        '/ordenes': (context) => const OrdenesScreen(),
      },
    );
  }
}
