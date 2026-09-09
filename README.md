# PIUM (피움)

60세 이상을 위한 AI 보조 접근성 런처 (Android · Flutter).

## 주요 기능

| 홈 메뉴 | 설명 |
|---------|------|
| 병원/약국 | 주변 병원·약국 검색 (Kakao API, Supabase Edge Function) |
| 가족 연띙 | 전화 연결 |
| 키오스크 연습 | 무인 주문기 연습 (연습/도전/자유 모드) |
| 119에 전화 | 응급 전화 확인 후 연결 |
| 일자리 찾기 | 노인 구인정보 검색 (전국 지역 선택, 접수중 공고만) |

## 로컬 PC에서 시작하기

**Cursor Cloud에서 작업한 코드를 PC로 옮길 때:**

```powershell
git clone https://github.com/Churious/Pium.git
cd Pium
.\scripts\setup-local.ps1
flutter run
```

이미 클론한 경우:

```powershell
git pull origin main
flutter pub get
flutter run
```

상세 설정·문제 해결: **[docs/LOCAL_SETUP.md](docs/LOCAL_SETUP.md)**

## 개발 명령어

```powershell
flutter pub get
flutter analyze lib
flutter test
flutter run
```

Cursor / VS Code: 실행 구성 **`PIUM (Supabase 연결)`** (`.vscode/launch.json`)

## 백엔드 (Supabase)

- 프로젝트: `glhgqolncenyqtsyzuhz` (ap-northeast-2)
- Edge Functions: `nearby`, `senior-jobs`
- API Secret은 Supabase에만 저장 — Flutter에 키를 넣지 않음

| 문서 | 내용 |
|------|------|
| [docs/LOCAL_SETUP.md](docs/LOCAL_SETUP.md) | 로컬 PC 환경 설정 |
| [docs/SENIOR_JOBS_SETUP.md](docs/SENIOR_JOBS_SETUP.md) | 일자리 API·Edge Function |

## 구조

```
lib/
├── main.dart
├── config/supabase_config.dart
├── screens/          # 홈, 일자리, 키오스크
├── widgets/          # 지역 선택, 결과 시트 등
├── services/         # 위치, TTS, API
└── data/             # korean_regions.json, 샘플 데이터
supabase/functions/   # nearby, senior-jobs
```

Android만 Git 추적 (`ios/`, `web/` 등은 gitignore).
