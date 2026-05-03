import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/mine_report.dart';
import '../utils/firebase_ready.dart';
import '../core/network/network_executor.dart';
import '../core/error/error_logger.dart';

class MineReportRepository extends ChangeNotifier {
  FirebaseFirestore? get _db => firestoreOrNull;

  // Real-time stream of all reports (for the Inbox)
  Stream<List<MineReport>> streamReports() {
    final db = _db;
    if (db == null) return Stream.value([]);
    return db
        .collection('daily_mine_reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MineReport.fromFirestore(doc)).toList();
    }).handleError((e, st) {
      ErrorLogger.record(e, st, customMessage: 'MineReport stream error');
    });
  }

  // Real-time stream of PENDING reports
  Stream<List<MineReport>> streamPendingReports() {
    final db = _db;
    if (db == null) return Stream.value([]);
    return db
        .collection('daily_mine_reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MineReport.fromFirestore(doc)).toList();
    }).handleError((e, st) {
      ErrorLogger.record(e, st,
          customMessage: 'MineReport streamPendingReports error');
    });
  }

  // Real-time stream of PENDING reports filtered by type (ore_block | rc_drill | ore_stockpile)
  Stream<List<MineReport>> streamPendingReportsByType(String reportType) {
    final db = _db;
    if (db == null) return Stream.value([]);
    return db
        .collection('daily_mine_reports')
        .where('status', isEqualTo: 'pending')
        .where('reportType', isEqualTo: reportType)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MineReport.fromFirestore(doc)).toList();
    }).handleError((e, st) {
      ErrorLogger.record(e, st,
          customMessage: 'MineReport streamPendingReportsByType error');
    });
  }

  // Real-time stream of VERIFIED reports (for Analytics)
  Stream<List<MineReport>> streamVerifiedReports() {
    final db = _db;
    if (db == null) return Stream.value([]);
    return db
        .collection('daily_mine_reports')
        .where('status', isEqualTo: 'verified')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MineReport.fromFirestore(doc)).toList();
    }).handleError((e, st) {
      ErrorLogger.record(e, st,
          customMessage: 'MineReport streamVerifiedReports error');
    });
  }

  // Update report to Verified status, alongside the corrected parsedData
  Future<void> verifyReport(String reportId, Map<String, dynamic> correctedData,
      String verifiedByUserName) async {
    final db = _db;
    if (db == null) return;
    try {
      await NetworkExecutor.execute(
        () => db.collection('daily_mine_reports').doc(reportId).update({
          'status': 'verified',
          'parsedData': correctedData,
          'verifiedBy': verifiedByUserName,
          'verifiedAt': FieldValue.serverTimestamp(),
        }),
        actionName: 'Verify Mine Report',
        maxRetries: 2,
      );
    } catch (e, st) {
      ErrorLogger.record(e, st, customMessage: 'Error verifying report');
      rethrow;
    }
  }

  // Delete/Reject report
  Future<void> deleteReport(String reportId) async {
    final db = _db;
    if (db == null) return;
    try {
      await NetworkExecutor.execute(
        () => db.collection('daily_mine_reports').doc(reportId).delete(),
        actionName: 'Delete Mine Report',
        maxRetries: 2,
      );
    } catch (e, st) {
      ErrorLogger.record(e, st, customMessage: 'Error deleting report');
      rethrow;
    }
  }
}
