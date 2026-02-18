import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ViewModel/company_employee_view_model.dart';
import '../Models/company_employee.dart';
import '../Models/company.dart';
import '../Widget/main_layout.dart';
import '../Widget/responsive_helper.dart';
import '../Widget/editable_cell.dart';
import '../Widget/custom_snackbar.dart';
import '../Widget/translate_text.dart';
import '../Config/Themes/app_text_styles.dart';
import '../Widget/dropdown_field.dart';
import '../Config/app_routes/app_route_names.dart';

class CompanyEmployeeView extends StatefulWidget {
  final bool wrapWithLayout;
  const CompanyEmployeeView({super.key, this.wrapWithLayout = true});

  @override
  State<CompanyEmployeeView> createState() => _CompanyEmployeeViewState();
}

class _CompanyEmployeeViewState extends State<CompanyEmployeeView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<CompanyEmployeeViewModel>().fetchEmployees(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CompanyEmployeeViewModel>();
    final content = ResponsiveBuilder(
      mobile: (context) => _buildMobileLayout(context, viewModel),
      desktop: (context) => _buildDesktopLayout(context, viewModel),
    );

    if (!widget.wrapWithLayout) return content;

    return MainLayout(
      title: 'Company Employees',
      showSidebar: false,
      backButtonRoute: RouteNames.dashboard,
      body: content,
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    CompanyEmployeeViewModel viewModel,
  ) {
    return Column(
      children: [
        _buildSearchField(context, viewModel),
        Expanded(
          child: viewModel.isLoading && viewModel.employees.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _buildDataTable(context, viewModel),
        ),
        _buildBottomActions(context, viewModel),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    CompanyEmployeeViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 400,
                child: _buildSearchField(context, viewModel),
              ),
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

  Widget _buildSearchField(
    BuildContext context,
    CompanyEmployeeViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: Translate.get(context, 'Search Company Employees...'),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) => viewModel.searchEmployees(value),
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    CompanyEmployeeViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showEmployeeDialog(context, null),
          ),
          IconButton(
            icon: Icon(
              viewModel.isEditMode ? Icons.edit_off : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () => viewModel.toggleEditMode(),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () async {
              await viewModel.saveBulkChanges();
              if (viewModel.errorMessage == null) {
                if (context.mounted) {
                  CustomSnackBar.show(context, 'Changes saved successfully');
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => _showDeleteConfirmation(context, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActions(
    BuildContext context,
    CompanyEmployeeViewModel viewModel,
  ) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showEmployeeDialog(context, null),
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
          onPressed: () async {
            await viewModel.saveBulkChanges();
            if (viewModel.errorMessage == null) {
              if (context.mounted) {
                CustomSnackBar.show(context, 'Changes saved successfully');
              }
            }
          },
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

  Widget _buildDataTable(
    BuildContext context,
    CompanyEmployeeViewModel viewModel,
  ) {
    final List<String> headers = [
      'Select',
      'Company Name',
      'Emp ID',
      'Name',
      'Email',
      'Username',
      'Password',
      'Privilege',
      'Status',
    ];
    final employees = viewModel.employees;

    bool isMobile = Responsive.isMobile(context);
    double screenWidth = MediaQuery.of(context).size.width;
    List<double> widths;

    if (isMobile) {
      widths = [50, 200, 120, 150, 200, 120, 100, 100, 100];
    } else {
      widths = [
        screenWidth * 0.04, // Select
        screenWidth * 0.15, // Company Name
        screenWidth * 0.10, // Emp ID
        screenWidth * 0.15, // Name
        screenWidth * 0.15, // Email
        screenWidth * 0.12, // Username
        screenWidth * 0.08, // Password
        screenWidth * 0.09, // Privilege
        screenWidth * 0.09, // Status
      ];
    }

    double totalWidth = widths.reduce((a, b) => a + b);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        child: Column(
          children: [
            _buildTableHeader(headers, widths, viewModel),
            Expanded(
              child: ListView.builder(
                itemCount: employees.length,
                itemBuilder: (context, index) =>
                    _buildTableRow(employees[index], widths, viewModel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(
    List<String> headers,
    List<double> widths,
    CompanyEmployeeViewModel viewModel,
  ) {
    return Row(
      children: List.generate(
        headers.length,
        (index) => Container(
          width: widths[index],
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            border: Border.all(color: Colors.black, width: 0.8),
          ),
          child: Text(
            Translate.get(context, headers[index]),
            style: AppTextStyles.defaultHeader1(),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(
    CompanyEmployee emp,
    List<double> widths,
    CompanyEmployeeViewModel viewModel,
  ) {
    final isSelected = viewModel.selectedIds.contains(emp.id);
    return Row(
      children: [
        Container(
          width: widths[0],
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 0.8),
          ),
          child: Checkbox(
            value: isSelected,
            onChanged: (val) => viewModel.toggleSelection(emp.id),
          ),
        ),
        _buildCell(
          widths[1],
          viewModel.dropdownCompanies
                  .firstWhere(
                    (c) => c.id == emp.companyId,
                    orElse: () => Company(id: 0, name: '-'),
                  )
                  .name ??
              '',
          viewModel.isEditMode,
        ),
        _buildCell(widths[2], emp.employeeId, viewModel.isEditMode),
        viewModel.isEditMode
            ? EditableCell(
                width: widths[3],
                value: emp.name ?? '',
                height: 55,
                onChanged: (v) => viewModel.updateLocal(emp.copyWith(name: v)),
              )
            : _buildCell(widths[3], emp.name ?? '', viewModel.isEditMode),
        viewModel.isEditMode
            ? EditableCell(
                width: widths[4],
                value: emp.email ?? '',
                height: 55,
                onChanged: (v) => viewModel.updateLocal(emp.copyWith(email: v)),
              )
            : _buildCell(widths[4], emp.email ?? '', viewModel.isEditMode),
        viewModel.isEditMode
            ? EditableCell(
                width: widths[5],
                value: emp.username ?? '',
                height: 55,
                onChanged: (v) => viewModel.updateLocal(emp.copyWith(email: v)),
              )
            : _buildCell(widths[5], emp.username ?? '', viewModel.isEditMode),
        viewModel.isEditMode
            ? EditableCell(
                width: widths[6],
                value: emp.password ?? '',
                height: 55,
                onChanged: (v) =>
                    viewModel.updateLocal(emp.copyWith(password: v)),
              )
            : _buildCell(widths[6], '******', viewModel.isEditMode),

        viewModel.isEditMode
            ? _buildDropdownCell(
                widths[8],
                emp.privilege,
                viewModel.globalState.privilegeOptions,
                (v) => viewModel.updateLocal(emp.copyWith(privilege: v)),
              )
            : _buildCell(widths[7], emp.privilege ?? '', viewModel.isEditMode),
        viewModel.isEditMode
            ? _buildDropdownCell(
                widths[8],
                emp.status,
                viewModel.globalState.statusOptions,
                (v) => viewModel.updateLocal(emp.copyWith(status: v)),
              )
            : _buildCell(widths[8], emp.status ?? '', viewModel.isEditMode),
      ],
    );
  }

  Widget _buildCell(double width, String text, bool isEditMode) {
    return Container(
      width: width,
      height: 55,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDropdownCell(
    double width,
    String? value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      width: width,
      height: 55,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.8),
      ),
      child: DropdownButton<String>(
        value: items.contains(value) ? value : null,
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        isExpanded: true,
      ),
    );
  }

  void _showEmployeeDialog(BuildContext context, CompanyEmployee? emp) {
    final vm = context.read<CompanyEmployeeViewModel>();
    if (emp != null)
      vm.populateControllers(emp);
    else
      vm.clearControllers();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          Translate.get(
            context,
            emp != null ? 'Edit Employee' : 'Add Employee',
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: Consumer<CompanyEmployeeViewModel>(
          builder: (context, viewModel, _) => SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogRow(
                    context,
                    'Company:',
                    DropdownField<Company>(
                      controller: viewModel.companyController,
                      items: viewModel.dropdownCompanies,
                      itemLabel: (c) => c.name ?? '',
                      onSelected: (c) => viewModel.setSelectedCompany(c.id),
                      hintText: 'Select Company',
                    ),
                  ),
                  _buildDialogRow(
                    context,
                    'Employee ID:',
                    TextField(
                      controller: viewModel.employeeIdController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      style: AppTextStyles.bodyText(Colors.black),
                    ),
                  ),
                  _buildDialogRow(
                    context,
                    'Name:',
                    TextField(
                      controller: viewModel.nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      style: AppTextStyles.bodyText(Colors.black),
                    ),
                  ),
                  _buildDialogRow(
                    context,
                    'Email:',
                    TextField(
                      controller: viewModel.emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      style: AppTextStyles.bodyText(Colors.black),
                    ),
                  ),
                  _buildDialogRow(
                    context,
                    'Username:',
                    TextField(
                      controller: viewModel.usernameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      style: AppTextStyles.bodyText(Colors.black),
                    ),
                  ),
                  _buildDialogRow(
                    context,
                    'Password:',
                    TextField(
                      controller: viewModel.passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      style: AppTextStyles.bodyText(Colors.black),
                    ),
                  ),

                  _buildDialogRow(
                    context,
                    'Privilege:',
                    DropdownButtonFormField<String>(
                      value: viewModel.selectedPrivilege,
                      items: viewModel.globalState.privilegeOptions
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (v) => viewModel.setSelectedPrivilege(v),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                  _buildDialogRow(
                    context,
                    'Status:',
                    DropdownButtonFormField<String>(
                      value: viewModel.selectedStatus,
                      items: viewModel.globalState.statusOptions
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) => viewModel.setSelectedStatus(v),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
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
            child: Text(Translate.get(context, 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEmp = CompanyEmployee(
                id: emp?.id ?? 0,
                employeeId: vm.employeeIdController.text,
                name: vm.nameController.text,
                email: vm.emailController.text,
                username: vm.usernameController.text,
                companyId: vm.selectedCompanyId ?? 0,
                privilege: vm.selectedPrivilege ?? 'User',
                status: vm.selectedStatus ?? 'Active',
              );
              if (emp != null)
                await vm.updateEmployee(
                  emp.id,
                  newEmp,
                  password: vm.passwordController.text,
                );
              else
                await vm.addEmployee(newEmp, vm.passwordController.text);
              Navigator.pop(context);
              CustomSnackBar.show(context, 'Saved successfully');
            },
            child: Text(Translate.get(context, 'Save')),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(BuildContext context, String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              Translate.get(context, label),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: field,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    CompanyEmployeeViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translate.get(context, 'Confirm Delete')),
        content: Text(
          Translate.get(
            context,
            'Are you sure you want to delete selected employees?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translate.get(context, 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.deleteSelected();
              Navigator.pop(context);
            },
            child: Text(Translate.get(context, 'Delete')),
          ),
        ],
      ),
    );
  }
}
