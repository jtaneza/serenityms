import 'package:flutter/material.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';

class SerenityApp extends StatelessWidget {
  const SerenityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serenity Massage & Spa',
      debugShowCheckedModeBanner: false,
      initialRoute: RouteNames.login,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}