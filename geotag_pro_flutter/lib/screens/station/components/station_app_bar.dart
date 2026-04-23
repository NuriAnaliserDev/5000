import 'package:flutter/material.dart';
import '../../../models/station.dart';
import '../../../utils/app_localizations.dart';

class StationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Station? station;
  final VoidCallback onSave;
  final Function(String) onMenuAction;

  const StationAppBar({
    super.key,
    this.station,
    required this.onSave,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    final surf = Theme.of(context).colorScheme.surface;

    return AppBar(
      backgroundColor: surf,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => onMenuAction('back'),
      ),
      title: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage, color: Color(0xFF1976D2), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                station?.name ?? context.loc('camera'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (station != null)
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF1976D2), size: 22),
            tooltip: context.loc('save'),
            onPressed: onSave,
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF1976D2)),
          onSelected: onMenuAction,
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'pdf',
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(context.loc('pdf_report')),
                ],
              ),
            ),
            if (station != null)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(context.loc('delete'), style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
