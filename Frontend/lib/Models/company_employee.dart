class CompanyEmployee {
  final int id;
  final String employeeId;
  final String? name;
  final String? email;
  final int? companyId;
  final String username;
  final String? password;
  final String? privilege;
  final String? status;

  CompanyEmployee({
    required this.id,
    required this.employeeId,
    this.name,
    this.email,
    this.companyId,
    required this.username,
    this.password,
    this.privilege,
    this.status,
  });

  factory CompanyEmployee.fromJson(Map<String, dynamic> json) {
    return CompanyEmployee(
      id: json['TableID'] ?? 0,
      employeeId: json['EmployeeID'] ?? '',
      name: json['EmployeeName'],
      email: json['EmployeeEmail'],
      companyId: json['CompanyID'],
      username: json['Username'] ?? '',
      password: json['Password'],
      privilege: json['Privilege'],
      status: json['Status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TableID': id is String ? int.tryParse(id.toString()) ?? id : id,
      'EmployeeID': employeeId,
      'EmployeeName': name,
      'EmployeeEmail': email,
      'CompanyID': companyId is String
          ? int.tryParse(companyId.toString()) ?? companyId
          : companyId,
      'Username': username,
      'Password': password,
      'Privilege': privilege,
      'Status': status,
    };
  }

  CompanyEmployee copyWith({
    int? id,
    String? employeeId,
    String? name,
    String? email,
    int? companyId,
    String? username,
    String? privilege,
    String? status,
    String? password,
  }) {
    return CompanyEmployee(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      email: email ?? this.email,
      companyId: companyId ?? this.companyId,
      username: username ?? this.username,
      password: password ?? this.password,
      privilege: privilege ?? this.privilege,
      status: status ?? this.status,
    );
  }
}
