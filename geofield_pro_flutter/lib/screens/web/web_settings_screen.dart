import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_controller.dart';
import '../../services/settings_controller.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_sync_service.dart';
import '../../core/error/error_handler.dart';

class WebSettingsScreen extends StatefulWidget {
  const WebSettingsScreen({super.key});

  @override
  State<WebSettingsScreen> createState() => _WebSettingsScreenState();
}

class _WebSettingsScreenState extends State<WebSettingsScreen> {
  bool _isSyncing = false;
  String? _lastSyncText;

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    try {
      final syncService = context.read<CloudSyncService>();
      await syncService.triggerSync();
      setState(() => _lastSyncText = 'Oxirgi sinxronizatsiya: hozir');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sinxronizatsiya muvaffaqiyatli!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    final settings = context.watch<SettingsController>();
    final auth = context.watch<AuthService>();
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tizim Sozlamalari',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Foydalanuvchi Ma'lumotlari ──────────────────────────────
              _sectionTitle(context, 'Foydalanuvchi', Icons.person_outline),
              _card(
                t,
                child: Column(
                  children: [
                    _infoRow(
                      icon: Icons.badge_outlined,
                      label: 'Foydalanuvchi',
                      value: auth.currentUser?.email ??
                          settings.currentUserName ??
                          'Noma\'lum',
                    ),
                    const Divider(height: 1),
                    _infoRow(
                      icon: Icons.psychology_outlined,
                      label: 'Rejim',
                      value: settings.expertMode ? 'Professional' : 'Oddiy',
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text('Tizimdan Chiqish',
                          style: TextStyle(color: Colors.redAccent)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.redAccent),
                      onTap: () async {
                        await auth.logout();
                        if (context.mounted) {
                          settings.clearLocalDisplayName();
                          settings.forgetAuth();
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Ko'rinish ───────────────────────────────────────────────
              _sectionTitle(
                  context, 'Ko\'rinish (Tema)', Icons.palette_outlined),
              _card(
                t,
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Yorug\''),
                        icon: Icon(Icons.light_mode, size: 16)),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Qorong\'u'),
                        icon: Icon(Icons.dark_mode, size: 16)),
                    ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Tizim'),
                        icon: Icon(Icons.settings_suggest, size: 16)),
                  ],
                  selected: {themeCtrl.mode},
                  onSelectionChanged: (values) =>
                      themeCtrl.setMode(values.first),
                ),
              ),

              const SizedBox(height: 24),

              // ── Xarita Uslubi ───────────────────────────────────────────
              _sectionTitle(context, 'Xarita Uslubi', Icons.map_outlined),
              _card(
                t,
                child: Column(
                  children: [
                    _mapStyleTile(settings, 'opentopomap',
                        'OpenTopoMap (Topografik)', Icons.terrain),
                    const Divider(height: 1),
                    _mapStyleTile(
                        settings, 'osm', 'OpenStreetMap (Standart)', Icons.map),
                    const Divider(height: 1),
                    _mapStyleTile(settings, 'satellite', 'Yo\'ldosh Tasviri',
                        Icons.satellite_alt),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Sinxronizatsiya ─────────────────────────────────────────
              _sectionTitle(context, 'Ma\'lumotlar Sinxronizatsiyasi',
                  Icons.sync_outlined),
              _card(
                t,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_lastSyncText != null) ...[
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Text(_lastSyncText!,
                                style: const TextStyle(
                                    color: Colors.green, fontSize: 13)),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                    ListTile(
                      leading: _isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cloud_sync_outlined,
                              color: Color(0xFF1565C0)),
                      title: const Text('Hozir Sinxronizatsiya Qilish'),
                      subtitle: const Text(
                          'Barcha ma\'lumotlarni Firebase ga yuklaydi',
                          style: TextStyle(fontSize: 12)),
                      trailing: ElevatedButton(
                        onPressed: _isSyncing ? null : _triggerSync,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child:
                            Text(_isSyncing ? 'YUKLANMOQDA...' : 'SINXRONLASH'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Ma'lumotlarni Tozalash ──────────────────────────────────
              _sectionTitle(
                  context, 'Ma\'lumotlarni Boshqarish', Icons.storage_outlined),
              _card(
                t,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.auto_delete_outlined,
                          color: Colors.orange),
                      title: const Text('Avtomatik Tozalash (Kunlar)'),
                      subtitle: Text(
                          '${settings.autoPurgeDays} kundan eski ma\'lumotlar o\'chiriladi'),
                      trailing: SizedBox(
                        width: 80,
                        child: DropdownButton<int>(
                          value: settings.autoPurgeDays,
                          underline: const SizedBox.shrink(),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 30, child: Text('30 kun')),
                            DropdownMenuItem(value: 60, child: Text('60 kun')),
                            DropdownMenuItem(value: 90, child: Text('90 kun')),
                            DropdownMenuItem(
                                value: 180, child: Text('180 kun')),
                          ],
                          onChanged: (val) {
                            if (val != null) settings.autoPurgeDays = val;
                          },
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _infoRow(
                      icon: Icons.folder_outlined,
                      label: 'Joriy Loyiha',
                      value: settings.currentProject,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Tizim Ma'lumotlari ──────────────────────────────────────
              _sectionTitle(context, 'Tizim Ma\'lumotlari', Icons.info_outline),
              _card(
                t,
                child: Column(
                  children: [
                    _infoRow(
                        icon: Icons.app_settings_alt,
                        label: 'Ilova Versiyasi',
                        value: 'v${settings.appVersion} (Web)'),
                    const Divider(height: 1),
                    _infoRow(
                        icon: Icons.verified_user_outlined,
                        label: 'Xavfsizlik',
                        value: 'Firebase Auth + HTTPS'),
                    const Divider(height: 1),
                    _infoRow(
                        icon: Icons.business,
                        label: 'Tashkilot',
                        value: 'Aurum Global Group'),
                    const Divider(height: 1),
                    _infoRow(
                        icon: Icons.copyright_outlined,
                        label: 'Huquqlar',
                        value: '© 2026 GeoField Pro N'),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1565C0), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0)),
          ),
        ],
      ),
    );
  }

  Widget _card(ThemeData t, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow(
      {required IconData icon, required String label, required String value}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: Colors.grey),
      title:
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _mapStyleTile(SettingsController settings, String styleKey,
      String label, IconData icon) {
    final isSelected = settings.mapStyle == styleKey;
    return ListTile(
      dense: true,
      leading: Icon(icon,
          size: 20, color: isSelected ? const Color(0xFF1565C0) : Colors.grey),
      title: Text(label,
          style: TextStyle(
              fontSize: 13,
              color: isSelected ? const Color(0xFF1565C0) : null,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF1565C0), size: 18)
          : null,
      onTap: () => settings.mapStyle = styleKey,
    );
  }
}
