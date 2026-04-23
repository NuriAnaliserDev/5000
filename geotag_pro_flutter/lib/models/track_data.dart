import 'package:hive/hive.dart';

class TrackPoint {
  final double lat;
  final double lng;
  final double alt;
  final DateTime time;

  TrackPoint({
    required this.lat,
    required this.lng,
    required this.alt,
    required this.time,
  });
  
  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'alt': alt,
    'time': time.millisecondsSinceEpoch,
  };
  
  factory TrackPoint.fromJson(Map<dynamic, dynamic> map) {
    return TrackPoint(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      alt: (map['alt'] as num).toDouble(),
      time: DateTime.fromMillisecondsSinceEpoch(map['time'] as int),
    );
  }
}

class TrackData extends HiveObject {
  String name;
  DateTime startTime;
  DateTime? endTime;
  List<TrackPoint> points;
  double distanceMeters;
  
  // YANGI MAYDONLAR
  String? authorName;
  String? authorRole;
  String? shiftLabel;
  bool isSynced;
  int stationsCount; // YANGI SESSION QATORI

  TrackData({
    required this.name,
    required this.startTime,
    this.endTime,
    required this.points,
    this.distanceMeters = 0.0,
    this.authorName,
    this.authorRole,
    this.shiftLabel,
    this.isSynced = false,
    this.stationsCount = 0,
  });
}

class TrackDataAdapter extends TypeAdapter<TrackData> {
  @override
  final int typeId = 2; // Using 2, since Station is 1

  @override
  TrackData read(BinaryReader reader) {
    // Eskirgan versiyalardan ma'lumot qolgan bo'lishi mumkinligi uchun
    // read/write tartibi juda muhim.
    final name = reader.readString();
    final startTime = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final hasEndTime = reader.readBool();
    final endTime = hasEndTime ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null;
    final points = (reader.readList()).map((e) => TrackPoint.fromJson(e as Map)).toList();
    final distanceMeters = reader.readDouble();
    
    // Yangi maydonlarni o'qish (try-catch bilan eskirgan versiyalar uchun)
    String? authorName;
    String? authorRole;
    String? shiftLabel;
    bool isSynced = false;
    int stationsCount = 0;

    try {
      authorName = reader.readString();
      authorRole = reader.readString();
      shiftLabel = reader.readString();
      isSynced = reader.readBool();
      stationsCount = reader.readInt();
    } catch (_) {
      // Eskirgan ma'lumotlarda bu maydonlar yo'q
    }

    return TrackData(
      name: name,
      startTime: startTime,
      endTime: endTime,
      points: points,
      distanceMeters: distanceMeters,
      authorName: authorName,
      authorRole: authorRole,
      shiftLabel: shiftLabel,
      isSynced: isSynced,
    )..stationsCount = stationsCount;
  }

  @override
  void write(BinaryWriter writer, TrackData obj) {
    writer.writeString(obj.name);
    writer.writeInt(obj.startTime.millisecondsSinceEpoch);
    writer.writeBool(obj.endTime != null);
    if (obj.endTime != null) {
      writer.writeInt(obj.endTime!.millisecondsSinceEpoch);
    }
    writer.writeList(obj.points.map((p) => p.toJson()).toList());
    writer.writeDouble(obj.distanceMeters);
    
    // Yangi maydonlar
    writer.writeString(obj.authorName ?? '');
    writer.writeString(obj.authorRole ?? '');
    writer.writeString(obj.shiftLabel ?? '');
    writer.writeBool(obj.isSynced);
    writer.writeInt(obj.stationsCount);
  }
}
