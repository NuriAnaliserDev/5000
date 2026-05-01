import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../services/station_repository.dart';
import '../services/track_service.dart';
import '../services/elevation_service.dart';
import '../services/location_service.dart';
import '../services/settings_controller.dart';
import '../services/boundary_service.dart';
import '../services/geological_line_repository.dart';
import '../services/map_structure_repository.dart';
import '../services/tutorial_service.dart';
import '../services/presence_service.dart';
import '../services/sos_service.dart';
import '../models/station.dart';
import '../models/geological_line.dart';
import '../models/map_structure_annotation.dart';
import '../models/measurement.dart';
import '../models/boundary_polygon.dart';
import '../utils/gis_geojson_export.dart';
import '../utils/gis_import_feedback.dart';
import '../utils/linework_utils.dart';
import '../utils/map_geodesy.dart';
import '../utils/spatial_calculator.dart';
import '../utils/utm_wgs84.dart';
import '../l10n/app_strings.dart';
import '../utils/app_nav_bar.dart';
import '../utils/app_localizations.dart';
import '../utils/overlay_fab_layout.dart';
import '../widgets/common/draggable_fab.dart';
import '../widgets/gis_import_precheck_dialog.dart';
import '../widgets/map/map_search_sheet.dart';
import 'cross_section_screen.dart';

// Components
import 'map/components/map_track_layer.dart';
import 'map/components/map_station_layer.dart';
import 'map/components/map_linework_layer.dart';
import 'map/components/map_team_presence_layer.dart';
import 'map/components/map_sos_signals_layer.dart';
import 'map/components/map_gps_hud.dart';
import 'map/components/map_legend.dart';
import 'map/components/map_top_bar.dart';
import 'map/components/map_stitch_top_cluster.dart';
import 'map/components/map_stitch_map_hub.dart';
import 'map/components/map_live_track_stats.dart';
import 'map/components/map_sos_button.dart';
import 'map/components/map_track_fab.dart';
import 'map/components/map_linework_controls.dart';
import 'map/components/map_projection_controls.dart';
import 'map/components/map_layer_drawer.dart';
import 'map/components/map_structure_markers_layer.dart';
import 'map/map_pro_tools_screen.dart';
import 'map/map_tile_config.dart';
import 'map/map_polygon_builders.dart';
import 'three_d_viewer_screen.dart';
import '../app/app_router.dart';
import '../app/main_tab_navigation.dart';

part 'global_map_screen_state.dart';

class GlobalMapScreen extends StatefulWidget {
  final Map<String, dynamic>? initLocation;
  /// `true` — alohida marshrut: Pro maydon (qatlam, GIS, chizim, struktura bitta fokus).
  final bool fieldWorkshopMode;
  /// `true` — [MainTabShell] ostida; pastki tab bar tashqi scaffoldda.
  final bool embedded;

  const GlobalMapScreen({
    super.key,
    this.initLocation,
    this.fieldWorkshopMode = false,
    this.embedded = false,
  });

  @override
  State<GlobalMapScreen> createState() => _GlobalMapScreenState();
}
