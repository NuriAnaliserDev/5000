import 'package:cloud_firestore/cloud_firestore.dart';

class MineReport {
  final String id;
  final String reportType; // 'ore_block', 'rc_drill', 'stockpile'
  final DateTime createdAt;
  final String authorName;
  final String? authorUid;
  final String imageUrl;
  final String? audioUrl;
  final double? lat;
  final double? lng;
  final String status; // 'pending', 'verified'
  final Map<String, dynamic> parsedData;
  final String? verifiedBy;
  final DateTime? verifiedAt;

  MineReport({
    required this.id,
    required this.reportType,
    required this.createdAt,
    required this.authorName,
    this.authorUid,
    required this.imageUrl,
    this.audioUrl,
    this.lat,
    this.lng,
    required this.status,
    required this.parsedData,
    this.verifiedBy,
    this.verifiedAt,
  });

  factory MineReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MineReport(
      id: doc.id,
      reportType: data['reportType'] ?? 'unknown',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      authorName: data['authorName'] ?? 'Noma\'lum',
      authorUid: data['authorUid'] as String?,
      imageUrl: data['imageUrl'] ?? '',
      audioUrl: data['audioUrl'],
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      status: data['status'] ?? 'pending',
      parsedData: data['parsedData'] as Map<String, dynamic>? ?? {},
      verifiedBy: data['verifiedBy'],
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportType': reportType,
      'createdAt': Timestamp.fromDate(createdAt),
      'authorName': authorName,
      if (authorUid != null) 'authorUid': authorUid,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'lat': lat,
      'lng': lng,
      'status': status,
      'parsedData': parsedData,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
    };
  }
}
