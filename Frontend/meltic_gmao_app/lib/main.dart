import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/machine_detail_screen.dart';
import 'screens/usuarios_screen.dart';
import 'screens/ordenes_screen.dart';
import 'screens/activos_plc_screen.dart';

import 'theme/industrial_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es_ES';
  runApp(const SmrGmaoApp());
}

class SmrGmaoApp extends StatelessWidget {
  const SmrGmaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meltic 4.0',
      theme: IndustrialTheme.dark,
      initialRoute: '/',
      // Configuración de Localización al Español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      locale: const Locale('es', 'ES'),
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/machine-detail': (context) => const MachineDetailScreen(),
        '/usuarios': (context) => const UsuariosScreen(),
        '/ordenes': (context) => const OrdenesScreen(),
        '/activos-plc': (context) => const ActivosPLCScreen(),
      },
    );
  }
}
