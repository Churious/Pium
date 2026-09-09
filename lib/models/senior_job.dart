/// 일자리 찾기 화면 조건 버튼
enum JobFilterTag {
  nearHome('우리 동네 일자리'),
  morning('오전에 하는 일'),
  afternoon('오후에 하는 일'),
  partTime('주 2~3회 일자리'),
  lightWork('몸에 무리가 적은 일'),
  helpingPeople('사람을 돕는 일');

  const JobFilterTag(this.label);
  final String label;
}

/// 한국노인인력개발원 노인 구인정보 (Edge Function JSON)
class SeniorJob {
  const SeniorJob({
    required this.jobId,
    required this.title,
    required this.acceptanceStatus,
    required this.acceptanceStartDate,
    required this.acceptanceEndDate,
    required this.workRegion,
    required this.workAddress,
    required this.employmentType,
    required this.jobCategory,
    required this.acceptanceMethod,
    required this.acceptanceAgency,
    required this.workDescription,
    required this.recruitAge,
    required this.recruitCount,
    required this.contactName,
    required this.contactPhone,
    required this.detailUrl,
    required this.otherNotes,
  });

  final String jobId;
  final String title;
  final String acceptanceStatus;
  final String acceptanceStartDate;
  final String acceptanceEndDate;
  final String workRegion;
  final String workAddress;
  final String employmentType;
  final String jobCategory;
  final String acceptanceMethod;
  final String acceptanceAgency;
  final String workDescription;
  final String recruitAge;
  final String recruitCount;
  final String contactName;
  final String contactPhone;
  final String detailUrl;
  final String otherNotes;

  bool get hasPhone => contactPhone.trim().isNotEmpty;

  bool get hasDetailUrl {
    final url = detailUrl.trim();
    return url.startsWith('http://') || url.startsWith('https://');
  }

  String get workPeriodLabel {
    if (acceptanceStartDate.isEmpty && acceptanceEndDate.isEmpty) {
      return employmentType.isNotEmpty ? employmentType : '근무 조건은 문의해 주세요';
    }
    if (acceptanceStartDate.isNotEmpty && acceptanceEndDate.isNotEmpty) {
      return '접수 $acceptanceStartDate ~ $acceptanceEndDate';
    }
    return acceptanceStartDate.isNotEmpty
        ? '접수 시작 $acceptanceStartDate'
        : '접수 마감 $acceptanceEndDate';
  }

  String get summaryLine {
    final parts = <String>[];
    if (workRegion.isNotEmpty) parts.add(workRegion);
    if (employmentType.isNotEmpty) parts.add(employmentType);
    return parts.isEmpty ? '근무 지역 확인 중' : parts.join(' · ');
  }

  factory SeniorJob.fromJson(Map<String, dynamic> json) {
    String str(String key) => (json[key] as String?)?.trim() ?? '';
    return SeniorJob(
      jobId: str('jobId'),
      title: str('title'),
      acceptanceStatus: str('acceptanceStatus'),
      acceptanceStartDate: str('acceptanceStartDate'),
      acceptanceEndDate: str('acceptanceEndDate'),
      workRegion: str('workRegion'),
      workAddress: str('workAddress'),
      employmentType: str('employmentType'),
      jobCategory: str('jobCategory'),
      acceptanceMethod: str('acceptanceMethod'),
      acceptanceAgency: str('acceptanceAgency'),
      workDescription: str('workDescription'),
      recruitAge: str('recruitAge'),
      recruitCount: str('recruitCount'),
      contactName: str('contactName'),
      contactPhone: str('contactPhone'),
      detailUrl: str('detailUrl'),
      otherNotes: str('otherNotes'),
    );
  }

  SeniorJob mergeDetail(SeniorJob detail) {
    return SeniorJob(
      jobId: jobId.isNotEmpty ? jobId : detail.jobId,
      title: detail.title.isNotEmpty ? detail.title : title,
      acceptanceStatus:
          detail.acceptanceStatus.isNotEmpty ? detail.acceptanceStatus : acceptanceStatus,
      acceptanceStartDate: detail.acceptanceStartDate.isNotEmpty
          ? detail.acceptanceStartDate
          : acceptanceStartDate,
      acceptanceEndDate:
          detail.acceptanceEndDate.isNotEmpty ? detail.acceptanceEndDate : acceptanceEndDate,
      workRegion: detail.workRegion.isNotEmpty ? detail.workRegion : workRegion,
      workAddress: detail.workAddress.isNotEmpty ? detail.workAddress : workAddress,
      employmentType:
          detail.employmentType.isNotEmpty ? detail.employmentType : employmentType,
      jobCategory: detail.jobCategory.isNotEmpty ? detail.jobCategory : jobCategory,
      acceptanceMethod:
          detail.acceptanceMethod.isNotEmpty ? detail.acceptanceMethod : acceptanceMethod,
      acceptanceAgency:
          detail.acceptanceAgency.isNotEmpty ? detail.acceptanceAgency : acceptanceAgency,
      workDescription: detail.workDescription.isNotEmpty
          ? detail.workDescription
          : workDescription,
      recruitAge: detail.recruitAge.isNotEmpty ? detail.recruitAge : recruitAge,
      recruitCount: detail.recruitCount.isNotEmpty ? detail.recruitCount : recruitCount,
      contactName: detail.contactName.isNotEmpty ? detail.contactName : contactName,
      contactPhone: detail.contactPhone.isNotEmpty ? detail.contactPhone : contactPhone,
      detailUrl: detail.detailUrl.isNotEmpty ? detail.detailUrl : detailUrl,
      otherNotes: detail.otherNotes.isNotEmpty ? detail.otherNotes : otherNotes,
    );
  }
}

class SeniorJobSearchResult {
  const SeniorJobSearchResult({
    required this.jobs,
    required this.pageNo,
    required this.numOfRows,
    required this.totalCount,
  });

  final List<SeniorJob> jobs;
  final int pageNo;
  final int numOfRows;
  final int totalCount;

  bool get hasMore => pageNo * numOfRows < totalCount;

  factory SeniorJobSearchResult.fromJson(Map<String, dynamic> json) {
    final rawJobs = json['jobs'];
    final jobs = rawJobs is List
        ? rawJobs
            .whereType<Map<String, dynamic>>()
            .map(SeniorJob.fromJson)
            .where((j) => j.jobId.isNotEmpty || j.title.isNotEmpty)
            .toList()
        : <SeniorJob>[];
    return SeniorJobSearchResult(
      jobs: jobs,
      pageNo: _int(json['pageNo'], 1),
      numOfRows: _int(json['numOfRows'], 10),
      totalCount: _int(json['totalCount'], jobs.length),
    );
  }

  static int _int(Object? value, int fallback) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
