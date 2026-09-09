import 'package:flutter/material.dart';

/// 홈 화면 간격·모서리·터치 영역. 값만 여기서 맞춰 일관되게 쓴다.
class PiumLayout {
  PiumLayout._();

  static const pagePadding = 20.0;
  static const sectionGap = 24.0;
  static const itemGap = 12.0;
  static const headerPadding = EdgeInsets.fromLTRB(20, 12, 20, 8);
  static const cardPadding = EdgeInsets.fromLTRB(20, 20, 20, 20);
  static const radius = 16.0;
  static const radiusSm = 12.0;
  static const minTap = 64.0;
  static const featureRowMinHeight = 80.0;
  static const primaryButtonHeight = 72.0;
  static const iconBox = 56.0;

  static double pageHorizontal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width * 0.05).clamp(16.0, 24.0);
  }
}
