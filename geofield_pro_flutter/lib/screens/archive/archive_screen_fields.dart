part of '../archive_screen.dart';

mixin ArchiveScreenFields on State<ArchiveScreen> {
  String _searchQuery = '';
  String? _selectedProject;
  bool _isSelectionMode = false;
  bool _isTrackSelectionMode = false;
  final Set<int> _selectedStationKeys = {};
  final Set<int> _selectedTrackKeys = {};
  late TabController _tabController;
}
