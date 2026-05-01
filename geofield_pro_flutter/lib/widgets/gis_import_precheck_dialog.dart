import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// GIS fayl tanlashdan oldin formatlar va DXF talablari haqida aniqlik.
Future<bool> showGisImportPrecheckDialog(BuildContext context) async {
  final s = GeoFieldStrings.of(context);
  if (s == null) return false;
  final scheme = Theme.of(context).colorScheme;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: scheme.primary, size: 28),
          const SizedBox(width: 10),
          Expanded(child: Text(s.gis_import_precheck_title)),
        ],
      ),
      content: SingleChildScrollView(
        child: SelectableText(
          s.gis_import_precheck_body,
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(s.gis_import_choose_file),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
  return go == true;
}
