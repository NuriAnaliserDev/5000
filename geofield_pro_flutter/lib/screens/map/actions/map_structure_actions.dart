import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_strings.dart';
import '../../../models/map_structure_annotation.dart';
import '../../../models/measurement.dart';
import '../../../services/map_structure_repository.dart';

class MapStructureActions {
  const MapStructureActions._();

  static Future<void> showAddStructureDialog(
    BuildContext context,
    LatLng point,
  ) async {
    final s = GeoFieldStrings.of(context);
    if (s == null) return;
    const types = <String>[
      'bedding',
      'cleavage',
      'lineation',
      'joint',
      'contact',
      'fault',
      'other',
    ];
    var selectedType = 'bedding';
    final strikeCtrl = TextEditingController(text: '0');
    final dipCtrl = TextEditingController(text: '45');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(s.map_structure_add_title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: strikeCtrl,
                    decoration: InputDecoration(
                      labelText: s.map_structure_strike_label,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dipCtrl,
                    decoration:
                        InputDecoration(labelText: s.map_structure_dip_label),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      s.map_structure_type_label,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: types.map((type) {
                      final selected = selectedType == type;
                      return FilterChip(
                        label: Text(
                          Measurement(
                            type: type,
                            strike: 0,
                            dip: 0,
                            dipDirection: 0,
                            capturedAt: DateTime.now(),
                          ).localizedType,
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: selected,
                        onSelected: (_) => setLocal(() => selectedType = type),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.save_label),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !context.mounted) return;

    var strike = double.tryParse(strikeCtrl.text.replaceAll(',', '.')) ?? 0;
    var dip = double.tryParse(dipCtrl.text.replaceAll(',', '.')) ?? 0;
    strike = strike % 360;
    if (strike < 0) strike += 360;
    dip = dip.clamp(0, 90);

    final annotation = MapStructureAnnotation(
      id: const Uuid().v4(),
      lat: point.latitude,
      lng: point.longitude,
      strike: strike,
      dip: dip,
      structureType: selectedType,
      createdAt: DateTime.now(),
    );
    await context.read<MapStructureRepository>().addAnnotation(annotation);
  }
}
