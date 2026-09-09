import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pium/models/senior_job.dart';
import 'package:pium/utils/job_search_query.dart';

void main() {
  test('SeniorJob.fromJson parses edge function JSON', () {
    final job = SeniorJob.fromJson({
      'jobId': 'RECR_001',
      'title': '전시장 안내',
      'acceptanceStatus': '접수중',
      'acceptanceStartDate': '2026.01.01',
      'acceptanceEndDate': '2026.03.31',
      'workRegion': '중구',
      'workAddress': '서울 중구',
      'employmentType': '시간제일자리',
      'jobCategory': '안내',
      'acceptanceMethod': '방문',
      'acceptanceAgency': '서울시립미술관',
      'workDescription': '안내 업무',
      'recruitAge': '60 이상',
      'recruitCount': '2',
      'contactName': '김담당',
      'contactPhone': '02-123-4567',
      'detailUrl': 'https://example.org',
      'otherNotes': '',
    });

    expect(job.jobId, 'RECR_001');
    expect(job.hasPhone, isTrue);
    expect(job.hasDetailUrl, isTrue);
    expect(job.summaryLine, contains('중구'));
  });

  test('SeniorJobSearchResult.fromJson handles empty list', () {
    final result = SeniorJobSearchResult.fromJson({
      'jobs': [],
      'pageNo': 1,
      'numOfRows': 10,
      'totalCount': 0,
    });
    expect(result.jobs, isEmpty);
    expect(result.hasMore, isFalse);
  });

  test('JobSearchQuery maps part-time filter to emplymShp CM0103', () {
    final query = JobSearchQuery.fromFilters(
      filters: {JobFilterTag.partTime},
      selectedRegion: null,
    );
    expect(query.emplymShp, 'CM0103');
    expect(query.search, isNull);
  });

  test('JobSearchQuery maps nearHome to workPlcNm', () {
    final query = JobSearchQuery.fromFilters(
      filters: {JobFilterTag.nearHome},
      selectedRegion: '강남구',
    );
    expect(query.workPlcNm, '강남구');
  });

  test('sample list XML fixture contains expected jobId', () {
    final xml = File('test/fixtures/senior_jobs_list.xml').readAsStringSync();
    expect(xml, contains('<jobId>RECR_000000000013950</jobId>'));
    expect(xml, contains('<resultCode>00</resultCode>'));
  });

  test('sample detail XML fixture contains contact phone', () {
    final xml = File('test/fixtures/senior_jobs_detail.xml').readAsStringSync();
    expect(xml, contains('<clerkContt>02-123-4567</clerkContt>'));
  });

  test('sample JSON asset is valid SeniorJobSearchResult', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final raw = await File('lib/data/sample_senior_jobs_response.json')
        .readAsString();
    final result = SeniorJobSearchResult.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    expect(result.jobs, isNotEmpty);
    expect(result.jobs.first.title, isNotEmpty);
  });
}
