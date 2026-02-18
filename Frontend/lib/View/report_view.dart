import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../Config/app_routes/app_route_names.dart';
import '../ViewModel/report_view_model.dart';
import '../Models/report.dart';
import '../Models/company.dart';
import '../Models/customer.dart';
import '../Models/machine.dart';
import '../Widget/main_layout.dart';
import '../Widget/responsive_helper.dart';
import '../Widget/editable_cell.dart';
import '../Widget/custom_snackbar.dart';
import '../Widget/error_popup.dart';
import '../Widget/translate_text.dart';
import '../Config/Themes/app_text_styles.dart';
import '../Widget/dropdown_field.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ReportViewModel>().fetchReports());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReportViewModel>();
    return MainLayout(
      title: 'Reports',
      showSidebar: false,
      backButtonRoute: RouteNames.dashboard,
      body: ResponsiveBuilder(
        mobile: (context) => _buildMobileLayout(context, viewModel),
        desktop: (context) => _buildDesktopLayout(context, viewModel),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ReportViewModel viewModel) {
    return Column(
      children: [
        _buildFilterSection(context, viewModel),
        Expanded(
          child: viewModel.isLoading && viewModel.reports.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _buildDataTable(context, viewModel),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ReportViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterSection(context, viewModel),
          const SizedBox(height: 16),
          Expanded(child: _buildDataTable(context, viewModel)),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, ReportViewModel viewModel) {
    bool isMobile = Responsive.isMobile(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 250,
                child: DropdownField<Machine>(
                  controller: viewModel.machineController,
                  items: viewModel.dropdownMachines,
                  itemLabel: (m) => m.name,
                  onSelected: (m) {
                    viewModel.selectedMachineId = m.id;
                    viewModel.fetchReports();
                  },
                  hintText: Translate.get(context, 'Select Machine'),
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 180,
                child: _buildDatePicker(
                  context,
                  "From Date",
                  viewModel.fromDate,
                  (d) => viewModel.setDateRange(d, viewModel.toDate),
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 180,
                child: _buildDatePicker(
                  context,
                  "To Date",
                  viewModel.toDate,
                  (d) => viewModel.setDateRange(viewModel.fromDate, d),
                ),
              ),
              if (!isMobile) ..._buildActionButtons(context, viewModel),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildActionButtons(context, viewModel),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    ReportViewModel viewModel,
  ) {
    return [
      IconButton(
        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
        onPressed: () => _showAddReportDialog(context, viewModel),
        tooltip: Translate.get(context, 'Add Manual'),
      ),
      IconButton(
        icon: const Icon(Icons.search, color: Colors.blue),
        onPressed: () => viewModel.fetchReports(),
        tooltip: Translate.get(context, 'Search'),
      ),
      IconButton(
        icon: const Icon(Icons.refresh, color: Colors.orange),
        onPressed: () => viewModel.clearFilters(),
        tooltip: Translate.get(context, 'Reset'),
      ),
      const SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: () async {
          final success = await viewModel.exportToExcel();
          if (success) {
            CustomSnackBar.show(context, Translate.get(context, 'Excel exported successfully'));
          } else {
            CustomSnackBar.show(context, Translate.get(context, 'Excel export cancelled'), isError: true);
          }
        },
        icon: const Icon(
          Icons.file_download_rounded,
          color: Colors.green,
          size: 20,
        ),
        label: Text(Translate.get(context, 'Excel')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.withOpacity(0.1),
          foregroundColor: Colors.green,
          elevation: 0,
        ),
      ),
      const SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: () async {
          final success = await viewModel.exportToPDF();
          if (success) {
            CustomSnackBar.show(context, Translate.get(context, 'PDF exported successfully'));
          } else {
            CustomSnackBar.show(context, Translate.get(context, 'PDF export cancelled'), isError: true);
          }
        },
        icon: const Icon(
          Icons.picture_as_pdf_rounded,
          color: Colors.red,
          size: 20,
        ),
        label: Text(Translate.get(context, 'PDF')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.1),
          foregroundColor: Colors.red,
          elevation: 0,
        ),
      ),
      const SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: () async {
          final success = await viewModel.printReports();
          if (success) {
            CustomSnackBar.show(context, Translate.get(context, 'Report printed successfully'));
          } else {
            CustomSnackBar.show(context, Translate.get(context, 'Print cancelled'), isError: true);
          }
        },
        icon: const Icon(Icons.print_rounded, color: Colors.blue, size: 20),
        label: Text(Translate.get(context, 'Print')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.withOpacity(0.1),
          foregroundColor: Colors.blue,
          elevation: 0,
        ),
      ),
    ];
  }

  Widget _buildDatePicker(
    BuildContext context,
    String label,
    DateTime? selectedDate,
    Function(DateTime?) onSelected,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) onSelected(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(selectedDate)
                  : Translate.get(context, label),
              style: TextStyle(
                color: selectedDate != null ? Colors.black : Colors.grey,
                fontSize: 14,
              ),
            ),
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, ReportViewModel viewModel) {
    final List<String> columnHeaders = [
      'ID',
      'Machine',
      'Customer',
      'Start Time',
      'End Time',
      'Duration',
      'AreaCovered',
      'Energy',
      'Water',
    ];

    bool isMobile = Responsive.isMobile(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double rowHeight = 55;
    List<double> columnWidths;

    if (isMobile) {
      columnWidths = [
        60, // ID
        120, // Machine
        120, // Customer
        120, // Start Time
        120, // End Time
        100, // Duration
        120, // AreaCovered
        120, // Energy
        120, // Water
      ];
    } else {
      columnWidths = [
        screenWidth * 0.04,
        screenWidth * 0.12,
        screenWidth * 0.12,
        screenWidth * 0.12,
        screenWidth * 0.12,
        screenWidth * 0.08,
        screenWidth * 0.12,
        screenWidth * 0.12,
        screenWidth * 0.12,
      ];
    }

    double totalWidth = columnWidths.reduce((a, b) => a + b);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: totalWidth,
        child: Column(
          children: [
            // Header
            Row(
              children: List.generate(columnHeaders.length, (index) {
                return Container(
                  width: columnWidths[index],
                  height: 45,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    border: Border.all(color: Colors.black, width: 0.8),
                  ),
                  child: Text(
                    Translate.get(context, columnHeaders[index]),
                    style: AppTextStyles.defaultHeader1(),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ),

            // Rows
            Expanded(
              child: ListView.builder(
                itemCount: viewModel.reports.length,
                itemBuilder: (context, rowIndex) {
                  final report = viewModel.reports[rowIndex];

                  return Row(
                    children: [
                      // ID
                      _internalBuildCell(
                        width: columnWidths[0],
                        text: report.id.toString(),
                        height: rowHeight,
                      ),

                      // Machine
                      _internalBuildCell(
                        width: columnWidths[1],
                        text: report.machineName ?? '',
                        height: rowHeight,
                      ),

                      // Customer
                      _internalBuildCell(
                        width: columnWidths[2],
                        text: report.customerName ?? '',
                        height: rowHeight,
                      ),

                      // Start Time
                      _internalBuildCell(
                        width: columnWidths[3],
                        text: report.startTime != null
                            ? DateFormat(
                                'MM-dd HH:mm',
                              ).format(report.startTime!)
                            : '',
                        height: rowHeight,
                      ),

                      // End Time
                      _internalBuildCell(
                        width: columnWidths[4],
                        text: report.endTime != null
                            ? DateFormat('MM-dd HH:mm').format(report.endTime!)
                            : '',
                        height: rowHeight,
                      ),

                      // Duration
                      _internalBuildCell(
                        width: columnWidths[5],
                        text: report.duration ?? '',
                        height: rowHeight,
                      ),

                      // AreaCovered
                      _internalBuildCell(
                        width: columnWidths[6],
                        text: report.areaCovered ?? '',
                        height: rowHeight,
                      ),

                      // Energy
                      _internalBuildCell(
                        width: columnWidths[7],
                        text: report.energyConsumption ?? '',
                        height: rowHeight,
                      ),

                      // Water
                      _internalBuildCell(
                        width: columnWidths[8],
                        text: report.waterUsage ?? '',
                        height: rowHeight,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _internalBuildCell({
    required double width,
    required String text,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showAddReportDialog(BuildContext context, ReportViewModel viewModel) {
    final TextEditingController dialogMachineController =
        TextEditingController();
    int? selectedMachineId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String duration = "";
            if (viewModel.manualStartTime != null &&
                viewModel.manualEndTime != null) {
              duration = viewModel.calculateDuration(
                viewModel.manualStartTime!,
                viewModel.manualEndTime!,
              );
            }

            return AlertDialog(
              title: Text(Translate.get(context, 'Add Manual Report')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownField<Machine>(
                      controller: dialogMachineController,
                      items: viewModel.dropdownMachines,
                      itemLabel: (m) => m.name,
                      onSelected: (m) => selectedMachineId = m.id,
                      hintText: Translate.get(context, 'Select Machine'),
                    ),
                    const SizedBox(height: 16),
                    _buildTimePicker(
                      context,
                      "Start Time",
                      viewModel.manualStartTime,
                      (dt) =>
                          setDialogState(() => viewModel.manualStartTime = dt),
                    ),
                    const SizedBox(height: 16),
                    _buildTimePicker(
                      context,
                      "End Time",
                      viewModel.manualEndTime,
                      (dt) =>
                          setDialogState(() => viewModel.manualEndTime = dt),
                    ),
                    if (duration.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        "${Translate.get(context, 'Duration')}: $duration",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: viewModel.energyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Translate.get(context, 'Energy Consumption'),
                        suffixText: 'kWh',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: viewModel.areaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Translate.get(context, 'Area Covered'),
                        suffixText: 'm²',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: viewModel.waterController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Translate.get(context, 'Water Usage'),
                        suffixText: 'L',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    viewModel.clearManualControllers();
                    Navigator.pop(context);
                  },
                  child: Text(Translate.get(context, 'Cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedMachineId == null) {
                      CustomSnackBar.show(
                        context,
                        'Please select a machine',
                        isError: true,
                      );
                      return;
                    }
                    final success = await viewModel.saveManualReport(
                      selectedMachineId!,
                    );
                    if (success) {
                      Navigator.pop(context);
                      CustomSnackBar.show(context, 'Report added successfully');
                    } else if (viewModel.errorMessage != null) {
                      CustomSnackBar.show(context, viewModel.errorMessage!);
                    }
                  },
                  child: Text(Translate.get(context, 'Save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimePicker(
    BuildContext context,
    String label,
    DateTime? selectedDateTime,
    Function(DateTime) onSelected,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDateTime ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(
              selectedDateTime ?? DateTime.now(),
            ),
          );
          if (time != null) {
            onSelected(
              DateTime(date.year, date.month, date.day, time.hour, time.minute),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDateTime != null
                  ? DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime)
                  : Translate.get(context, label),
              style: TextStyle(
                color: selectedDateTime != null ? Colors.black : Colors.grey,
                fontSize: 14,
              ),
            ),
            const Icon(Icons.access_time, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
