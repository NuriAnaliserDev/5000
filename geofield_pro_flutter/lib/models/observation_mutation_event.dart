import 'dart:convert';

import 'field_trust_category.dart';
import 'observation_pipeline_types.dart';

/// Append-only operatsion jurnal (event sourcing emas).
class ObservationMutationEvent {
  final String observationId;
  final int timestampMsUtc;
  final ObservationMutationSource mutationSource;
  final List<String> changedFields;
  final FieldTrustCategory? previousCategory;
  final FieldTrustCategory newCategory;
  final List<String> previousWarnings;
  final List<String> newWarnings;
  final String? reasonHint;

  const ObservationMutationEvent({
    required this.observationId,
    required this.timestampMsUtc,
    required this.mutationSource,
    this.changedFields = const [],
    this.previousCategory,
    required this.newCategory,
    this.previousWarnings = const [],
    required this.newWarnings,
    this.reasonHint,
  });

  Map<String, dynamic> toJson() => {
        'obs': observationId,
        'ts': timestampMsUtc,
        'src': mutationSource.name,
        'fields': changedFields,
        'pcat': previousCategory?.name,
        'ncat': newCategory.name,
        'pw': List<String>.from(previousWarnings),
        'nw': List<String>.from(newWarnings),
        if (reasonHint != null) 'hint': reasonHint,
      };

  String encodeLine() => jsonEncode(toJson());

  static ObservationMutationEvent? tryDecodeLine(String line) {
    try {
      final m = jsonDecode(line) as Map<String, dynamic>;
      final srcName = m['src'] as String?;
      ObservationMutationSource src = ObservationMutationSource.capture;
      if (srcName != null) {
        for (final v in ObservationMutationSource.values) {
          if (v.name == srcName) {
            src = v;
            break;
          }
        }
      }
      FieldTrustCategory? pc;
      final pr = m['pcat'] as String?;
      if (pr != null) {
        for (final c in FieldTrustCategory.values) {
          if (c.name == pr) {
            pc = c;
            break;
          }
        }
      }
      FieldTrustCategory nc = FieldTrustCategory.suspect;
      final nr = m['ncat'] as String?;
      if (nr != null) {
        for (final c in FieldTrustCategory.values) {
          if (c.name == nr) {
            nc = c;
            break;
          }
        }
      }
      return ObservationMutationEvent(
        observationId: m['obs'] as String? ?? '',
        timestampMsUtc: m['ts'] as int? ?? 0,
        mutationSource: src,
        changedFields:
            (m['fields'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        previousCategory: pc,
        newCategory: nc,
        previousWarnings:
            (m['pw'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        newWarnings:
            (m['nw'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        reasonHint: m['hint'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
