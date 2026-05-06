import 'package:flutter/material.dart';

import '../../core/di/dependency_injection.dart';
import '../../models/geological_line.dart';
import '../../models/map_structure_annotation.dart';
import '../../models/station.dart';
import '../../models/sync_conflict.dart';
import '../../models/sync_item.dart';
import '../../services/geological_line_repository.dart';
import '../../services/map_structure_repository.dart';
import '../../services/station_repository.dart';
import '../../services/sync/conflict_queue_service.dart';
import '../../services/sync/sync_processor.dart';

part 'conflict_resolution_part.dart';

class ConflictResolutionScreen extends StatefulWidget {
  const ConflictResolutionScreen({super.key});

  @override
  State<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}
