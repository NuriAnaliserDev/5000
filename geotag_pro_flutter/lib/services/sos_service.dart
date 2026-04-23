import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class EmergencySignal {
  final String id;
  final String senderUid;
  final String senderName;
  final LatLng position;
  final DateTime timestamp;
  final bool isActive;

  EmergencySignal({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.position,
    required this.timestamp,
    required this.isActive,
  });

  factory EmergencySignal.fromMap(Map<String, dynamic> map, String id) {
    return EmergencySignal(
      id: id,
      senderUid: map['senderUid'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      position: LatLng(map['lat'] ?? 0.0, map['lng'] ?? 0.0),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}

class SosService extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<List<EmergencySignal>> get emergencySignals {
    return _firestore
        .collection('emergency_signals')
        .where('isActive', isEqualTo: true)
        .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(hours: 4)))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencySignal.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendSos(LatLng position, String name) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('emergency_signals').add({
        'senderUid': user.uid,
        'senderName': name,
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      debugPrint('Error sending SOS: $e');
    }
  }

  Future<void> clearSos(String signalId) async {
    try {
      await _firestore.collection('emergency_signals').doc(signalId).update({
        'isActive': false,
      });
    } catch (e) {
      debugPrint('Error clearing SOS: $e');
    }
  }
}
