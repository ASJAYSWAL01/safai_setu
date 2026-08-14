import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/auth/role_select_page.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SafaiSetuApp());
}

class SafaiSetuApp extends StatelessWidget {
  const SafaiSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.instance.isDark,
      builder: (context, isDark, _) {
        // Keep the palette in sync before the tree rebuilds.
        AppColors.isDark = isDark;
        return MaterialApp(
          title: 'Safai Setu',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const RoleSelectPage(),
        );
      },
    );
  }
}
