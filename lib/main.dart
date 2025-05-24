import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcoin/pages/homepage.dart';
import 'package:tapcoin/pages/on_board.dart';
import 'constants/constants.dart';
import 'constants/onboarding_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String localeCode = prefs.getString('selected_language') ?? 'en';
  MobileAds.instance.initialize();
  OneSignal.initialize(oneSignalAppId);
  OneSignal.Notifications.requestPermission(true);
  runApp(
    EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
          Locale('de'),
          Locale('hi'),
          Locale('pt'),
          Locale('ar'),
          Locale('es'),
          Locale('vi'),
          Locale('th'),
          Locale('tl'),
        ],
        path:
            'assets/translations', // <-- change the path of the translation files
        fallbackLocale: const Locale('en'),
        startLocale: Locale(localeCode),
        child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness:
            Brightness.dark, // Dark == white status bar -- for IOS.
        statusBarIconBrightness: Brightness.dark));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'TapCoin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            primary: const Color(0xff174F53),
            onPrimary: const Color(0xff16373C),
            tertiary: Colors.white,
            secondary: Colors.black),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: OnboardingManager.isOnboardingShown(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            final isOnboardingShown = snapshot.data ?? false;
            return isOnboardingShown
                ? const HomePage(
                    initialIndex: 0,
                  )
                : const OnBoard();
          }
        },
      ),
    );
  }
}
