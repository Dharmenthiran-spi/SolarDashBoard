import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Config/app_routes/app_route_names.dart';
import 'package:provider/provider.dart';
import '../ViewModel/global_state.dart';
import '../Widget/main_layout.dart';
import '../Widget/responsive_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    
    final globalState = Provider.of<GlobalState>(context);
    final List<Map<String, dynamic>> navigationItems = [];

    if (globalState.isCompanyEmployee) {
      navigationItems.addAll([
        {
          'icon': Icons.business,
          'label': 'Companies',
          'route': RouteNames.companies,
        },
        {
          'icon': Icons.people,
          'label': 'Company Employees',
          'route': '${RouteNames.employees}/company',
        },
        {
          'icon': Icons.people,
          'label': 'Customers',
          'route': RouteNames.customers,
        },
      ]);
    } else if (globalState.isCustomerUser && globalState.isAdmin) {
       // For Customer Admin, show 'Users' (which links to their Customer details/User list)
       navigationItems.add({
         'icon': Icons.people,
         'label': 'Users',
         'route': RouteNames.customers,
       });
    }

    return MainLayout(
      title: 'Settings',
      showSidebar: true, // Enable sidebar/drawer for custom nav
      backButtonRoute: RouteNames.dashboard,
      customNavigationItems: navigationItems,
      body: isMobile ? Container() : _buildDesktopBody(context),
    );
  }

  Widget _buildDesktopBody(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
      child: const Center(
        child: Text(
          'Select an administrative task from the left menu.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}
