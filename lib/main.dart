import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_control/config/app_theme.dart';
import 'package:inventory_control/services/service_locator.dart';
import 'package:inventory_control/features/auth/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  
  runApp(
    const ProviderScope(
      child: InventoryControlApp(),
    ),
  );
}

class InventoryControlApp extends StatelessWidget {
  const InventoryControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Control',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
