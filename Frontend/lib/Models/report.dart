class Report {
  final int id;
  final int? companyId;
  final int? customerId;
  final int? machineId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? duration;
  final String? areaCovered;
  final String? energyConsumption;
  final String? machineName;
  final String? waterUsage;
  final String? customerName;

  Report({
    required this.id,
    this.companyId,
    this.customerId,
    this.machineId,
    this.startTime,
    this.endTime,
    this.duration,
    this.areaCovered,
    this.energyConsumption,
    this.waterUsage,
    this.machineName,
    this.customerName,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['TableID'] ?? 0,
      companyId: json['CompanyID'],
      customerId: json['CustomerID'],
      machineId: json['MachineID'],
      startTime: json['StartTime'] != null
          ? DateTime.parse(json['StartTime'])
          : null,
      endTime: json['EndTime'] != null ? DateTime.parse(json['EndTime']) : null,
      duration: json['Duration'],
      areaCovered: json['AreaCovered'],
      energyConsumption: json['EnergyConsumption'],
      waterUsage: json['WaterUsage'],
      machineName: json['MachineName'],
      customerName: json['CustomerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TableID': id,
      'CompanyID': companyId,
      'CustomerID': customerId,
      'MachineID': machineId,
      'StartTime': startTime?.toIso8601String(),
      'EndTime': endTime?.toIso8601String(),
      'Duration': duration,
      'AreaCovered': areaCovered,
      'EnergyConsumption': energyConsumption,
      'WaterUsage': waterUsage,
      'MachineName': machineName,
      'CustomerName': customerName,
    };
  }

  Report copyWith({
    int? id,
    int? companyId,
    int? customerId,
    int? machineId,
    DateTime? startTime,
    DateTime? endTime,
    String? duration,
    String? areaCovered,
    String? energyConsumption,
    String? waterUsage,
    String? machineName,
    String? customerName,
  }) {
    return Report(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      customerId: customerId ?? this.customerId,
      machineId: machineId ?? this.machineId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      areaCovered: areaCovered ?? this.areaCovered,
      energyConsumption: energyConsumption ?? this.energyConsumption,
      waterUsage: waterUsage ?? this.waterUsage,
      machineName: machineName ?? this.machineName,
      customerName: customerName ?? this.customerName,
    );
  }
}
