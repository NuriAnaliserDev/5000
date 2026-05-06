import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/boundary_service.dart';
import '../../services/location_service.dart';
import '../../models/boundary_polygon.dart';
import '../../l10n/app_strings.dart';
import '../../utils/firebase_ready.dart';
import '../../utils/gis_import_feedback.dart';
import '../../widgets/gis_import_precheck_dialog.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/error_mapper.dart';
import 'components/web_map_drawing_panel.dart';
import 'components/web_map_zone_list_panel.dart';
import 'components/web_map_shift_logs_panel.dart';
import 'components/web_map_toolbar.dart';

part 'web_map_screen_fields.dart';
part 'web_map_screen_actions.dart';
part 'web_map_screen_map.dart';
part 'web_map_screen_state.dart';

class WebMapScreen extends StatefulWidget {
  const WebMapScreen({super.key});

  @override
  State<WebMapScreen> createState() => _WebMapScreenState();
}
