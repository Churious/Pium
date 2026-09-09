import 'package:flutter/material.dart';
import 'package:pium/theme/pium_colors.dart';

/// 정답 타깃 옐로우 테두리 (애니메이션 없음 — 트리 안정)
class StepHighlight extends StatelessWidget {
  const StepHighlight({
    super.key,
    required this.active,
    required this.child,
    this.borderRadius = 14,
  });

  final bool active;
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: active ? PiumColors.pulseYellow : Colors.transparent,
          width: active ? 3 : 0,
        ),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x66FACC15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
