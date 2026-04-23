import 'package:flutter/foundation.dart';

import '../models/station.dart';
import 'geo/stereonet_engine.dart';
import 'geology_utils.dart';

/// Stereonet zichlik panjarasi: og'ir hisob [compute]da (UI threadni bo'g'lamaslik).
List<ProjectedPoint> collectStereonetPoles(
  List<Station> stations,
  double radius,
  StereonetProjection projection,
) {
  final points = <ProjectedPoint>[];
  for (final s in stations) {
    final dipDir = s.dipDirection ?? ((s.strike + 90) % 360);
    points.add(
      StereonetEngine.projectPole(
        dipDirection: dipDir,
        dip: s.dip,
        radius: radius,
        proj: projection,
        data: s,
      ),
    );
    if (s.measurements != null) {
      for (final m in s.measurements!) {
        points.add(
          StereonetEngine.projectPole(
            dipDirection: m.dipDirection,
            dip: m.dip,
            radius: radius,
            proj: projection,
            data: s,
          ),
        );
      }
    }
  }
  return points;
}

class StereonetDensityJob {
  const StereonetDensityJob({
    required this.poleX,
    required this.poleY,
    required this.radius,
    required this.gridSize,
    required this.bandwidth,
  });

  final List<double> poleX;
  final List<double> poleY;
  final double radius;
  final int gridSize;
  final double bandwidth;
}

List<List<double>> stereonetDensityGridCompute(StereonetDensityJob job) {
  final pts = List<ProjectedPoint>.generate(
    job.poleX.length,
    (i) => ProjectedPoint(x: job.poleX[i], y: job.poleY[i], data: null),
  );
  return StereonetEngine.calculateDensityGrid(
    pts,
    job.radius,
    job.gridSize,
    job.bandwidth,
  );
}

/// [stations] o'zgarganda chaqiring — [compute] orqali.
Future<List<List<double>>?> runStereonetDensityCompute({
  required List<Station> stations,
  required double radius,
  required StereonetProjection projection,
  int gridSize = 50,
  double? bandwidth,
}) async {
  if (stations.isEmpty) return null;
  final pts = collectStereonetPoles(stations, radius, projection);
  if (pts.isEmpty) return null;
  final bw = bandwidth ?? (radius * 0.12);
  final job = StereonetDensityJob(
    poleX: [for (final p in pts) p.x],
    poleY: [for (final p in pts) p.y],
    radius: radius,
    gridSize: gridSize,
    bandwidth: bw,
  );
  return compute(stereonetDensityGridCompute, job);
}
