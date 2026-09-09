import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pium/screens/job_search_screen.dart';
import 'package:pium/screens/kiosk_practice_screen.dart';
import 'package:pium/services/senior_jobs_service.dart';
import 'package:pium/services/location_service.dart';
import 'package:pium/services/nearby_service.dart';
import 'package:pium/services/tts_service.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/theme/pium_layout.dart';
import 'package:pium/utils/defer_state.dart';
import 'package:pium/utils/user_messages.dart';
import 'package:pium/widgets/home_ai_help_card.dart';
import 'package:pium/widgets/home_all_features_button.dart';
import 'package:pium/widgets/home_compact_header.dart';
import 'package:pium/widgets/home_emergency_card.dart';
import 'package:pium/widgets/home_feature_row.dart';
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
        const SnackBar(
          content: Text(
            UserMessages.callFailed,
            style: TextStyle(fontSize: 18),
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

  /// 전체 기능 화면이 생기면 여기에서 Navigator.push만 연결한다.
  void _onAllFeatures() {}

  List<HomeFeatureItem> get _frequentFeatures => [
        HomeFeatureItem(
          title: UserMessages.homeHospitalTitle,
          subtitle: UserMessages.homeHospitalSubtitle,
          icon: Icons.local_hospital_outlined,
          accentColor: PiumColors.tileTeal,
          onTap: () => _onTileTap(_HomeTileAction.hospital),
        ),
        HomeFeatureItem(
          title: UserMessages.homeFamilyTitle,
          subtitle: UserMessages.homeFamilySubtitle,
          icon: Icons.phone_in_talk,
          accentColor: PiumColors.tileBlue,
          onTap: () => _onTileTap(_HomeTileAction.family),
        ),
        HomeFeatureItem(
          title: UserMessages.homePracticeTitle,
          subtitle: UserMessages.homePracticeSubtitle,
          icon: Icons.touch_app,
          accentColor: PiumColors.tileOrange,
          onTap: () => _onTileTap(_HomeTileAction.kiosk),
        ),
        HomeFeatureItem(
          title: UserMessages.homeJobsTitle,
          subtitle: UserMessages.homeJobsSubtitle,
          icon: Icons.work_outline,
          accentColor: PiumColors.tilePurple,
          onTap: () => _onTileTap(_HomeTileAction.jobs),
        ),
      ];

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
    final horizontal = PiumLayout.pageHorizontal(context);

    return Scaffold(
      backgroundColor: PiumColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeCompactHeader(now: _now),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeAiHelpCard(
                      listening: _listening,
                      onAsk: _listening ? null : _onMic,
                    ),
                    const SizedBox(height: PiumLayout.sectionGap),
                    const HomeSectionTitle(UserMessages.homeFrequentTitle),
                    const SizedBox(height: PiumLayout.itemGap),
                    ..._frequentFeatures.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: PiumLayout.itemGap,
                        ),
                        child: HomeFeatureRow(item: item),
                      ),
                    ),
                    HomeAllFeaturesButton(onPressed: _onAllFeatures),
                    const SizedBox(height: PiumLayout.sectionGap),
                    const HomeSectionTitle(
                      UserMessages.homeEmergencyTitle,
                      color: PiumColors.tileRed,
                    ),
                    const SizedBox(height: PiumLayout.itemGap),
                    HomeEmergencyCard(
                      onTap: () => _onTileTap(_HomeTileAction.sos),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
