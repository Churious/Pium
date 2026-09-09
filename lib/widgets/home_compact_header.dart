import 'package:flutter/material.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/theme/pium_layout.dart';
import 'package:pium/utils/date_format.dart';
import 'package:pium/utils/user_messages.dart';

/// 홈 상단 — 브랜드, 날짜, 시간, 날씨를 낮게 배치한다.
class HomeCompactHeader extends StatelessWidget {
  const HomeCompactHeader({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: PiumLayout.headerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                UserMessages.homeBrand,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: PiumColors.navy,
                  height: 1.2,
                ),
              ),
              Spacer(),
              Icon(
                Icons.wb_sunny,
                color: Color(0xFFEAB308),
                size: 26,
              ),
              SizedBox(width: 6),
              Text(
                UserMessages.homeWeather,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: PiumColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatKoreanDate(now),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: PiumColors.navy,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatKoreanTime(now),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: PiumColors.navy,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
