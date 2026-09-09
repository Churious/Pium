import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pium/config/supabase_config.dart';
import 'package:pium/models/senior_job.dart';
import 'package:pium/utils/app_log.dart';
import 'package:pium/utils/job_search_query.dart';
import 'package:pium/utils/user_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeniorJobsSearchException implements Exception {
  SeniorJobsSearchException(this.userMessage, {this.cause});

  final String userMessage;
  final Object? cause;

  @override
  String toString() => userMessage;
}

class SeniorJobsService {
  SeniorJobsService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  Future<SeniorJobSearchResult>? _inFlightSearch;
  Future<SeniorJob>? _inFlightDetail;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<SeniorJobSearchResult> search({
    required Set<JobFilterTag> filters,
    String? selectedRegion,
    int pageNo = 1,
    int numOfRows = 10,
  }) async {
    if (_inFlightSearch != null) {
      return _inFlightSearch!;
    }

    final future = _searchInternal(
      filters: filters,
      selectedRegion: selectedRegion,
      pageNo: pageNo,
      numOfRows: numOfRows,
    );
    _inFlightSearch = future;
    try {
      return await future;
    } finally {
      _inFlightSearch = null;
    }
  }

  Future<SeniorJobSearchResult> _searchInternal({
    required Set<JobFilterTag> filters,
    String? selectedRegion,
    required int pageNo,
    required int numOfRows,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      appLog('Senior jobs: Supabase not configured, using sample data');
      return _loadSampleResult();
    }

    final query = JobSearchQuery.fromFilters(
      filters: filters,
      selectedRegion: selectedRegion,
    );

    try {
      final response = await _supabase.functions.invoke(
        'senior-jobs',
        body: query.toRequestBody(pageNo: pageNo, numOfRows: numOfRows),
      );

      if (response.status != 200) {
        appLog(
          'senior-jobs failed: status=${response.status} data=${response.data}',
        );
        throw SeniorJobsSearchException(UserMessages.jobSearchFailed);
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw SeniorJobsSearchException(UserMessages.jobSearchFailed);
      }

      if (data['error'] != null) {
        appLog('senior-jobs error payload: ${data['error']}');
        throw SeniorJobsSearchException(UserMessages.jobSearchFailed);
      }

      return SeniorJobSearchResult.fromJson(data);
    } on SeniorJobsSearchException {
      rethrow;
    } on FunctionException catch (e) {
      appLog('senior-jobs function error: status=${e.status} details=${e.details}');
      throw SeniorJobsSearchException(UserMessages.jobSearchFailed, cause: e);
    } catch (e, st) {
      appLog('senior-jobs search error: $e\n$st');
      throw SeniorJobsSearchException(UserMessages.jobSearchFailed, cause: e);
    }
  }

  Future<SeniorJob> fetchDetail(String jobId) async {
    if (jobId.trim().isEmpty) {
      throw SeniorJobsSearchException(UserMessages.jobSearchFailed);
    }

    if (_inFlightDetail != null) {
      return _inFlightDetail!;
    }

    final future = _fetchDetailInternal(jobId.trim());
    _inFlightDetail = future;
    try {
      return await future;
    } finally {
      _inFlightDetail = null;
    }
  }

  Future<SeniorJob> _fetchDetailInternal(String jobId) async {
    if (!SupabaseConfig.isConfigured) {
      final sample = await _loadSampleResult();
      return sample.jobs.firstWhere(
        (j) => j.jobId == jobId,
        orElse: () => sample.jobs.first,
      );
    }

    try {
      final response = await _supabase.functions.invoke(
        'senior-jobs',
        body: {'action': 'detail', 'jobId': jobId},
      );

      if (response.status == 404) {
        throw SeniorJobsSearchException(UserMessages.jobNotFound);
      }
      if (response.status != 200) {
        appLog(
          'senior-jobs detail failed: status=${response.status} data=${response.data}',
        );
        throw SeniorJobsSearchException(UserMessages.jobSearchFailed);
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw SeniorJobsSearchException(UserMessages.jobSearchFailed);
      }
      if (data['error'] != null) {
        throw SeniorJobsSearchException(UserMessages.jobSearchFailed);
      }

      final jobRaw = data['job'];
      if (jobRaw is! Map<String, dynamic>) {
        throw SeniorJobsSearchException(UserMessages.jobNotFound);
      }
      return SeniorJob.fromJson(jobRaw);
    } on SeniorJobsSearchException {
      rethrow;
    } on FunctionException catch (e) {
      appLog('senior-jobs detail error: status=${e.status}');
      throw SeniorJobsSearchException(UserMessages.jobSearchFailed, cause: e);
    } catch (e, st) {
      appLog('senior-jobs detail error: $e\n$st');
      throw SeniorJobsSearchException(UserMessages.jobSearchFailed, cause: e);
    }
  }

  Future<SeniorJobSearchResult> _loadSampleResult() async {
    final raw = await rootBundle.loadString(
      'lib/data/sample_senior_jobs_response.json',
    );
    return SeniorJobSearchResult.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}
