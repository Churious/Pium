import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pium/main.dart';
import 'package:pium/screens/pium_home_screen.dart';
import 'package:pium/utils/user_messages.dart';
import 'package:pium/widgets/home_ai_help_card.dart';
import 'package:pium/widgets/home_all_features_button.dart';
import 'package:pium/widgets/home_emergency_card.dart';
import 'package:pium/widgets/home_feature_row.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => 1);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PiumApp());
    await tester.pumpAndSettle();
  }

  testWidgets('Pium app smoke test', (WidgetTester tester) async {
    await pumpHome(tester);

    expect(find.text(UserMessages.homeBrand), findsOneWidget);
    expect(find.text(UserMessages.homeAiTitle), findsOneWidget);
    expect(find.text(UserMessages.homeAiButton), findsOneWidget);
    expect(find.text(UserMessages.homeHospitalTitle), findsOneWidget);
    expect(find.text(UserMessages.homeFamilyTitle), findsOneWidget);
    expect(find.text(UserMessages.homePracticeTitle), findsOneWidget);
    expect(find.text(UserMessages.homeJobsTitle), findsOneWidget);
    expect(find.text(UserMessages.homeSosTitle), findsOneWidget);
    expect(find.text(UserMessages.homeAllFeatures), findsOneWidget);
  });

  testWidgets('home uses list tiles instead of colorful grid labels',
      (WidgetTester tester) async {
    await pumpHome(tester);

    expect(find.text('키오스크'), findsNothing);
    expect(find.text('병원/약국'), findsNothing);
    expect(find.text('119에 전화'), findsNothing);
    expect(find.text('음성 질문'), findsNothing);
    expect(find.byType(HomeFeatureRow), findsNWidgets(4));
    expect(find.byType(HomeAiHelpCard), findsOneWidget);
    expect(find.byType(HomeEmergencyCard), findsOneWidget);
    expect(find.byType(HomeAllFeaturesButton), findsOneWidget);
  });

  testWidgets('119 still opens the existing confirm dialog',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.ensureVisible(find.text(UserMessages.homeSosTitle));
    await tester.tap(find.text(UserMessages.homeSosTitle));
    await tester.pumpAndSettle();

    expect(find.text('응급 상황'), findsOneWidget);
    expect(find.text('119에 연결할까요?'), findsOneWidget);
    expect(find.text('119 연결'), findsOneWidget);
  });

  testWidgets('digital practice still opens the kiosk practice screen',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.ensureVisible(find.text(UserMessages.homePracticeTitle));
    await tester.tap(find.text(UserMessages.homePracticeTitle));
    await tester.pumpAndSettle();

    expect(find.text('무인주문기 연습'), findsOneWidget);
  });

  testWidgets('HomeFeatureRow taps the whole row', (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeFeatureRow(
            item: HomeFeatureItem(
              title: UserMessages.homeHospitalTitle,
              subtitle: UserMessages.homeHospitalSubtitle,
              icon: Icons.local_hospital_outlined,
              accentColor: Colors.teal,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(HomeFeatureRow));
    expect(tapped, isTrue);
  });

  testWidgets('voice ask button still starts listening',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text(UserMessages.homeAiButton));
    await tester.pump();

    expect(find.text(UserMessages.homeListening), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('small phone size does not overflow the home screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PiumApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(PiumHomeScreen), findsOneWidget);
    await tester.ensureVisible(find.text(UserMessages.homeSosTitle));
    expect(find.text(UserMessages.homeSosTitle), findsOneWidget);
  });
}
