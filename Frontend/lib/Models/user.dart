class User {
  final String userType; // "CompanyEmployee" or "CustomerUser"
  final String privilege; // "Admin" or "User"
  final int userId;
  final String username;
  final int? customerId;
  final int? companyId;
  final String? customerName;
  final String? employeeName;

  User({
    required this.userType,
    required this.privilege,
    required this.userId,
    required this.username,
    this.customerId,
    this.companyId,
    this.customerName,
    this.employeeName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userType: json['user_type'] as String,
      privilege: json['privilege'] as String,
      userId: json['user_id'] as int,
      username: json['username'] as String,
      customerId: json['customer_id'] as int?,
      companyId: json['company_id'] as int?,
      customerName: json['customer_name'] as String?,
      employeeName: json['employee_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_type': userType,
      'privilege': privilege,
      'user_id': userId,
      'username': username,
      'customer_id': customerId,
      'company_id': companyId,
      'customer_name': customerName,
      'employee_name': employeeName,
    };
  }

  // Convenience getters
  bool get isCompanyEmployee => userType == 'CompanyEmployee';
  bool get isCustomerUser => userType == 'CustomerUser';
  bool get isAdmin => privilege == 'Admin';
  bool get isUser => privilege == 'User';
}
