import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pium/screens/job_search_screen.dart';
import 'package:pium/screens/kiosk_practice_screen.dart';
import 'package:pium/services/senior_jobs_service.dart';
import 'package:pium/services/location_service.dart';
import 'package:pium/services/nearby_service.dart';
import 'package:pium/services/tts_service.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/utils/date_format.dart';
import 'package:pium/utils/defer_state.dart';
import 'package:pium/utils/user_messages.dart';
import 'package:pium/widgets/nearby_results_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class PiumHomeScreen extends StatefulWidget {
  const PiumHomeScreen({
    super.key,
    this.locationService,
    this.nearbyService,
    this.seniorJobsService,
  });

  final LocationService? locationService;
  final NearbyService? nearbyService;
  final SeniorJobsService? seniorJobsService;

  @override
  State<PiumHomeScreen> createState() => _PiumHomeScreenState();
}

class _PiumHomeScreenState extends State<PiumHomeScreen> {
  bool _listening = false;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  Timer? _aiTimer;
  int _intentIndex = 0;

  static const _intents = [
    _AiIntent(
      speech:
          '병원 진료가 필요하신가요? 가장 가까운 내과와 접수 방법을 화면에 띄워드릴게요.',
      type: _IntentType.hospital,
    ),
    _AiIntent(
      speech:
          '무인 주문기가 어려우신가요? 무인단말기 실습에서 실제와 같은 연습을 시작해 보세요.',
      type: _IntentType.kiosk,
    ),
    _AiIntent(
      speech: '가족에게 연락하시겠어요? 가족 연락 버튼을 누르면 바로 연결해 드립니다.',
      type: _IntentType.family,
    ),
  ];

  @override
  void initState() {
    super.initState();
    TtsService.init();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _aiTimer?.cancel();
    super.dispose();
  }

  Future<void> _launchTel(String number, String tts) async {
    await TtsService.speak(tts);
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserMessages.callFailed,
            style: const TextStyle(fontSize: 18),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openHospitalSearch() async {
    await TtsService.speak('가까운 병원과 약국을 찾아볼게요.');
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NearbyResultsSheet(
        locationService: widget.locationService,
        nearbyService: widget.nearbyService,
      ),
    );
  }

  Future<void> _openJobSearch() async {
    await TtsService.speak(UserMessages.jobHomeOpen);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            JobSearchScreen(seniorJobsService: widget.seniorJobsService),
      ),
    );
  }

  Future<void> _openKiosk() async {
    await TtsService.speak('실제 매장과 같은 무인 주문기 연습을 시작합니다.');
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const KioskPracticeScreen()),
    );
  }

  Future<void> _onMic() async {
    if (_listening) return;
    setState(() => _listening = true);

    _aiTimer?.cancel();
    _aiTimer = Timer(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      final intent = _intents[_intentIndex % _intents.length];
      _intentIndex++;
      setState(() => _listening = false);
      await TtsService.speak(intent.speech);
      if (!mounted) return;
      deferState(() {
        if (mounted) unawaited(_routeIntent(intent));
      });
    });
  }

  Future<void> _routeIntent(_AiIntent intent) async {
    if (!mounted) return;
    switch (intent.type) {
      case _IntentType.hospital:
        await _openHospitalSearch();
      case _IntentType.kiosk:
        await _openKiosk();
      case _IntentType.family:
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('가족 연락', style: TextStyle(fontSize: 22)),
            content: const Text(
              '등록된 가족 연락처로 전화를 연결할까요?',
              style: TextStyle(fontSize: 18),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('취소', style: TextStyle(fontSize: 18)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  deferState(() {
                    if (mounted) {
                      _launchTel('010-1234-5678', '가족 연락처로 연결합니다.');
                    }
                  });
                },
                child: const Text('연결', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        );
    }
  }

  void _onTileTap(_HomeTileAction action) {
    switch (action) {
      case _HomeTileAction.hospital:
        _openHospitalSearch();
      case _HomeTileAction.family:
        _launchTel('010-1234-5678', '가족 연락처로 연결합니다.');
      case _HomeTileAction.kiosk:
        _openKiosk();
      case _HomeTileAction.sos:
        _confirmSos();
      case _HomeTileAction.jobs:
        _openJobSearch();
    }
  }

  Future<void> _confirmSos() async {
    if (!mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('응급 상황', style: TextStyle(fontSize: 22)),
        content: const Text(
          '119에 연결할까요?',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(fontSize: 18)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: PiumColors.tileRed),
            child: const Text('119 연결', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      await _launchTel('119', '응급 상황입니다. 119에 연결합니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _HomeHeader(now: _now),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _QuickCard(
                              label: '병원/약국',
                              icon: Icons.local_hospital_outlined,
                              color: PiumColors.tileTeal,
                              onTap: () =>
                                  _onTileTap(_HomeTileAction.hospital),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickCard(
                              label: '가족 연락',
                              icon: Icons.phone_in_talk,
                              color: PiumColors.tileBlue,
                              onTap: () => _onTileTap(_HomeTileAction.family),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      flex: 2,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _QuickCard(
                              label: '키오스크',
                              icon: Icons.point_of_sale,
                              color: PiumColors.tileOrange,
                              onTap: () => _onTileTap(_HomeTileAction.kiosk),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickCard(
                              label: '119에 전화',
                              icon: Icons.emergency_outlined,
                              color: PiumColors.tileRed,
                              onTap: () => _onTileTap(_HomeTileAction.sos),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 88,
                      width: double.infinity,
                      child: _QuickCard(
                        label: '일자리 찾기',
                        icon: Icons.work_outline,
                        color: PiumColors.tilePurple,
                        onTap: () => _onTileTap(_HomeTileAction.jobs),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 32,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _listening ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_listening,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: PiumColors.guideBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PiumColors.navy, width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hearing, color: PiumColors.navy, size: 18),
                          SizedBox(width: 6),
                          Text(
                            '듣고 있어요...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: PiumColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: _MicButton(
                listening: _listening,
                onPressed: _listening ? null : _onMic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _HomeTileAction { hospital, family, kiosk, sos, jobs }

enum _IntentType { hospital, kiosk, family }

class _AiIntent {
  const _AiIntent({required this.speech, required this.type});
  final String speech;
  final _IntentType type;
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: PiumColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '피움',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatKoreanDate(now),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatKoreanTime(now),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wb_sunny, color: Color(0xFFFBBF24), size: 22),
              SizedBox(width: 4),
              Text(
                '24°',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      shadowColor: color.withOpacity(0.35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.listening, required this.onPressed});

  final bool listening;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: listening ? PiumColors.pulseYellow : Colors.transparent,
            width: listening ? 3 : 0,
          ),
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: PiumColors.navy,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF64748B),
            minimumSize: const Size(double.infinity, 60),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          icon: Icon(listening ? Icons.graphic_eq : Icons.mic, size: 26),
          label: const Text(
            '음성 질문',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
