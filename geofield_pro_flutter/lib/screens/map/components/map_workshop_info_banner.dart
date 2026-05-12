import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';

class MapWorkshopInfoBanner extends StatelessWidget {
  const MapWorkshopInfoBanner({
    super.key,
    required this.checklist,
    required this.onClose,
    required this.onChecklistChanged,
  });

  final List<bool> checklist;
  final VoidCallback onClose;
  final void Function(int index, bool value) onChecklistChanged;

  @override
  Widget build(BuildContext context) {
    final s = GeoFieldStrings.of(context);
    if (s == null) return const SizedBox.shrink();
    final t = Theme.of(context);

    return Positioned(
      top: 64,
      left: 10,
      right: 10,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        color: t.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 4, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.checklist_rtl, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.field_workshop_checklist,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: t.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                s.field_workshop_banner,
                style: TextStyle(
                  fontSize: 10,
                  color:
                      t.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
              _ChecklistItem(
                value: checklist[0],
                title: s.field_workshop_ch1,
                onChanged: (v) => onChecklistChanged(0, v),
              ),
              _ChecklistItem(
                value: checklist[1],
                title: s.field_workshop_ch2,
                onChanged: (v) => onChecklistChanged(1, v),
              ),
              _ChecklistItem(
                value: checklist[2],
                title: s.field_workshop_ch3,
                onChanged: (v) => onChecklistChanged(2, v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.value,
    required this.title,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(title, style: const TextStyle(fontSize: 11)),
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
