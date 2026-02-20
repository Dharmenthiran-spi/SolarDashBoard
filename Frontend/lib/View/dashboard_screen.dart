import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashVM = context.read<DashboardViewModel>();
      final statusVM = context.read<MachineStatusViewModel>();
      final globalState = context.read<GlobalState>();

      dashVM.fetchSummary();
      statusVM.startPolling();

      if (globalState.currentUser?.companyId != null) {
        statusVM.connectToCompany(globalState.currentUser!.companyId!);
      }
    });
  }

  @override
  void dispose() {
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

        return Consumer<DashboardViewModel>(
          builder: (context, dashVM, _) {
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

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernHeader(context, isDark),
                  const SizedBox(height: 16),
                  _buildLiveStatusGrid(
                    context,
                    dashVM,
                    isDark,
                  ), // statusVM removed
                  const SizedBox(height: 16),
                  _buildSplitHUD(context, dashVM, isDark),
                  const SizedBox(height: 24),
                  _buildAnalyticsSection(context, dashVM, isDark),
                ],
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

  Widget _buildSplitHUD(
    BuildContext context,
    DashboardViewModel dashVM,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 1100;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildMachinePulseSection(
                  context,
                  dashVM,
                  isDark,
                  hideHeader: true,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: _buildFleetIntelligence(context, dashVM, isDark),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildFleetIntelligence(context, dashVM, isDark),
              const SizedBox(height: 20),
              _buildMachinePulseSection(context, dashVM, isDark),
            ],
          );
        }
      },
    );
  }

  Widget _buildFleetIntelligence(
    BuildContext context,
    DashboardViewModel dashVM,
    bool isDark,
  ) {
    return Consumer<MachineStatusViewModel>(
      builder: (context, statusVM, _) {
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
                (dashVM.allMachines.length > 0
                    ? dashVM.allMachines.length
                    : 1)) *
            100;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 300,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FLEET INTELLIGENCE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey,
                          letterSpacing: 1.5,
                        ),
                      ),
                      _PulsingDot(color: Colors.blueAccent, size: 6),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      children: [
                        // Pie Chart Section
                        Expanded(
                          flex: 4,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 35,
                                  sections: [
                                    PieChartSectionData(
                                      value: active.toDouble(),
                                      color: Colors.greenAccent,
                                      radius: 8,
                                      showTitle: false,
                                    ),
                                    PieChartSectionData(
                                      value: error.toDouble(),
                                      color: Colors.redAccent,
                                      radius: 8,
                                      showTitle: false,
                                    ),
                                    PieChartSectionData(
                                      value: idle.toDouble(),
                                      color: Colors.orangeAccent,
                                      radius: 8,
                                      showTitle: false,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
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
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Stats Column Section
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildInsightRow(
                                'Active',
                                '$active',
                                Colors.greenAccent,
                              ),
                              _buildInsightRow(
                                'Critical',
                                '$error',
                                Colors.redAccent,
                              ),
                              _buildInsightRow(
                                'Reserve',
                                '${dashVM.summary?.totalEnergyGenerated.toStringAsFixed(0)}k',
                                Colors.amberAccent,
                              ),
                              _buildInsightRow(
                                'Util.',
                                '${utilization.toStringAsFixed(0)}%',
                                Colors.blueAccent,
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
      },
    );
  }

  Widget _buildSystemLogCard(bool isDark, List<Map<String, dynamic>> reports) {
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
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE PRODUCTION FEED',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.sensors_rounded,
                    size: 14,
                    color: Colors.greenAccent.withOpacity(0.7),
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
                    : ListView.builder(
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final r = reports[index];
                          final time = r['start_time'] != null
                              ? r['start_time']
                                    .toString()
                                    .split('T')
                                    .last
                                    .substring(0, 5)
                              : '--:--';

                          return _buildLogItem(
                            time,
                            'Machine #${r['machine_id']} recorded ${r['energy']} kWh',
                            index == 0 ? Colors.greenAccent : Colors.blueAccent,
                            isDark,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(String time, String message, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 2,
            height: 14,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusGrid(
    BuildContext context,
    DashboardViewModel dashVM,
    bool isDark,
  ) {
    final summary = dashVM.summary;
    if (summary == null) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 600
            ? 2
            : (constraints.maxWidth < 1200 ? 4 : 4);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth < 600
              ? 1.4
              : 3.2, // Much slimmer
          children: [
            _buildKPICard(
              'CONSUMED ENERGY',
              summary.totalEnergyGenerated.toStringAsFixed(1),
              'kWh',
              '↑ 12%',
              Icons.bolt_rounded,
              Colors.amber,
              isDark,
            ),
            _buildKPICard(
              'USED WATER',
              summary.totalWaterUsage.toStringAsFixed(0),
              'Litres',
              'Stable',
              Icons.water_drop_rounded,
              Colors.cyan,
              isDark,
            ),
            _buildKPICard(
              'LOADED MACHINES',
              '${summary.totalMachines}',
              'Units',
              '100% OK',
              Icons.precision_manufacturing_rounded,
              Colors.indigoAccent,
              isDark,
            ),
            _buildKPICard(
              'RECENT LOGS',
              '${summary.totalReports}',
              'Entry',
              'Real-time',
              Icons.analytics_rounded,
              Colors.purpleAccent,
              isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPICard(
    String label,
    String value,
    String unit,
    String trend,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 60, color: color.withOpacity(0.04)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trend,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(
    BuildContext context,
    DashboardViewModel viewModel,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRODUCTION ANALYTICS',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 1100;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 3 : 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: isWide ? 1.4 : 1.5,
              children: [
                _buildDeepChart(
                  context,
                  'ENERGY HARVEST RATE',
                  viewModel,
                  true,
                  isDark,
                  duration: viewModel.energyDuration,
                  onToggle: (days) => viewModel.toggleEnergyDuration(days),
                ),
                _buildDeepChart(
                  context,
                  'WATER CONSUMPTION',
                  viewModel,
                  false,
                  isDark,
                  duration: viewModel.waterDuration,
                  onToggle: (days) => viewModel.toggleWaterDuration(days),
                ),
                _buildSystemLogCard(
                  isDark,
                  viewModel.summary?.recentReports ?? [],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeepChart(
    BuildContext context,
    String title,
    DashboardViewModel viewModel,
    bool isEnergy,
    bool isDark, {
    required int duration,
    required Function(int) onToggle,
  }) {
    List<DailyGraphicData> data = isEnergy
        ? viewModel.energyData
        : viewModel.waterData;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton(
                      '7D',
                      duration == 7,
                      isDark,
                      () => onToggle(7),
                    ),
                    _buildToggleButton(
                      '30D',
                      duration == 30,
                      isDark,
                      () => onToggle(30),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildChart(data, isEnergy, isDark)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    bool isActive,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                    ? Colors.blueAccent.withOpacity(0.2)
                    : Colors.blueAccent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive
                ? (isDark ? Colors.blueAccent : Colors.white)
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildChart(List<DailyGraphicData> data, bool isEnergy, bool isDark) {
    if (data.isEmpty) return const SizedBox();

    // Determine min/max for scaling
    double maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    maxY = maxY * 1.2; // Add headroom

    if (isEnergy) {
      // Energy -> Line Chart
      return LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= data.length)
                    return const SizedBox();
                  if (index == 0 ||
                      index == data.length - 1 ||
                      index == data.length ~/ 2) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        data[index].date.substring(5),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                  .toList(),
              isCurved: true,
              color: Colors.orangeAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orangeAccent.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
    } else {
      // Water -> Bar Chart
      return BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= data.length)
                    return const SizedBox();
                  if (index == 0 ||
                      index == data.length - 1 ||
                      index == data.length ~/ 2) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        data[index].date.substring(5),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: Colors.cyanAccent,
                  width: 6,
                  borderRadius: BorderRadius.circular(2),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _buildMachinePulseSection(
    BuildContext context,
    DashboardViewModel dashVM,
    bool isDark, {
    bool hideHeader = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hideHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OPERATIONS PULSE',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Live machine telemetry and system status',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              _buildLiveBadge(),
            ],
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          height: 300, // Slightly reduced height
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.value(
                context: context,
                mobile: 1,
                tablet: 2,
                desktop: hideHeader ? 2 : 3, // Fewer columns if in side-HUD
              ),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
            ),
            physics: const BouncingScrollPhysics(),
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
        ),
      ],
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

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasAlert
                      ? Colors.redAccent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                  width: hasAlert ? 1.5 : 1,
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
                              Text(
                                machine.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  _PulsingDot(color: statusColor, size: 6),
                                  const SizedBox(width: 6),
                                  Text(
                                    status?.status.toUpperCase() ?? 'OFFLINE',
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: statusColor,
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
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
                ],
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 8, color: color.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 15,
                fontWeight: FontWeight.w800,
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
