import '../../app/app_router.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:torch_light/torch_light.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/station.dart';
import '../../services/location_service.dart';
import '../../services/settings_controller.dart';
import '../../services/station_repository.dart';
import '../../services/track_service.dart';
import '../../services/tutorial_service.dart';
import '../../utils/app_localizations.dart';
import '../../utils/app_nav_bar.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/error_mapper.dart';
import '../../core/diagnostics/production_diagnostics.dart';
import '../../core/diagnostics/app_timeouts.dart';
import '../../utils/geo_orientation.dart';
import '../../utils/geology_utils.dart';
import '../../utils/image_utils.dart';
import '../../utils/status_semantics.dart';

import 'components/camera_bottom_controls.dart';
import 'components/camera_overlays.dart';
import 'components/camera_side_controls.dart';
import 'components/camera_top_bar.dart';
import 'components/focus_mode_geology_overlay.dart';
import 'components/geological_ar_view.dart';
import 'components/lithology_ar_overlay.dart';
import '../../models/ai_analysis_result.dart';
import '../../services/ai_lithology_service.dart';
import '../../models/user_context.dart';

part 'smart_camera_screen_fields_mixin.dart';
part 'smart_camera_screen_sensor_mixin.dart';
part 'smart_camera_screen_capture_mixin.dart';
part 'smart_camera_screen_camera_mixin.dart';
part 'smart_camera_screen_presentation_mixin.dart';
part 'smart_camera_screen_state.dart';

enum CameraMode { geological, document, lithology }

/// Kamera holati: maydonlar + sensor/capture/camera/presentation mixinlari va [smart_camera_screen_state.dart] ichidagi scaffold/build.
class SmartCameraScreen extends StatefulWidget {
  final int? stationId;
  final bool embedded;

  /// [MainTabShell] / IndexedStack: faqat tanlangan tabda kamera yoki AR ishga tushadi.
  /// Boshqa tab ochiq turganida ham vidjet quriladi — bu flag «ko‘rinmas» holatda texnikani yopadi.
  final bool tabVisible;

  const SmartCameraScreen({
    super.key,
    this.stationId,
    this.embedded = false,
    this.tabVisible = true,
  });

  @override
  State<SmartCameraScreen> createState() => SmartCameraScreenState();
}
