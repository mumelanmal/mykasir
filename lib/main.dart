import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/themes/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/product_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/staff_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/transactions/transaction_screen.dart';
import 'screens/history/history_list_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/staff/staff_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/printer/printer_settings_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Hive untuk settings/preferences
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox(AppConstants.preferencesBox);

  runApp(const MyKasirApp());
}

class MyKasirApp extends StatelessWidget {
  const MyKasirApp({super.key});

  // Navigator key so we can reliably inspect/navigation stack from the app shell
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  // Track current route name to determine if we're at Home
  static String currentRoute = '/';

  // Simple navigator observer that keeps `currentRoute` up to date
  static final NavigatorObserver routeTracker = _RouteTracker();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: navigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/transactions': (context) => const TransactionScreen(),
          '/history': (context) => const HistoryListScreen(),
          '/products': (context) => const ProductListScreen(),
          '/staff': (context) => const StaffScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/printer': (context) => const PrinterSettingsScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        navigatorObservers: [routeTracker],
        builder: (context, child) {
          return WillPopScope(
            onWillPop: () async {
              final navState = MyKasirApp.navigatorKey.currentState;
              final navContext = MyKasirApp.navigatorKey.currentContext ?? context;

              // If navigator is not available, allow default behavior
              if (navState == null) return true;

              // If current route is not home, go back to home (replace stack)
              if (MyKasirApp.currentRoute != '/') {
                navState.pushNamedAndRemoveUntil('/', (route) => false);
                MyKasirApp.currentRoute = '/';
                return false; // handled
              }

              // We're at root (Home). Ask for confirmation before exiting.
              final shouldExit = await showDialog<bool>(
                context: navContext,
                builder: (ctx) => AlertDialog(
                  title: const Text('Konfirmasi'),
                  content: const Text('Keluar dari aplikasi?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
              return shouldExit == true;
            },
            child: child!,
          );
        },
      ),
    );
  }
}

class _RouteTracker extends NavigatorObserver {
  void _update(Route? route) {
    if (route is PageRoute) {
      MyKasirApp.currentRoute = route.settings.name ?? '/';
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _update(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _update(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _update(previousRoute);
    super.didPop(route, previousRoute);
  }
}
