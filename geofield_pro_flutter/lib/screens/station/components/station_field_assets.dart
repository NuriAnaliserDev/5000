import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/station.dart';
import '../../../utils/app_localizations.dart';

class StationFieldAssets extends StatelessWidget {
  final Station? station;
  final bool isDark;
  final bool isPlaying;
  final VoidCallback onAddCamera;
  final VoidCallback onAddGallery;
  final Function(String) onDeletePhoto;
  final Function(String) onViewPhoto;
  final Function(String) onOpenPainter;
  final VoidCallback onPlayAudio;

  const StationFieldAssets({
    super.key,
    required this.station,
    required this.isDark,
    required this.isPlaying,
    required this.onAddCamera,
    required this.onAddGallery,
    required this.onDeletePhoto,
    required this.onViewPhoto,
    required this.onOpenPainter,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final photoPaths = station?.photoPaths ??
        (station?.photoPath != null ? [station!.photoPath!] : []);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.loc('field_assets'),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 2,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAddButton(
                context,
                Icons.add_a_photo,
                context.loc('camera').toUpperCase(),
                onAddCamera,
              ),
              _buildAddButton(
                context,
                Icons.photo_library,
                context.loc('add_gallery').toUpperCase(),
                onAddGallery,
              ),
              ...photoPaths.map((p) => _buildPhotoItem(context, p)),
              if (station?.audioPath != null) _buildAudioItem(context, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF1976D2).withValues(alpha: 0.4),
            width: 2,
          ),
          color: isDark ? const Color(0xFF222222) : Colors.grey.shade100,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1976D2), size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(BuildContext context, String path) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(
          image: FileImage(File(path)),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onViewPhoto(path),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => onDeletePhoto(path),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 36,
            child: GestureDetector(
              onTap: () => onOpenPainter(path),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioItem(BuildContext context, ThemeData theme) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.lightBlueAccent.withValues(alpha: 0.5),
          width: 2,
        ),
        color: isDark
            ? const Color(0xFF1A237E)
            : theme.colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            iconSize: 32,
            color: isDark ? Colors.white : theme.colorScheme.primary,
            icon: Icon(
              isPlaying ? Icons.pause_circle : Icons.play_circle,
            ),
            onPressed: onPlayAudio,
          ),
          const SizedBox(height: 4),
          const Text(
            'AUDIO NOTE',
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}
