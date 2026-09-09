import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pium/data/korean_regions.dart';
import 'package:pium/models/work_region_selection.dart';

void main() {
  setUpAll(() {
    final raw = File('lib/data/korean_regions.json').readAsStringSync();
    loadKoreanRegionsFromJsonString(raw);
  });

  test('loads nationwide regions', () {
    expect(KoreanRegionsData.regions.length, greaterThan(200));
    expect(KoreanRegionsData.sidoOrder.length, 17);
  });

  test('search finds regions by sigungu and sido', () {
    final gangnam = KoreanRegionsData.search('강남');
    expect(
      gangnam.any((r) => r.sigungu == '강남구' && r.sido == '서울특별시'),
      isTrue,
    );

    final gyeonggi = KoreanRegionsData.search('경기');
    expect(gyeonggi.every((r) => r.sido == '경기도'), isTrue);
  });

  test('WorkRegionSelection apiValue uses sigungu tail for compound names', () {
    const selection = WorkRegionSelection(
      sido: '경기도',
      sigungu: '수원시 영통구',
    );
    expect(selection.apiValue, '영통구');
    expect(selection.displayLabel, '경기도 수원시 영통구');
  });
}
