import 'package:flutter_test/flutter_test.dart';
import 'package:pium/main.dart';

void main() {
  testWidgets('Pium app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PiumApp());
    await tester.pumpAndSettle();

    expect(find.text('피움'), findsOneWidget);
    expect(find.text('병원/약국'), findsOneWidget);
    expect(find.text('가족 연락'), findsOneWidget);
    expect(find.text('키오스크'), findsOneWidget);
    expect(find.text('긴급 SOS'), findsOneWidget);
    expect(find.text('음성 질문'), findsOneWidget);
  });
}
