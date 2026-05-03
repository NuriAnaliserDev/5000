import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../core/network/network_executor.dart';

/// Nuqta uchun DEM taxmini — Open-Elevation (internet talab).
class ElevationService {
  static const _url = 'https://api.open-elevation.com/api/v1/lookup';

  static Future<double?> fetchElevationMeters(LatLng p) async {
    try {
      final res = await NetworkExecutor.execute(
        () => http.post(
          Uri.parse(_url),
          headers: const {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'locations': [
              {'latitude': p.latitude, 'longitude': p.longitude},
            ],
          }),
        ),
        actionName: 'Fetch Elevation',
        maxRetries: 2,
        timeout: const Duration(seconds: 12),
      );

      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final r = data?['results'];
      if (r is! List || r.isEmpty) return null;
      final o = r[0] as Map<String, dynamic>?;
      final e = o?['elevation'];
      if (e is num) return e.toDouble();
      return null;
    } catch (_) {
      return null;
    }
  }
}
