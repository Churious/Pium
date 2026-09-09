import 'package:pium/config/supabase_config.dart';
import 'package:pium/models/nearby_place.dart';
import 'package:pium/utils/app_log.dart';
import 'package:pium/utils/user_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 사용자에게 보여줄 메시지만 담습니다. 기술 정보는 [cause]에만 둡니다.
class NearbySearchException implements Exception {
  NearbySearchException(this.userMessage, {this.cause});

  final String userMessage;
  final Object? cause;

  @override
  String toString() => userMessage;
}

class NearbyService {
  NearbyService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// 병원·약국을 한 번에 조회 (Edge Function 1회, Kakao 2회 병렬)
  Future<({List<NearbyPlace> hospitals, List<NearbyPlace> pharmacies})>
      searchAll({
    required double latitude,
    required double longitude,
  }) async {
    final places = await _invokeNearby(
      latitude: latitude,
      longitude: longitude,
      type: 'all',
    );
    return (
      hospitals: places.where((p) => p.isHospital).toList(),
      pharmacies: places.where((p) => p.isPharmacy).toList(),
    );
  }

  Future<List<NearbyPlace>> search({
    required String type,
    required double latitude,
    required double longitude,
  }) async {
    return _invokeNearby(
      latitude: latitude,
      longitude: longitude,
      type: type,
    );
  }

  Future<List<NearbyPlace>> _invokeNearby({
    required double latitude,
    required double longitude,
    required String type,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      appLog('Nearby search skipped: Supabase not configured');
      throw NearbySearchException(UserMessages.hospitalSearchRetry);
    }

    try {
      final response = await _supabase.functions.invoke(
        'nearby',
        body: {
          'type': type,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.status != 200) {
        appLog(
          'nearby function failed: status=${response.status} data=${response.data}',
        );
        throw NearbySearchException(
          UserMessages.hospitalSearchFailed,
          cause: 'HTTP ${response.status}',
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        appLog('nearby function invalid response: $data');
        throw NearbySearchException(UserMessages.hospitalSearchRetry);
      }

      if (data['error'] != null) {
        appLog('nearby function error payload: ${data['error']}');
        throw NearbySearchException(UserMessages.hospitalSearchFailed);
      }

      final rawPlaces = data['places'];
      if (rawPlaces is! List) {
        return [];
      }

      return rawPlaces
          .whereType<Map<String, dynamic>>()
          .map(NearbyPlace.fromJson)
          .where((p) => p.name.isNotEmpty)
          .toList();
    } on NearbySearchException {
      rethrow;
    } on FunctionException catch (e) {
      appLog('nearby function error: status=${e.status} details=${e.details}');
      throw NearbySearchException(
        UserMessages.hospitalSearchFailed,
        cause: e,
      );
    } catch (e, st) {
      appLog('nearby search error: $e\n$st');
      throw NearbySearchException(
        UserMessages.hospitalSearchFailed,
        cause: e,
      );
    }
  }
}
