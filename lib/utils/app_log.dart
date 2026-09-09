import 'package:flutter/foundation.dart';

/// 개발자용 로그 — 릴리스 빌드에서는 출력하지 않습니다.
void appLog(String message) {
  if (kDebugMode) {
    debugPrint('[PIUM] $message');
  }
}
