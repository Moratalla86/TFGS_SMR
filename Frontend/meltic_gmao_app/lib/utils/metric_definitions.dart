import 'package:flutter/material.dart';

class MetricDefinition {
  final String id;
  final String label;
  final String unit;
  final List<String> supportedUnits;
  final IconData icon;
  final Color color;

  const MetricDefinition({
    required this.id,
    required this.label,
    required this.unit,
    this.supportedUnits = const [],
    required this.icon,
    required this.color,
  });

  static const List<MetricDefinition> all = [
    MetricDefinition(
      id: 'temperatura',
      label: 'TEMP. AMBIENTE',
      unit: '°C',
      supportedUnits: ['°C', '°F'],
      icon: Icons.thermostat,
      color: Colors.orange,
    ),
    MetricDefinition(
      id: 'humedad',
      label: 'HUMEDAD REL.',
      unit: '%',
      supportedUnits: ['%'],
      icon: Icons.water_drop,
      color: Colors.blue,
    ),
    MetricDefinition(
      id: 'caudal',
      label: 'CAUDAL LÍNEA',
      unit: 'L/min',
      supportedUnits: ['L/min', 'm³/h'],
      icon: Icons.waves,
      color: Colors.cyan,
    ),
    MetricDefinition(
      id: 'presion',
      label: 'PRESIÓN SISTEMA',
      unit: 'Bar',
      supportedUnits: ['Bar', 'PSI'],
      icon: Icons.speed,
      color: Colors.redAccent,
    ),
    MetricDefinition(
      id: 'rpm',
      label: 'VELOCIDAD GIRO',
      unit: 'RPM',
      supportedUnits: ['RPM'],
      icon: Icons.autorenew,
      color: Colors.purpleAccent,
    ),
    // ... rest of definitions updated with defaults
    MetricDefinition(
      id: 'vibracion_axial',
      label: 'VIBR. AXIAL',
      unit: 'mm/s',
      supportedUnits: ['mm/s'],
      icon: Icons.vibration,
      color: Colors.yellowAccent,
    ),
    MetricDefinition(
      id: 'vibracion_radial',
      label: 'VIBR. RADIAL',
      unit: 'mm/s',
      supportedUnits: ['mm/s'],
      icon: Icons.sync_problem,
      color: Colors.yellow,
    ),
    MetricDefinition(
      id: 'temp_motor',
      label: 'TEMP. MOTOR',
      unit: '°C',
      supportedUnits: ['°C', '°F'],
      icon: Icons.settings_power,
      color: Colors.orangeAccent,
    ),
    MetricDefinition(
      id: 'temp_reductor',
      label: 'TEMP. REDUCTOR',
      unit: '°C',
      supportedUnits: ['°C', '°F'],
      icon: Icons.settings_input_component,
      color: Colors.deepOrange,
    ),
    MetricDefinition(
      id: 'temp_producto_entrada',
      label: 'TEMP. PROD. ENTRADA',
      unit: '°C',
      supportedUnits: ['°C', '°F'],
      icon: Icons.login,
      color: Colors.green,
    ),
    MetricDefinition(
      id: 'temp_producto_salida',
      label: 'TEMP. PROD. SALIDA',
      unit: '°C',
      supportedUnits: ['°C', '°F'],
      icon: Icons.logout,
      color: Colors.red,
    ),
    MetricDefinition(
      id: 'consumo_electrico',
      label: 'CONSUMO ELÉC.',
      unit: 'kW',
      supportedUnits: ['kW', 'W'],
      icon: Icons.electric_bolt,
      color: Colors.lightGreenAccent,
    ),
    MetricDefinition(
      id: 'nivel_aceite',
      label: 'NIVEL ACEITE',
      unit: '%',
      supportedUnits: ['%'],
      icon: Icons.oil_barrel,
      color: Colors.brown,
    ),
    MetricDefinition(
      id: 'voltaje_fase',
      label: 'VOLTAJE RED',
      unit: 'V',
      supportedUnits: ['V', 'kV'],
      icon: Icons.bolt,
      color: Colors.blueGrey,
    ),
    MetricDefinition(
      id: 'corriente_fase',
      label: 'INTENSIDAD',
      unit: 'A',
      supportedUnits: ['A', 'mA'],
      icon: Icons.electric_meter,
      color: Colors.indigo,
    ),
  ];

  static double convert(double value, String from, String to, String type) {
    if (from == to) return value;

    // Lógica de conversión Option B
    if (type.contains('temp')) {
      if (from == '°C' && to == '°F') return (value * 9 / 5) + 32;
      if (from == '°F' && to == '°C') return (value - 32) * 5 / 9;
    }

    if (type == 'presion') {
      if (from == 'Bar' && to == 'PSI') return value * 14.5038;
      if (from == 'PSI' && to == 'Bar') return value / 14.5038;
    }

    if (type == 'caudal') {
      if (from == 'L/min' && to == 'm³/h') return value * 0.06;
      if (from == 'm³/h' && to == 'L/min') return value / 0.06;
    }

    return value; // Fallback
  }

  static MetricDefinition getById(String id) {
    return all.firstWhere(
      (m) => m.id == id,
      orElse: () => MetricDefinition(
        id: id,
        label: id.toUpperCase(),
        unit: '',
        icon: Icons.help_outline,
        color: Colors.grey,
      ),
    );
  }
}
