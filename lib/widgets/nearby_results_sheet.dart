import 'package:flutter/material.dart';
import 'package:pium/models/nearby_place.dart';
import 'package:pium/services/location_service.dart';
import 'package:pium/services/nearby_service.dart';
import 'package:pium/services/tts_service.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/utils/user_messages.dart';
import 'package:pium/widgets/nearby_place_card.dart';

enum _SearchPhase { locating, searching, done, error }

/// 병원/약국 검색 BottomSheet — 위치 조회 → Supabase → 결과 표시
class NearbyResultsSheet extends StatefulWidget {
  const NearbyResultsSheet({
    super.key,
    this.locationService,
    this.nearbyService,
  });

  final LocationService? locationService;
  final NearbyService? nearbyService;

  @override
  State<NearbyResultsSheet> createState() => _NearbyResultsSheetState();
}

class _NearbyResultsSheetState extends State<NearbyResultsSheet> {
  late final LocationService _locationService;
  late final NearbyService _nearbyService;

  _SearchPhase _phase = _SearchPhase.locating;
  String _statusMessage = '현재 위치를 확인하고 있어요.';
  String? _errorMessage;
  LocationFailureAction? _errorAction;
  List<NearbyPlace> _hospitals = [];
  List<NearbyPlace> _pharmacies = [];

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? LocationService();
    _nearbyService = widget.nearbyService ?? NearbyService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch());
  }

  Future<void> _runSearch() async {
    if (!mounted) return;

    setState(() {
      _phase = _SearchPhase.locating;
      _statusMessage = '현재 위치를 확인하고 있어요.';
      _errorMessage = null;
      _errorAction = null;
    });

    final location = await _locationService.getCurrentPosition();
    if (!mounted) return;

    if (!location.isSuccess) {
      setState(() {
        _phase = _SearchPhase.error;
        _errorMessage = location.message;
        _errorAction = location.action;
      });
      await TtsService.speak(location.message!.replaceAll('\n', ' '));
      return;
    }

    setState(() {
      _phase = _SearchPhase.searching;
      _statusMessage = '가까운 병원과 약국을 찾고 있어요.';
    });

    try {
      final lat = location.latitude!;
      final lng = location.longitude!;

      final results = await _nearbyService.searchAll(
        latitude: lat,
        longitude: lng,
      );

      if (!mounted) return;

      _hospitals = results.hospitals;
      _pharmacies = results.pharmacies;

      if (_hospitals.isEmpty && _pharmacies.isEmpty) {
        setState(() {
          _phase = _SearchPhase.error;
          _errorMessage = UserMessages.hospitalNotFound;
        });
        await TtsService.speak(UserMessages.hospitalNotFound);
        return;
      }

      setState(() => _phase = _SearchPhase.done);

      await _speakSummary();
    } on NearbySearchException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _SearchPhase.error;
        _errorMessage = e.userMessage;
      });
      await TtsService.speak(e.userMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _SearchPhase.error;
        _errorMessage = UserMessages.hospitalSearchFailed;
      });
      await TtsService.speak(UserMessages.hospitalSearchFailed);
    }
  }

  Future<void> _speakSummary() async {
    final parts = <String>[];
    if (_hospitals.isNotEmpty) {
      parts.add('병원 ${_hospitals.length}곳');
    }
    if (_pharmacies.isNotEmpty) {
      parts.add('약국 ${_pharmacies.length}곳');
    }
    await TtsService.speak('가까운 ${parts.join(', ')}을 찾았어요.');

    if (_hospitals.isNotEmpty) {
      final nearest = _hospitals.first;
      await TtsService.speak(
        '가장 가까운 병원은 ${nearest.name}이에요. 약 ${nearest.distanceMeters}미터 떨어져 있어요.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
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
                '가까운 병원 · 약국',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_phase == _SearchPhase.locating ||
                  _phase == _SearchPhase.searching)
                _LoadingView(message: _statusMessage),
              if (_phase == _SearchPhase.error)
                _ErrorView(
                  message: _errorMessage!,
                  action: _errorAction,
                  onOpenSettings: _errorAction == null
                      ? null
                      : () => _locationService.openSuggestedSettings(_errorAction!),
                ),
              if (_phase == _SearchPhase.done)
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      if (_hospitals.isNotEmpty) ...[
                        const _SectionTitle(
                          label: '가까운 병원',
                          icon: Icons.local_hospital,
                        ),
                        ..._hospitals.map((p) => NearbyPlaceCard(place: p)),
                      ],
                      if (_pharmacies.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const _SectionTitle(
                          label: '가까운 약국',
                          icon: Icons.local_pharmacy,
                        ),
                        ..._pharmacies.map((p) => NearbyPlaceCard(place: p)),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _phase == _SearchPhase.error
                      ? _runSearch
                      : () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: PiumColors.navy,
                  ),
                  child: Text(
                    _phase == _SearchPhase.error ? '다시 찾기' : '닫기',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 28, color: PiumColors.navy),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 5),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    this.action,
    this.onOpenSettings,
  });

  final String message;
  final LocationFailureAction? action;
  final Future<bool> Function()? onOpenSettings;

  String get _settingsLabel {
    switch (action) {
      case LocationFailureAction.openLocationSettings:
        return '휴대폰 위치 설정 열기';
      case LocationFailureAction.openAppSettings:
        return '피움 설정에서 허용하기';
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: PiumColors.navy),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, height: 1.5),
            ),
            if (onOpenSettings != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: onOpenSettings,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PiumColors.navy,
                    side: const BorderSide(color: PiumColors.navy, width: 2),
                  ),
                  icon: const Icon(Icons.settings, size: 24),
                  label: Text(
                    _settingsLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
