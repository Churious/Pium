/// 시니어 사용자에게 보여주는 문구만 모아 둡니다.
/// 기술 용어(Supabase, JWT, Exception 등)는 여기에 넣지 않습니다.
class UserMessages {
  UserMessages._();

  // 홈
  static const homeBrand = '피움';
  static const homeWeather = '24°';
  static const homeAiTitle = '무엇을 도와드릴까요?';
  static const homeAiSubtitle = '어려운 일을 말로 물어보세요.';
  static const homeAiButton = '말로 질문하기';
  static const homeAiExampleLabel = '예시';
  static const homeAiExample = '키오스크 주문을 연습하고 싶어요';
  static const homeListening = '듣고 있어요...';
  static const homeFrequentTitle = '자주 쓰는 기능';
  static const homeAllFeatures = '전체 기능 보기';
  static const homeEmergencyTitle = '긴급할 때';
  static const homeHospitalTitle = '병원·약국';
  static const homeHospitalSubtitle = '가까운 병원과 약국을 찾아요';
  static const homeFamilyTitle = '가족 연락';
  static const homeFamilySubtitle = '등록한 가족에게 바로 전화해요';
  static const homePracticeTitle = '디지털 연습';
  static const homePracticeSubtitle = '키오스크와 스마트폰 사용을 연습해요';
  static const homeJobsTitle = '일자리 찾기';
  static const homeJobsSubtitle = '나에게 맞는 일자리를 찾아요';
  static const homeSosTitle = '119 전화하기';

  // 병원/약국 검색
  static const hospitalSearchFailed =
      '병원 정보를 불러오지 못했어요. 인터넷 연결을 확인한 뒤 다시 눌러주세요.';
  static const hospitalSearchRetry =
      '병원 정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
  static const hospitalNotFound = '근처에서 병원이나 약국을 찾지 못했어요.';

  // 위치
  static const locationServiceOff =
      '휴대폰의 현재 위치 기능이 꺼져 있어요.\n설정에서 위치를 켠 뒤 다시 찾기를 눌러 주세요.';
  static const locationPermissionNeeded =
      '가까운 병원을 찾으려면 피움이 위치를 확인하도록 허용해 주세요.';
  static const locationPermissionOff =
      '피움이 위치를 확인할 수 없어요. 설정에서 피움 앱의 위치 사용을 허용해 주세요.';
  static const locationUnavailable =
      '현재 위치를 확인할 수 없어요. 잠시 후 다시 시도해 주세요.';

  // 전화 · 지도
  static const noPhoneNumber = '등록된 전화번호가 없어요.';
  static const callFailed = '전화 연결을 시작할 수 없어요.';
  static const mapFailed = '길 안내를 열 수 없어요. 잠시 후 다시 시도해 주세요.';

  // 일자리 찾기
  static const jobIntro =
      '어떤 일자리를 찾으시나요? 원하는 조건을 골라 주세요.';
  static const jobQuestion = '어떤 일자리를 찾으시나요?';
  static const jobSelectHint = '원하는 조건을 골라 주세요.';
  static const jobSelectAtLeastOne = '조건을 하나 이상 골라 주세요.';
  static const jobSelectRegion = '우리 동네를 선택해 주세요.';
  static const jobRegionTitle = '근무 지역 (우리 동네)';
  static const jobRegionHint = '시·도와 시·군·구를 선택해 주세요';
  static const jobRegionPickTitle = '근무 지역 고르기';
  static const jobRegionPickHint =
      '지역을 검색하거나, 시·도 → 시·군·구 순서로 골라 주세요.';
  static const jobRegionSearchHint = '지역명 검색 (예: 강남, 수원, 전주)';
  static const jobRegionUseCurrentLocation = '현재 위치로 설정';
  static const jobRegionLocating = '현재 위치를 확인하고 있어요...';
  static const jobRegionSelectedLabel = '선택한 지역';
  static const jobRegionConfirm = '선택 완료';
  static const jobRegionSidoTitle = '시·도';
  static const jobRegionSigunguTitle = '시·군·구';
  static const jobRegionBackToSido = '시·도 다시 고르기';
  static const jobRegionSearchResultTitle = '검색 결과';
  static const jobRegionSearchEmpty =
      '검색어와 맞는 지역을 찾지 못했어요. 다른 이름으로 검색해 보세요.';
  static const jobRegionLoadFailed =
      '지역 목록을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
  static const jobRegionLocationMatchFailed =
      '현재 위치의 지역을 확인하지 못했어요. 목록에서 직접 골라 주세요.';
  static const jobSearching = '조건에 맞는 일자리를 찾아볼게요.';
  static const jobSearchingShort =
      '잠시만 기다려 주세요. 일자리를 찾고 있어요.';
  static const jobFound = '조건에 맞는 일자리를 찾아봤어요.';
  static const jobNotFound =
      '현재 모집 중인 일자리를 찾지 못했어요. 지역이나 조건을 바꿔서 다시 찾아볼까요?';
  static const jobTryChangeFilters = '조건을 바꿔서 다시 찾아 볼게요.';
  static const jobSearchFailed =
      '일자리 정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
  static const jobCallHint = '이 일자리가 궁금하면 전화로 물어볼 수 있어요.';
  static const jobCallConnecting = '전화로 문의를 연결합니다.';
  static const jobOpenUrlFailed = '공고 내용을 열 수 없어요. 잠시 후 다시 시도해 주세요.';
  static const jobVoiceAsk = 'AI에게 말로 물어보기';
  static const jobVoiceListening = '말씀해 주세요. 듣고 있어요.';
  static const jobVoiceListeningShort = '듣고 있어요...';
  static const jobVoiceDemoResult =
      '오전에 하는, 강남구 일자리를 찾아 볼게요.';
  static const jobHomeOpen = '내게 맞는 일자리를 천천히 살펴볼게요.';

  static String jobResultCount(int count) => '찾은 일자리 $count곳';
}
