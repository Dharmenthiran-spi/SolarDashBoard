class MachineStatus {
  final int statusId;
  final int machineId;
  final String status;
  final double energyValue;
  final double waterValue;
  final double areaValue;
  final DateTime timestamp;

  // New Telemetry Fields (Simulated)
  final String mode;
  final int timer;
  final double batteryLevel;
  final double batteryVoltage;
  final bool isCharging;
  final double waterLevel;
  final bool pumpStatus;
  final int brushRPM;
  final double brushTemp;
  final bool isBrushJam;
  final double speed;
  final double direction;
  final bool emergencyStop;
  final bool obstacleDetected;
  final double areaToday;
  final int cleaningTime;
  final int totalCycles;

  MachineStatus({
    required this.statusId,
    required this.machineId,
    required this.status,
    required this.energyValue,
    required this.waterValue,
    required this.areaValue,
    required this.timestamp,
    this.mode = 'Auto',
    this.timer = 0,
    this.batteryLevel = 100.0,
    this.batteryVoltage = 24.0,
    this.isCharging = false,
    this.waterLevel = 100.0,
    this.pumpStatus = false,
    this.brushRPM = 0,
    this.brushTemp = 25.0,
    this.isBrushJam = false,
    this.speed = 0.0,
    this.direction = 0.0,
    this.emergencyStop = false,
    this.obstacleDetected = false,
    this.areaToday = 0.0,
    this.cleaningTime = 0,
    this.totalCycles = 0,
  });

  factory MachineStatus.fromJson(Map<String, dynamic> json) {
    return MachineStatus(
      statusId: json['StatusID'],
      machineId: json['MachineID'],
      status: json['Status'],
      energyValue: (json['EnergyValue'] as num?)?.toDouble() ?? 0.0,
      waterValue: (json['WaterValue'] as num?)?.toDouble() ?? 0.0,
      areaValue: (json['AreaValue'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['Timestamp'] != null 
          ? DateTime.parse(json['Timestamp']) 
          : DateTime.now(),
      mode: json['Mode'] ?? 'Auto',
      timer: json['Timer'] ?? 0,
      batteryLevel: (json['BatteryLevel'] ?? 100.0).toDouble(),
      batteryVoltage: (json['BatteryVoltage'] ?? 24.0).toDouble(),
      isCharging: json['IsCharging'] ?? false,
      waterLevel: (json['WaterLevel'] ?? 100.0).toDouble(),
      pumpStatus: json['PumpStatus'] ?? false,
      brushRPM: json['BrushRPM'] ?? 0,
      brushTemp: (json['BrushTemp'] ?? 25.0).toDouble(),
      isBrushJam: json['IsBrushJam'] ?? false,
      speed: (json['Speed'] ?? 0.0).toDouble(),
      direction: (json['Direction'] ?? 0.0).toDouble(),
      emergencyStop: json['EmergencyStop'] ?? false,
      obstacleDetected: json['ObstacleDetected'] ?? false,
      areaToday: (json['AreaToday'] ?? 0.0).toDouble(),
      cleaningTime: json['CleaningTime'] ?? 0,
      totalCycles: json['TotalCycles'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'StatusID': statusId,
      'MachineID': machineId,
      'Status': status,
      'EnergyValue': energyValue,
      'WaterValue': waterValue,
      'AreaValue': areaValue,
      'Timestamp': timestamp.toIso8601String(),
      'Mode': mode,
      'Timer': timer,
      'BatteryLevel': batteryLevel,
      'BatteryVoltage': batteryVoltage,
      'IsCharging': isCharging,
      'WaterLevel': waterLevel,
      'PumpStatus': pumpStatus,
      'BrushRPM': brushRPM,
      'BrushTemp': brushTemp,
      'IsBrushJam': isBrushJam,
      'Speed': speed,
      'Direction': direction,
      'EmergencyStop': emergencyStop,
      'ObstacleDetected': obstacleDetected,
      'AreaToday': areaToday,
      'CleaningTime': cleaningTime,
      'TotalCycles': totalCycles,
    };
  }
}
