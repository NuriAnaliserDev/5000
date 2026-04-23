import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../models/station.dart';
import '../../services/location_service.dart';
import '../../services/settings_controller.dart';
import '../../services/station_repository.dart';
import '../../services/track_service.dart';
import '../../services/tutorial_service.dart';
import '../../utils/app_localizations.dart';
import '../../utils/geo_orientation.dart';
import '../../utils/geology_utils.dart';
import '../../utils/image_utils.dart';
import '../../utils/status_semantics.dart';
import '../components/ar_strike_dip_overlay.dart';

import 'components/camera_bottom_controls.dart';
import 'components/camera_gps_hud.dart';
import 'components/camera_heading_hud.dart';
import 'components/camera_orientation_hud.dart';
import 'components/camera_overlays.dart';
import 'components/camera_side_controls.dart';
import 'components/camera_top_bar.dart';

part 'smart_camera_screen_state.dart';

enum CameraMode { geological, document }

/// Kamera + sensor mantiqi [smart_camera_screen_state.dart] part faylida (qatorlar bo‘yicha bo‘lingan).
class SmartCameraScreen extends StatefulWidget {
  final int? stationId;

  const SmartCameraScreen({super.key, this.stationId});

  @override
  State<SmartCameraScreen> createState() => SmartCameraScreenState();
}
