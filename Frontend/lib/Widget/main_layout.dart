import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../Config/Themes/app_colors.dart';

import '../Config/app_routes/app_route_names.dart';
import 'responsive_helper.dart';
import 'translate_text.dart';
import '../Config/Language/language_view_model.dart';
import '../Config/Themes/theme_view_model.dart';
import '../ViewModel/global_state.dart';
import 'package:language_picker_with_country_flag/language_picker_with_country_flag.dart';
import 'package:language_picker_with_country_flag/languages.dart';

class MainLayout extends StatefulWidget {
  final Widget body;
  final String title;
  final String? backButtonRoute;

  final bool showSidebar;
  final List<Widget>? actions;
  final List<Map<String, dynamic>>? customNavigationItems;

  const MainLayout({
    super.key,
    required this.body,
    required this.title,
    this.backButtonRoute,
    this.showSidebar = true,
    this.actions,
    this.customNavigationItems,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isSidebarCollapsed = false;

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (Responsive.isMobile(context) || !widget.showSidebar)
          ? AppBar(
              title: Text(Translate.get(context, widget.title)),
              leading: widget.showSidebar
                  ? Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => widget.backButtonRoute != null
                          ? context.go(widget.backButtonRoute!)
                          : context.pop(),
                    ),
              actions: [
                IconButton(
                  icon: Icon(
                    Provider.of<ThemeViewModel>(context).themeMode ==
                            ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () => Provider.of<ThemeViewModel>(
                    context,
                    listen: false,
                  ).toggleTheme(),
                ),
                IconButton(
                  icon: const Icon(Icons.language),
                  onPressed: () => _showLanguagePicker(context),
                ),
                if (widget.actions != null) ...widget.actions!,
              ],
            )
          : null,
      drawer: (Responsive.isMobile(context) && widget.showSidebar)
          ? Drawer(child: _buildSidebarContent(context, false))
          : null,
      body: Row(
        children: [
          if (!Responsive.isMobile(context) && widget.showSidebar)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isSidebarCollapsed ? 80 : 250,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: _buildSidebarContent(context, _isSidebarCollapsed),
            ),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: widget.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(BuildContext context, bool isCollapsed) {
    return Column(
      children: [
        SafeArea(
          child: Container(
            height: 60,
            alignment: Alignment.center,
            child: isCollapsed
                ? const Icon(Icons.solar_power, size: 32, color: Colors.orange)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.backButtonRoute != null)
                          IconButton(
                            icon: const Icon(Icons.arrow_back, size: 20),
                            onPressed: () =>
                                context.go(widget.backButtonRoute!),
                            tooltip: 'Back',
                          ),
                        const Icon(Icons.solar_power, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            Translate.get(context, widget.title),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: widget.customNavigationItems != null
                ? widget.customNavigationItems!.map((item) {
                    return _buildNavItem(
                      context,
                      item['icon'] as IconData,
                      item['label'] as String,
                      item['route'] as String,
                      isCollapsed,
                    );
                  }).toList()
                : [
                    if (Provider.of<GlobalState>(context).isAdmin) ...[
                      _buildNavItem(
                        context,
                        Icons.precision_manufacturing,
                        'Machines',
                        RouteNames.machines,
                        isCollapsed,
                      ),
                    ],
                    _buildNavItem(
                      context,
                      Icons.assessment,
                      'Reports',
                      RouteNames.reports,
                      isCollapsed,
                    ),
                    if (Provider.of<GlobalState>(context).isAdmin) ...[
                      _buildNavItem(
                        context,
                        Icons.settings,
                        'Settings',
                        RouteNames.settings,
                        isCollapsed,
                      ),
                    ],
                  ],
          ),
        ),

        if (!Responsive.isMobile(context))
          IconButton(
            icon: Icon(
              isCollapsed ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              size: 16,
            ),
            onPressed: _toggleSidebar,
          ),

        const Divider(),
        _buildSettingsSection(context, isCollapsed),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, bool isCollapsed) {
    final themeVM = Provider.of<ThemeViewModel>(context);
    final isDark = themeVM.themeMode == ThemeMode.dark;

    return Column(
      children: [
        ListTile(
          leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 20),
          title: isCollapsed ? null : Text(isDark ? 'Light Mode' : 'Dark Mode'),
          onTap: () => themeVM.toggleTheme(),
          dense: true,
        ),
        ListTile(
          leading: const Icon(Icons.language, size: 20),
          title: isCollapsed ? null : const Text('Language'),
          onTap: () => _showLanguagePicker(context),
          dense: true,
        ),
      ],
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final language = languages[index];
              return ListTile(
                leading: Text(
                  language.flagEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(language.name),
                onTap: () {
                  Provider.of<LanguageViewModel>(
                    context,
                    listen: false,
                  ).changeLanguage(language);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
    bool isCollapsed,
  ) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final isActive = currentRoute == route;
    final theme = Theme.of(context);
    final translatedLabel = Translate.get(context, label);

    return InkWell(
      onTap: () => context.go(route),
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? theme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: theme.primaryColor.withOpacity(0.5))
              : null,
        ),
        child: isCollapsed
            ? Tooltip(
                message: translatedLabel,
                child: Icon(
                  icon,
                  color: isActive ? theme.primaryColor : theme.iconTheme.color,
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isActive
                          ? theme.primaryColor
                          : theme.iconTheme.color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        translatedLabel,
                        style: TextStyle(
                          color: isActive
                              ? theme.primaryColor
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
