import 'http_helper.dart';

class ReportService {
  static Future<Map<String, dynamic>> getAll({
    int? machineId,
    int? customerId,
    DateTime? fromTime,
    DateTime? toTime,
  }) async {
    String query = '';
    final params = <String>[];
    if (machineId != null) params.add('machine_id=$machineId');
    if (customerId != null) params.add('customer_id=$customerId');
    if (fromTime != null) params.add('from_time=${fromTime.toIso8601String()}');
    if (toTime != null) params.add('to_time=${toTime.toIso8601String()}');
    
    if (params.isNotEmpty) {
      query = '?' + params.join('&');
    }
    return await HttpHelper.get('/reports$query');
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return await HttpHelper.post('/reports', data);
  }

  static Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    return await HttpHelper.put('/reports/$id', data);
  }

  static Future<Map<String, dynamic>> updateList(List<Map<String, dynamic>> data) async {
    return await HttpHelper.put('/reports/update_list', data);
  }

  static Future<Map<String, dynamic>> delete(int id) async {
    return await HttpHelper.delete('/reports/$id');
  }

  static Future<Map<String, dynamic>> deleteList(List<int> ids) async {
    return await HttpHelper.delete('/reports/delete_list', body: {'ids': ids});
  }
}
