import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pium/models/work_region_selection.dart';

/// 전국 시·도 / 시·군·구 한 쌍.
class KoreanRegion {
  const KoreanRegion({
    required this.sido,
    required this.sigungu,
    required this.shortSido,
  });

  final String sido;
  final String sigungu;
  final String shortSido;

  String get displayLabel => '$sido $sigungu';

  WorkRegionSelection toSelection({bool fromCurrentLocation = false}) {
    return WorkRegionSelection(
      sido: sido,
      sigungu: sigungu,
      fromCurrentLocation: fromCurrentLocation,
    );
  }

  factory KoreanRegion.fromJson(Map<String, dynamic> json) {
    return KoreanRegion(
      sido: json['sido'] as String,
      sigungu: json['sigungu'] as String,
      shortSido: json['shortSido'] as String,
    );
  }
}

class KoreanRegionsData {
  KoreanRegionsData._();

  static List<KoreanRegion>? _regions;
  static List<String>? _sidoOrder;
  static Map<String, String>? _shortSido;

  static Future<void> ensureLoaded() async {
    if (_regions != null) return;

    final raw = await rootBundle.loadString('lib/data/korean_regions.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final items = (json['regions'] as List<dynamic>)
        .map((e) => KoreanRegion.fromJson(e as Map<String, dynamic>))
        .toList();

    final shortMap = <String, String>{};
    for (final entry in (json['shortSido'] as Map<String, dynamic>).entries) {
      shortMap[entry.key] = entry.value as String;
    }

    final sidoOrder = <String>[];
    for (final region in items) {
      if (!sidoOrder.contains(region.sido)) {
        sidoOrder.add(region.sido);
      }
    }

    _regions = items;
    _sidoOrder = sidoOrder;
    _shortSido = shortMap;
  }

  static List<KoreanRegion> get regions {
    assert(_regions != null, 'Call KoreanRegionsData.ensureLoaded() first');
    return _regions!;
  }

  static List<String> get sidoOrder {
    assert(_sidoOrder != null, 'Call KoreanRegionsData.ensureLoaded() first');
    return _sidoOrder!;
  }

  static String shortSidoLabel(String sido) {
    assert(_shortSido != null, 'Call KoreanRegionsData.ensureLoaded() first');
    return _shortSido![sido] ?? sido;
  }

  static List<KoreanRegion> sigunguForSido(String sido) {
    return regions.where((r) => r.sido == sido).toList();
  }

  static List<KoreanRegion> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final lower = q.toLowerCase();
    final results = <KoreanRegion>[];
    for (final region in regions) {
      final haystacks = [
        region.sido,
        region.sigungu,
        region.shortSido,
        region.displayLabel,
        region.sigungu.split(' ').last,
      ];
      final matched = haystacks.any(
        (text) => text.toLowerCase().contains(lower),
      );
      if (matched) results.add(region);
    }
    return results;
  }

  static WorkRegionSelection? matchFromAddressParts(
    List<String?> parts, {
    bool fromCurrentLocation = false,
  }) {
    final tokens = parts
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;

    KoreanRegion? best;
    var bestScore = 0;

    for (final region in regions) {
      var score = 0;
      final sigunguTail = region.sigungu.contains(' ')
          ? region.sigungu.split(' ').last
          : region.sigungu;

      for (final token in tokens) {
        if (token == region.sido || token.contains(region.sido)) {
          score += 3;
        } else if (token.contains(region.shortSido) ||
            region.sido.contains(token)) {
          score += 2;
        }
        if (token == region.sigungu ||
            token == sigunguTail ||
            token.contains(sigunguTail) ||
            region.sigungu.contains(token)) {
          score += 4;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = region;
      }
    }

    if (best == null || bestScore < 4) return null;
    return best.toSelection(fromCurrentLocation: fromCurrentLocation);
  }
}

/// 테스트·동기 초기화용 (JSON 문자열 직접 주입).
void loadKoreanRegionsFromJsonString(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final items = (json['regions'] as List<dynamic>)
      .map((e) => KoreanRegion.fromJson(e as Map<String, dynamic>))
      .toList();

  final shortMap = <String, String>{};
  for (final entry in (json['shortSido'] as Map<String, dynamic>).entries) {
    shortMap[entry.key] = entry.value as String;
  }

  final sidoOrder = <String>[];
  for (final region in items) {
    if (!sidoOrder.contains(region.sido)) {
      sidoOrder.add(region.sido);
    }
  }

  KoreanRegionsData._regions = items;
  KoreanRegionsData._sidoOrder = sidoOrder;
  KoreanRegionsData._shortSido = shortMap;
}
