# PIUM 로컬 PC 초기 설정 스크립트 (Windows PowerShell)
# 사용: .\scripts\setup-local.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== PIUM 로컬 설정 ===" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter가 PATH에 없습니다." -ForegroundColor Red
    Write-Host "https://docs.flutter.dev/get-started/install/windows 에서 설치 후 다시 실행하세요."
    exit 1
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot
Write-Host "프로젝트: $repoRoot"

Write-Host "`n[1/4] Flutter 버전" -ForegroundColor Yellow
flutter --version

Write-Host "`n[2/4] flutter doctor" -ForegroundColor Yellow
flutter doctor

Write-Host "`n[3/4] pub get" -ForegroundColor Yellow
flutter pub get

Write-Host "`n[4/4] analyze" -ForegroundColor Yellow
flutter analyze lib

Write-Host "`n=== 완료 ===" -ForegroundColor Green
Write-Host "실기기 연결 후: flutter run"
Write-Host "또는 Cursor에서 실행 구성 'PIUM (Supabase 연결)' 사용"
Write-Host "자세한 내용: docs/LOCAL_SETUP.md"
