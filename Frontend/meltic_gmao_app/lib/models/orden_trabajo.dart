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
  final String? fechaPlanificada; // Phase 4
  final String? tipo;
  final String? checklists;
  final String? fotoBase64;
  final String? reportePdfBase64;
  final int? maquinaId;
  final String? maquinaNombre;
  final String? maquinaModelo;
  final int? tecnicoId;
  final String? tecnicoNombre;
  final int? solicitanteId;
  final String? solicitanteNombre;

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
    this.fechaPlanificada,
    this.tipo,
    this.checklists,
    this.fotoBase64,
    this.reportePdfBase64,
    this.maquinaId,
    this.maquinaNombre,
    this.maquinaModelo,
    this.tecnicoId,
    this.tecnicoNombre,
    this.solicitanteId,
    this.solicitanteNombre,
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
      fechaPlanificada: json['fechaPlanificada']?.toString(),
      tipo: json['tipo'],
      checklists: json['checklists'],
      fotoBase64: json['fotoBase64'],
      reportePdfBase64: json['reportePdfBase64'],
      maquinaId: json['maquina'] != null ? json['maquina']['id'] : null,
      maquinaNombre: json['maquina'] != null ? json['maquina']['nombre'] : null,
      maquinaModelo: json['maquina'] != null ? json['maquina']['modelo'] : null,
      tecnicoId: json['tecnico'] != null ? json['tecnico']['id'] : null,
      tecnicoNombre: json['tecnico'] != null
          ? ('${json['tecnico']['nombre'] ?? ''} ${json['tecnico']['apellido1'] ?? ''}')
                .trim()
          : null,
      solicitanteId: json['solicitante'] != null ? json['solicitante']['id'] : null,
      solicitanteNombre: json['solicitante'] != null
          ? ('${json['solicitante']['nombre'] ?? ''} ${json['solicitante']['apellido1'] ?? ''}')
                .trim()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'descripcion': descripcion,
      'prioridad': prioridad,
      'estado': estado,
      if (fechaPlanificada != null) 'fechaPlanificada': fechaPlanificada,
      if (tipo != null) 'tipo': tipo,
      if (checklists != null) 'checklists': checklists,
      if (fotoBase64 != null) 'fotoBase64': fotoBase64,
      if (reportePdfBase64 != null) 'reportePdfBase64': reportePdfBase64,
      if (maquinaId != null) 'maquina': {'id': maquinaId},
      if (tecnicoId != null) 'tecnico': {'id': tecnicoId},
      if (solicitanteId != null) 'solicitante': {'id': solicitanteId},
    };
  }
}
