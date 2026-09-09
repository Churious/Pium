import 'package:flutter/material.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/theme/pium_layout.dart';
import 'package:pium/utils/user_messages.dart';

/// 홈에서 가장 먼저 보이는 음성 AI 영역.
class HomeAiHelpCard extends StatelessWidget {
  const HomeAiHelpCard({
    super.key,
    required this.listening,
    required this.onAsk,
  });

  final bool listening;
  final VoidCallback? onAsk;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: UserMessages.homeAiTitle,
      child: Container(
        width: double.infinity,
        padding: PiumLayout.cardPadding,
        decoration: BoxDecoration(
          color: PiumColors.card,
          borderRadius: BorderRadius.circular(PiumLayout.radius),
          border: Border.all(color: PiumColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              UserMessages.homeAiTitle,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: PiumColors.navy,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              UserMessages.homeAiSubtitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: PiumColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: PiumLayout.primaryButtonHeight,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAsk,
                style: FilledButton.styleFrom(
                  backgroundColor: PiumColors.navy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: PiumColors.navyLight,
                  disabledForegroundColor: Colors.white,
                  minimumSize: const Size(
                    double.infinity,
                    PiumLayout.primaryButtonHeight,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PiumLayout.radiusSm),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  listening ? Icons.graphic_eq : Icons.mic,
                  size: 28,
                ),
                label: Text(
                  listening
                      ? UserMessages.homeListening
                      : UserMessages.homeAiButton,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              UserMessages.homeAiExampleLabel,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: PiumColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '"${UserMessages.homeAiExample}"',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: PiumColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
