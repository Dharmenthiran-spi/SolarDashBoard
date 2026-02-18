import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_route_names.dart';
import '../../View/login_screen.dart';
import '../../View/dashboard_screen.dart';
import '../../View/company_view.dart';
import '../../View/customer_view.dart';
import '../../View/machine_view.dart';
import '../../View/report_view.dart';
import '../../View/company_employee_view.dart';
import '../../View/customer_user_view.dart';
import '../../View/settings_screen.dart';
import '../../View/machine_detail_screen.dart';
import '../../Models/machine.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RouteNames.login,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => RouteNames.login),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.companies,
        name: 'companies',
        builder: (context, state) => const CompanyListScreen(),
      ),
      GoRoute(
        path: RouteNames.customers,
        name: 'customers',
        builder: (context, state) => const CustomerListScreen(),
      ),
      GoRoute(
        path: RouteNames.machines,
        name: 'machines',
        builder: (context, state) => const MachineListScreen(),
      ),
      GoRoute(
        path: RouteNames.reports,
        name: 'reports',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ReportListScreen()),
      ),
      GoRoute(
        path: '${RouteNames.employees}/company',
        name: 'company_employees',
        builder: (context, state) => const CompanyEmployeeView(),
      ),
      GoRoute(
        path: '${RouteNames.employees}/customer',
        name: 'customer_employees',
        builder: (context, state) => const CustomerUserView(),
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.machineDetail,
        name: 'machine_detail',
        builder: (context, state) {
          final machine = state.extra as Machine;
          return MachineDetailScreen(machine: machine);
        },
      ),
    ],
  );
}
