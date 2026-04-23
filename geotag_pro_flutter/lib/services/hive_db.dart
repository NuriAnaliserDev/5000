import 'package:hive_flutter/hive_flutter.dart';

import '../models/geological_line.dart';
import '../models/measurement.dart';
import '../models/audit_entry.dart';
import '../models/station.dart';
import '../models/track_data.dart';
import '../models/chat_message.dart';
import '../models/chat_group.dart';

class HiveDb {
  static const stationsBox = 'stations';
  static const tracksBox = 'tracks';
  static const settingsBox = 'settings';
  static const syncStateBox = 'sync_state';
  static const chatMessagesBox = 'chat_messages';
  static const chatGroupsBox = 'chat_groups';
  static const linesBox = 'geological_lines';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    _registerAdapter(StationAdapter());
    _registerAdapter(TrackDataAdapter());
    _registerAdapter(ChatMessageAdapter());
    _registerAdapter(ChatGroupAdapter());
    _registerAdapter(GeologicalLineAdapter());
    _registerAdapter(MeasurementAdapter());
    _registerAdapter(AuditEntryAdapter());

    // Open Boxes
    await Hive.openBox<Station>(stationsBox);
    await Hive.openBox<TrackData>(tracksBox);
    await Hive.openBox<ChatMessage>(chatMessagesBox);
    await Hive.openBox<ChatGroup>(chatGroupsBox);
    await Hive.openBox<GeologicalLine>(linesBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox(syncStateBox);
  }

  static void _registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }
}

