import 'package:flutter/material.dart';
import 'package:pium/config/supabase_config.dart';
import 'package:pium/screens/pium_home_screen.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/utils/app_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );
    } catch (e, st) {
      appLog('Supabase initialize failed: $e\n$st');
    }
  }

  runApp(const PiumApp());
}

class PiumApp extends StatelessWidget {
  const PiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '피움 (PIUM)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: PiumColors.navy,
          brightness: Brightness.light,
        ).copyWith(
          primary: PiumColors.navy,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          bodyLarge: TextStyle(fontSize: 20, color: Colors.black, height: 1.5),
          bodyMedium: TextStyle(fontSize: 18, color: Colors.black, height: 1.5),
        ),
      ),
      home: const PiumHomeScreen(),
    );
  }
}
