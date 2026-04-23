import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'hive_db.dart';

class SettingsController extends ChangeNotifier {
  SettingsController() : _box = Hive.box(HiveDb.settingsBox);

  final Box _box;

  static const _projectKey = 'currentProject';
  static const _projectsListKey = 'projectsList';
  static const _languageKey = 'language';
  static const _ecoModeKey = 'ecoMode';
  static const _expertModeKey = 'expertMode';
  static const _userRoleKey = 'currentUserRole';
  static const _userNameKey = 'currentUserName';
  static const _isFirstRunKey = 'isFirstRun';
  static const _mapTutorialKey = 'hasSeenMapTutorial';
  static const _cameraTutorialKey = 'hasSeenCameraTutorial';

  String? get currentUserRole => _box.get(_userRoleKey) as String?;
  String? get currentUserName => _box.get(_userNameKey) as String?;

  void login(String role, String name) {
    _box.put(_userRoleKey, role);
    _box.put(_userNameKey, name);
    notifyListeners();
  }

  void logout() {
    _box.delete(_userRoleKey);
    _box.delete(_userNameKey);
    notifyListeners();
  }

  String get currentProject =>
      (_box.get(_projectKey) as String?)?.trim().isNotEmpty == true
          ? (_box.get(_projectKey) as String)
          : 'Default';

  String get appVersion => '1.9.0+12';

  List<String> get projects {
    final list = _box.get(_projectsListKey) as List?;
    if (list == null || list.isEmpty) {
      return ['Default'];
    }
    final casted = list.map((e) => e.toString()).toSet().toList();
    if (!casted.contains('Default')) casted.insert(0, 'Default');
    return casted;
  }

  static const _calibrationKey = 'hasDismissedCalibration';
  
  bool get hasDismissedCalibration =>
      _box.get(_calibrationKey, defaultValue: false) as bool;

  set hasDismissedCalibration(bool value) {
    _box.put(_calibrationKey, value);
    notifyListeners();
  }

  bool get isFirstRun => _box.get(_isFirstRunKey, defaultValue: true) as bool;

  set isFirstRun(bool value) {
    _box.put(_isFirstRunKey, value);
    notifyListeners();
  }

  bool get hasSeenMapTutorial => _box.get(_mapTutorialKey, defaultValue: false) as bool;
  set hasSeenMapTutorial(bool value) {
    _box.put(_mapTutorialKey, value);
    notifyListeners();
  }

  bool get hasSeenCameraTutorial => _box.get(_cameraTutorialKey, defaultValue: false) as bool;
  set hasSeenCameraTutorial(bool value) {
    _box.put(_cameraTutorialKey, value);
    notifyListeners();
  }

  static const _pixelsPerMmKey = 'pixelsPerMm';
  
  double get pixelsPerMm =>
      _box.get(_pixelsPerMmKey, defaultValue: 6.0) as double;

  set pixelsPerMm(double value) {
    _box.put(_pixelsPerMmKey, value);
    notifyListeners();
  }

  String get language => _box.get(_languageKey, defaultValue: 'uz') as String;
  
  set language(String value) {
    _box.put(_languageKey, value);
    notifyListeners();
  }

  bool get ecoMode => _box.get(_ecoModeKey, defaultValue: false) as bool;

  set ecoMode(bool value) {
    _box.put(_ecoModeKey, value);
    notifyListeners();
  }

  bool get expertMode => _box.get(_expertModeKey, defaultValue: false) as bool;

  set expertMode(bool value) {
    _box.put(_expertModeKey, value);
    notifyListeners();
  }

  set currentProject(String value) {
    final v = value.trim().isEmpty ? 'Default' : value.trim();
    _box.put(_projectKey, v);
    
    // Add to project list if not exists
    final currentList = projects;
    if (!currentList.contains(v)) {
      currentList.add(v);
      _box.put(_projectsListKey, currentList);
    }
    
    notifyListeners();
  }

  static const _declinationKey = 'magneticDeclination';

  double get magneticDeclination =>
      _box.get(_declinationKey, defaultValue: 0.0) as double;

  set magneticDeclination(double value) {
    _box.put(_declinationKey, value);
    notifyListeners();
  }

  void renameProject(String oldName, String newName) {
    if (oldName == 'Default' || oldName == newName) return;
    
    final currentList = projects;
    if (currentList.contains(oldName)) {
      currentList.remove(oldName);
      if (!currentList.contains(newName)) {
        currentList.add(newName);
      }
      _box.put(_projectsListKey, currentList);
      
      if (currentProject == oldName) {
        _box.put(_projectKey, newName);
      }
      notifyListeners();
    }
  }

  void deleteProject(String projectName) {
    if (projectName == 'Default') return;
    
    final currentList = projects;
    if (currentList.contains(projectName)) {
      currentList.remove(projectName);
      _box.put(_projectsListKey, currentList);
      
      if (currentProject == projectName) {
        _box.put(_projectKey, 'Default');
      }
      notifyListeners();
    }
  }

  static const _altitudeOffsetKey = 'altitudeOffset';

  double get altitudeOffset =>
      _box.get(_altitudeOffsetKey, defaultValue: 0.0) as double;

  set altitudeOffset(double value) {
    _box.put(_altitudeOffsetKey, value);
    notifyListeners();
  }

  static const _useMslAltitudeKey = 'useMslAltitude';

  bool get useMslAltitude =>
      _box.get(_useMslAltitudeKey, defaultValue: true) as bool;

  set useMslAltitude(bool value) {
    _box.put(_useMslAltitudeKey, value);
    notifyListeners();
  }

  static const _baseLatKey = 'baseLatitude';
  static const _baseLngKey = 'baseLongitude';
  static const _autoPurgeDaysKey = 'autoPurgeDays';

  double? get baseLat => _box.get(_baseLatKey) as double?;
  double? get baseLng => _box.get(_baseLngKey) as double?;

  void setBaseLocation(double lat, double lng) {
    _box.put(_baseLatKey, lat);
    _box.put(_baseLngKey, lng);
    notifyListeners();
  }

  void clearBaseLocation() {
    _box.delete(_baseLatKey);
    _box.delete(_baseLngKey);
    notifyListeners();
  }

  int get autoPurgeDays => _box.get(_autoPurgeDaysKey, defaultValue: 30) as int;

  set autoPurgeDays(int value) {
    _box.put(_autoPurgeDaysKey, value);
    notifyListeners();
  }

  static const _mapStyleKey = 'mapStyle';

  String get mapStyle => _box.get(_mapStyleKey, defaultValue: 'opentopomap') as String;

  set mapStyle(String value) {
    if (['opentopomap', 'osm', 'satellite', 'mbtiles'].contains(value)) {
      _box.put(_mapStyleKey, value);
      notifyListeners();
    }
  }

  static const _customMbtilesPathKey = 'customMbtilesPath';

  String? get customMbtilesPath => _box.get(_customMbtilesPathKey) as String?;

  set customMbtilesPath(String? value) {
    if (value == null) {
      _box.delete(_customMbtilesPathKey);
    } else {
      _box.put(_customMbtilesPathKey, value);
    }
    notifyListeners();
  }
}

