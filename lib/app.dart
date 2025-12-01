import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';

class TeammyApp extends StatelessWidget {
  const TeammyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Teammy',
      theme: AppTheme.light(),
      home: const OnboardingPage(),
    );
  }
}
