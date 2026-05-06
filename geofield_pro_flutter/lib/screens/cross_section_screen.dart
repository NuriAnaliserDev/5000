import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../services/cross_section_service.dart';
import '../services/station_repository.dart';
import '../utils/app_card.dart';
import 'cross_section/profile_section_painter.dart';

part 'cross_section/cross_section_fields.dart';
part 'cross_section/cross_section_ui.dart';
part 'cross_section/cross_section_state.dart';

class CrossSectionScreen extends StatefulWidget {
  final LatLng start;
  final LatLng end;

  const CrossSectionScreen({
    super.key,
    required this.start,
    required this.end,
  });

  @override
  State<CrossSectionScreen> createState() => _CrossSectionScreenState();
}
