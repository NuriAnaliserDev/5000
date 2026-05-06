part of 'web_map_screen.dart';

mixin WebMapScreenActionsMixin on WebMapScreenFields {
  Future<void> _saveDrawnZone() async {
    if (_drawingPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Kamida 3 nuqta chizing!'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final name =
        _zoneNameCtrl.text.trim().isEmpty ? 'Zona' : _zoneNameCtrl.text.trim();
    final desc =
        _zoneDescCtrl.text.trim().isEmpty ? null : _zoneDescCtrl.text.trim();

    try {
      await context.read<BoundaryService>().addPolygonFromPoints(
            points: List.from(_drawingPoints),
            name: name,
            zoneType: _selectedZoneType,
            description: desc,
          );

      setState(() {
        _isDrawingMode = false;
        _drawingPoints.clear();
        _zoneNameCtrl.text = 'Yangi Zona';
        _zoneDescCtrl.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ "$name" saqlandi!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, ErrorMapper.map(e));
      }
    }
  }

  Future<void> _deletePolygon(BoundaryPolygon polygon) async {
    final id = polygon.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zonani o\'chirish'),
        content: Text('"${polygon.name}" ni o\'chirishni tasdiqlaysizmi?'),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false),
              child: const Text('Bekor qilish')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => ctx.pop(true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await context.read<BoundaryService>().deletePolygon(id);
      setState(() => _editingPolygon = null);
    }
  }

  void _showEditDialog(BoundaryPolygon polygon) {
    final nameCtrl = TextEditingController(text: polygon.name);
    final descCtrl = TextEditingController(text: polygon.description ?? '');
    ZoneType selectedType = polygon.zoneType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Zonani Tahrirlash'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Zona nomi', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Tavsif (ixtiyoriy)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Zona turi:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ZoneType.values.map((zt) {
                    final isSelected = selectedType == zt;
                    return FilterChip(
                      label: Text(zt.label,
                          style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white : zt.color,
                              fontWeight: FontWeight.bold)),
                      selected: isSelected,
                      selectedColor: zt.color,
                      onSelected: (_) => setDlgState(() => selectedType = zt),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => ctx.pop(), child: const Text('Bekor qilish')),
            ElevatedButton(
              child: const Text('Saqlash'),
              onPressed: () async {
                ctx.pop();
                final pid = polygon.id;
                if (pid != null) {
                  await context.read<BoundaryService>().updatePolygon(
                        firestoreId: pid,
                        name: nameCtrl.text.trim().isEmpty
                            ? polygon.name
                            : nameCtrl.text.trim(),
                        zoneType: selectedType,
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                      );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onImportFromWeb() async {
    final s = GeoFieldStrings.of(context);
    try {
      final ok = await showGisImportPrecheckDialog(context);
      if (!ok || !mounted) return;
      final pos = context.read<LocationService>().currentPosition;
      final c = _mapController.camera.center;
      final r = await context.read<BoundaryService>().importFileFromWeb(
            hintLatitude: pos?.latitude ?? c.latitude,
            hintLongitude: pos?.longitude ?? c.longitude,
          );
      if (!mounted) return;
      if (r == null) return;
      if (s != null) {
        showGisImportResultSnackbar(context, s, r);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('GIS: ${r.importedCount} / skipped ${r.skippedCount}'),
            backgroundColor:
                r.importedCount > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.show(context, ErrorMapper.map(e));
    }
  }
}
