import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/orden_trabajo.dart';
import '../models/maquina.dart';
import '../services/orden_trabajo_service.dart';
import '../services/maquina_service.dart';
import '../services/app_session.dart';
import '../theme/industrial_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final OrdenTrabajoService _otService = OrdenTrabajoService();
  final MaquinaService _maquinaService = MaquinaService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  Map<DateTime, List<OrdenTrabajo>> _events = {};
  List<Maquina> _maquinas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final preventivas = await _otService.fetchPreventivas();
      final maquinas = await _maquinaService.fetchMaquinas();
      
      Map<DateTime, List<OrdenTrabajo>> eventMap = {};
      for (var ot in preventivas) {
        if (ot.fechaPlanificada != null) {
          DateTime date = DateTime.parse(ot.fechaPlanificada!);
          DateTime day = DateTime(date.year, date.month, date.day);
          if (eventMap[day] == null) eventMap[day] = [];
          eventMap[day]!.add(ot);
        }
      }

      if (mounted) {
        setState(() {
          _events = eventMap;
          _maquinas = maquinas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<OrdenTrabajo> _getEventsForDay(DateTime day) {
    DateTime key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CALENDARIO PREVENTIVO", 
          style: TextStyle(letterSpacing: 2, fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: IndustrialTheme.neonCyan), onPressed: _loadData),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: IndustrialTheme.neonCyan))
        : LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 800;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: SingleChildScrollView(child: _buildCalendar())),
                    Container(width: 1, color: Colors.white10, margin: const EdgeInsets.symmetric(vertical: 20)),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildEventsHeader(),
                          Expanded(child: _buildEventList()),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildCalendar(),
                    const SizedBox(height: 8),
                    _buildEventsHeader(),
                    Expanded(child: _buildEventList()),
                  ],
                );
              }
            },
          ),
      floatingActionButton: AppSession.instance.isJefe ? FloatingActionButton.extended(
        onPressed: () => _showCreatePreventivaDialog(context),
        backgroundColor: IndustrialTheme.neonCyan,
        icon: const Icon(Icons.add, color: IndustrialTheme.spaceCadet),
        label: const Text("PROGRAMAR OT", style: TextStyle(color: IndustrialTheme.spaceCadet, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: IndustrialTheme.claudCloud,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TableCalendar(
        locale: 'es_ES',
        startingDayOfWeek: StartingDayOfWeek.monday,
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(color: Color(0x1A00E5FF), shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: IndustrialTheme.neonCyan))),
          selectedDecoration: BoxDecoration(color: IndustrialTheme.neonCyan, shape: BoxShape.circle),
          markerDecoration: BoxDecoration(color: IndustrialTheme.warningOrange, shape: BoxShape.circle),
          defaultTextStyle: TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: IndustrialTheme.slateGray),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: IndustrialTheme.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 1),
          leftChevronIcon: Icon(Icons.chevron_left, color: IndustrialTheme.neonCyan),
          rightChevronIcon: Icon(Icons.chevron_right, color: IndustrialTheme.neonCyan),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildEventsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: IndustrialTheme.neonCyan, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(
            DateFormat('EEEE, d MMMM', 'es_ES').format(_selectedDay!).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 48, color: IndustrialTheme.slateGray.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            const Text("SIN TAREAS PROGRAMADAS", style: TextStyle(color: IndustrialTheme.slateGray, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final ot = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: IndustrialTheme.warningOrange, width: 4)),
            ),
            child: ListTile(
              leading: const Icon(Icons.settings_backup_restore, color: IndustrialTheme.warningOrange),
              title: Text(ot.maquinaNombre ?? 'MÁQUINA NO ASIGNADA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(ot.descripcion, style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 16, color: IndustrialTheme.slateGray),
              onTap: () => Navigator.pushNamed(context, '/ot-detail', arguments: ot.id),
            ),
          ),
        );
      },
    ).animate().fadeIn(delay: 200.ms);
  }

  void _showCreatePreventivaDialog(BuildContext context) {
    final TextEditingController descCtrl = TextEditingController();
    Maquina? selectedMaquina;
    String prioridad = 'MEDIA';

    final widget = StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 3, height: 18, decoration: BoxDecoration(color: IndustrialTheme.neonCyan, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                const Text("PROGRAMAR MANTENIMIENTO", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<Maquina>(
              decoration: const InputDecoration(labelText: "Máquina Industrial"),
              items: _maquinas.map((m) => DropdownMenuItem(value: m, child: Text(m.nombre))).toList(),
              onChanged: (val) => setModalState(() => selectedMaquina = val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: "Descripción técnica de la tarea"),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedMaquina == null || descCtrl.text.isEmpty) return;
                  
                  final newOt = OrdenTrabajo(
                    id: 0,
                    descripcion: descCtrl.text,
                    prioridad: prioridad,
                    estado: 'PLANIFICADA',
                    tipo: 'PREVENTIVA',
                    fechaPlanificada: DateFormat('yyyy-MM-dd').format(_selectedDay!),
                    maquinaId: selectedMaquina!.id,
                    solicitanteId: AppSession.instance.userId,
                  );

                  try {
                    await _otService.crearOrden(newOt, maquinaId: selectedMaquina!.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OT Programada Correctamente"), backgroundColor: IndustrialTheme.operativeGreen));
                    }
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: IndustrialTheme.criticalRed));
                  }
                },
                child: const Text("CONFIRMAR PROGRAMACIÓN", style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );

    if (MediaQuery.of(context).size.width > 800) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: IndustrialTheme.spaceCadet,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: widget,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: IndustrialTheme.spaceCadet,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => widget,
      );
    }
  }
}
