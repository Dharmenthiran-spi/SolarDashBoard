import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'ViewModel/company_view_model.dart';
import 'ViewModel/customer_view_model.dart';
import 'ViewModel/machine_view_model.dart';
import 'ViewModel/report_view_model.dart';
import 'Config/Language/language_view_model.dart';
import 'Config/Themes/app_themes.dart';
import 'Config/Themes/theme_view_model.dart';
import 'Config/app_routes/app_route_config.dart';
import 'ViewModel/dashboard_view_model.dart';
import 'ViewModel/company_employee_view_model.dart';
import 'ViewModel/customer_user_view_model.dart';
import 'ViewModel/machine_status_view_model.dart';
import 'ViewModel/global_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CompanyViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerViewModel()),
        ChangeNotifierProvider(create: (_) => MachineViewModel()),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
        ChangeNotifierProvider(create: (_) => CompanyEmployeeViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerUserViewModel()),
        ChangeNotifierProvider(create: (_) => LanguageViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => MachineStatusViewModel()),
        ChangeNotifierProvider(create: (_) => GlobalState()),
      ],
      child: Builder(
        builder: (context) {
          final themeViewModel = Provider.of<ThemeViewModel>(context);
          final languageViewModel = Provider.of<LanguageViewModel>(context);

          return MaterialApp.router(
            title: 'Solar Dashboard',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeViewModel.themeMode,
            routerConfig: _router,
            locale: languageViewModel.locale,
            localizationsDelegates: const [],
          );
        },
      ),
    );
  }
}
