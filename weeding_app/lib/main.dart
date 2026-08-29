import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/theme/wedding_theme_controller.dart';
import 'app/core/constants/supabase_config.dart';
import 'app/core/storage/secure_local_storage.dart';
import 'app/routes/app_pages.dart';
import 'app/bindings/app_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  if (!SupabaseConfig.isConfigured) {
    throw StateError(
      'Supabase credentials missing. Copy .env.example to .env and fill in '
      'SUPABASE_URL and SUPABASE_ANON_KEY.',
    );
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(),
      persistSession: true,
      autoRefreshToken: true,
    ),
  );

  Get.put(WeddingThemeController(), permanent: true);

  runApp(const WeddingApp());
}

class WeddingApp extends StatelessWidget {
  const WeddingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<WeddingThemeController>();
    return Obx(
      () => GetMaterialApp(
        title: 'Mariage Étienne',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightThemeFor(themeController.palette.value),
        initialBinding: AppBinding(),
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
        defaultTransition: Transition.fadeIn,
        locale: const Locale('fr', 'CI'),
        supportedLocales: const [Locale('fr'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
