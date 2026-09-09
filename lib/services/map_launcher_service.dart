import 'package:flutter/material.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/utils/app_log.dart';
import 'package:pium/utils/user_messages.dart';
import 'package:url_launcher/url_launcher.dart';

/// 길 안내 목적지 — 장소 이름(상호) 우선
class MapDestination {
  const MapDestination({
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
  });

  final String name;
  final String address;
  final double? latitude;
  final double? longitude;

  /// 지도 앱에 넘길 검색어 — 장소 이름 우선 (예: "제일의원")
  /// 주소 전체가 아닌 상호/시설명으로 검색해 시니어가 결과를 알아보기 쉽게 합니다.
  String get query {
    final placeName = name.trim();
    if (placeName.isNotEmpty) return placeName;
    return address.trim();
  }

  bool get isValid => query.isNotEmpty;
}

class _MapAppOption {
  const _MapAppOption({
    required this.label,
    required this.icon,
    required this.buildUri,
  });

  final String label;
  final IconData icon;
  final Uri Function(MapDestination dest) buildUri;
}

/// 외부 지도 앱 연동 — 도로명 주소 기반, 설치된 앱 중 선택
class MapLauncherService {
  const MapLauncherService();

  static const _apps = [
    _MapAppOption(
      label: 'Google 지도',
      icon: Icons.map,
      buildUri: _googleDirections,
    ),
    _MapAppOption(
      label: '네이버 지도',
      icon: Icons.navigation,
      buildUri: _naverSearch,
    ),
    _MapAppOption(
      label: '카카오맵',
      icon: Icons.place,
      buildUri: _kakaoSearch,
    ),
    _MapAppOption(
      label: 'T map',
      icon: Icons.directions_car,
      buildUri: _tmapSearch,
    ),
  ];

  /// 도로명 주소로 길 안내 — 설치된 지도 앱이 여러 개면 선택 시트 표시
  Future<void> showDirectionsPicker(
    BuildContext context, {
    required MapDestination destination,
  }) async {
    if (!destination.isValid) {
      _showSnack(context, UserMessages.mapFailed);
      return;
    }

    final available = <_MapAppOption>[];
    for (final app in _apps) {
      final uri = app.buildUri(destination);
      if (await canLaunchUrl(uri)) {
        available.add(app);
      }
    }

    if (!context.mounted) return;

    if (available.isEmpty) {
      appLog('map: no app can handle directions for "${destination.query}"');
      _showSnack(context, UserMessages.mapFailed);
      return;
    }

    if (available.length == 1) {
      await _launch(context, available.first, destination);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MapPickerSheet(
        destination: destination,
        options: available,
        onSelect: (app) async {
          Navigator.of(ctx, rootNavigator: true).pop();
          if (context.mounted) {
            await _launch(context, app, destination);
          }
        },
      ),
    );
  }

  Future<void> _launch(
    BuildContext context,
    _MapAppOption app,
    MapDestination destination,
  ) async {
    final uri = app.buildUri(destination);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      appLog('map: launch failed ${app.label} uri=$uri');
      _showSnack(context, UserMessages.mapFailed);
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 18)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── URI builders (도로명 주소 query 우선) ─────────────────────────────

  static Uri _googleDirections(MapDestination d) {
    final q = Uri.encodeComponent(d.query);
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$q&travelmode=walking',
    );
  }

  static Uri _naverSearch(MapDestination d) {
    final q = Uri.encodeComponent(d.query);
    return Uri.parse('nmap://search?query=$q&appname=pium');
  }

  static Uri _kakaoSearch(MapDestination d) {
    final q = Uri.encodeComponent(d.query);
    return Uri.parse('kakaomap://search?q=$q');
  }

  static Uri _tmapSearch(MapDestination d) {
    final q = Uri.encodeComponent(d.query);
    return Uri.parse('tmap://search?name=$q');
  }
}

class _MapPickerSheet extends StatelessWidget {
  const _MapPickerSheet({
    required this.destination,
    required this.options,
    required this.onSelect,
  });

  final MapDestination destination;
  final List<_MapAppOption> options;
  final ValueChanged<_MapAppOption> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '어떤 지도로 길을 안내할까요?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              destination.name.trim().isNotEmpty
                  ? destination.name.trim()
                  : destination.address.trim(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (destination.address.trim().isNotEmpty &&
                destination.name.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                destination.address.trim(),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ...options.map(
              (app) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FilledButton.icon(
                  onPressed: () => onSelect(app),
                  style: FilledButton.styleFrom(
                    backgroundColor: PiumColors.navy,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(app.icon, size: 26),
                  label: Text(
                    app.label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
