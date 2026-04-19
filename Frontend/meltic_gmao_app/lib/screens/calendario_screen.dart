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
          // Normalizar a medianoche para el mapa
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
        title: const Text("CALENDARIO PREVENTIVO", style: TextStyle(letterSpacing: 1.5, fontSize: 14)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: IndustrialTheme.neonCyan))
        : Column(
            children: [
              _buildCalendar(),
              const SizedBox(height: 8),
              _buildEventsHeader(),
              Expanded(child: _buildEventList()),
            ],
          ),
      floatingActionButton: AppSession.instance.isJefe ? FloatingActionButton.extended(
        onPressed: _showCreatePreventivaDialog,
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
        border: Border.all(color: Colors.white10),
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
          todayDecoration: BoxDecoration(color: IndustrialTheme.claudCloud, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: IndustrialTheme.neonCyan))),
          selectedDecoration: BoxDecoration(color: IndustrialTheme.neonCyan, shape: BoxShape.circle),
          markerDecoration: BoxDecoration(color: IndustrialTheme.warningOrange, shape: BoxShape.circle),
          defaultTextStyle: TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: IndustrialTheme.slateGray),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: IndustrialTheme.neonCyan, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: IndustrialTheme.neonCyan),
          rightChevronIcon: Icon(Icons.chevron_right, color: IndustrialTheme.neonCyan),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildEventsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.event_note, color: IndustrialTheme.neonCyan, size: 18),
          const SizedBox(width: 8),
          Text(
            DateFormat('EEEE, d MMMM', 'es_ES').format(_selectedDay!).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: IndustrialTheme.slateGray),
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
            Icon(Icons.calendar_today_outlined, size: 48, color: IndustrialTheme.slateGray.withAlpha(50)),
            const SizedBox(height: 12),
            const Text("No hay tareas programadas", style: TextStyle(color: IndustrialTheme.slateGray)),
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
          child: ListTile(
            leading: const Icon(Icons.settings_backup_restore, color: IndustrialTheme.warningOrange),
            title: Text(ot.maquinaNombre ?? 'MÁQUINA NO ASIGNADA', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(ot.descripcion),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: IndustrialTheme.warningOrange.withAlpha(50), borderRadius: BorderRadius.circular(8)),
              child: const Text("PREVENTIVA", style: TextStyle(color: IndustrialTheme.warningOrange, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            onTap: () => Navigator.pushNamed(context, '/ot-detail', arguments: ot.id),
          ),
        );
      },
    ).animate().fadeIn(delay: 200.ms);
  }

  void _showCreatePreventivaDialog() {
    final TextEditingController descCtrl = TextEditingController();
    Maquina? selectedMaquina;
    String prioridad = 'MEDIA';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: IndustrialTheme.spaceCadet,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("PROGRAMAR MANTENIMIENTO", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 20),
              DropdownButtonFormField<Maquina>(
                decoration: const InputDecoration(labelText: "Máquina"),
                items: _maquinas.map((m) => DropdownMenuItem(value: m, child: Text(m.nombre))).toList(),
                onChanged: (val) => setModalState(() => selectedMaquina = val),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Descripción de la tarea"),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
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
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OT Programada Correctamente"), backgroundColor: IndustrialTheme.operativeGreen));
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: IndustrialTheme.criticalRed));
                    }
                  },
                  child: const Text("GUARDAR PROGRAMACIÓN"),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
