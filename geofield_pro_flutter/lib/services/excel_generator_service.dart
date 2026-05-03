import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/mine_report.dart';
import '../utils/downloader/file_downloader.dart';
import '../core/error/app_error.dart';
import '../core/error/error_logger.dart';

class ExcelGeneratorService {
  /// Tasdiqlangan (Verified) hisobotlarni Excel shablonga kiritib kompyuterga yuklash
  /// Uchta tur qo'llab-quvvatlanadi: ore_block, rc_drill, ore_stockpile
  Future<void> generateAndDownload(List<MineReport> reports) async {
    try {
      // 1. Shablon faylini o'qish
      final byteData = await rootBundle.load('assets/KUNLIK HISOBOTLAR.xlsx');
      final bytes = byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      final excel = Excel.decodeBytes(bytes);

      final targetSheetName = excel.tables.keys.first;
      final sheet = excel[targetSheetName];

      // 2. Har tur uchun boshlanish qatori — shablon tuzilmasiga mos
      int oreBlockRow = 3; // Spotter / Ore Block jadvali boshlanishi
      int rcDrillRow = 20; // RC Burg'ulash jadvali boshlanishi
      int stockpileRow = 40; // Ore Stockpile Monitoring jadvali boshlanishi

      for (final report in reports) {
        final data = report.parsedData;

        switch (report.reportType) {
          // ── Ore Block (Spotter) ─────────────────────────────────────────────
          case 'ore_block':
            final row = oreBlockRow++;
            _writeText(sheet, 1, row, data['pit']?.toString() ?? '');
            _writeText(sheet, 2, row, data['horizon']?.toString() ?? '');
            _writeText(sheet, 3, row, data['markup']?.toString() ?? '');
            _writeText(sheet, 4, row, data['block_full']?.toString() ?? '');
            _writeText(sheet, 5, row, data['destination']?.toString() ?? '');
            _writeText(sheet, 6, row, data['total_loads']?.toString() ?? '');
            _writeText(sheet, 7, row, data['grade']?.toString() ?? '');
            _writeText(sheet, 8, row, data['excavator']?.toString() ?? '');
            _writeText(sheet, 9, row, data['spotter']?.toString() ?? '');
            _writeText(sheet, 10, row, data['date']?.toString() ?? '');
            break;

          // ── RC Burg'ulash (RC Daily Operation Report) ────────────────────────
          case 'rc_drill':
            final row = rcDrillRow++;
            _writeText(sheet, 1, row, data['date']?.toString() ?? '');
            _writeText(sheet, 2, row, data['rig_id']?.toString() ?? '');
            _writeText(sheet, 3, row, data['rig_model']?.toString() ?? '');
            _writeText(sheet, 4, row, data['contractor']?.toString() ?? '');
            _writeText(sheet, 5, row, data['project']?.toString() ?? '');
            _writeText(sheet, 6, row, data['hole_id']?.toString() ?? '');
            _writeText(sheet, 7, row, data['depth']?.toString() ?? '');
            _writeText(sheet, 8, row, data['sample_from']?.toString() ?? '');
            _writeText(sheet, 9, row, data['sample_to']?.toString() ?? '');
            _writeText(sheet, 10, row, data['sample_count']?.toString() ?? '');
            _writeText(sheet, 11, row, data['total_depth']?.toString() ?? '');
            _writeText(
                sheet, 12, row, data['downtime_cause']?.toString() ?? '');
            break;

          // ── Ore Stockpile Daily Monitoring ───────────────────────────────────
          case 'ore_stockpile':
            final row = stockpileRow++;
            _writeText(sheet, 1, row, data['date']?.toString() ?? '');
            _writeText(sheet, 2, row, data['shift']?.toString() ?? '');
            _writeText(sheet, 3, row, data['geologist']?.toString() ?? '');
            _writeText(sheet, 4, row, data['grand_total']?.toString() ?? '');

            // Loader ma'lumotlari (list bo'lishi mumkin)
            final loaders = data['loaders'];
            if (loaders is List) {
              for (int li = 0; li < loaders.length; li++) {
                final loader = loaders[li];
                if (loader is Map) {
                  _writeText(sheet, 5 + li * 4, row,
                      loader['loader_id']?.toString() ?? '');
                  _writeText(sheet, 6 + li * 4, row,
                      loader['material']?.toString() ?? '');
                  _writeText(sheet, 7 + li * 4, row,
                      loader['grade']?.toString() ?? '');
                  _writeText(sheet, 8 + li * 4, row,
                      loader['total_loads']?.toString() ?? '');
                }
              }
            }
            break;
        }
      }

      // 3. Faylni saqlash va yuklash
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final dateStr = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
        final fileName = 'KUNLIK_HISOBOT_$dateStr.xlsx';
        await FileDownloader.downloadBytes(fileBytes, fileName);
      } else {
        throw AppError("Excel encoding muvaffaqiyatsiz", category: ErrorCategory.unknown);
      }
    } catch (e, st) {
      if (e is AppError) rethrow;
      ErrorLogger.record(e, st, customMessage: 'Excel Yaratishda Xato');
      throw AppError("Excel Yaratishda Xato: $e", category: ErrorCategory.unknown);
    }
  }

  void _writeText(Sheet sheet, int col, int row, String text) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue(text);
  }
}
