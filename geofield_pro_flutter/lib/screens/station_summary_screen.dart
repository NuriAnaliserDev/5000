import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../models/station.dart';
import '../models/measurement.dart';
import '../services/station_repository.dart';
import '../services/settings_controller.dart';
import '../services/pdf_export_service.dart';
import '../services/ai_lithology_service.dart';
import '../services/ai/ai_rate_limiter.dart';
import '../utils/app_localizations.dart';
import '../utils/rocks_list.dart';
import '../utils/munsell_data.dart';
import '../app/main_tab_navigation.dart';
import '../core/error/error_handler.dart';
import '../core/error/error_mapper.dart';

import 'station/components/station_app_bar.dart';
import 'station/components/station_form_body.dart';
import 'station/components/station_map_header.dart';

part 'station/station_summary_fields.dart';
part 'station/station_summary_actions.dart';
part 'station/station_summary_state.dart';

class StationSummaryScreen extends StatefulWidget {
  final int? stationId;
  const StationSummaryScreen({super.key, this.stationId});

  @override
  State<StationSummaryScreen> createState() => _StationSummaryScreenState();
}
