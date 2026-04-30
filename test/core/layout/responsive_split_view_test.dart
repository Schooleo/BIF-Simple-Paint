import 'package:bif_simple_paint/core/layout/responsive_split_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ResponsiveSplitView returns mobile on small widths', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveSplitView(
          mobile: Scaffold(body: Center(child: Text('MobileChild'))),
          desktop: Scaffold(body: Center(child: Text('DesktopChild'))),
        ),
      ),
    );

    expect(find.text('MobileChild'), findsOneWidget);
    expect(find.text('DesktopChild'), findsNothing);
  });

  testWidgets('ResponsiveSplitView returns desktop on large widths', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveSplitView(
          mobile: SizedBox.shrink(),
          desktop: Scaffold(body: Center(child: Text('DesktopChild'))),
        ),
      ),
    );

    expect(find.text('DesktopChild'), findsOneWidget);
    expect(find.text('MobileChild'), findsNothing);
  });
}
