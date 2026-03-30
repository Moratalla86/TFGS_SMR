import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/orden_trabajo.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<String?> generarReporteCierreBase64(
    OrdenTrabajo ot,
    String trabajos,
    Map<String, bool> checklists,
    String? fotoBase64,
    String? firmaTecnicoBase64,
    String? firmaClienteBase64,
  ) async {
    try {
      final pdf = pw.Document();

      pw.Widget buildChecklist() {
        if (checklists.isEmpty) return pw.SizedBox();
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'PROTOCOLO DE REVISIÓN',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 8),
            ...checklists.entries
                .map(
                  (e) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 12,
                          height: 12,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.blue900),
                            color: e.value
                                ? PdfColors.blue900
                                : PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(e.key, style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          e.value ? '✓' : '○',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: e.value ? PdfColors.green : PdfColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            pw.SizedBox(height: 20),
          ],
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.blue900, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'GMAO INDUSTRIAL SMR 4.0',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'Sistema de Gestión de Mantenimiento Industrial',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'HOJA DE INTERVENCIÓN TÉCNICA',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'TICKET #${ot.id} — ${ot.tipo ?? 'CORRECTIVA'}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          build: (context) => [
            pw.SizedBox(height: 20),

            // DATOS GENERALES
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DATOS DEL ACTIVO Y SERVICIO',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Activo Intervenido: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        ot.maquinaNombre ?? 'GENERAL',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Técnico Asignado: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        ot.tecnicoNombre ?? 'SIN ASIGNAR',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Fecha de Cierre: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        DateFormat(
                          'dd/MM/yyyy HH:mm:ss',
                        ).format(DateTime.now()),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Prioridad: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        ot.prioridad,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Motivo / Descriptivo:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    ot.descripcion,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // CHECKLIST
            buildChecklist(),

            // TRABAJOS REALIZADOS
            pw.Text(
              'ACCIONES Y RESOLUCIÓN FINAL',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Text(
                trabajos.isEmpty
                    ? 'Sin observaciones descritas por el operario.'
                    : trabajos,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 20),

            // EVIDENCIAS FOTOGRÁFICAS
            if (fotoBase64 != null) ...[
              pw.Text(
                'EVIDENCIA EN CAMPO',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 200,
                alignment: pw.Alignment.centerLeft,
                child: pw.Image(pw.MemoryImage(base64Decode(fotoBase64))),
              ),
              pw.SizedBox(height: 20),
            ],

            // FIRMAS
            pw.Text(
              'CERTIFICACIÓN LEGAL',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    firmaTecnicoBase64 != null
                        ? pw.Image(
                            pw.MemoryImage(base64Decode(firmaTecnicoBase64)),
                            height: 60,
                          )
                        : pw.Container(
                            height: 60,
                            width: 150,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey200),
                            ),
                          ),
                    pw.Container(width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Firma Funcionario Técnico',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    firmaClienteBase64 != null
                        ? pw.Image(
                            pw.MemoryImage(base64Decode(firmaClienteBase64)),
                            height: 60,
                          )
                        : pw.Container(
                            height: 60,
                            width: 150,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey200),
                            ),
                          ),
                    pw.Container(width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Validación Cliente/Planta',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ],
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Reporte Oficial GMAO INDUSTRIAL SMR 4.0  //  Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
        ),
      );

      final bytes = await pdf.save();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  /// Visualiza un PDF desde base64 usando el visor nativo del sistema operativo
  static Future<void> viewLocalPdf(String base64String, String name) async {
    try {
      final bytes = base64Decode(base64String);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: name,
      );
    } catch (_) {}
  }

  /// Genera y muestra inmediatamente un PDF para OTs cerradas antiguas (sin reportePdfBase64)
  static Future<void> generarYVerPdf(
    OrdenTrabajo ot,
    Map<String, bool> checklists,
  ) async {
    final b64 = await generarReporteCierreBase64(
      ot,
      ot.trabajosRealizados ?? '',
      checklists,
      ot.fotoBase64,
      ot.firmaTecnico,
      ot.firmaCliente,
    );
    if (b64 != null) {
      await viewLocalPdf(b64, 'Reporte_OT_${ot.id}.pdf');
    }
  }
}
