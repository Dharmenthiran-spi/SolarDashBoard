class CustomerUser {
  final int id;
  final int? customerId;
  final String? customerName;
  final String? companyName;
  final String? organizationName;
  final String username;
  final String? privilege;
  final String? password;
  final String? status;

  CustomerUser({
    required this.id,
    this.customerId,
    this.customerName,
    this.companyName,
    this.organizationName,
    required this.username,
    this.password,
    this.privilege,
    this.status,
  });

  factory CustomerUser.fromJson(Map<String, dynamic> json) {
    return CustomerUser(
      id: json['UserID'] ?? 0,
      customerId: json['CustomerID'],
      customerName: json['CustomerName'],
      companyName: json['CompanyName'],
      organizationName: json['OrganizationName'],
      username: json['Username'] ?? '',
      password: json['Password'],
      privilege: json['Privilege'],
      status: json['Status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UserID': id is String ? int.tryParse(id.toString()) ?? id : id,
      'CustomerID': customerId is String
          ? int.tryParse(customerId.toString()) ?? customerId
          : customerId,
      'CustomerName': customerName,
      'CompanyName': companyName,
      'Username': username,
      'Password': password,
      'Privilege': privilege,
      'Status': status,
    };
  }

  CustomerUser copyWith({
    int? id,
    int? customerId,
    String? customerName,
    String? companyName,
    String? organizationName,
    String? username,
    String? password,
    String? privilege,
    String? status,
  }) {
    return CustomerUser(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      companyName: companyName ?? this.companyName,
      organizationName: organizationName ?? this.organizationName,
      username: username ?? this.username,
      password: password ?? this.password,
      privilege: privilege ?? this.privilege,
      status: status ?? this.status,
    );
  }
}
