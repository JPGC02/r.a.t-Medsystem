import 'package:flutter/material.dart';


import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppStateProvider(),
      child: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'Equipment Tracking System',
            theme: AppTheme.lightTheme(),
            debugShowCheckedModeBanner: false,
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}