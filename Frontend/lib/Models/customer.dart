class Customer {
  final int id;
  final String name;
  final String? address;
  final String? location;
  final int? companyId;
  final String? image;

  Customer({
    required this.id,
    required this.name,
    this.address,
    this.location,
    this.companyId,
    this.image,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['CustomerID'] ?? 0,
      name: json['CustomerName'] ?? '',
      address: json['CustomerAddress'],
      location: json['Location'],
      companyId: json['CompanyID'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CustomerID': id is String ? int.tryParse(id.toString()) ?? id : id,
      'CustomerName': name,
      'CustomerAddress': address,
      'Location': location,
      'CompanyID': companyId is String
          ? int.tryParse(companyId.toString()) ?? companyId
          : companyId,
      'image': image,
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    String? address,
    String? location,
    int? companyId,
    String? image,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      companyId: companyId ?? this.companyId,
      image: image ?? this.image,
    );
  }
}
