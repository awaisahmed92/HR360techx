import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr360techx/controllers/app_state.dart';
import 'package:hr360techx/core/auth/auth_state.dart';
import 'package:hr360techx/core/config/app_config.dart';
import 'package:hr360techx/core/self_service/self_service_state.dart';
import 'package:hr360techx/views/my_dashboard_view.dart';
import 'package:hr360techx/widgets/dashboard_clock_face.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void recordHeroErrors(List<FlutterErrorDetails> heroErrors) {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.toString();
      final hero = text.contains('_HeroBanner') ||
          text.contains('DashboardSignBar') ||
          text.contains('DashboardClockFace') ||
          text.contains('dashboard_clock_face.dart') ||
          text.contains('dashboard_punch.dart');
      if (hero) {
        heroErrors.add(details);
        previous?.call(details);
      }
    };
  }

  Future<void> pumpDashboard(
    WidgetTester tester,
    Size size,
    List<FlutterErrorDetails> heroErrors,
  ) async {
    recordHeroErrors(heroErrors);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues({
      AppConfig.prefsSessionKey: jsonEncode({
        'token': 'demo',
        'is_demo': true,
        'user': {
          'employee_id': 1,
          'name': 'James Carter',
          'user_name': 'james',
          'email': 'james@example.com',
          'designation_id': 1,
          'designation_name': 'Software Engineer, Technology',
          'user_status': 1,
          'is_first_login': 0,
          'is_superuser': false,
        },
        'company': {
          'name': 'Techx',
          'code': 'demo',
          'currency': 'USD',
          'date_format': 'd-m-Y',
          'subdomain': 'demo',
        },
        'permissions': {'all': true},
      }),
    });
    final auth = AuthState();
    await auth.bootstrap();
    final app = AppState();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: app),
          ChangeNotifierProvider(create: (_) => SelfServiceState(auth)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MyDashboardView()),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> expectClockInside(
    WidgetTester tester,
    Size size,
    List<FlutterErrorDetails> heroErrors,
  ) async {
    final clock = tester.getRect(find.byType(DashboardClockFace));
    // List padding is 16, so the card's clip edge is inset from the screen.
    final cardRight = size.width - 16;
    final cardLeft = 16.0;
    expect(clock.left, greaterThanOrEqualTo(cardLeft), reason: 'clock left ${clock.left}');
    expect(clock.right, lessThanOrEqualTo(cardRight), reason: 'clock right ${clock.right} > $cardRight');
    expect(clock.width, greaterThan(60));
    expect(find.text('James Carter'), findsOneWidget);
    expect(find.text('You have not clocked in today!'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(heroErrors, isEmpty, reason: heroErrors.map((e) => e.exceptionAsString()).join('\n'));
  }

  testWidgets('clock stays inside a 320px phone', (tester) async {
    const size = Size(320, 720);
    final heroErrors = <FlutterErrorDetails>[];
    await pumpDashboard(tester, size, heroErrors);
    await expectClockInside(tester, size, heroErrors);
  });

  testWidgets('clock stays inside a 390px phone', (tester) async {
    const size = Size(390, 844);
    final heroErrors = <FlutterErrorDetails>[];
    await pumpDashboard(tester, size, heroErrors);
    await expectClockInside(tester, size, heroErrors);
  });

  testWidgets('clock stays inside at the desktop breakpoint', (tester) async {
    const size = Size(732, 800);
    final heroErrors = <FlutterErrorDetails>[];
    await pumpDashboard(tester, size, heroErrors);
    await expectClockInside(tester, size, heroErrors);
  });

  testWidgets('clock stays inside a desktop window', (tester) async {
    const size = Size(1280, 800);
    final heroErrors = <FlutterErrorDetails>[];
    await pumpDashboard(tester, size, heroErrors);
    await expectClockInside(tester, size, heroErrors);
  });
}
