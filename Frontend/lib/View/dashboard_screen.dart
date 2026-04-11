import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../Config/app_routes/app_route_names.dart';
import '../Models/dashboard_data.dart';
import '../ViewModel/dashboard_view_model.dart';
import '../ViewModel/global_state.dart';
import '../ViewModel/machine_status_view_model.dart';
import '../Config/Themes/theme_view_model.dart';
import '../Widget/main_layout.dart';
import '../Widget/responsive_helper.dart';
import '../Models/machine.dart';
import '../Models/report.dart';
import '../Models/machine_status.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _machineScrollController = ScrollController();
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashVM = context.read<DashboardViewModel>();
      final statusVM = context.read<MachineStatusViewModel>();
      final globalState = context.read<GlobalState>();

      dashVM.fetchSummary();
      statusVM
          .fetchAllLiveStatus(); // Fetch immediate state via HTTP so UI is instant

      if (globalState.currentUser?.companyId != null) {
        statusVM.connectToCompany(globalState.currentUser!.companyId!);
        statusVM.startSmartPolling(); // Start backup polling logic
      }
    });
  }

  @override
  void dispose() {
    _machineScrollController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = Provider.of<ThemeViewModel>(context);
    final isDark = themeVM.themeMode == ThemeMode.dark;

    return MainLayout(
      title: 'Production Intelligence',
      body: _buildDashboardBody(context, isDark),
    );
  }

  Widget _buildDashboardBody(BuildContext context, bool isDark) {
    return Selector<DashboardViewModel, bool>(
      selector: (_, vm) => vm.isLoading && vm.summary == null,
      builder: (context, isLoading, _) {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Consumer2<DashboardViewModel, MachineStatusViewModel>(
          builder: (context, dashVM, statusVM, _) {
            if (dashVM.errorMessage != null && dashVM.summary == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      dashVM.errorMessage!,
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => dashVM.fetchSummary(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (dashVM.summary == null) {
              return const Center(child: Text('No data available'));
            }

            return Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? RadialGradient(
                        center: const Alignment(-0.8, -0.6),
                        radius: 1.2,
                        colors: [
                          Colors.blueAccent.withOpacity(0.05),
                          Colors.transparent,
                        ],
                        stops: const [0, 1],
                      )
                    : null,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModernHeader(context, isDark),
                    const SizedBox(height: 24),
                    _buildFleetIntelligence(context, dashVM, statusVM, isDark),
                    const SizedBox(height: 32),
                    _buildMainDashboardLayout(
                      context,
                      dashVM,
                      statusVM,
                      isDark,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernHeader(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent, Colors.cyanAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOLAR INTELLIGENT HUB',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Row(
                        children: [
                          _PulsingDot(color: Colors.greenAccent, size: 6),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE FLEET STREAM',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.greenAccent.withOpacity(0.8),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              _HeaderClock(isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFleetIntelligence(
    BuildContext context,
    DashboardViewModel dashVM,
    MachineStatusViewModel statusVM,
    bool isDark,
  ) {
    int active = 0;
    int error = 0;
    int idle = 0;

    for (var m in dashVM.allMachines) {
      final s = statusVM.liveStatuses[m.id];
      if (s?.status == 'Error')
        error++;
      else if (s?.status == 'Idle')
        idle++;
      else
        active++;
    }

    double utilization =
        (active /
            (dashVM.allMachines.isNotEmpty ? dashVM.allMachines.length : 1)) *
        100;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 600
            ? 2
            : (constraints.maxWidth < 1200 ? 4 : 4);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth < 600 ? 1.1 : 2.0,
          children: [
            _buildFleetChartCard(active, error, idle, utilization, isDark),
            _buildFleetStatCard('ACTIVE', '$active', Icons.bolt_rounded, [
              Colors.greenAccent,
              Colors.tealAccent,
            ], isDark),
            _buildFleetStatCard('CRITICAL', '$error', Icons.warning_rounded, [
              Colors.redAccent,
              Colors.orangeAccent,
            ], isDark),
            _buildFleetStatCard(
              'UTILIZATION',
              '${utilization.toStringAsFixed(0)}%',
              Icons.shutter_speed_rounded,
              [Colors.blueAccent, Colors.indigoAccent],
              isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFleetChartCard(
    int active,
    int error,
    int idle,
    double utilization,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'FLEET DISTRIBUTION',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey.withOpacity(0.8),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 36,
                        sections: [
                          PieChartSectionData(
                            value: active.toDouble(),
                            color: Colors.greenAccent,
                            radius: 12,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: error.toDouble(),
                            color: Colors.redAccent,
                            radius: 12,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: idle.toDouble(),
                            color: Colors.orangeAccent,
                            radius: 12,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${utilization.toStringAsFixed(0)}%',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueAccent,
                            ),
                          ),
                          Text(
                            'LOAD',
                            style: GoogleFonts.inter(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFleetStatCard(
    String label,
    String value,
    IconData icon,
    List<Color> colors,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.first.withOpacity(0.2), width: 1.5),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: colors.first.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.first.withOpacity(0.2),
                        colors.last.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: colors.first, size: 18),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20), // Compensate for top icon
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemLogCard(bool isDark, List<MachineStatus> reports) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          'LOG',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'LIVE PRODUCTION FEED',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white.withOpacity(0.95)
                              : Colors.black,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'SYNCING',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PulsingDot(color: Colors.greenAccent, size: 8),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: reports.isEmpty
                    ? Center(
                        child: Text(
                          'Waiting for telemetry...',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                        ),
                      )
                    : Scrollbar(
                        controller: _logScrollController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _logScrollController,
                          padding: const EdgeInsets.only(right: 12),
                          itemCount: reports.length,
                          itemBuilder: (context, index) {
                            // Show latest first
                            final r = reports[reports.length - 1 - index];
                            final time = DateFormat(
                              'HH:mm:ss',
                            ).format(r.timestamp);

                            return _buildLogItem(
                              time,
                              'Machine #${r.machineId} updated status to ${r.status}',
                              r.status == 'Error'
                                  ? Colors.redAccent
                                  : (r.status == 'Idle'
                                        ? Colors.orangeAccent
                                        : Colors.greenAccent),
                              isDark,
                              area: '${r.areaToday.toStringAsFixed(1)} m²',
                              water: '${r.waterLevel.toStringAsFixed(0)}%',
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(
    String time,
    String message,
    Color color,
    bool isDark, {
    String? area,
    String? water,
  }) {
    IconData icon = Icons.info_outline_rounded;
    if (message.contains('Error')) icon = Icons.error_outline_rounded;
    if (message.contains('Idle')) icon = Icons.pause_circle_outline_rounded;
    if (message.contains('Online')) icon = Icons.check_circle_outline_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.02)
              : Colors.black.withOpacity(0.01),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Tactical Left Accent Bar
                Container(width: 4, color: color),
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: color.withOpacity(0.05),
                  child: Center(
                    child: Text(
                      time,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, size: 16, color: color.withOpacity(0.7)),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: isDark
                                ? Colors.white.withOpacity(0.85)
                                : Colors.black87,
                          ),
                        ),
                        if (area != null || water != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                if (area != null) ...[
                                  _buildLogDetailTag(
                                    'UNIT_AREA',
                                    area,
                                    Colors.blueAccent,
                                    isDark,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (water != null)
                                  _buildLogDetailTag(
                                    'UNIT_WATER',
                                    water,
                                    Colors.cyanAccent,
                                    isDark,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogDetailTag(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.replaceAll('UNIT_', ''),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 7,
              fontWeight: FontWeight.w900,
              color: color.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDashboardLayout(
    BuildContext context,
    DashboardViewModel dashVM,
    MachineStatusViewModel statusVM,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 600, // Consistent fixed height
                  child: _buildMachinePulseSection(
                    context,
                    dashVM,
                    isDark,
                    hideHeader: false,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 600, // Matching height for logs
                  child: _buildSystemLogCard(isDark, statusVM.telemetryHistory),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              SizedBox(
                height: 500, // Fixed height for machines in mobile
                child: _buildMachinePulseSection(context, dashVM, isDark),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 400, // Matching height for logs in mobile
                child: _buildSystemLogCard(isDark, statusVM.telemetryHistory),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildMachinePulseSection(
    BuildContext context,
    DashboardViewModel dashVM,
    bool isDark, {
    bool hideHeader = false,
  }) {
    return Scrollbar(
      controller: _machineScrollController,
      thumbVisibility: true,
      child: GridView.builder(
        controller: _machineScrollController,
        padding: const EdgeInsets.only(right: 16), // Padding for scrollbar
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.value(
            context: context,
            mobile: 1,
            tablet: 1,
            desktop: 2,
          ),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemCount: dashVM.allMachines.length,
        itemBuilder: (context, index) {
          final machine = dashVM.allMachines[index];
          return InkWell(
            onTap: () {
              dashVM.selectMachine(machine);
              context.push(RouteNames.machineDetail, extra: machine);
            },
            child: _buildPulseCard(context, machine, isDark),
          );
        },
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(color: Colors.redAccent, size: 8),
          const SizedBox(width: 8),
          Text(
            'LIVE STREAM',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.redAccent,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseCard(BuildContext context, Machine machine, bool isDark) {
    return Selector<MachineStatusViewModel, MachineStatus?>(
      selector: (_, vm) => vm.liveStatuses[machine.id],
      builder: (context, status, _) {
        Color statusColor = Colors.greenAccent;
        if (status?.status == 'Error') statusColor = Colors.redAccent;
        if (status?.status == 'Idle') statusColor = Colors.orangeAccent;
        if (status?.status == 'Offline') statusColor = Colors.grey;

        bool hasAlert = status?.status == 'Error';

        return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: hasAlert
                        ? Colors.redAccent.withOpacity(0.4)
                        : Colors.white.withOpacity(0.08),
                    width: hasAlert ? 1.5 : 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    // Header Segment
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: Colors.white.withOpacity(0.03),
                      child: Row(
                        children: [
                          _buildMachineIcon(machine, isDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    machine.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _PulsingDot(color: statusColor, size: 6),
                                    const SizedBox(width: 6),
                                    Text(
                                      status?.status.toUpperCase() ?? 'OFFLINE',
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (hasAlert)
                            _PulsingDot(color: Colors.redAccent, size: 8),
                        ],
                      ),
                    ),
                    // Data Grid Segment
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          10,
                          8,
                          10,
                          0,
                        ), // Removed bottom padding
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1.8,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildCompactTile(
                              'BATT',
                              status != null
                                  ? '${status.batteryLevel.toInt()}%'
                                  : '--',
                              status != null && status.batteryLevel < 20
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                              Icons.bolt_rounded,
                            ),
                            _buildCompactTile(
                              'WATER',
                              status != null
                                  ? '${status.waterLevel.toInt()}%'
                                  : '--',
                              status != null && status.waterLevel < 15
                                  ? Colors.redAccent
                                  : Colors.cyanAccent,
                              Icons.water_drop_rounded,
                            ),
                            _buildCompactTile(
                              'MOTOR',
                              status != null ? '${status.brushRPM}' : '--',
                              Colors.orangeAccent,
                              Icons.sync_rounded,
                            ),
                            _buildCompactTile(
                              'TEMP',
                              status != null
                                  ? '${status.brushTemp.toInt()}°C'
                                  : '--',
                              status != null && status.brushTemp > 60
                                  ? Colors.redAccent
                                  : Colors.amberAccent,
                              Icons.thermostat_rounded,
                            ),
                            _buildCompactTile(
                              'SPEED',
                              status != null
                                  ? status.speed.toStringAsFixed(1)
                                  : '--',
                              Colors.indigoAccent,
                              Icons.speed_rounded,
                            ),
                            _buildCompactTile(
                              'PERF',
                              status != null
                                  ? '${status.areaToday.toInt()}m²'
                                  : '--',
                              Colors.blueAccent,
                              Icons.auto_graph_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Action Buttons Segment (Moved to Bottom)
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                context,
                                machine.id,
                                'START',
                                Icons.bolt_rounded,
                                Colors.greenAccent,
                                isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionButton(
                                context,
                                machine.id,
                                'STOP',
                                Icons.power_settings_new_rounded,
                                Colors.redAccent,
                                isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionButton(
                                context,
                                machine.id,
                                'DOCK',
                                Icons.anchor_rounded,
                                Colors.blueAccent,
                                isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactTile(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: color.withOpacity(0.8)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.withOpacity(0.7),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineIcon(Machine machine, bool isDark) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: machine.image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                base64Decode(machine.image!),
                fit: BoxFit.cover,
              ),
            )
          : Icon(
              Icons.settings_input_component_rounded,
              color: Colors.blueAccent.withOpacity(0.5),
            ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    int machineId,
    String label,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final statusVM = context.read<MachineStatusViewModel>();
          final success = await statusVM.sendCommand(
            machineId,
            label.toLowerCase(),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Command $label sent successfully'
                      : 'Failed to send $label command',
                ),
                backgroundColor: success ? Colors.green : Colors.red,
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulsingDot({
    super.key,
    this.color = Colors.redAccent,
    this.size = 8.0,
  });

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.5),
              blurRadius: widget.size,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _HeaderClock extends StatefulWidget {
  final bool isDark;
  const _HeaderClock({required this.isDark});

  @override
  State<_HeaderClock> createState() => _HeaderClockState();
}

class _HeaderClockState extends State<_HeaderClock> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 16,
            color: Colors.grey.withOpacity(0.8),
          ),
          const SizedBox(width: 10),
          Text(
            '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: widget.isDark
                  ? Colors.white.withOpacity(0.9)
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
