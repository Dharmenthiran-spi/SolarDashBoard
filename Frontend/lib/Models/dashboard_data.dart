class DailyGraphicData {
  final String date;
  final double value;

  DailyGraphicData({required this.date, required this.value});

  factory DailyGraphicData.fromJson(Map<String, dynamic> json) {
    return DailyGraphicData(
      date: json['date'],
      value: (json['value'] as num).toDouble(),
    );
  }
}

class DashboardSummary {
  final int totalCompanies;
  final int totalCustomers;
  final int totalMachines;
  final int totalReports;
  final double totalEnergyGenerated;
  final double totalWaterUsage;
  final List<Map<String, dynamic>> recentReports;
  final List<DailyGraphicData> dailyEnergy;
  final List<DailyGraphicData> dailyWater;

  DashboardSummary({
    required this.totalCompanies,
    required this.totalCustomers,
    required this.totalMachines,
    required this.totalReports,
    required this.totalEnergyGenerated,
    required this.totalWaterUsage,
    required this.recentReports,
    required this.dailyEnergy,
    required this.dailyWater,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalCompanies: json['total_companies'],
      totalCustomers: json['total_customers'],
      totalMachines: json['total_machines'],
      totalReports: json['total_reports'],
      totalEnergyGenerated: (json['total_energy_generated'] as num).toDouble(),
      totalWaterUsage: (json['total_water_usage'] as num).toDouble(),
      recentReports: List<Map<String, dynamic>>.from(json['recent_reports']),
      dailyEnergy: (json['daily_energy'] as List).map((e) => DailyGraphicData.fromJson(e)).toList(),
      dailyWater: (json['daily_water'] as List).map((e) => DailyGraphicData.fromJson(e)).toList(),
    );
  }
}
