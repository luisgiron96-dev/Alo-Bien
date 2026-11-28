import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'features/auth/auth_gate.dart';
import 'features/splash/animated_splash.dart';
import 'firebase_options.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  await PushService.instance.init();
  runApp(const AloBienApp());
}

class AloBienApp extends StatelessWidget {
  const AloBienApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ALO BIEN',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AnimatedSplash(child: AuthGate()),
      );
}