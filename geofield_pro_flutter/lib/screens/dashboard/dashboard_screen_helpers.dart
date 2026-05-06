part of '../dashboard_screen.dart';

int _dashboardSettingsToken(SettingsController s) => Object.hash(
      s.currentProject,
      s.mapStyle,
      s.currentUserName,
      Object.hashAll(s.projects),
    );

({double lat, double lng, double acc, bool hasFix}) _locSlice(
    LocationService loc) {
  final p = loc.currentPosition;
  if (p == null) {
    return (
      lat: loc.latitude,
      lng: loc.longitude,
      acc: loc.accuracy,
      hasFix: false,
    );
  }
  return (
    lat: p.latitude,
    lng: p.longitude,
    acc: p.accuracy,
    hasFix: true,
  );
}
