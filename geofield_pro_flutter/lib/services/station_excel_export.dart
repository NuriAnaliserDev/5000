import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;

import '../models/station.dart';

/// Stansiyalar jadvali — alohida `.xlsx` (shablon hisobot emas).
class StationExcelExport {
  static final _dateFmt = DateFormat('yyyy-MM-dd HH:mm');

  static Future<io.File> writeStationsFile(List<Station> stations) async {
    final excel = Excel.createExcel();
    final firstName = excel.tables.keys.first;
    excel.rename(firstName, 'Stations');
    final sheet = excel['Stations'];
    const headers = <String>[
      'name',
      'lat',
      'lng',
      'altitude_m',
      'strike',
      'dip',
      'azimuth',
      'dip_direction',
      'date_utc',
      'project',
      'rockType',
      'structure',
      'measurementType',
      'sampleId',
      'sampleType',
      'description',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    for (final st in stations) {
      sheet.appendRow([
        TextCellValue(st.name),
        DoubleCellValue(st.lat),
        DoubleCellValue(st.lng),
        DoubleCellValue(st.altitude),
        DoubleCellValue(st.strike),
        DoubleCellValue(st.dip),
        DoubleCellValue(st.azimuth),
        st.dipDirection != null
            ? DoubleCellValue(st.dipDirection!)
            : TextCellValue(''),
        TextCellValue(_dateFmt.format(st.date.toUtc())),
        TextCellValue(st.project ?? ''),
        TextCellValue(st.rockType ?? ''),
        TextCellValue(st.structure ?? ''),
        TextCellValue(st.measurementType ?? ''),
        TextCellValue(st.sampleId ?? ''),
        TextCellValue(st.sampleType ?? ''),
        TextCellValue(st.description ?? ''),
      ]);
    }
    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Excel encode');
    }
    final dir = await getTemporaryDirectory();
    final f = io.File(
      '${dir.path}/geofield_stations_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }
}
