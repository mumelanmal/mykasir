// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mykasir/main.dart';

void main() {
  testWidgets('MyKasir app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyKasirApp());

    // Verify that MyKasir title appears
    expect(find.text('MyKasir'), findsOneWidget);

    // Open Drawer to see navigation menu
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    // Verify that menu items are present (including new Riwayat)
    expect(find.text('Transaksi'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Produk'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);
  });
}
