class OrdenTrabajo {
  final int id;
  final String descripcion;
  final String prioridad;
  final String estado;
  final String? fechaCreacion;
  final String? fechaInicio;
  final String? fechaFin;
  final String? trabajosRealizados;
  final String? firmaTecnico;
  final String? firmaCliente;
  final int? maquinaId;
  final String? maquinaNombre;
  final int? tecnicoId;
  final String? tecnicoNombre;

  OrdenTrabajo({
    required this.id,
    required this.descripcion,
    required this.prioridad,
    required this.estado,
    this.fechaCreacion,
    this.fechaInicio,
    this.fechaFin,
    this.trabajosRealizados,
    this.firmaTecnico,
    this.firmaCliente,
    this.maquinaId,
    this.maquinaNombre,
    this.tecnicoId,
    this.tecnicoNombre,
  });

  factory OrdenTrabajo.fromJson(Map<String, dynamic> json) {
    return OrdenTrabajo(
      id: json['id'],
      descripcion: json['descripcion'] ?? '',
      prioridad: json['prioridad'] ?? 'BAJA',
      estado: json['estado'] ?? 'PENDIENTE',
      fechaCreacion: json['fechaCreacion']?.toString(),
      fechaInicio: json['fechaInicio']?.toString(),
      fechaFin: json['fechaFin']?.toString(),
      trabajosRealizados: json['trabajosRealizados'],
      firmaTecnico: json['firmaTecnico'],
      firmaCliente: json['firmaCliente'],
      maquinaId: json['maquina'] != null ? json['maquina']['id'] : null,
      maquinaNombre: json['maquina'] != null ? json['maquina']['nombre'] : null,
      tecnicoId: json['tecnico'] != null ? json['tecnico']['id'] : null,
      tecnicoNombre: json['tecnico'] != null
          ? ('${json['tecnico']['nombre'] ?? ''} ${json['tecnico']['apellido1'] ?? ''}').trim()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'descripcion': descripcion,
      'prioridad': prioridad,
      'estado': estado,
    };
  }
}
