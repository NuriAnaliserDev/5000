import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../utils/firebase_ready.dart';

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
  FirebaseFirestore? get _firestore => firestoreOrNull;
  FirebaseAuth? get _auth {
    if (!isFirebaseCoreReady) return null;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  Timer? _presenceTimer;
  StreamSubscription? _teamSubscription;
  List<TeamMember> _teamMembers = [];
  LatLng? _lastSentPosition;

  List<TeamMember> get teamMembers => _teamMembers;

  PresenceService() {
    _initTeamListener();
  }

  void _initTeamListener() {
    final fs = _firestore;
    final auth = _auth;
    if (fs == null || auth == null) return;
    _teamSubscription = fs
        .collection('presence')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _teamMembers = snapshot.docs
          .map((doc) => TeamMember.fromMap(doc.data(), doc.id))
          .where((m) => m.uid != auth.currentUser?.uid) // Exclude self
          .toList();
      notifyListeners();
    });
  }

  /// Starts periodic location updates for the current user
  void startBroadcasting(LatLng Function() getPosition, String name, String role) {
    _presenceTimer?.cancel();
    final first = getPosition();
    _lastSentPosition = first;
    _updatePresence(first, name, role, true);
    _presenceTimer = Timer.periodic(const Duration(seconds: 120), (_) {
      final pos = getPosition();
      if (_lastSentPosition != null) {
        final d = Geolocator.distanceBetween(
          _lastSentPosition!.latitude,
          _lastSentPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );
        if (d < 10.0) {
          return;
        }
      }
      _lastSentPosition = pos;
      _updatePresence(pos, name, role, true);
    });
  }

  Future<void> _updatePresence(LatLng position, String name, String role, bool isOnline) async {
    final user = _auth?.currentUser;
    if (user == null) return;
    final fs = _firestore;
    if (fs == null) return;

    try {
      await fs.collection('presence').doc(user.uid).set({
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
