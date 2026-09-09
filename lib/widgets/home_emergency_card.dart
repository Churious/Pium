import 'package:flutter/material.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/theme/pium_layout.dart';
import 'package:pium/utils/user_messages.dart';

/// 일반 기능 목록과 분리된 119 긴급 전화 카드.
class HomeEmergencyCard extends StatelessWidget {
  const HomeEmergencyCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: UserMessages.homeSosTitle,
      child: Material(
        color: PiumColors.emergencyBg,
        borderRadius: BorderRadius.circular(PiumLayout.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PiumLayout.radius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PiumLayout.radius),
              border: Border.all(color: PiumColors.tileRed, width: 2),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: PiumLayout.featureRowMinHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: PiumLayout.iconBox,
                      height: PiumLayout.iconBox,
                      decoration: BoxDecoration(
                        color: PiumColors.tileRed,
                        borderRadius: BorderRadius.circular(PiumLayout.radiusSm),
                      ),
                      child: const Icon(
                        Icons.emergency_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        UserMessages.homeSosTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: PiumColors.tileRed,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
