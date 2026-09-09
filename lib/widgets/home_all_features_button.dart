import 'package:flutter/material.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/theme/pium_layout.dart';
import 'package:pium/utils/user_messages.dart';

/// 전체 기능 화면이 생기면 [onPressed]에 Navigator.push만 연결하면 된다.
class HomeAllFeaturesButton extends StatelessWidget {
  const HomeAllFeaturesButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PiumLayout.minTap,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: PiumColors.navy,
          side: const BorderSide(color: PiumColors.navy, width: 1.5),
          minimumSize: const Size(double.infinity, PiumLayout.minTap),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PiumLayout.radiusSm),
          ),
        ),
        child: const Text(
          UserMessages.homeAllFeatures,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
