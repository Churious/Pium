# PIUM 로컬 PC 개발 환경 설정

Cursor Cloud에서 작업한 내용을 **로컬 Windows PC**에서 이어서 개발·실행하는 방법입니다.

> **대상:** Android (Galaxy S21 등), Flutter 3.x stable, PowerShell

---

## 1. 사전 준비 (한 번만)

| 항목 | 버전·설명 |
|------|-----------|
| [Git](https://git-scm.com/download/win) | 최신 |
| [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) | **3.x stable** |
| [Android Studio](https://developer.android.com/studio) | SDK **36**, JDK **17** |
| [Cursor](https://cursor.com) 또는 VS Code | Flutter / Dart 확장 |

Android Studio → **SDK Manager**에서 설치 확인:

- Android SDK Platform **36**
- Android SDK Build-Tools (최신)
- Android SDK Command-line Tools

터미널에서 라이선스 동의:

```powershell
flutter doctor --android-licenses
```

`flutter doctor -v` 에서 Android toolchain이 ✓ 이면 준비 완료입니다.

---

## 2. 저장소 받기

### 새로 클론

```powershell
git clone https://github.com/Churious/Pium.git
cd Pium
git checkout main
```

### 이미 로컬에 있는 경우 (Cloud와 동기화)

```powershell
cd Pium
git fetch origin
git checkout main
git pull origin main
```

pull이 실패하거나 예전 파일이 섞였을 때:

```powershell
git fetch origin
git checkout main
git reset --hard origin/main
git clean -fd
```

> `git clean -fd`는 추적되지 않는 로컬 파일을 삭제합니다. 백업이 필요하면 먼저 복사하세요.

---

## 3. 프로젝트 의존성

```powershell
flutter pub get
```

자동 스크립트를 쓰려면:

```powershell
.\scripts\setup-local.ps1
```

---

## 4. 앱 실행

### 방법 A — Cursor / VS Code (권장)

1. 저장소 루트를 Cursor에서 엽니다.
2. Android 폰 USB 연결 후 **개발자 옵션 → USB 디버깅** 켜기  
   (또는 Android Studio 에뮬레이터 실행)
3. 실행 구성 **`PIUM (Supabase 연결)`** 선택 후 F5

`.vscode/launch.json`에 Supabase URL·anon key가 들어 있습니다.  
별도 `.env` 파일은 **필요 없습니다**.

### 방법 B — 터미널

```powershell
flutter devices
flutter run
```

`lib/config/supabase_config.dart`에 기본 Supabase 값이 있어 `--dart-define` 없이도 동작합니다.

---

## 5. 검증

```powershell
flutter analyze lib
flutter test
```

---

## 6. 실기기 테스트 체크리스트

| 기능 | 필요 조건 |
|------|-----------|
| 병원/약국 | 위치 권한, Supabase `nearby` 함수, Kakao API 키(서버) |
| 일자리 찾기 | Supabase `senior-jobs` 함수, 공공데이터 API 키(서버) |
| 우리 동네 + 현재 위치 | 위치 권한, geocoding |
| 가족 연띙 / 119 | `tel:` (실기기 권장) |
| 키오스크 연습 | 네트워크 불필요 |

API 키는 **Supabase Edge Function Secret**에만 있습니다. Flutter 코드에 넣지 않습니다.  
일자리 API 설정: [SENIOR_JOBS_SETUP.md](./SENIOR_JOBS_SETUP.md)

Supabase 없이도 일자리 찾기는 `lib/data/sample_senior_jobs_response.json` 샘플로 동작합니다.

---

## 7. Edge Function 배포 (선택)

앱 코드만 수정할 때는 불필요합니다. 서버 함수를 바꿀 때만:

```powershell
# Supabase CLI 설치 후
supabase login
supabase link --project-ref glhgqolncenyqtsyzuhz
supabase secrets set SENIOR_JOB_API_KEY="발급받은_키"
supabase secrets set KAKAO_REST_API_KEY="발급받은_키"
supabase functions deploy nearby
supabase functions deploy senior-jobs
```

---

## 8. Cloud Agent ↔ 로컬 PC

| | Cursor Cloud | 로컬 PC |
|---|--------------|---------|
| Flutter / Android 빌드 | ❌ (SDK 없음) | ✅ |
| 실기기 실행 | ❌ | ✅ |
| 코드·Git | ✅ | ✅ `git pull`로 동기화 |
| Edge Function 배포 | CLI 가능 | CLI 가능 |

**작업 흐름 예시**

1. Cloud Agent에서 코드 수정 → `main`에 merge
2. 로컬 PC: `git pull origin main`
3. `flutter pub get` → `flutter run`으로 실기기 확인

---

## 9. 자주 나는 문제

### `geocoding_android` / compileSdk 오류

`android/app/build.gradle.kts`에 `compileSdk = 36` 이 설정되어 있어야 합니다.  
Android Studio에서 SDK 36을 설치했는지 확인하세요.

### pull 충돌 / 빌드 에러 (옛 파일 섞임)

```powershell
git reset --hard origin/main
git clean -fd
flutter pub get
```

### 일자리 API 502 / Upstream API error

Supabase에 `SENIOR_JOB_API_KEY`가 올바르게 설정·배포되었는지 [SENIOR_JOBS_SETUP.md](./SENIOR_JOBS_SETUP.md)를 따르세요.

### `ios/`, `web/` 폴더 없음

이 프로젝트는 **Android만** Git에 포함합니다. 다른 플랫폼 폴더는 로컬에서 `flutter create .`로 생성할 수 있으나 커밋하지 않습니다.

---

## 10. 유용한 명령어 요약

```powershell
git pull origin main
flutter pub get
flutter run
flutter analyze lib
flutter test
flutter build apk --debug
```
