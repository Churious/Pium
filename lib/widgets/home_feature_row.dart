import 'package:flutter/material.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/theme/pium_layout.dart';

/// 홈 기능 한 줄. 항목을 리스트에 추가하면 그대로 늘어난다.
class HomeFeatureItem {
  const HomeFeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
}

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle(this.text, {super.key, this.color = PiumColors.navy});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      ),
    );
  }
}

/// 시니어용 큰 리스트 타일. 행 전체가 터치 영역이다.
class HomeFeatureRow extends StatelessWidget {
  const HomeFeatureRow({super.key, required this.item});

  final HomeFeatureItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.title}. ${item.subtitle}',
      child: Material(
        color: PiumColors.card,
        borderRadius: BorderRadius.circular(PiumLayout.radius),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(PiumLayout.radius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PiumLayout.radius),
              border: Border.all(color: PiumColors.border),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: PiumLayout.featureRowMinHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Row(
                  children: [
                    _IconBadge(icon: item.icon, color: item.accentColor),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: PiumColors.navy,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: PiumColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 32,
                      color: PiumColors.navyLight,
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

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: PiumLayout.iconBox,
      height: PiumLayout.iconBox,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(PiumLayout.radiusSm),
      ),
      child: Icon(icon, size: 30, color: color),
    );
  }
}
