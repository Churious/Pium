/// 일자리 검색용 근무 지역 선택값.
class WorkRegionSelection {
  const WorkRegionSelection({
    required this.sido,
    required this.sigungu,
    this.fromCurrentLocation = false,
  });

  final String sido;
  final String sigungu;
  final bool fromCurrentLocation;

  /// getJobList `workPlcNm`에 넣을 값 (시·군·구 단위).
  String get apiValue {
    if (sigungu.contains(' ')) {
      return sigungu.split(' ').last;
    }
    if (sigungu == '세종특별자치시') return '세종';
    return sigungu;
  }

  String get displayLabel => '$sido $sigungu';

  String get buttonLabel => sigungu;

  @override
  bool operator ==(Object other) =>
      other is WorkRegionSelection &&
      other.sido == sido &&
      other.sigungu == sigungu;

  @override
  int get hashCode => Object.hash(sido, sigungu);
}
