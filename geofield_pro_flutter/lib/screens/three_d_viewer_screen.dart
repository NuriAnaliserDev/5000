import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/station_repository.dart';
import 'three_d/structural_3d_viewer_painter.dart';

part 'three_d/three_d_viewer_fields.dart';
part 'three_d/three_d_viewer_state.dart';

class ThreeDViewerScreen extends StatefulWidget {
  final LatLng? centerPoint;
  const ThreeDViewerScreen({super.key, this.centerPoint});

  @override
  State<ThreeDViewerScreen> createState() => _ThreeDViewerScreenState();
}
