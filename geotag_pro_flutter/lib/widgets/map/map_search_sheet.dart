import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Xarita ustida joy izlash uchun pastdan chiqadigan bottom sheet.
/// OpenStreetMap (Nominatim) API orqali qidiradi, tanlangan natija
/// [LatLng] qaytaradi.
class MapSearchSheet extends StatefulWidget {
  const MapSearchSheet({super.key});

  @override
  State<MapSearchSheet> createState() => _MapSearchSheetState();
}

class _MapSearchSheetState extends State<MapSearchSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<_GeoResult> _results = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(q.trim());
    });
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': q,
          'format': 'json',
          'limit': '10',
          'accept-language': 'uz,ru,en',
          'addressdetails': '1',
        },
      );
      final resp = await http.get(
        uri,
        headers: {
          'User-Agent': 'GeoFieldPro/1.9 (Flutter)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (resp.statusCode != 200) {
        setState(() {
          _error = 'Server xatoligi: ${resp.statusCode}';
          _loading = false;
        });
        return;
      }
      final body = jsonDecode(resp.body) as List;
      final list = body.whereType<Map<String, dynamic>>().map(_GeoResult.fromJson).toList();
      setState(() {
        _results = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Qidiruvda xatolik: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onChanged,
                  onSubmitted: (v) => _search(v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Shahar, hudud yoki manzil...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _ctrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _ctrl.clear();
                              _onChanged('');
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                if (!_loading && _error == null && _results.isEmpty && _ctrl.text.length >= 2)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Hech narsa topilmadi',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = _results[i];
                      return ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(
                          r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          r.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.of(context).pop(r.point);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GeoResult {
  final String name;
  final String displayName;
  final LatLng point;

  _GeoResult({required this.name, required this.displayName, required this.point});

  factory _GeoResult.fromJson(Map<String, dynamic> j) {
    final lat = double.tryParse('${j['lat']}') ?? 0.0;
    final lon = double.tryParse('${j['lon']}') ?? 0.0;
    final display = j['display_name']?.toString() ?? '';
    final addr = j['address'] as Map<String, dynamic>?;
    String name = '';
    if (addr != null) {
      name = addr['city']?.toString() ??
          addr['town']?.toString() ??
          addr['village']?.toString() ??
          addr['hamlet']?.toString() ??
          addr['suburb']?.toString() ??
          addr['state']?.toString() ??
          addr['country']?.toString() ??
          '';
    }
    if (name.isEmpty) {
      name = display.split(',').first.trim();
    }
    return _GeoResult(
      name: name,
      displayName: display,
      point: LatLng(lat, lon),
    );
  }
}
