import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pium/data/korean_regions.dart';
import 'package:pium/models/senior_job.dart';
import 'package:pium/models/work_region_selection.dart';
import 'package:pium/services/senior_jobs_service.dart';
import 'package:pium/services/tts_service.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/utils/phone_launcher.dart';
import 'package:pium/utils/user_messages.dart';
import 'package:pium/widgets/job_listing_card.dart';
import 'package:pium/widgets/work_region_picker.dart';
import 'package:url_launcher/url_launcher.dart';

enum _JobSearchPhase { idle, searching, done, error }

class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({super.key, this.seniorJobsService});

  final SeniorJobsService? seniorJobsService;

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  late final SeniorJobsService _service;
  final Set<JobFilterTag> _selected = {};
  List<SeniorJob> _results = [];
  _JobSearchPhase _phase = _JobSearchPhase.idle;
  String? _errorMessage;
  bool _voiceListening = false;
  bool _loadingMore = false;
  int _pageNo = 1;
  int _totalCount = 0;
  bool _hasMore = false;
  WorkRegionSelection? _selectedRegion;
  Timer? _voiceTimer;

  @override
  void initState() {
    super.initState();
    _service = widget.seniorJobsService ?? SeniorJobsService();
    unawaited(KoreanRegionsData.ensureLoaded());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(TtsService.speak(UserMessages.jobIntro));
    });
  }

  @override
  void dispose() {
    _voiceTimer?.cancel();
    super.dispose();
  }

  Future<void> _search({bool loadMore = false}) async {
    if (_selected.isEmpty) {
      await TtsService.speak(UserMessages.jobSelectAtLeastOne);
      if (!mounted) return;
      _showSnack(UserMessages.jobSelectAtLeastOne);
      return;
    }

    if (_selected.contains(JobFilterTag.nearHome) &&
        _selectedRegion == null) {
      await TtsService.speak(UserMessages.jobSelectRegion);
      if (!mounted) return;
      _showSnack(UserMessages.jobSelectRegion);
      return;
    }

    final nextPage = loadMore ? _pageNo + 1 : 1;

    setState(() {
      if (loadMore) {
        _loadingMore = true;
      } else {
        _phase = _JobSearchPhase.searching;
        _errorMessage = null;
        _results = [];
        _pageNo = 1;
      }
    });

    if (!loadMore) {
      await TtsService.speak(UserMessages.jobSearching);
    }

    try {
      final result = await _service.search(
        filters: _selected,
        selectedRegion: _selectedRegion?.apiValue,
        pageNo: nextPage,
        numOfRows: 10,
      );
      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _results = [..._results, ...result.jobs];
          _loadingMore = false;
        } else {
          _results = result.jobs;
          _phase = _JobSearchPhase.done;
        }
        _pageNo = result.pageNo;
        _totalCount = result.totalCount;
        _hasMore = result.hasMore;
      });
      if (!loadMore) {
        if (result.jobs.isEmpty) {
          await TtsService.speak(UserMessages.jobNotFound);
        } else {
          await TtsService.speak(UserMessages.jobFound);
        }
      }
    } on SeniorJobsSearchException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _JobSearchPhase.error;
        _errorMessage = e.userMessage;
        _loadingMore = false;
        if (!loadMore) _results = [];
      });
      await TtsService.speak(e.userMessage);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 18)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// TODO: speech_to_text 등 실제 음성 인식 API 연동
  Future<void> _onVoiceAsk() async {
    if (_voiceListening) return;
    setState(() => _voiceListening = true);
    await TtsService.speak(UserMessages.jobVoiceListening);

    _voiceTimer?.cancel();
    _voiceTimer = Timer(const Duration(milliseconds: 1800), () async {
      if (!mounted) return;
      setState(() {
        _voiceListening = false;
        _selected
          ..clear()
          ..addAll({JobFilterTag.morning, JobFilterTag.nearHome});
        _selectedRegion = const WorkRegionSelection(
          sido: '서울특별시',
          sigungu: '강남구',
        );
      });
      await TtsService.speak(UserMessages.jobVoiceDemoResult);
      if (mounted) await _search();
    });
  }

  void _toggleFilter(JobFilterTag tag) {
    setState(() {
      if (_selected.contains(tag)) {
        _selected.remove(tag);
        if (tag == JobFilterTag.nearHome) _selectedRegion = null;
      } else {
        _selected.add(tag);
      }
      _phase = _JobSearchPhase.idle;
      _results = [];
    });
  }

  Future<void> _showJobDetail(SeniorJob job) async {
    SeniorJob display = job;
    try {
      final detail = await _service.fetchDetail(job.jobId);
      display = job.mergeDetail(detail);
    } on SeniorJobsSearchException {
      // 목록 정보만으로 상세 표시
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _JobDetailDialog(job: display),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: PiumColors.navy,
        foregroundColor: Colors.white,
        title: const Text(
          '일자리 찾기',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              UserMessages.jobQuestion,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: PiumColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              UserMessages.jobSelectHint,
              style: TextStyle(fontSize: 18, height: 1.4),
            ),
            const SizedBox(height: 12),
            _buildFilterGrid(),
            if (_selected.contains(JobFilterTag.nearHome)) ...[
              const SizedBox(height: 10),
              WorkRegionPicker(
                selection: _selectedRegion,
                enabled: true,
                compact: true,
                onChanged: (value) => setState(() => _selectedRegion = value),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: OutlinedButton(
                      onPressed: _voiceListening ? null : _onVoiceAsk,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PiumColors.navy,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        side: BorderSide(
                          color: _voiceListening
                              ? PiumColors.pulseYellow
                              : PiumColors.navy,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _voiceListening ? Icons.hearing : Icons.mic_none,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _voiceListening
                                ? UserMessages.jobVoiceListeningShort
                                : '음성으로',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 60,
                    child: FilledButton.icon(
                      onPressed: _phase == _JobSearchPhase.searching
                          ? null
                          : () => _search(),
                      style: FilledButton.styleFrom(
                        backgroundColor: PiumColors.tilePurple,
                        disabledBackgroundColor: const Color(0xFF94A3B8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.search, size: 26),
                      label: const Text(
                        '일자리 찾아보기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    switch (_phase) {
      case _JobSearchPhase.idle:
        return const SizedBox.shrink();
      case _JobSearchPhase.searching:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              CircularProgressIndicator(color: PiumColors.tilePurple),
              SizedBox(height: 16),
              Text(
                UserMessages.jobSearchingShort,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      case _JobSearchPhase.error:
        return _EmptyOrErrorBox(
          icon: Icons.error_outline,
          message: _errorMessage ?? UserMessages.jobSearchFailed,
          actionLabel: '다시 찾아보기',
          onAction: () => _search(),
        );
      case _JobSearchPhase.done:
        if (_results.isEmpty) {
          return _EmptyOrErrorBox(
            icon: Icons.search_off,
            message: UserMessages.jobNotFound,
            actionLabel: '조건 바꾸기',
            onAction: () {
              setState(() {
                _phase = _JobSearchPhase.idle;
                _results = [];
              });
              TtsService.speak(UserMessages.jobTryChangeFilters);
            },
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              UserMessages.jobResultCount(_totalCount),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: PiumColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              UserMessages.jobCallHint,
              style: TextStyle(fontSize: 18, height: 1.4),
            ),
            const SizedBox(height: 14),
            ..._results.map(
              (job) => JobListingCard(
                job: job,
                onTapDetail: () => _showJobDetail(job),
              ),
            ),
            if (_hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loadingMore ? null : () => _search(loadMore: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PiumColors.navy,
                      side: const BorderSide(color: PiumColors.navy, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _loadingMore ? '불러오는 중...' : '더 많은 일자리 보기',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
    }
  }

  Widget _buildFilterGrid() {
    final tags = JobFilterTag.values;
    final rows = <Widget>[];

    for (var i = 0; i < tags.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < tags.length ? 8 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FilterButton(
                  label: tags[i].label,
                  selected: _selected.contains(tags[i]),
                  onTap: () => _toggleFilter(tags[i]),
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: i + 1 < tags.length
                    ? _FilterButton(
                        label: tags[i + 1].label,
                        selected: _selected.contains(tags[i + 1]),
                        onTap: () => _toggleFilter(tags[i + 1]),
                        compact: true,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: selected ? PiumColors.tilePurple : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? PiumColors.tilePurple : PiumColors.navy,
                width: 2,
              ),
            ),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 60),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 16,
                vertical: compact ? 10 : 14,
              ),
              child: compact
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? Icons.check_circle : Icons.circle_outlined,
                          color: selected ? Colors.white : PiumColors.navy,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: selected ? Colors.white : PiumColors.navy,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          selected ? Icons.check_circle : Icons.circle_outlined,
                          color: selected ? Colors.white : PiumColors.navy,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : PiumColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyOrErrorBox extends StatelessWidget {
  const _EmptyOrErrorBox({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PiumColors.guideBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PiumColors.navy, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: PiumColors.navy),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: PiumColors.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobDetailDialog extends StatelessWidget {
  const _JobDetailDialog({required this.job});

  final SeniorJob job;

  Future<void> _call(BuildContext context) async {
    if (!job.hasPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            UserMessages.noPhoneNumber,
            style: TextStyle(fontSize: 18),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pop();
    await launchPhoneCall(
      context,
      number: job.contactPhone,
      speakBeforeCall: UserMessages.jobCallConnecting,
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    if (!job.hasDetailUrl) return;
    final uri = Uri.parse(job.detailUrl.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            UserMessages.jobOpenUrlFailed,
            style: TextStyle(fontSize: 18),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        job.title.isNotEmpty ? job.title : '일자리 상세',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (job.acceptanceStatus.isNotEmpty)
              _DetailLine(label: '접수 상태', value: job.acceptanceStatus),
            _DetailLine(label: '근무 지역', value: job.workRegion),
            if (job.workAddress.isNotEmpty)
              _DetailLine(label: '근무지 주소', value: job.workAddress),
            _DetailLine(label: '근무 시간·기간', value: job.workPeriodLabel),
            if (job.employmentType.isNotEmpty)
              _DetailLine(label: '고용 형태', value: job.employmentType),
            if (job.jobCategory.isNotEmpty)
              _DetailLine(label: '직종', value: job.jobCategory),
            if (job.recruitAge.isNotEmpty)
              _DetailLine(label: '모집 연령', value: job.recruitAge),
            if (job.recruitCount.isNotEmpty)
              _DetailLine(label: '모집 인원', value: job.recruitCount),
            if (job.workDescription.isNotEmpty)
              _DetailLine(label: '업무 내용', value: job.workDescription),
            if (job.acceptanceMethod.isNotEmpty)
              _DetailLine(label: '접수 방법', value: job.acceptanceMethod),
            if (job.acceptanceAgency.isNotEmpty)
              _DetailLine(label: '접수 기관', value: job.acceptanceAgency),
            if (job.contactName.isNotEmpty)
              _DetailLine(label: '담당자', value: job.contactName),
            if (job.otherNotes.isNotEmpty)
              _DetailLine(label: '기타', value: job.otherNotes),
            const SizedBox(height: 8),
            const Text(
              UserMessages.jobCallHint,
              style: TextStyle(fontSize: 17, height: 1.4, color: Colors.black54),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기', style: TextStyle(fontSize: 18)),
        ),
        if (job.hasDetailUrl)
          FilledButton.icon(
            onPressed: () => _openUrl(context),
            style: FilledButton.styleFrom(
              backgroundColor: PiumColors.navy,
              minimumSize: const Size(0, 48),
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text(
              '공고 내용 열어보기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        if (job.hasPhone)
          FilledButton.icon(
            onPressed: () => _call(context),
            style: FilledButton.styleFrom(
              backgroundColor: PiumColors.tileBlue,
              minimumSize: const Size(0, 48),
            ),
            icon: const Icon(Icons.phone),
            label: const Text(
              '전화로 문의하기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: PiumColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, height: 1.4)),
        ],
      ),
    );
  }
}
