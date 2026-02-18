import 'http_helper.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getSummary({int? customerId}) async {
    final queryParams = customerId != null ? {'customer_id': customerId.toString()} : null;
    return await HttpHelper.get('/dashboard/summary', queryParams: queryParams);
  }
}
