import 'package:flutter/material.dart';

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
    return FloatingActionButton.small(
      heroTag: 'slice_fab',
      backgroundColor: isSliceMode ? Colors.orange : Colors.white,
      onPressed: onPressed,
      child: Icon(Icons.content_cut, color: isSliceMode ? Colors.white : Colors.black87),
    );
  }
}
