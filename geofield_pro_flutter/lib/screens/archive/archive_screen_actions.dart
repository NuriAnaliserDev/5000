part of '../archive_screen.dart';

mixin ArchiveScreenActionsMixin on ArchiveScreenFields {
  Future<void> _shareExportedFile(File file) async {
    if (!mounted) return;
    await archiveShareExportFile(file);
    if (!mounted) return;
    setState(() {
      _isSelectionMode = false;
      _isTrackSelectionMode = false;
      _selectedStationKeys.clear();
      _selectedTrackKeys.clear();
    });
  }

  void _showFilterDialog() {
    final settings = context.read<SettingsController>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.loc('filter'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                decoration: InputDecoration(
                  labelText: context.loc('by_project'),
                  border: const OutlineInputBorder(),
                ),
                initialValue: _selectedProject,
                items: [
                  DropdownMenuItem(
                      value: null, child: Text(context.loc('all_projects'))),
                  ...settings.projects
                      .map((p) => DropdownMenuItem(value: p, child: Text(p))),
                ],
                onChanged: (val) {
                  setState(() => _selectedProject = val);
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
