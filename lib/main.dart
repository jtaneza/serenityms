import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';

import 'views/customer/customer_landing_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SerenityApp());
}

class SerenityApp extends StatelessWidget {
  const SerenityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serenity Management Suite',
      debugShowCheckedModeBanner: false,

      initialRoute: RouteNames.login,
      onGenerateRoute: AppRouter.generateRoute,

      //home: const CustomerSplashPage(),

      theme: ThemeData(
        fontFamily: 'Manrope',
        scaffoldBackgroundColor: const Color(0xFFF4FAFD),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006B55),
        ),
        useMaterial3: true,
      ),
    );
  }
}
