import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Config/app_routes/app_route_names.dart';
import '../ViewModel/machine_view_model.dart';
import '../ViewModel/global_state.dart';
import '../Models/machine.dart';
import '../Models/company.dart';
import '../Models/customer.dart';
import '../Widget/main_layout.dart';
import '../Widget/responsive_helper.dart';
import '../Widget/editable_cell.dart';
import '../Widget/custom_snackbar.dart';
import '../Widget/error_popup.dart';
import '../Widget/translate_text.dart';
import '../Config/Themes/app_text_styles.dart';
import '../Widget/dropdown_field.dart';
import 'dart:io'; // For File
import 'dart:convert'; // For base64Decode

class MachineListScreen extends StatefulWidget {
  const MachineListScreen({super.key});

  @override
  State<MachineListScreen> createState() => _MachineListScreenState();
}

class _MachineListScreenState extends State<MachineListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<MachineViewModel>().fetchMachines());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MachineViewModel>();
    return MainLayout(
      title: 'Machines',
      showSidebar: false,
      backButtonRoute: RouteNames.dashboard,
      body: ResponsiveBuilder(
        mobile: (context) => _buildMobileLayout(context, viewModel),
        desktop: (context) => _buildDesktopLayout(context, viewModel),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, MachineViewModel viewModel) {
    return Column(
      children: [
        _buildSearchField(context),
        Expanded(
          child: viewModel.isLoading && viewModel.machines.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _buildDataTable(context, viewModel),
        ),
        _buildBottomActions(context, viewModel),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, MachineViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 400, child: _buildSearchField(context)),
              const SizedBox(width: 16),
              _buildDesktopActions(context, viewModel),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildDataTable(context, viewModel)),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: Translate.get(context, 'Search Machines...'),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) => context.read<MachineViewModel>().search(value),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, MachineViewModel viewModel) {
    final globalState = Provider.of<GlobalState>(context);
    if (globalState.isCustomerUser && globalState.isAdmin) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showMachineDialog(context, null),
            tooltip: Translate.get(context, 'Add'),
          ),
          IconButton(
            icon: Icon(
              viewModel.isEditMode ? Icons.edit_off : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () => viewModel.toggleEditMode(),
            tooltip: Translate.get(context, 'Edit'),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () => _showSaveConfirmation(context, viewModel),
            tooltip: Translate.get(context, 'Save'),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => _showDeleteConfirmation(context, viewModel),
            tooltip: Translate.get(context, 'Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActions(
    BuildContext context,
    MachineViewModel viewModel,
  ) {
    final globalState = Provider.of<GlobalState>(context);
    if (globalState.isCustomerUser && globalState.isAdmin) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showMachineDialog(context, null),
          icon: const Icon(Icons.add),
          label: Text(Translate.get(context, 'Add')),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => viewModel.toggleEditMode(),
          icon: Icon(viewModel.isEditMode ? Icons.edit_off : Icons.edit),
          label: Text(
            Translate.get(context, viewModel.isEditMode ? 'Stop Edit' : 'Edit'),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _showSaveConfirmation(context, viewModel),
          icon: const Icon(Icons.save),
          label: Text(Translate.get(context, 'Save')),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _showDeleteConfirmation(context, viewModel),
          icon: const Icon(Icons.delete),
          style: ElevatedButton.styleFrom(),
          label: Text(Translate.get(context, 'Delete')),
        ),
      ],
    );
  }

  Widget _buildDataTable(BuildContext context, MachineViewModel viewModel) {
    final List<String> columnHeaders = [
      'Select',
      'Company',
      'Customer',
      'Name',
      'Serial No',
      'Description',
      'MQTT User',
      'MQTT Pass',
      'Image',
    ];

    bool isMobile = Responsive.isMobile(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double rowHeight = 55;
    List<double> columnWidths;

    if (isMobile) {
      columnWidths = [
        50, // Select
        120, // Company
        120, // Customer
        150, // Name
        120, // Serial No
        200, // Description
        120, // MQTT User
        120, // MQTT Pass
        80, // Image
      ];
    } else {
      columnWidths = [
        screenWidth * 0.05,
        screenWidth * 0.15, // Company
        screenWidth * 0.10, // Customer
        screenWidth * 0.10, // Name
        screenWidth * 0.08, // Serial No
        screenWidth * 0.15, // Description
        screenWidth * 0.10, // MQTT User
        screenWidth * 0.10, // MQTT Pass
        screenWidth * 0.10, // Image
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
                itemCount: viewModel.machines.length,
                itemBuilder: (context, rowIndex) {
                  final machine = viewModel.machines[rowIndex];
                  final isSelected = viewModel.selectedIds.contains(machine.id);

                  return Row(
                    children: [
                      // Checkbox
                      Container(
                        width: columnWidths[0],
                        height: rowHeight,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 0.8),
                        ),
                        alignment: Alignment.center,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (val) =>
                              viewModel.toggleSelection(machine.id),
                        ),
                      ),

                      // Company
                      viewModel.isEditMode
                          ? Container(
                              width: columnWidths[1],
                              height: rowHeight,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black,
                                  width: 0.8,
                                ),
                              ),
                              child: DropdownButton<int>(
                                value:
                                    viewModel.dropdownCompanies.any(
                                      (c) => c.id == machine.companyId,
                                    )
                                    ? machine.companyId
                                    : null,
                                items: viewModel.dropdownCompanies.map((
                                  company,
                                ) {
                                  return DropdownMenuItem<int>(
                                    value: company.id,
                                    child: Text(
                                      company.name ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  viewModel.updateLocal(
                                    machine.copyWith(companyId: val),
                                  );
                                },
                                underline: SizedBox(),
                                isExpanded: true,
                              ),
                            )
                          : _buildCell(
                              width: columnWidths[1],
                              text:
                                  viewModel.dropdownCompanies
                                      .firstWhere(
                                        (c) => c.id == machine.companyId,
                                        orElse: () => Company(id: 0, name: '-'),
                                      )
                                      .name ??
                                  '-',
                              height: rowHeight,
                              isEditMode: viewModel.isEditMode,
                            ),
                      // Customer
                      viewModel.isEditMode
                          ? Container(
                              width: columnWidths[2],
                              height: rowHeight,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black,
                                  width: 0.8,
                                ),
                              ),
                              child: DropdownButton<int>(
                                value:
                                    viewModel.dropdownCustomers.any(
                                      (c) => c.id == machine.customerId,
                                    )
                                    ? machine.customerId
                                    : null,
                                items: viewModel.dropdownCustomers.map((
                                  customer,
                                ) {
                                  return DropdownMenuItem<int>(
                                    value: customer.id,
                                    child: Text(
                                      customer.name ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  viewModel.updateLocal(
                                    machine.copyWith(customerId: val),
                                  );
                                },
                                underline: SizedBox(),
                                isExpanded: true,
                              ),
                            )
                          : _buildCell(
                              width: columnWidths[2],
                              text:
                                  viewModel.dropdownCustomers
                                      .firstWhere(
                                        (c) => c.id == machine.customerId,
                                        orElse: () =>
                                            Customer(id: 0, name: '-'),
                                      )
                                      .name ??
                                  '-',
                              height: rowHeight,
                              isEditMode: viewModel.isEditMode,
                            ),

                      // Name
                      viewModel.isEditMode
                          ? EditableCell(
                              width: columnWidths[3],
                              value: machine.name,
                              height: rowHeight,
                              onChanged: (val) => viewModel.updateLocal(
                                machine.copyWith(name: val),
                              ),
                            )
                          : _buildCell(
                              width: columnWidths[3],
                              text: machine.name,
                              height: rowHeight,
                              isEditMode: viewModel.isEditMode,
                            ),

                      // Serial No
                      viewModel.isEditMode
                          ? EditableCell(
                              width: columnWidths[4],
                              value: machine.serialNo,
                              height: rowHeight,
                              onChanged: (val) => viewModel.updateLocal(
                                machine.copyWith(serialNo: val),
                              ),
                            )
                          : _buildCell(
                              width: columnWidths[4],
                              text: machine.serialNo,
                              height: rowHeight,
                              isEditMode: viewModel.isEditMode,
                            ),

                      // Description
                      viewModel.isEditMode
                          ? EditableCell(
                              width: columnWidths[5],
                              value: machine.description ?? '',
                              height: rowHeight,
                              onChanged: (val) => viewModel.updateLocal(
                                machine.copyWith(description: val),
                              ),
                            )
                          : _buildCell(
                              width: columnWidths[5],
                              text: machine.description ?? '',
                              height: rowHeight,
                              isEditMode: viewModel.isEditMode,
                            ),

                      // MQTT User
                      _buildCell(
                        width: columnWidths[6],
                        text: (viewModel.globalState.isCompanyEmployee && viewModel.globalState.isAdmin)
                            ? (machine.mqttUsername ?? '-')
                            : '****',
                        height: rowHeight,
                        isEditMode: false, // Keep it read-only in table
                      ),

                      // MQTT Pass
                      _buildCell(
                        width: columnWidths[7],
                        text: (viewModel.globalState.isCompanyEmployee && viewModel.globalState.isAdmin)
                            ? (machine.mqttPassword ?? '-')
                            : '****',
                        height: rowHeight,
                        isEditMode: false, // Keep it read-only in table
                      ),

                      // Image
                      _buildImageCell(
                        context: context,
                        width: columnWidths[8],
                        height: rowHeight,
                        base64Image: machine.image,
                        isEditable: viewModel.isEditMode,
                        onTap: () async {
                          if (viewModel.isEditMode) {
                            File? picked = await viewModel.chooseImage();
                            if (picked != null) {
                              String base64 = await viewModel.fileToBase64(
                                picked,
                              );
                              viewModel.updateLocal(
                                machine.copyWith(image: base64),
                              );
                            }
                          }
                        },
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

  Widget _buildCell({
    required double width,
    required String text,
    required double height,
    required bool isEditMode,
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
        style: isEditMode
            ? AppTextStyles.editableBody1()
            : Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showMachineDialog(BuildContext context, Machine? machine) {
    final viewModel = context.read<MachineViewModel>();

    // Clear or populate controllers
    if (machine == null) {
      viewModel.clearControllers();
    } else {
      viewModel.populateControllers(machine);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            Translate.get(
              context,
              machine == null ? 'Add Machine' : 'Edit Machine',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          content: Consumer<MachineViewModel>(
            builder: (context, vm, child) => Container(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Dropdown (Searchable)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              Translate.get(context, 'Company:'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(
                            child: DropdownField<Company>(
                              controller: vm.companyController,
                              items: vm.dropdownCompanies,
                              itemLabel: (c) => c.name ?? '',
                              onSelected: (c) {
                                vm.selectedCompanyId = c.id;
                              },
                              hintText: Translate.get(
                                context,
                                'Choose Company',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Customer Dropdown (Searchable)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              Translate.get(context, 'Customer:'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(
                            child: DropdownField<Customer>(
                              controller: vm.customerController,
                              items: vm.dropdownCustomers,
                              itemLabel: (c) => c.name ?? '',
                              onSelected: (c) {
                                vm.selectedCustomerId = c.id;
                              },
                              hintText: Translate.get(
                                context,
                                'Choose Customer',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Machine Name
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              Translate.get(context, 'Machine Name:'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: TextField(
                                controller: vm.machineNameController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                                style: AppTextStyles.bodyText(Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Serial No
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              Translate.get(context, 'Serial No:'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: TextField(
                                controller: vm.serialController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                                style: AppTextStyles.bodyText(Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // MQTT Username (Only for Company Admins)
                    if (vm.globalState.isCompanyEmployee && vm.globalState.isAdmin)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                Translate.get(context, 'MQTT Username:'),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: TextField(
                                  controller: vm.mqttUsernameController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  style: AppTextStyles.bodyText(Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // MQTT Password (Only for Company Admins)
                    if (vm.globalState.isCompanyEmployee && vm.globalState.isAdmin)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                Translate.get(context, 'MQTT Password:'),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: TextField(
                                  controller: vm.mqttPasswordController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  style: AppTextStyles.bodyText(Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              Translate.get(context, 'Description:'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: TextField(
                                controller: vm.descriptionController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                                style: AppTextStyles.bodyText(Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Image Selection
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              Translate.get(context, 'Image:'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(child: _buildImagePicker(context, vm)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                Translate.get(context, 'Cancel'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (viewModel.machineNameController.text.isEmpty ||
                    viewModel.serialController.text.isEmpty) {
                  CustomSnackBar.show(
                    context,
                    "Name and Serial No are required",
                    isError: true,
                  );
                  return;
                }

                final newMachine = Machine(
                  id: machine?.id ?? 0,
                  name: viewModel.machineNameController.text,
                  serialNo: viewModel.serialController.text,
                  description: viewModel.descriptionController.text,
                  companyId: viewModel.selectedCompanyId,
                  customerId: viewModel.selectedCustomerId,
                  image: viewModel.selectedImageBase64,
                  mqttUsername: viewModel.mqttUsernameController.text,
                  mqttPassword: viewModel.mqttPasswordController.text,
                );

                try {
                  if (machine == null) {
                    await viewModel.addMachine(newMachine);
                    CustomSnackBar.show(context, "Machine added successfully");
                  } else {
                    await viewModel.updateMachine(machine.id, newMachine);
                    CustomSnackBar.show(
                      context,
                      "Machine updated successfully",
                    );
                  }
                  Navigator.pop(context);
                } catch (e) {
                  CustomSnackBar.show(context, e.toString(), isError: true);
                }
              },
              child: Text(
                Translate.get(context, 'Save'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    MachineViewModel viewModel,
  ) {
    if (viewModel.selectedIds.isEmpty) {
      CustomSnackBar.show(context, "No items selected", isError: true);
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translate.get(context, 'Confirm Delete')),
        content: Text(
          Translate.get(
            context,
            'Delete ${viewModel.selectedIds.length} items?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translate.get(context, 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await viewModel.deleteSelected();
                CustomSnackBar.show(context, "Deleted successfully");
              } catch (e) {
                CustomSnackBar.show(
                  context,
                  "Failed to delete: $e",
                  isError: true,
                );
              }
            },
            child: Text(Translate.get(context, 'Delete')),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context, MachineViewModel viewModel) {
    String displayName = viewModel.selectedImageBase64 == null
        ? "Choose Image"
        : "Image Selected";

    return InkWell(
      onTap: () => viewModel.pickImage(),
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(width: 0.5, color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            viewModel.selectedImageBase64 == null
                ? const Icon(Icons.image, size: 30, color: Colors.grey)
                : Image.memory(
                    base64Decode(viewModel.selectedImageBase64!),
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                Translate.get(context, displayName),
                style: AppTextStyles.bodyText(Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (viewModel.selectedImageBase64 != null)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                onPressed: () => viewModel.clearImage(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCell({
    required BuildContext context,
    required double width,
    required double height,
    required String? base64Image,
    required bool isEditable,
    required VoidCallback onTap,
  }) {
    Widget imageWidget;

    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Image);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      } catch (e) {
        imageWidget = const Icon(Icons.broken_image, color: Colors.grey);
      }
    } else {
      imageWidget = const SizedBox();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.8),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: height - 10,
              height: height - 10,
              child: imageWidget,
            ),
            if (isEditable)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _showSaveConfirmation(BuildContext context, MachineViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            Translate.get(context, 'Confirmation'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            Translate.get(
              context,
              'Are you sure you want to save the changes?',
            ),
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(Translate.get(context, 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await viewModel.saveChanges();
                  if (context.mounted) {
                    CustomAlertDialog.show(
                      context: context,
                      title: 'Success',
                      content: 'Changes saved successfully!',
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    CustomAlertDialog.show(
                      context: context,
                      title: 'Error',
                      content: e.toString(),
                    );
                  }
                }
              },
              child: Text(Translate.get(context, 'Confirm')),
            ),
          ],
        );
      },
    );
  }
}
