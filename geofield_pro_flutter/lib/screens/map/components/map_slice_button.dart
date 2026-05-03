import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';

class MapSliceButton extends StatelessWidget {
  final bool isSliceMode;
  final VoidCallback onPressed;

  const MapSliceButton({
    super.key,
    required this.isSliceMode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tip = GeoFieldStrings.of(context)?.map_slice_tooltip ?? '';
    return Tooltip(
      message: tip,
      child: FloatingActionButton.small(
        heroTag: 'slice_fab',
        backgroundColor: isSliceMode ? Colors.orange : Colors.white,
        onPressed: onPressed,
        child: Icon(Icons.content_cut,
            color: isSliceMode ? Colors.white : Colors.black87),
      ),
    );
  }
}
