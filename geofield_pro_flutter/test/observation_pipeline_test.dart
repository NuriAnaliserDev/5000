import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/domain/observation_state_derivation.dart';
import 'package:geofield_pro_flutter/models/field_trust_category.dart';
import 'package:geofield_pro_flutter/models/field_trust_meta.dart';
import 'package:geofield_pro_flutter/models/observation_mutation_event.dart';
import 'package:geofield_pro_flutter/models/observation_pipeline_types.dart';
import 'package:geofield_pro_flutter/models/observation_warn_codes.dart';
import 'package:geofield_pro_flutter/models/station.dart';
import 'package:geofield_pro_flutter/services/export_service.dart';
import 'package:geofield_pro_flutter/services/observation_pipeline_service.dart';

void main() {
  group('ObservationPipeline', () {
    test('1) bir xil kirish — bir xil derivation (mantiqiy maydonlar)', () {
      final wall = DateTime(2024, 6, 1, 12, 0, 0).millisecondsSinceEpoch;
      final pos = PositionLike(
        latitude: 41.3,
        longitude: 69.2,
        altitude: 400,
        accuracy: 12,
        timestamp: DateTime(2024, 6, 1, 11, 58, 0),
        isMocked: false,
        altitudeAccuracy: 8,
      );
      final facts = ObservationRawFacts(
        position: pos,
        locationSourceOverride: ObservationLocationSources.liveRefresh,
        captureWallClockMs: wall,
        fieldSessionId: 'sess-a',
        captureId: 'cap-a',
        networkConnected: true,
        imageSha256: 'a' * 64,
        imageSizeBytes: 4000,
        provenance: const ObservationProvenance(
            source: ObservationMutationSource.capture),
      );
      final a = ObservationStateDerivation.deriveObservationState(
        facts,
        derivedAtUtc:
            DateTime.fromMillisecondsSinceEpoch(wall, isUtc: true),
      );
      final b = ObservationStateDerivation.deriveObservationState(
        facts,
        derivedAtUtc:
            DateTime.fromMillisecondsSinceEpoch(wall, isUtc: true),
      );
      expect(a.normalizedWarnings, b.normalizedWarnings);
      expect(a.category, b.category);
      expect(a.trustScore, b.trustScore);
      expect(a.duplicateInfo.duplicateType, b.duplicateInfo.duplicateType);
      expect(a.derivationVersion, b.derivationVersion);
    });

    test('2) manual_edit core — recovery_manual_post_edit', () {
      final r = ObservationStateDerivation.deriveManualPostEditCore(
        coordinateTrusted: true,
        locationSource: ObservationLocationSources.liveRefresh,
        gpsMockSuspected: false,
        gpsFixStale: false,
        priorTrustScore: 95,
        priorWarnings: const [],
        provenance: const ObservationProvenance(
            source: ObservationMutationSource.manual_edit),
      );
      expect(
        r.normalizedWarnings,
        contains(ObservationWarnCodes.recoveryManualPostEdit),
      );
      expect(r.category, isNot(FieldTrustCategory.verified));
    });

    test('3) duplicate linkage JSON — forCapture', () {
      final wall = DateTime(2024, 6, 1, 12, 0, 0).millisecondsSinceEpoch;
      final meta = ObservationPipelineService.buildCaptureTrustMeta(
        pos: null,
        captureWallClockMs: wall,
        fieldSessionId: 'sess-dup',
        captureId: 'cap-new',
        networkConnected: false,
        imageSha256: 'b' * 64,
        imageSizeBytes: 300,
        duplicateSessionImageHashMatchCaptureId: 'cap-old',
      );
      expect(meta.observationDuplicate, isNotNull);
      expect(meta.observationDuplicate!.canonicalObservationId, 'cap-old');
      expect(meta.observationDuplicate!.hashMatchedObservationIds,
          contains('cap-new'));
      final json = meta.encode();
      expect(json, contains('dup_grp'));
      expect(json, contains('byte_identical'));
    });

    test('4) eksport — canonicalFieldTrustMeta == decode', () {
      final wall = DateTime.now().millisecondsSinceEpoch;
      final meta = ObservationPipelineService.buildCaptureTrustMeta(
        pos: null,
        captureWallClockMs: wall,
        fieldSessionId: 's',
        captureId: 'c',
        networkConnected: false,
      );
      final st = Station(
        name: 'T',
        lat: 0,
        lng: 0,
        altitude: 0,
        strike: 0,
        dip: 45,
        azimuth: 0,
        date: DateTime.now(),
        fieldTrustMetaJson: meta.encode(),
      );
      expect(
        ObservationPipelineService.canonicalFieldTrustMeta(st)?.category,
        FieldTrustMeta.decode(st.fieldTrustMetaJson)?.category,
      );
    });

    test('5) recovery kontekst — inflight JSON', () {
      const raw =
          '{"capture_id":"c1","started_ms":1000,"session":"sx","photo_path":"/tmp/x.jpg"}';
      final ctx =
          ObservationPipelineService.recoveryContextFromInflightJson(raw);
      expect(ctx.inflightCaptureId, 'c1');
      expect(ctx.sessionId, 'sx');
      expect(ctx.photoPath, '/tmp/x.jpg');
    });

    test('6) legacy warning normalizatsiyasi', () {
      const legacy =
          '{"v":"1","coord_ok":true,"src":"live_refresh","stale":true,"mock":false,'
          '"trust":90,"warn":["stale_fix"],"sess":"","cid":"","online":true,"alt_ok":false}';
      final m = FieldTrustMeta.decode(legacy);
      expect(m, isNotNull);
      expect(m!.warnings, contains(ObservationWarnCodes.gpsStaleFix));
      expect(m.category, FieldTrustCategory.stale);
    });

    test('7) integrity — hash mismatch signal (model)', () {
      const info = ObservationIntegrityInfo(
        storedContentSha256: 'abc',
        hashMismatch: true,
      );
      expect(info.hashMismatch, true);
      final encoded = FieldTrustMeta(
        schemaVersion: '3',
        locationSource: ObservationLocationSources.liveRefresh,
        coordinateTrusted: true,
        gpsFixStale: false,
        gpsMockSuspected: false,
        fieldSessionId: 's',
        captureId: 'c',
        networkConnected: true,
        altitudeAvailable: false,
        trustScore: 80,
        warnings: const [],
        category: FieldTrustCategory.suspect,
        observationIntegrity: info,
      ).encode();
      final round = FieldTrustMeta.decode(encoded);
      expect(round?.observationIntegrity?.hashMismatch, true);
    });

    test('8) kategoriya qayta hisoblanishi — decode saqlangan cat’ni e’tiborsiz', () {
      const badCat =
          '{"v":"3","coord_ok":false,"src":"absent","stale":true,"mock":false,'
          '"trust":50,"warn":["gps_no_fix"],"cat":"VERIFIED","sess":"s","cid":"c","online":false,"alt_ok":false}';
      final m = FieldTrustMeta.decode(badCat);
      expect(m?.category, FieldTrustCategory.partial);
      expect(m?.category, isNot(FieldTrustCategory.verified));
    });

    test('legacy dup_type sessionImageHash → byte_identical', () {
      final d = ObservationDuplicateInfo.fromJson({
        'dup_type': 'sessionImageHash',
      });
      expect(d.duplicateType, ObservationDuplicateType.byte_identical);
    });

    test('mutation journal event roundtrip', () {
      final e = ObservationMutationEvent(
        observationId: 'x',
        timestampMsUtc: 100,
        mutationSource: ObservationMutationSource.manual_edit,
        previousCategory: FieldTrustCategory.verified,
        newCategory: FieldTrustCategory.suspect,
        previousWarnings: const ['a'],
        newWarnings: const ['a', ObservationWarnCodes.recoveryManualPostEdit],
      );
      final round = ObservationMutationEvent.tryDecodeLine(e.encodeLine());
      expect(round?.observationId, 'x');
      expect(round?.newCategory, FieldTrustCategory.suspect);
    });

    test('rederive — ikki marta bir xil', () {
      final wall = DateTime(2024, 1, 1).millisecondsSinceEpoch;
      final meta = ObservationPipelineService.buildCaptureTrustMeta(
        pos: null,
        captureWallClockMs: wall,
        fieldSessionId: 's',
        captureId: 'c',
        networkConnected: false,
      );
      final st = Station(
        name: 'R',
        lat: 0,
        lng: 0,
        altitude: 0,
        strike: 0,
        dip: 45,
        azimuth: 0,
        date: DateTime(2024, 1, 1),
        fieldTrustMetaJson: meta.encode(),
      );
      final r1 = ObservationPipelineService.rederiveObservation(st);
      final r2 = ObservationPipelineService.rederiveObservation(st);
      expect(r1!.category, r2!.category);
      expect(r1.warnings, r2.warnings);
      expect(r1.trustScore, r2.trustScore);
    });

    test('structured export report tuzilmasi', () {
      final r = ExportService.buildStructuredExportReport(
        format: 'csv',
        rowCount: 2,
        issues: const ['export_test:x'],
        mode: ExportIntegrityMode.strict,
      );
      expect(r['format'], 'csv');
      expect(r['validation_failed'], true);
      expect(r.containsKey('derivation_logic_version'), true);
    });

    test('export validatsiya — asosiy export_ kodlari', () {
      final wall = DateTime.now().millisecondsSinceEpoch;
      final meta = ObservationPipelineService.buildCaptureTrustMeta(
        pos: null,
        captureWallClockMs: wall,
        fieldSessionId: 's',
        captureId: 'c',
        networkConnected: false,
      );
      final st = Station(
        name: 'M1',
        lat: 1,
        lng: 1,
        altitude: 0,
        strike: 0,
        dip: 45,
        azimuth: 0,
        date: DateTime.now(),
        fieldTrustMetaJson: meta.encode(),
      );
      final issues = ExportService.validateStationsForExport([st]);
      expect(issues.any((e) => e.startsWith('export_')), true);
    });
  });
}
