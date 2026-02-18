import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ViewModel/customer_user_view_model.dart';
import '../Models/customer_user.dart';
import '../Models/customer.dart';
import '../Widget/main_layout.dart';
import '../Widget/responsive_helper.dart';
import '../Widget/editable_cell.dart';
import '../Widget/custom_snackbar.dart';
import '../Widget/translate_text.dart';
import '../Config/Themes/app_text_styles.dart';
import '../Widget/dropdown_field.dart';
import '../Config/app_routes/app_route_names.dart';

class CustomerUserView extends StatefulWidget {
  final bool wrapWithLayout;
  const CustomerUserView({super.key, this.wrapWithLayout = true});

  @override
  State<CustomerUserView> createState() => _CustomerUserViewState();
}

class _CustomerUserViewState extends State<CustomerUserView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CustomerUserViewModel>().fetchUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomerUserViewModel>();
    final content = ResponsiveBuilder(
      mobile: (context) => _buildMobileLayout(context, viewModel),
      desktop: (context) => _buildDesktopLayout(context, viewModel),
    );

    if (!widget.wrapWithLayout) return content;

    return MainLayout(
      title: 'Customer Users',
      showSidebar: false,
      backButtonRoute: RouteNames.dashboard,
      body: content,
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    CustomerUserViewModel viewModel,
  ) {
    return Column(
      children: [
        _buildSearchField(context, viewModel),
        Expanded(
          child: viewModel.isLoading && viewModel.users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _buildDataTable(context, viewModel),
        ),
        _buildBottomActions(context, viewModel),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    CustomerUserViewModel viewModel,
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
    CustomerUserViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: Translate.get(context, 'Search Customer Users...'),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) => viewModel.searchUsers(value),
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    CustomerUserViewModel viewModel,
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
            onPressed: () => _showUserDialog(context, null),
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
    CustomerUserViewModel viewModel,
  ) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showUserDialog(context, null),
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
    CustomerUserViewModel viewModel,
  ) {
    final List<String> headers = [
      'Select',
      'Company',
      'Organization',
      'Name',
      'Username',
      'Password',
      'Privilege',
      'Status',
    ];
    final users = viewModel.users;

    bool isMobile = Responsive.isMobile(context);
    double screenWidth = MediaQuery.of(context).size.width;
    List<double> widths;

    if (isMobile) {
      widths = [50, 100, 100, 120, 100, 100, 100, 100];
    } else {
      widths = [
        screenWidth * 0.05, // Select
        screenWidth * 0.12, // Company
        screenWidth * 0.13, // Organization
        screenWidth * 0.15, // Name
        screenWidth * 0.15, // Username
        screenWidth * 0.10, // Password
        screenWidth * 0.15, // Privilege
        screenWidth * 0.15, // Status
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
                itemCount: users.length,
                itemBuilder: (context, index) =>
                    _buildTableRow(users[index], widths, viewModel),
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
    CustomerUserViewModel viewModel,
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
    CustomerUser user,
    List<double> widths,
    CustomerUserViewModel viewModel,
  ) {
    final isSelected = viewModel.selectedIds.contains(user.id);
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
            onChanged: (val) => viewModel.toggleSelection(user.id),
          ),
        ),
        _buildCell(widths[1], user.companyName ?? '-', viewModel.isEditMode),
        _buildCell(
          widths[2],
          user.organizationName ?? '-',
          viewModel.isEditMode,
        ),
        viewModel.isEditMode
            ? EditableCell(
                width: widths[3],
                value: user.customerName ?? '',
                height: 55,
                onChanged: (v) =>
                    viewModel.updateLocal(user.copyWith(customerName: v)),
              )
            : _buildCell(
                widths[3],
                user.customerName ?? '',
                viewModel.isEditMode,
              ),
        viewModel.isEditMode
            ? EditableCell(
                width: widths[4],
                value: user.username ?? '',
                height: 55,
                onChanged: (v) =>
                    viewModel.updateLocal(user.copyWith(customerName: v)),
              )
            : _buildCell(widths[4], user.username ?? '', viewModel.isEditMode),
        viewModel.isEditMode
            ? EditableCell(
                width: widths[5],
                value: user.password ?? '',
                height: 55,
                onChanged: (v) =>
                    viewModel.updateLocal(user.copyWith(password: v)),
              )
            : _buildCell(widths[5], '********', viewModel.isEditMode),
        viewModel.isEditMode
            ? _buildDropdownCell(
                widths[6],
                user.privilege,
                viewModel.globalState.privilegeOptions,
                (v) => viewModel.updateLocal(user.copyWith(privilege: v)),
              )
            : _buildCell(widths[6], user.privilege ?? '', viewModel.isEditMode),
        viewModel.isEditMode
            ? _buildDropdownCell(
                widths[7],
                user.status,
                viewModel.globalState.statusOptions,
                (v) => viewModel.updateLocal(user.copyWith(status: v)),
              )
            : _buildCell(widths[7], user.status ?? '', viewModel.isEditMode),
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

  void _showUserDialog(BuildContext context, CustomerUser? user) {
    final vm = context.read<CustomerUserViewModel>();
    if (user != null)
      vm.populateControllers(user);
    else
      vm.clearControllers();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          Translate.get(context, user != null ? 'Edit User' : 'Add User'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: Consumer<CustomerUserViewModel>(
          builder: (context, viewModel, _) => SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogRow(
                    context,
                    'Customer:',
                    DropdownField<Customer>(
                      controller: viewModel.customerController,
                      items: viewModel.dropdownCustomers,
                      itemLabel: (c) => c.name ?? '',
                      onSelected: (c) => viewModel.setSelectedCustomer(c.id),
                      hintText: 'Select Customer',
                    ),
                  ),
                  _buildDialogRow(
                    context,
                    'Name:',
                    TextField(
                      controller: viewModel.customerNameController,
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
              final newUser = CustomerUser(
                id: user?.id ?? 0,
                customerName: vm.customerNameController.text,
                username: vm.usernameController.text,
                customerId: vm.selectedCustomerId ?? 0,
                privilege: vm.selectedPrivilege ?? 'User',
                status: vm.selectedStatus ?? 'Active',
              );
              if (user != null)
                await vm.updateUser(
                  user.id,
                  newUser,
                  password: vm.passwordController.text,
                );
              else
                await vm.addUser(newUser, vm.passwordController.text);
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
    CustomerUserViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translate.get(context, 'Confirm Delete')),
        content: Text(
          Translate.get(
            context,
            'Are you sure you want to delete selected users?',
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
