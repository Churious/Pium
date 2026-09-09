/// 시니어 사용자에게 보여주는 문구만 모아 둡니다.
/// 기술 용어(Supabase, JWT, Exception 등)는 여기에 넣지 않습니다.
class UserMessages {
  UserMessages._();

  // 병원/약국 검색
  static const hospitalSearchFailed =
      '병원 정보를 불러오지 못했어요. 인터넷 연결을 확인한 뒤 다시 눌러주세요.';
  static const hospitalSearchRetry =
      '병원 정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
  static const hospitalNotFound = '근처에서 병원이나 약국을 찾지 못했어요.';

  // 위치
  static const locationServiceOff =
      '휴대폰 위치(GPS)가 꺼져 있어요.\n설정에서 위치를 켠 뒤 다시 찾기를 눌러 주세요.';
  static const locationPermissionNeeded =
      '가까운 병원을 찾으려면 위치 권한이 필요해요.';
  static const locationPermissionOff =
      '위치 권한이 꺼져 있어요. 설정에서 피움 앱의 위치 권한을 허용해 주세요.';
  static const locationUnavailable =
      '현재 위치를 확인할 수 없어요. 잠시 후 다시 시도해 주세요.';

  // 전화 · 지도
  static const noPhoneNumber = '등록된 전화번호가 없어요.';
  static const callFailed = '전화 연결을 시작할 수 없어요.';
  static const mapFailed = '길 안내를 열 수 없어요. 잠시 후 다시 시도해 주세요.';
}
