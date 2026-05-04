import 'package:flutter/material.dart';
import 'package:flutter_application_1/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import 'app_navigator.dart';
import 'notification_payload_handler.dart';
import 'services/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await ReminderService.initTimeZone();
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  
  runApp(const MyApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      ReminderService.instance
          .handleNotificationAppLaunch()
          .then((_) => tryFlushPendingEmotionPostOpen()),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exam Recovery',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      home: const SplashScreen(),
    );
    
  }
}

