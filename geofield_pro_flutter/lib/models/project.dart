import 'package:hive/hive.dart';

part 'project.g.dart';

@HiveType(typeId: 10)
class Project extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late String leadGeologist;

  Project({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdAt,
    this.leadGeologist = '',
  });

  factory Project.create(String name, {String leadGeologist = ''}) {
    return Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      leadGeologist: leadGeologist,
    );
  }
}
