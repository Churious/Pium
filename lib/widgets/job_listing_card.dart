import 'package:flutter/material.dart';
import 'package:pium/models/senior_job.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/utils/phone_launcher.dart';
import 'package:pium/utils/user_messages.dart';

class JobListingCard extends StatelessWidget {
  const JobListingCard({
    super.key,
    required this.job,
    required this.onTapDetail,
  });

  final SeniorJob job;
  final VoidCallback onTapDetail;

  Future<void> _call(BuildContext context) async {
    if (!job.hasPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            UserMessages.noPhoneNumber,
            style: TextStyle(fontSize: 18),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await launchPhoneCall(
      context,
      number: job.contactPhone,
      speakBeforeCall: UserMessages.jobCallConnecting,
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = job.workDescription.isNotEmpty
        ? job.workDescription
        : job.jobCategory;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border.all(color: PiumColors.navy, width: 2),
        borderRadius: BorderRadius.circular(14),
        color: PiumColors.guideBg,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapDetail,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.work_outline, size: 36, color: PiumColors.navy),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title.isNotEmpty ? job.title : '일자리',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.summaryLine,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: PiumColors.tilePurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InfoRow(icon: Icons.schedule, text: job.workPeriodLabel),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.description_outlined,
                    text: description,
                    maxLines: 2,
                  ),
                ],
                if (job.acceptanceAgency.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoRow(icon: Icons.apartment, text: job.acceptanceAgency),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTapDetail,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PiumColors.navy,
                          side: const BorderSide(color: PiumColors.navy, width: 2),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline, size: 22),
                        label: const Text(
                          '자세히 보기',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (job.hasPhone) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _call(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: PiumColors.tileBlue,
                            minimumSize: const Size(0, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.phone, size: 24),
                          label: const Text(
                            '전화로 문의하기',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.maxLines = 3,
  });

  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: PiumColors.navy),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, height: 1.4),
          ),
        ),
      ],
    );
  }
}
