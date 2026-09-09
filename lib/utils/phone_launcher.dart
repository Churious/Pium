import 'package:flutter/material.dart';
import 'package:pium/services/tts_service.dart';
import 'package:pium/utils/user_messages.dart';
import 'package:url_launcher/url_launcher.dart';

/// 전화 연결 (홈·일자리 등 공통)
Future<void> launchPhoneCall(
  BuildContext context, {
  required String number,
  String? speakBeforeCall,
}) async {
  if (speakBeforeCall != null && speakBeforeCall.isNotEmpty) {
    await TtsService.speak(speakBeforeCall);
  }
  final uri = Uri(scheme: 'tel', path: number);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        UserMessages.callFailed,
        style: TextStyle(fontSize: 18),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
