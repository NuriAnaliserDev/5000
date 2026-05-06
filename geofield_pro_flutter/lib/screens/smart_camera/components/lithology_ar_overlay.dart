import 'package:flutter/material.dart';
import '../../../models/ai_analysis_result.dart';
import '../../../services/ai/decision_engine.dart';
import '../../../models/user_context.dart';

class LithologyArOverlay extends StatelessWidget {
  final AIAnalysisResult? result;
  final UserContext userContext;
  final VoidCallback onReset;
  final VoidCallback onManualInput;
  final VoidCallback onAccept;

  const LithologyArOverlay({
    super.key,
    this.result,
    required this.userContext,
    required this.onReset,
    required this.onManualInput,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              "NAMUNA TAHLIL QILINMOQDA...",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final ux = DecisionEngine.decide(result!, userContext);
    final isExpert = userContext.role == UserRole.expert;

    return Stack(
      children: [
        // ROI Frame (Center Area)
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: result!.isStabilized ? 260 : 240,
            height: result!.isStabilized ? 260 : 240,
            decoration: BoxDecoration(
              border: Border.all(
                color: ux.color.withOpacity(0.4),
                width: result!.isStabilized ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        // Central Rock Type Label (Glance Layer)
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(top: 290),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: ux.color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: ux.color.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5),
                  ],
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                  child: Text(result!.rockType.toUpperCase()),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildReliabilityBadge(ux, result!.isStabilized),
              ),
            ],
          ),
        ),

        // Bottom Panel (Details & Expert Layers)
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Column(
            children: [
              if (isExpert) _buildBreakdownPanel(result!),
              const SizedBox(height: 12),
              _buildMessageCard(ux),
              const SizedBox(height: 16),
              _buildActionButtons(ux),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReliabilityBadge(UXDecision ux, bool stable) {
    // Professional Balance: Minimal feedback while stabilizing
    if (!stable && ux.action != AppDecision.block) {
      return Text(
        "ANIQLANMOQDA...",
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    String label = "ANIQLANMOQDA...";
    if (stable) {
      if (ux.action == AppDecision.autoAccept) {
        label = "ISHONCHLI";
      } else if (ux.action == AppDecision.showWithWarning)
        label = "TEKSHIRIB KO'RING";
      else
        label = "DIQQAT: NOANIQ";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ux.color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              value: (stable || ux.action == AppDecision.block) ? 1.0 : null,
              strokeWidth: 2,
              color: ux.color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownPanel(AIAnalysisResult res) {
    final bd = res.trustBreakdown;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _bdItem("AI", bd['ai'] ?? 0),
          _divider(),
          _bdItem("DOM", bd['domain'] ?? 0),
          _divider(),
          _bdItem("IMG", bd['image'] ?? 0),
          _divider(),
          Text(
            "JAMI: ${(res.trustScore * 100).toInt()}%",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _bdItem(String label, double val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 8)),
        Text("${(val * 100).toInt()}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 16, color: Colors.white12);

  Widget _buildMessageCard(UXDecision ux) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: ux.color, width: 4)),
      ),
      child: Text(
        ux.userMessage,
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
      ),
    );
  }

  Widget _buildActionButtons(UXDecision ux) {
    return Row(
      children: [
        Expanded(
          child: _btn(
            label: "Qayta olish",
            icon: Icons.refresh,
            onPressed: onReset,
            color: Colors.white10,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _btn(
            label: "Manual",
            icon: Icons.edit,
            onPressed: onManualInput,
            color: Colors.white10,
          ),
        ),
        if (ux.action != AppDecision.block) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _btn(
              label: "Tasdiqlash",
              icon: Icons.check_circle,
              onPressed: onAccept,
              color: ux.color,
              isPrimary: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _btn({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isPrimary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class RoundedRectangleInBorder extends OutlinedBorder {
  final BorderRadius borderRadius;
  const RoundedRectangleInBorder({this.borderRadius = BorderRadius.zero});
  @override
  OutlinedBorder copyWith({BorderSide? side}) => this;
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
  @override
  ShapeBorder scale(double t) => this;
}
