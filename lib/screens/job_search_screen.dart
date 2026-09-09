import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pium/data/korean_regions.dart';
import 'package:pium/models/senior_job.dart';
import 'package:pium/services/senior_jobs_service.dart';
import 'package:pium/services/tts_service.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/utils/phone_launcher.dart';
import 'package:pium/utils/user_messages.dart';
import 'package:pium/widgets/job_listing_card.dart';
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
  String? _selectedRegion;
  Timer? _voiceTimer;

  @override
  void initState() {
    super.initState();
    _service = widget.seniorJobsService ?? SeniorJobsService();
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
        (_selectedRegion == null || _selectedRegion!.isEmpty)) {
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
        selectedRegion: _selectedRegion,
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
        _selectedRegion = '강남구';
      });
      await TtsService.speak(UserMessages.jobVoiceDemoResult);
      if (mounted) await _search();
    });
  }

  void _toggleFilter(JobFilterTag tag) {
    setState(() {
      if (_selected.contains(tag)) {
        _selected.remove(tag);
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
            const SizedBox(height: 8),
            const Text(
              UserMessages.jobSelectHint,
              style: TextStyle(fontSize: 18, height: 1.5),
            ),
            const SizedBox(height: 16),
            _RegionPicker(
              selected: _selectedRegion,
              enabled: _selected.contains(JobFilterTag.nearHome),
              onChanged: (value) => setState(() => _selectedRegion = value),
            ),
            const SizedBox(height: 12),
            ...JobFilterTag.values.map(
              (tag) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FilterButton(
                  label: tag.label,
                  selected: _selected.contains(tag),
                  onTap: () => _toggleFilter(tag),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: OutlinedButton.icon(
                onPressed: _voiceListening ? null : _onVoiceAsk,
                style: OutlinedButton.styleFrom(
                  foregroundColor: PiumColors.navy,
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
                icon: Icon(
                  _voiceListening ? Icons.hearing : Icons.mic_none,
                  size: 26,
                ),
                label: Text(
                  _voiceListening
                      ? UserMessages.jobVoiceListeningShort
                      : UserMessages.jobVoiceAsk,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: FilledButton.icon(
                onPressed: _phase == _JobSearchPhase.searching ? null : () => _search(),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
}

class _RegionPicker extends StatelessWidget {
  const _RegionPicker({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final String? selected;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RegionPickerSheet(selected: selected),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final label = selected ?? UserMessages.jobRegionHint;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : PiumColors.guideBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? PiumColors.navy : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                color: enabled ? PiumColors.navy : Colors.grey,
                size: 26,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  UserMessages.jobRegionTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: enabled ? PiumColors.navy : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: enabled ? () => _openPicker(context) : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: PiumColors.navy,
                side: BorderSide(
                  color: enabled ? PiumColors.navy : Colors.grey.shade400,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? (selected != null ? PiumColors.navy : Colors.black54)
                            : Colors.grey,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more,
                    size: 28,
                    color: enabled ? PiumColors.navy : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionPickerSheet extends StatelessWidget {
  const _RegionPickerSheet({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.45;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              UserMessages.jobRegionPickTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: PiumColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              UserMessages.jobRegionPickHint,
              style: TextStyle(fontSize: 17, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: koreanWorkRegions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final region = koreanWorkRegions[index];
                  final isSelected = region == selected;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(region),
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? PiumColors.tilePurple
                              : PiumColors.guideBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? PiumColors.tilePurple
                                : PiumColors.navy,
                            width: 2,
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 56),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color:
                                    isSelected ? Colors.white : PiumColors.navy,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                region,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : PiumColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PiumColors.navy,
                  side: const BorderSide(color: PiumColors.navy, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '닫기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
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
