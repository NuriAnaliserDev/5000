import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_strings.dart';
import '../../../models/geological_line.dart';
import '../../../services/geological_line_repository.dart';
import '../../../utils/app_localizations.dart';

class MapLineActions {
  const MapLineActions._();

  static Future<void> showLineActions(
    BuildContext context,
    GeologicalLine line,
  ) async {
    final s = GeoFieldStrings.of(context);
    if (s == null) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(s.line_action_edit),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: Text(s.delete),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(s.cancel),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;

    if (action == 'edit') {
      await showLinePropertyEditor(context, line);
    } else if (action == 'delete') {
      await confirmDeleteLine(context, line);
    }
  }

  static Future<bool> saveDrawing(
    BuildContext context, {
    required String selectedLineType,
    required List<LatLng> points,
    required bool isCurvedMode,
  }) async {
    final nameCtrl = TextEditingController(
      text: '${GeologicalLine.localizedName(selectedLineType)} 1',
    );
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.loc('save_drawing_title')),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: context.loc('drawing_name')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.loc('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.loc('save_label')),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return false;

    final newLine = GeologicalLine(
      id: const Uuid().v4(),
      name: nameCtrl.text,
      lineType: selectedLineType,
      lats: points.map((p) => p.latitude).toList(),
      lngs: points.map((p) => p.longitude).toList(),
      date: DateTime.now(),
      isClosed: selectedLineType == 'polygon',
      isDashed: selectedLineType == 'fault',
      isCurved: isCurvedMode,
    );

    await context.read<GeologicalLineRepository>().addLine(newLine);
    if (!context.mounted) return false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.locRead('drawing_saved'))),
    );
    return true;
  }

  static Future<void> confirmDeleteLine(
    BuildContext context,
    GeologicalLine line,
  ) async {
    final s = GeoFieldStrings.of(context);
    if (s == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(line.name),
        content: Text(s.map_tap_line_delete_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(s.delete_confirm_btn),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    await context.read<GeologicalLineRepository>().deleteLine(line.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.map_line_deleted_snack),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> showLinePropertyEditor(
    BuildContext context,
    GeologicalLine line,
  ) async {
    final s = GeoFieldStrings.of(context);
    if (s == null) return;

    const types = <String>[
      'fault',
      'contact',
      'bedding_trace',
      'fold_axis',
      'polygon',
      'other',
    ];
    final nameCtrl = TextEditingController(text: line.name);
    final notesCtrl = TextEditingController(text: line.notes ?? '');
    var lineType = line.lineType;
    if (!types.contains(lineType)) lineType = 'other';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(s.line_property_title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration:
                        InputDecoration(labelText: s.line_property_name),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Type'),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: lineType,
                      items: types
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(GeologicalLine.localizedName(e)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setLocal(() => lineType = v ?? lineType),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration:
                        InputDecoration(labelText: s.line_property_notes),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.save),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !context.mounted) return;

    final notes = notesCtrl.text.trim();
    final updated = GeologicalLine(
      id: line.id,
      name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : line.name,
      lineType: lineType,
      lats: line.lats,
      lngs: line.lngs,
      date: line.date,
      colorHex: line.colorHex,
      project: line.project,
      notes: notes.isEmpty ? null : notes,
      isClosed: line.isClosed,
      strokeWidth: line.strokeWidth,
      isDashed: line.isDashed,
      isCurved: line.isCurved,
      controlLats: line.controlLats,
      controlLngs: line.controlLngs,
    );
    await context.read<GeologicalLineRepository>().updateLine(updated);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.locRead('success_saved')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
