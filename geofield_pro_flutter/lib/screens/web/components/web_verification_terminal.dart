import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../services/mine_report_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/ai_translator_service.dart';
import '../../../models/mine_report.dart';
import '../../../core/error/app_error.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/error/error_mapper.dart';

part 'web_verification_terminal.part.dart';

class WebVerificationTerminal extends StatefulWidget {
  final MineReport report;
  final VoidCallback? onDismiss; // Tasdiqlash/rad etishdan keyin chaqiriladi

  const WebVerificationTerminal({
    super.key,
    required this.report,
    this.onDismiss,
  });

  @override
  State<WebVerificationTerminal> createState() =>
      _WebVerificationTerminalState();
}

class _WebVerificationTerminalState extends State<WebVerificationTerminal>
    with _WebVerificationTerminalPart {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Row(
      children: [
        // 1. Asl Rasm paneli
        Expanded(
          flex: 5,
          child: Container(
            color: Colors.black87,
            child: widget.report.imageUrl.isNotEmpty
                ? InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      widget.report.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => const Center(
                          child: Text("Rasm yuklanmadi",
                              style: TextStyle(color: Colors.grey))),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white));
                      },
                    ),
                  )
                : const Center(
                    child: Text("Rasm yo'q",
                        style: TextStyle(color: Colors.white54))),
          ),
        ),

        Container(width: 1, color: t.dividerColor),

        // 2. Xarita + forma
        Expanded(
          flex: 4,
          child: Column(
            children: [
              // GPS Xarita
              Expanded(
                flex: 1,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: (widget.report.lat != null &&
                                widget.report.lng != null)
                            ? LatLng(widget.report.lat!, widget.report.lng!)
                            : const LatLng(41.2995, 69.2401),
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.aurum.geofieldpro',
                        ),
                        if (widget.report.lat != null &&
                            widget.report.lng != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                    widget.report.lat!, widget.report.lng!),
                                width: 40,
                                height: 40,
                                child: Icon(Icons.location_on,
                                    color: vtTypeColor, size: 40),
                              )
                            ],
                          ),
                      ],
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "📍 ${widget.report.authorName}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Tahrirlash paneli
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  color: t.colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tur badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: vtTypeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: vtTypeColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          "$vtTypeLabel — ${widget.report.authorName}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: vtTypeColor,
                              fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // AI tugmasi
                      SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          icon: _isAiLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, size: 16),
                          label: Text(
                            _isAiLoading
                                ? "AI O'QIMOQDA..."
                                : "🤖 AI AUTO-FILL",
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A1B9A),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isAiLoading ? null : vtRunAiAnalysis,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Formalar
                      Expanded(child: vtBuildFormFields()),

                      const SizedBox(height: 10),

                      // Tugmalar qatori: RAD ETISH | TASDIQLASH
                      Row(
                        children: [
                          // Rad etish
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton.icon(
                                icon: _isRejecting
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.red))
                                    : const Icon(Icons.close, size: 16),
                                label: const Text("RAD ETISH",
                                    style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: (_isSaving || _isRejecting)
                                    ? null
                                    : vtReject,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tasdiqlash
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Icon(Icons.verified, size: 16),
                                label: Text(
                                  _isSaving ? "SAQLANMOQDA..." : "TASDIQLASH",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: (_isSaving || _isRejecting)
                                    ? null
                                    : vtVerify,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
