import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/mine_report.dart';
import '../utils/firebase_ready.dart';

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
    });
  }

  // Update report to Verified status, alongside the corrected parsedData
  Future<void> verifyReport(String reportId, Map<String, dynamic> correctedData,
      String verifiedByUserName) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('daily_mine_reports').doc(reportId).update({
        'status': 'verified',
        'parsedData': correctedData,
        'verifiedBy': verifiedByUserName,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error verifying report: $e");
      rethrow;
    }
  }

  // Delete/Reject report
  Future<void> deleteReport(String reportId) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('daily_mine_reports').doc(reportId).delete();
    } catch (e) {
      debugPrint("Error deleting report: $e");
      rethrow;
    }
  }
}
