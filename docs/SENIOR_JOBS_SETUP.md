# 노인 구인정보 API 연동 설정

한국노인인력개발원 **100세누리 구인정보** OpenAPI (SenuriService)를 Supabase Edge Function으로 호출합니다.

## API 키 설정 (필수)

공공데이터포털에서 발급받은 인증키를 **Supabase Secret**에만 저장합니다.  
Flutter 코드·Git·로그에 키를 넣지 마세요.

```bash
supabase link --project-ref glhgqolncenyqtsyzuhz
supabase secrets set SENIOR_JOB_API_KEY="발급받은_공공데이터_인증키"
```

## Edge Function 배포

```bash
supabase functions deploy senior-jobs
```

## API 요청 방식 (공식 문서 v1.1)

| 구분 | URL |
|------|-----|
| 목록 | `GET https://apis.data.go.kr/B552474/SenuriService/getJobList` |
| 상세 | `GET https://apis.data.go.kr/B552474/SenuriService/getJobInfo` |

### getJobList 필수 파라미터
- `serviceKey` — 공공데이터 인증키
- `pageNo` — 페이지 번호
- `numOfRows` — 한 페이지 결과 수

### getJobList 선택 파라미터
- `search` — 검색어
- `emplymShp` — 고용형태 (예: CM0103 = 시간제일자리)
- `workPlcNm` — 근무지명 (예: `강남구`, `중구`)

### getJobInfo 필수 파라미터
- `serviceKey`
- `id` — 목록의 `jobId`

## Flutter 호출

앱은 Supabase Function `senior-jobs`만 호출합니다.

```dart
// 목록
await supabase.functions.invoke('senior-jobs', body: {
  'action': 'list',
  'pageNo': 1,
  'numOfRows': 10,
  'workPlcNm': '강남구',
  'search': '오전',
  'emplymShp': 'CM0103',
});

// 상세
await supabase.functions.invoke('senior-jobs', body: {
  'action': 'detail',
  'jobId': 'RECR_...',
});
```

## 로컬 개발 (API 키 없이)

Supabase가 설정되지 않으면 `lib/data/sample_senior_jobs_response.json` 샘플 데이터를 사용합니다.

## TODO (문서 미확인 항목)

- `getJobList`에 **시도/시군구 코드** 파라미터는 공식 명세에 없음 → 현재 `workPlcNm` 텍스트 사용
- GPS 좌표 → 행정구역 자동 변환은 미구현 (수동 지역 선택)
- `search` 단일 파라미터만 지원 → 여러 조건은 키워드 결합으로 처리
