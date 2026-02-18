class Company {
  final int id;
  final String name;
  final String? address;
  final String? location;
  final String? image;

  Company({
    required this.id,
    required this.name,
    this.address,
    this.location,
    this.image,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['CompanyID'] ?? 0,
      name: json['CompanyName'] ?? '',
      address: json['Address'],
      location: json['Location'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CompanyID': id is String ? int.tryParse(id.toString()) ?? id : id,
      'CompanyName': name,
      'Address': address,
      'Location': location,
      'image': image,
    };
  }

  Company copyWith({
    int? id,
    String? name,
    String? address,
    String? location,
    String? image,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      image: image ?? this.image,
    );
  }
}
