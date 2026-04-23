import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class TeamMember {
  final String uid;
  final String name;
  final String role;
  final LatLng position;
  final bool isOnline;
  final DateTime lastSeen;

  TeamMember({
    required this.uid,
    required this.name,
    required this.role,
    required this.position,
    required this.isOnline,
    required this.lastSeen,
  });

  factory TeamMember.fromMap(Map<String, dynamic> map, String uid) {
    return TeamMember(
      uid: uid,
      name: map['name'] ?? 'Unknown',
      role: map['role'] ?? 'Geologist',
      position: LatLng(map['lat'] ?? 0.0, map['lng'] ?? 0.0),
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class PresenceService extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  Timer? _presenceTimer;
  StreamSubscription? _teamSubscription;
  List<TeamMember> _teamMembers = [];

  List<TeamMember> get teamMembers => _teamMembers;

  PresenceService() {
    _initTeamListener();
  }

  void _initTeamListener() {
    _teamSubscription = _firestore
        .collection('presence')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _teamMembers = snapshot.docs
          .map((doc) => TeamMember.fromMap(doc.data(), doc.id))
          .where((m) => m.uid != _auth.currentUser?.uid) // Exclude self
          .toList();
      notifyListeners();
    });
  }

  /// Starts periodic location updates for the current user
  void startBroadcasting(LatLng Function() getPosition, String name, String role) {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updatePresence(getPosition(), name, role, true);
    });
    // Immediate update
    _updatePresence(getPosition(), name, role, true);
  }

  Future<void> _updatePresence(LatLng position, String name, String role, bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('presence').doc(user.uid).set({
        'name': name,
        'role': role,
        'lat': position.latitude,
        'lng': position.longitude,
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  void stopBroadcasting() {
    _presenceTimer?.cancel();
    _updatePresence(const LatLng(0, 0), '', '', false);
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _teamSubscription?.cancel();
    super.dispose();
  }
}
