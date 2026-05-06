import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/station.dart';
import '../services/location_service.dart';
import '../services/settings_controller.dart';
import '../services/station_repository.dart';
import '../utils/app_nav_bar.dart';
import '../utils/app_scroll_physics.dart';

import '../widgets/dashboard/dashboard_components.dart';
import '../widgets/dashboard/dashboard_mini_map_box.dart';
import '../widgets/dashboard/dashboard_session_box.dart';
import '../widgets/dashboard/dashboard_widgets_2.dart';
import '../widgets/dashboard/tiles/utm_tile.dart';
import '../widgets/dashboard/tiles/fisher_reliability_tile.dart';
import '../widgets/common/stitch_screen_background.dart';
import '../widgets/dashboard/desktop/dashboard_desktop_sidebar.dart';
import '../widgets/dashboard/desktop/dashboard_desktop_bento_grid.dart';
import '../widgets/dashboard/desktop/dashboard_desktop_project_section.dart';
import '../widgets/dashboard/desktop/dashboard_desktop_header.dart';

part 'dashboard/dashboard_screen_helpers.dart';
part 'dashboard/dashboard_screen_fields.dart';
part 'dashboard/dashboard_screen_layouts.dart';
part 'dashboard/dashboard_screen_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.embedded = false});

  /// `true` — [MainTabShell] ichida; pastki nav tashqi [Scaffold] beradi.
  final bool embedded;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
