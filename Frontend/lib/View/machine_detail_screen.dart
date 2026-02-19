import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../Models/machine.dart';
import '../Models/machine_status.dart';
import '../Models/report.dart';
import '../ViewModel/machine_status_view_model.dart';
import '../ViewModel/dashboard_view_model.dart';
import '../Widget/main_layout.dart';
import '../Config/Themes/theme_view_model.dart';
import '../Services/machine_service.dart';

class MachineDetailScreen extends StatefulWidget {
  final Machine machine;

  const MachineDetailScreen({super.key, required this.machine});

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Connect to WebSocket for real-time updates when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MachineStatusViewModel>(context, listen: false)
          .connectToMachine(widget.machine.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = Provider.of<ThemeViewModel>(context);
    final isDark = themeVM.themeMode == ThemeMode.dark;

    return MainLayout(
      title: 'Machine Intelligence',
      showSidebar: false,
      body: Consumer2<MachineStatusViewModel, DashboardViewModel>(
        builder: (context, statusVM, dashVM, child) {
          final status = statusVM.liveStatuses[widget.machine.id];
          final reports = dashVM.machineReports;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, status, isDark),
                const SizedBox(height: 24),
                _buildTelemetryGrid(context, status, isDark),
                const SizedBox(height: 32),
                _buildPerformanceGraph(context, reports, isDark),
                const SizedBox(height: 32),
                _buildRecentEvents(context, isDark),
                const SizedBox(height: 32),
                _buildCommandCenter(context, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MachineStatus? status, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          _buildMachineAvatar(isDark),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.machine.name,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Serial: ${widget.machine.serialNo}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCredentialTag(
                      'MQTT USER',
                      widget.machine.mqttUsername ?? '---',
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildCredentialTag(
                      'MQTT PASS',
                      widget.machine.mqttPassword ?? '---',
                      isDark,
                      isPassword: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildLiveStatusBadge(status),
        ],
      ),
    );
  }

  Widget _buildCredentialTag(
    String label,
    String value,
    bool isDark, {
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 7,
              fontWeight: FontWeight.w900,
              color: Colors.blueAccent,
            ),
          ),
          Text(
            isPassword ? '••••••••' : value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineAvatar(bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: widget.machine.image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(
                base64Decode(widget.machine.image!),
                fit: BoxFit.cover,
              ),
            )
          : Icon(
              Icons.precision_manufacturing_rounded,
              size: 40,
              color: Colors.blueAccent.withOpacity(0.5),
            ),
    );
  }

  Widget _buildLiveStatusBadge(MachineStatus? status) {
    final isMachineOnline = widget.machine.isOnline == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (isMachineOnline ? Colors.greenAccent : Colors.redAccent)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: (isMachineOnline ? Colors.greenAccent : Colors.redAccent)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(
            color: isMachineOnline ? Colors.greenAccent : Colors.redAccent,
            size: 10,
          ),
          const SizedBox(width: 10),
          Text(
            isMachineOnline ? 'SYSTEM ONLINE' : 'SYSTEM OFFLINE',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isMachineOnline ? Colors.greenAccent : Colors.redAccent,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid(
    BuildContext context,
    MachineStatus? status,
    bool isDark,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width < 900 ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildDetailTile(
          'BATTERY LEVEL',
          status != null ? '${status.batteryLevel.toStringAsFixed(1)}%' : '--',
          Icons.battery_charging_full_rounded,
          Colors.greenAccent,
        ),
        _buildDetailTile(
          'WATER RESERVE',
          status != null ? '${status.waterLevel.toStringAsFixed(1)}%' : '--',
          Icons.water_drop_rounded,
          Colors.cyanAccent,
        ),
        _buildDetailTile(
          'BRUSH POWER',
          status != null ? '${status.brushRPM} RPM' : '--',
          Icons.sync_rounded,
          Colors.orangeAccent,
        ),
        _buildDetailTile(
          'CORE TEMP',
          status != null ? '${status.brushTemp.toStringAsFixed(1)}°C' : '--',
          Icons.thermostat_rounded,
          Colors.amberAccent,
        ),
        _buildDetailTile(
          'MOVEMENT SPEED',
          status != null ? '${status.speed.toStringAsFixed(2)} m/s' : '--',
          Icons.speed_rounded,
          Colors.indigoAccent,
        ),
        _buildDetailTile(
          'OPERATIONAL MODE',
          status?.mode ?? 'Auto',
          Icons.settings_rounded,
          Colors.blueAccent,
        ),
        _buildDetailTile(
          'BATT VOLTAGE',
          status != null
              ? '${status.batteryVoltage.toStringAsFixed(1)}V'
              : '--',
          Icons.bolt_rounded,
          Colors.yellowAccent,
        ),
        _buildDetailTile(
          'TOTAL CYCLES',
          status != null ? '${status.totalCycles}' : '--',
          Icons.loop_rounded,
          Colors.purpleAccent,
        ),
      ],
    );
  }

  Widget _buildDetailTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceGraph(
    BuildContext context,
    List<Report> reports,
    bool isDark,
  ) {
    // Parse energyConsumption strings (e.g., "5.2 kWh") into doubles
    final List<FlSpot> spots = reports.isEmpty
        ? [
            const FlSpot(0, 0),
            const FlSpot(1, 2),
            const FlSpot(2, 1),
            const FlSpot(3, 4),
          ]
        : reports.asMap().entries.map((e) {
            final valStr = e.value.energyConsumption?.split(' ')[0] ?? '0';
            final val = double.tryParse(valStr) ?? 0.0;
            return FlSpot(e.key.toDouble(), val);
          }).toList();

    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ENERGY PERFORMANCE LOG',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              _buildGraphLegend('Energy (kWh)', Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Colors.orangeAccent, Colors.redAccent],
                    ),
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.orangeAccent.withOpacity(0.2),
                          Colors.orangeAccent.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentEvents(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CRITICAL EVENT LOG',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        _buildEventItem('System Initialization', '10:00 AM', Colors.blueAccent),
        _buildEventItem(
          'Routine Cleaning Cycle Completed',
          '10:45 AM',
          Colors.greenAccent,
        ),
        _buildEventItem(
          'Obstacle Detected (Soft Resolution)',
          '11:15 AM',
          Colors.orangeAccent,
        ),
      ],
    );
  }

  Widget _buildEventItem(String title, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            time,
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandCenter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.blue.withOpacity(0.05)
            : Colors.blue.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INTELLIGENT COMMAND CENTER',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.blueAccent,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildControlButton(
                context,
                'START CLEANING',
                Icons.play_arrow_rounded,
                Colors.greenAccent,
                "start",
              ),
              const SizedBox(width: 12),
              _buildControlButton(
                context,
                'STOP MACHINE',
                Icons.stop_rounded,
                Colors.redAccent,
                "stop",
              ),
              const SizedBox(width: 12),
              _buildControlButton(
                context,
                'RETURN TO DOCK',
                Icons.home_rounded,
                Colors.amberAccent,
                "dock",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String cmd,
  ) {
    return Expanded(
      child: InkWell(
                onTap: () async {
          try {
            await MachineService.sendCommand(widget.machine.id, {"command": cmd});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Command "$label" dispatched to MQTT broker'),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send command: $e'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
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
  const _PulsingDot({required this.color, required this.size});

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
