import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/station.dart';
import '../../../services/settings_controller.dart';
import 'station_coordinate_section.dart';
import 'station_rock_section.dart';
import 'station_sample_section.dart';
import 'station_structural_section.dart';
import 'station_field_assets.dart';

class StationFormBody extends StatelessWidget {
  final Station? station;
  final TextEditingController descriptionController;
  final TextEditingController rockTypeController;
  final TextEditingController structureController;
  final TextEditingController colorController;
  final TextEditingController latController;
  final TextEditingController lngController;
  final TextEditingController strikeController;
  final TextEditingController dipController;
  final TextEditingController dipDirectionController;
  final TextEditingController azimuthController;
  final TextEditingController sampleIdController;
  final TextEditingController sampleTypeController;

  final String rockType;
  final String measurementType;
  final String subMeasurementType;
  final List<String> measurementTypes;
  final int confidence;
  final String munsellColor;
  final bool isAiLoading;
  final bool isPlaying;
  final String coordinateFormat;

  final Function(String?) onRockTypeChanged;
  final Function(String?) onSubRockTypeChanged;
  final VoidCallback onAiAnalyze;
  final Function(int) onConfidenceChanged;
  final VoidCallback onPickMunsell;
  final Function(String?) onMeasurementTypeChanged;
  final Function(String?) onSubMeasurementTypeChanged;
  final VoidCallback onUpdateGps;
  final Function(String) onCoordinateFormatChanged;
  final VoidCallback onAddCamera;
  final VoidCallback onAddGallery;
  final Function(String) onDeletePhoto;
  final Function(String) onViewPhoto;
  final Function(String) onOpenPainter;
  final VoidCallback onPlayAudio;

  const StationFormBody({
    super.key,
    this.station,
    required this.descriptionController,
    required this.rockTypeController,
    required this.structureController,
    required this.colorController,
    required this.latController,
    required this.lngController,
    required this.strikeController,
    required this.dipController,
    required this.dipDirectionController,
    required this.azimuthController,
    required this.sampleIdController,
    required this.sampleTypeController,
    required this.rockType,
    required this.measurementType,
    required this.subMeasurementType,
    required this.measurementTypes,
    required this.confidence,
    required this.munsellColor,
    required this.isAiLoading,
    required this.isPlaying,
    required this.coordinateFormat,
    required this.onRockTypeChanged,
    required this.onSubRockTypeChanged,
    required this.onAiAnalyze,
    required this.onConfidenceChanged,
    required this.onPickMunsell,
    required this.onMeasurementTypeChanged,
    required this.onSubMeasurementTypeChanged,
    required this.onUpdateGps,
    required this.onCoordinateFormatChanged,
    required this.onAddCamera,
    required this.onAddGallery,
    required this.onDeletePhoto,
    required this.onViewPhoto,
    required this.onOpenPainter,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expertMode = context.watch<SettingsController>().expertMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StationCoordinateSection(
            station: station,
            latController: latController,
            lngController: lngController,
            onUpdateGps: onUpdateGps,
            coordinateFormat: coordinateFormat,
            onFormatChanged: onCoordinateFormatChanged,
          ),
          const SizedBox(height: 24),
          StationRockSection(
            descriptionController: descriptionController,
            rockTypeController: rockTypeController,
            structureController: structureController,
            colorController: colorController,
            rockType: rockType,
            subRockType: rockTypeController.text,
            onRockTypeChanged: onRockTypeChanged,
            onSubRockTypeChanged: onSubRockTypeChanged,
            onAiAnalyze: onAiAnalyze,
            isAiLoading: isAiLoading,
          ),
          const SizedBox(height: 24),
          if (expertMode) ...[
            StationSampleSection(
              sampleIdController: sampleIdController,
              sampleTypeController: sampleTypeController,
              confidence: confidence,
              munsellColor: munsellColor,
              onConfidenceChanged: onConfidenceChanged,
              onPickMunsell: onPickMunsell,
            ),
            const SizedBox(height: 24),
          ],
          StationStructuralSection(
            strikeController: strikeController,
            dipController: dipController,
            dipDirectionController: dipDirectionController,
            azimuthController: azimuthController,
            measurementType: measurementType,
            subMeasurementType: subMeasurementType,
            measurementTypes: measurementTypes,
            onMeasurementTypeChanged: onMeasurementTypeChanged,
            onSubMeasurementTypeChanged: onSubMeasurementTypeChanged,
          ),
          if (expertMode)
            const Divider(height: 48)
          else
            const SizedBox(height: 16),
          StationFieldAssets(
            station: station,
            isDark: isDark,
            isPlaying: isPlaying,
            onAddCamera: onAddCamera,
            onAddGallery: onAddGallery,
            onDeletePhoto: onDeletePhoto,
            onViewPhoto: onViewPhoto,
            onOpenPainter: onOpenPainter,
            onPlayAudio: onPlayAudio,
          ),
        ],
      ),
    );
  }
}
