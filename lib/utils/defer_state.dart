import 'package:flutter/scheduler.dart';

/// 다이얼로그 닫힌 뒤 다음 프레임에 실행 — widget tree 충돌 방지
void deferState(void Function() action) {
  SchedulerBinding.instance.addPostFrameCallback((_) => action());
}
