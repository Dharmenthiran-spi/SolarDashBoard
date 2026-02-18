import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../Config/app_routes/app_route_names.dart';
import '../ViewModel/company_view_model.dart';
import '../Models/company.dart';
import '../Models/company_employee.dart';
import '../View/company_employee_view.dart';
import '../Widget/responsive_helper.dart';
import '../Widget/editable_cell.dart';
import '../Widget/custom_snackbar.dart';
import '../Widget/error_popup.dart';
import '../Widget/translate_text.dart';
import '../Config/Themes/app_text_styles.dart';
import '../Widget/simple_map_picker.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert'; // For base64Decode

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CompanyViewModel>().fetchCompanies());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CompanyViewModel>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(Translate.get(context, 'Company Management')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(RouteNames.settings),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: Translate.get(context, 'Company')),
              Tab(text: Translate.get(context, 'Employees')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ResponsiveBuilder(
              mobile: (context) => _buildMobileLayout(context, viewModel),
              desktop: (context) => _buildDesktopLayout(context, viewModel),
            ),
            const CompanyEmployeeView(wrapWithLayout: false),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, CompanyViewModel viewModel) {
    return Column(
      children: [
        _buildSearchField(context),
        Expanded(
          child: viewModel.isLoading && viewModel.companies.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _buildDataTable(context, viewModel),
        ),
        _buildBottomActions(context, viewModel),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, CompanyViewModel viewModel) {
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
          hintText: Translate.get(context, 'Search Companies...'),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) => context.read<CompanyViewModel>().search(value),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, CompanyViewModel viewModel) {
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
            onPressed: () => _showCompanyDialog(context, null),
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
    CompanyViewModel viewModel,
  ) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showCompanyDialog(context, null),
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
          label: Text(Translate.get(context, 'Delete')),
        ),
      ],
    );
  }

  Widget _buildDataTable(BuildContext context, CompanyViewModel viewModel) {
    final List<String> columnHeaders = [
      'Select',
      'ID',
      'Name',
      'Address',
      'Location',
      'Image',
    ];

    bool isMobile = Responsive.isMobile(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double rowHeight = 55;
    List<double> columnWidths;

    if (isMobile) {
      columnWidths = [
        50, // Select
        80, // ID
        200, // Name
        250, // Address
        200, // Location
        80, // Image
      ];
    } else {
      columnWidths = [
        screenWidth * 0.05,
        screenWidth * 0.10,
        screenWidth * 0.20,
        screenWidth * 0.30,
        screenWidth * 0.25,
        screenWidth * 0.10,
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
                itemCount: viewModel.companies.length,
                itemBuilder: (context, rowIndex) {
                  final company = viewModel.companies[rowIndex];
                  final isSelected = viewModel.selectedIds.contains(company.id);

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
                              viewModel.toggleSelection(company.id),
                        ),
                      ),

                      // ID
                      _buildCell(
                        width: columnWidths[1],
                        text: company.id.toString(),
                        height: rowHeight,
                        isEditMode: viewModel.isEditMode,
                      ),

                      viewModel.isEditMode
                          ? EditableCell(
                              width: columnWidths[2],
                              value: company.name,
                              height: rowHeight,
                              onChanged: (val) => viewModel.updateLocal(
                                company.copyWith(name: val),
                              ),
                            )
                          : _buildCell(
                              width: columnWidths[2],
                              text: company.name,
                              height: rowHeight,
                              isEditMode: viewModel.isEditMode,
                            ),
                      // Address
                      viewModel.isEditMode
                          ? EditableCell(
                              width: columnWidths[3],
                              value: company.address ?? '',
                              height: rowHeight,
                              onChanged: (val) => viewModel.updateLocal(
                                company.copyWith(address: val),
                              ),
                            )
                          : _buildCell(
                              width: columnWidths[3],
                              text: company.address ?? '',
                              height: rowHeight,
                              isEditMode: viewModel.isEditMode,
                            ),

                      // Location
                      viewModel.isEditMode
                          ? Container(
                              width: columnWidths[4],
                              height: rowHeight,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: EditableCell(
                                      value: company.location ?? '',
                                      width: double.infinity,
                                      height: rowHeight,
                                      onChanged: (val) => viewModel.updateLocal(
                                        company.copyWith(location: val),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.map, size: 16),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SimpleMapPicker(
                                            onLocationSelected: (_) {},
                                          ),
                                        ),
                                      );
                                      if (result != null && result is Map) {
                                        final lat = result['latitude'];
                                        final lng = result['longitude'];
                                        viewModel.updateLocal(
                                          company.copyWith(
                                            location: "$lat, $lng",
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            )
                          : _buildCell(
                              width: columnWidths[4],
                              text: company.location ?? '',
                              height: rowHeight,
                              isEditMode: viewModel.isEditMode,
                            ),
                      _buildImageCell(
                        context: context,
                        width: columnWidths[5],
                        height: rowHeight,
                        base64Image: company.image,
                        isEditable: viewModel.isEditMode,
                        onTap: () async {
                          if (viewModel.isEditMode) {
                            File? picked = await viewModel.chooseImage();
                            if (picked != null) {
                              String base64 = await viewModel.fileToBase64(
                                picked,
                              );
                              viewModel.updateLocal(
                                company.copyWith(image: base64),
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
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
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
      imageWidget = const Icon(Icons.image_not_supported, color: Colors.grey);
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

  void _showCompanyDialog(BuildContext context, Company? company) {
    final viewModel = context.read<CompanyViewModel>();

    // Clear or populate controllers
    // if (company == null) {
    //   viewModel.clearControllers();
    // } else {
    //   viewModel.populateControllers(company);
    // }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            Translate.get(
              context,
              company == null ? 'Add Company' : 'Edit Company',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          content: Consumer<CompanyViewModel>(
            builder: (context, vm, child) => Container(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Name
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              Translate.get(context, 'Company Name:'),
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
                                controller: vm.companyNameController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                style: AppTextStyles.bodyText(Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Address
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              Translate.get(context, 'Address:'),
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
                                controller: vm.addressController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                style: AppTextStyles.bodyText(Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Location
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              Translate.get(context, 'Location:'),
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
                                controller: vm.locationController,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.location_on,
                                      color: Colors.blueAccent,
                                    ),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SimpleMapPicker(
                                            onLocationSelected: (latlng) {},
                                          ),
                                        ),
                                      );

                                      if (result != null && result is Map) {
                                        final lat = result['latitude'];
                                        final lng = result['longitude'];
                                        final address = result['address'] ?? '';

                                        vm.addressController.text = address;
                                        vm.locationController.text =
                                            "$lat, $lng";
                                      }
                                    },
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
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                Translate.get(context, 'Cancel'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (viewModel.companyNameController.text.isEmpty) return;

                final newCompany = Company(
                  id: company?.id ?? 0,
                  name: viewModel.companyNameController.text,
                  address: viewModel.addressController.text,
                  location: viewModel.locationController.text,
                  image: viewModel.selectedImageBase64,
                );

                try {
                  if (company == null) {
                    await viewModel.addCompany(newCompany);
                    CustomSnackBar.show(context, "Company added");
                  } else {
                    await viewModel.updateCompany(company.id, newCompany);
                    CustomSnackBar.show(context, "Company updated");
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
    CompanyViewModel viewModel,
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

  Widget _buildImagePicker(BuildContext context, CompanyViewModel viewModel) {
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

  void _showSaveConfirmation(BuildContext context, CompanyViewModel viewModel) {
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
