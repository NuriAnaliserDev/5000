import 'dart:io';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/station.dart';
import 'export_service.dart';
import 'pdf/pdf_fonts.dart';

class PdfExportService {
  static Future<File> _atomicWriteBytes(String path, List<int> bytes) async {
    final target = File(path);
    final tmp = File('$path.tmp.${DateTime.now().microsecondsSinceEpoch}');
    await tmp.writeAsBytes(bytes, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await tmp.rename(target.path);
    return target;
  }

  static Future<File> generateStationReport(Station station) async {
    final issues = ExportService.validateStationsForExport([station]);
    ExportService.logExportValidation('pdf_station', [station], issues);
    await PdfFonts.ensureLoaded();
    final theme = PdfFonts.theme();
    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(station),
            pw.SizedBox(height: 20),
            _buildInfoTable(station),
            pw.SizedBox(height: 20),
            if (station.description != null &&
                station.description!.isNotEmpty) ...[
              pw.Text('Tavsif:',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(station.description!,
                  style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
            ],
            if (station.photoPath != null ||
                (station.photoPaths?.isNotEmpty ?? false))
              _buildPhotos(station),
            pw.SizedBox(height: 20),
            _buildStereonet(station),
            pw.SizedBox(height: 20),
            _buildAuditTrail(station),
            pw.SizedBox(height: 40),
            _buildSignatureSection(station),
          ];
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/report_${station.name}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final bytes = await pdf.save();
    return _atomicWriteBytes(path, bytes);
  }

  static Future<File> generateProjectReport(
      List<Station> stations, String projectName) async {
    final issues = ExportService.validateStationsForExport(stations);
    ExportService.logExportValidation('pdf_project', stations, issues);
    await PdfFonts.ensureLoaded();
    final theme = PdfFonts.theme();
    final pdf = pw.Document(theme: theme);

    // Summary Page
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Text('GeoField Pro N - PROJEKT HISOBOTI',
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900)),
            pw.SizedBox(height: 8),
            pw.Text('Loyiha: $projectName',
                style:
                    const pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
            pw.Text('Stansiyalar soni: ${stations.length}',
                style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: null,
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              data: [
                ['#', 'Stansiya', 'Koordinatalar', 'Tosh turi'],
                ...List.generate(
                    stations.length,
                    (i) => [
                          '${i + 1}',
                          stations[i].name,
                          '${stations[i].lat.toStringAsFixed(4)}, ${stations[i].lng.toStringAsFixed(4)}',
                          stations[i].rockType ?? '-'
                        ]),
              ],
            ),
          ];
        },
      ),
    );

    // Individual Station Pages
    for (final s in stations) {
      pdf.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(s),
              pw.SizedBox(height: 20),
              _buildInfoTable(s),
              pw.SizedBox(height: 20),
              if (s.description != null && s.description!.isNotEmpty) ...[
                pw.Text('Tavsif:',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text(s.description!,
                    style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 20),
              ],
              if (s.photoPath != null || (s.photoPaths?.isNotEmpty ?? false))
                _buildPhotos(s),
            ];
          },
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = projectName.replaceAll(RegExp(r'[^\w\s\-]'), '_');
    final path =
        '${dir.path}/project_${fileName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final bytes = await pdf.save();
    return _atomicWriteBytes(path, bytes);
  }

  static pw.Widget _buildPhotos(Station station) {
    // For simplicity in this demo, we just list paths.
    // In a real app, we would load images.
    final paths = <String>[];
    if (station.photoPath != null) paths.add(station.photoPath!);
    if (station.photoPaths != null) paths.addAll(station.photoPaths!);

    if (paths.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('FOTOSURATLAR:',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: paths
              .map((p) => pw.Container(
                    width: 150,
                    height: 100,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Center(
                        child: pw.Text('Surat: ${p.split("/").last}',
                            style: const pw.TextStyle(fontSize: 8))),
                  ))
              .toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildHeader(Station station) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('GeoField Pro N - JORC REPORT',
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900)),
            pw.Text('International Reporting Standard Compliant',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('STATION: ${station.name}',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Sanasi: ${DateFormat('dd.MM.yyyy').format(station.date)}',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInfoTable(Station station) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      headerStyle:
          pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
      },
      data: [
        ['MAYDON', 'QIYMAT'],
        ['ID', station.key.toString()],
        ['Litologiya', station.rockType],
        ['Namuna ID', station.sampleId ?? 'N/A'],
        ['Ishonchlilik (JORC)', station.confidence ?? 'Inferred'],
        ['Munsell Rangi', station.munsellColor ?? 'N/A'],
        [
          'Koordinatalar',
          '${station.lat.toStringAsFixed(6)}, ${station.lng.toStringAsFixed(6)}'
        ],
        ['Balandlik', '${station.altitude.toStringAsFixed(1)} m'],
      ],
    );
  }

  static pw.Widget _buildStereonet(Station station) {
    const double size = 150;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: size,
            height: size,
            child: pw.Stack(
              children: [
                pw.Center(
                  child: pw.CustomPaint(
                    size: const PdfPoint(size, size),
                    painter: (PdfGraphics canvas, PdfPoint sizePdf) {
                      final strikeRad = station.strike * math.pi / 180;
                      final dipRad = station.dip * math.pi / 180;
                      final radius = size / 2 - 10;
                      final dist = radius * math.tan(dipRad / 2);

                      final apex = math.Point(
                          size / 2 + dist * math.cos(strikeRad - math.pi / 2),
                          size / 2 + dist * math.sin(strikeRad - math.pi / 2));

                      canvas.setStrokeColor(const PdfColor(0.8, 0.8, 0.8));
                      canvas.setLineWidth(0.5);
                      canvas.drawLine(size / 2, 10, size / 2, size - 10);
                      canvas.strokePath();
                      canvas.drawLine(10, size / 2, size - 10, size / 2);
                      canvas.strokePath();

                      canvas.drawEllipse(apex.x - 3, apex.y - 3, 6, 6);
                      canvas.setFillColor(PdfColors.red);
                      canvas.fillPath();
                    },
                  ),
                ),
                pw.Positioned(
                    top: 0,
                    left: size / 2 - 5,
                    child:
                        pw.Text('N', style: const pw.TextStyle(fontSize: 8))),
                pw.Positioned(
                    bottom: 0,
                    left: size / 2 - 5,
                    child:
                        pw.Text('S', style: const pw.TextStyle(fontSize: 8))),
                pw.Positioned(
                    left: 0,
                    top: size / 2 - 5,
                    child:
                        pw.Text('W', style: const pw.TextStyle(fontSize: 8))),
                pw.Positioned(
                    right: 0,
                    top: size / 2 - 5,
                    child:
                        pw.Text('E', style: const pw.TextStyle(fontSize: 8))),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('STEREONET PROJECTED (Wulff)',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('Strike: ${station.strike.toStringAsFixed(0)}',
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Dip: ${station.dip.toStringAsFixed(0)}',
                  style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAuditTrail(Station station) {
    if (station.history == null || station.history!.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('AUDIT TRAIL (O\'zgarishlar Tarixi):',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red900)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          context: null,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          headerStyle:
              pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 7),
          data: [
            ['Vaqt', 'Muallif', 'Maydon', 'Eski Qiymat', 'Yangi Qiymat'],
            ...station.history!.map((e) => [
                  DateFormat('dd.MM.yyyy HH:mm').format(e.timestamp),
                  e.author,
                  e.fieldName,
                  e.oldValue,
                  e.newValue,
                ]),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureSection(Station station) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Hisobot tuzuvchi:',
                style:
                    pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text(station.authorName ?? 'Noma\'lum Geolog',
                style: const pw.TextStyle(fontSize: 11)),
            pw.Text(station.authorRole ?? 'Field Geologist',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              width: 120,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text('Imzo / Sana', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ],
    );
  }
}
