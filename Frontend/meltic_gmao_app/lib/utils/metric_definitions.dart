import 'package:flutter/material.dart';

class MetricDefinition {
  final String id;
  final String label;
  final String unit;
  final IconData icon;
  final Color color;

  const MetricDefinition({
    required this.id,
    required this.label,
    required this.unit,
    required this.icon,
    required this.color,
  });

  static const List<MetricDefinition> all = [
    MetricDefinition(
      id: 'temperatura',
      label: 'TEMP. AMBIENTE',
      unit: '°C',
      icon: Icons.thermostat,
      color: Colors.orange,
    ),
    MetricDefinition(
      id: 'humedad',
      label: 'HUMEDAD REL.',
      unit: '%',
      icon: Icons.water_drop,
      color: Colors.blue,
    ),
    MetricDefinition(
      id: 'caudal',
      label: 'CAUDAL LÍNEA',
      unit: 'L/min',
      icon: Icons.waves,
      color: Colors.cyan,
    ),
    MetricDefinition(
      id: 'presion',
      label: 'PRESIÓN SISTEMA',
      unit: 'Bar',
      icon: Icons.speed,
      color: Colors.redAccent,
    ),
    MetricDefinition(
      id: 'rpm',
      label: 'VELOCIDAD GIRO',
      unit: 'RPM',
      icon: Icons.autorenew,
      color: Colors.purpleAccent,
    ),
    MetricDefinition(
      id: 'vibracion_axial',
      label: 'VIBR. AXIAL',
      unit: 'mm/s',
      icon: Icons.vibration,
      color: Colors.yellowAccent,
    ),
    MetricDefinition(
      id: 'vibracion_radial',
      label: 'VIBR. RADIAL',
      unit: 'mm/s',
      icon: Icons.sync_problem,
      color: Colors.yellow,
    ),
    MetricDefinition(
      id: 'temp_motor',
      label: 'TEMP. MOTOR',
      unit: '°C',
      icon: Icons.settings_power,
      color: Colors.orangeAccent,
    ),
    MetricDefinition(
      id: 'temp_reductor',
      label: 'TEMP. REDUCTOR',
      unit: '°C',
      icon: Icons.settings_input_component,
      color: Colors.deepOrange,
    ),
    MetricDefinition(
      id: 'temp_producto_entrada',
      label: 'TEMP. PROD. ENTRADA',
      unit: '°C',
      icon: Icons.login,
      color: Colors.green,
    ),
    MetricDefinition(
      id: 'temp_producto_salida',
      label: 'TEMP. PROD. SALIDA',
      unit: '°C',
      icon: Icons.logout,
      color: Colors.red,
    ),
    MetricDefinition(
      id: 'consumo_electrico',
      label: 'CONSUMO ELÉC.',
      unit: 'kW',
      icon: Icons.electric_bolt,
      color: Colors.lightGreenAccent,
    ),
    MetricDefinition(
      id: 'nivel_aceite',
      label: 'NIVEL ACEITE',
      unit: '%',
      icon: Icons.oil_barrel,
      color: Colors.brown,
    ),
    MetricDefinition(
      id: 'voltaje_fase',
      label: 'VOLTAJE RED',
      unit: 'V',
      icon: Icons.bolt,
      color: Colors.blueGrey,
    ),
    MetricDefinition(
      id: 'corriente_fase',
      label: 'INTENSIDAD',
      unit: 'A',
      icon: Icons.electric_meter,
      color: Colors.indigo,
    ),
  ];

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
