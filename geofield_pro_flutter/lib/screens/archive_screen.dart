import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_router.dart';
import '../app/main_tab_navigation.dart';
import '../services/settings_controller.dart';
import '../services/station_repository.dart';
import '../services/track_service.dart';
import '../utils/app_localizations.dart';
import '../utils/app_nav_bar.dart';

import 'archive/archive_delete_helpers.dart';
import 'archive/archive_export_sheets.dart';
import 'archive/archive_share_export.dart';
import 'archive/tabs/stations_tab.dart';
import 'archive/tabs/tracks_tab.dart';

part 'archive/archive_screen_fields.dart';
part 'archive/archive_screen_actions.dart';
part 'archive/archive_screen_state.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}
