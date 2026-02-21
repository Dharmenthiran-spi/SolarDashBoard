class MachineStatus {
  final int machineId;
  final String status;
  final String mode;
  final double batteryLevel;
  final double batteryVoltage;
  final double waterLevel;
  final int brushRPM;
  final double brushTemp;
  final double speed;
  final double areaToday;
  final int totalCycles;
  final DateTime timestamp;

  MachineStatus({
    required this.machineId,
    required this.status,
    this.mode = 'Auto',
    this.batteryLevel = 100.0,
    this.batteryVoltage = 24.0,
    this.waterLevel = 100.0,
    this.brushRPM = 0,
    this.brushTemp = 25.0,
    this.speed = 0.0,
    this.areaToday = 0.0,
    this.totalCycles = 0,
    required this.timestamp,
  });

  factory MachineStatus.fromJson(Map<String, dynamic> json) {
    return MachineStatus(
      machineId: json['MachineID'] ?? json['machine_id'] ?? 0,
      status: json['Status'] ?? json['status'] ?? 'Offline',
      mode: json['Mode'] ?? 'Auto',
      batteryLevel: (json['BatteryLevel'] ?? json['battery'] ?? 100.0).toDouble(),
      batteryVoltage: (json['BatteryVoltage'] ?? json['solar_v'] ?? 24.0).toDouble(),
      waterLevel: (json['WaterLevel'] ?? json['water'] ?? 100.0).toDouble(),
      brushRPM: json['BrushRPM'] ?? 0,
      brushTemp: (json['BrushTemp'] ?? (json['extra']?['temp']) ?? 25.0).toDouble(),
      speed: (json['Speed'] ?? 0.0).toDouble(),
      areaToday: (json['AreaToday'] ?? json['area'] ?? 0.0).toDouble(),
      totalCycles: json['TotalCycles'] ?? 0,
      timestamp: json['Timestamp'] != null 
          ? DateTime.parse(json['Timestamp']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MachineID': machineId,
      'Status': status,
      'Mode': mode,
      'BatteryLevel': batteryLevel,
      'BatteryVoltage': batteryVoltage,
      'WaterLevel': waterLevel,
      'BrushRPM': brushRPM,
      'BrushTemp': brushTemp,
      'Speed': speed,
      'AreaToday': areaToday,
      'TotalCycles': totalCycles,
      'Timestamp': timestamp.toIso8601String(),
    };
  }
}
