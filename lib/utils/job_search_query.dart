import 'package:pium/models/senior_job.dart';

/// UI 조건 → SenuriService getJobList 파라미터
///
/// 공식 문서 기준 선택 파라미터: search, emplymShp, workPlcNm
/// TODO: sido/sigungu 코드 파라미터는 getJobList 명세에 없음 — 공식 지역코드 API 확인 후 확장
class JobSearchQuery {
  const JobSearchQuery({
    this.search,
    this.emplymShp,
    this.workPlcNm,
  });

  final String? search;

  /// CM0103 = 시간제일자리
  final String? emplymShp;
  final String? workPlcNm;

  static JobSearchQuery fromFilters({
    required Set<JobFilterTag> filters,
    String? selectedRegion,
  }) {
    final keywords = <String>[];

    if (filters.contains(JobFilterTag.morning)) keywords.add('오전');
    if (filters.contains(JobFilterTag.afternoon)) keywords.add('오후');
    if (filters.contains(JobFilterTag.lightWork)) keywords.add('가벼운');
    if (filters.contains(JobFilterTag.helpingPeople)) keywords.add('안내');

    String? workPlcNm;
    if (filters.contains(JobFilterTag.nearHome) &&
        selectedRegion != null &&
        selectedRegion.trim().isNotEmpty) {
      workPlcNm = selectedRegion.trim();
    }

    return JobSearchQuery(
      search: keywords.isEmpty ? null : keywords.join(' '),
      emplymShp: filters.contains(JobFilterTag.partTime) ? 'CM0103' : null,
      workPlcNm: workPlcNm,
    );
  }

  Map<String, dynamic> toRequestBody({
    required int pageNo,
    required int numOfRows,
  }) {
    return {
      'action': 'list',
      'pageNo': pageNo,
      'numOfRows': numOfRows,
      if (search != null && search!.isNotEmpty) 'search': search,
      if (emplymShp != null && emplymShp!.isNotEmpty) 'emplymShp': emplymShp,
      if (workPlcNm != null && workPlcNm!.isNotEmpty) 'workPlcNm': workPlcNm,
    };
  }
}
