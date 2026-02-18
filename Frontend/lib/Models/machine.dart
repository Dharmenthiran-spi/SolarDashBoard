class Machine {
  final int id;
  final String name;
  final String serialNo;
  final String? description;
  final int? companyId;
  final int? customerId;
  final String? image;

  Machine({
    required this.id,
    required this.name,
    required this.serialNo,
    this.description,
    this.companyId,
    this.customerId,
    this.image,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['TableID'] ?? 0,
      name: json['MachineName'] ?? '',
      serialNo: json['SerialNo'] ?? '',
      description: json['Description'],
      companyId: json['CompanyID'],
      customerId: json['CustomerID'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TableID': id is String ? int.tryParse(id.toString()) ?? id : id,
      'MachineName': name,
      'SerialNo': serialNo,
      'Description': description,
      'CompanyID': companyId is String
          ? int.tryParse(companyId.toString()) ?? companyId
          : companyId,
      'CustomerID': customerId is String
          ? int.tryParse(customerId.toString()) ?? customerId
          : customerId,
      'image': image,
    };
  }

  Machine copyWith({
    int? id,
    String? name,
    String? serialNo,
    String? description,
    int? companyId,
    int? customerId,
    String? image,
  }) {
    return Machine(
      id: id ?? this.id,
      name: name ?? this.name,
      serialNo: serialNo ?? this.serialNo,
      description: description ?? this.description,
      companyId: companyId ?? this.companyId,
      customerId: customerId ?? this.customerId,
      image: image ?? this.image,
    );
  }
}
