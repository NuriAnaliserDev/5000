import 'package:hive/hive.dart';

part 'project.g.dart';

@HiveType(typeId: 10)
class Project extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  String leadGeologist;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.leadGeologist,
  });
}
