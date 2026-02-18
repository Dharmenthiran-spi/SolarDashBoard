import 'http_helper.dart';

class MachineService {
  static Future<Map<String, dynamic>> getAll({int? customerId}) async {
    final queryParams = customerId != null ? {'customer_id': customerId.toString()} : null;
    return await HttpHelper.get('/machines', queryParams: queryParams);
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return await HttpHelper.post('/machines', data);
  }

  static Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    return await HttpHelper.put('/machines/$id', data);
  }

  static Future<Map<String, dynamic>> updateList(List<Map<String, dynamic>> data) async {
    return await HttpHelper.put('/machines/update_list', data);
  }

  static Future<Map<String, dynamic>> delete(int id) async {
    return await HttpHelper.delete('/machines/$id');
  }

  static Future<Map<String, dynamic>> deleteList(List<int> ids) async {
    return await HttpHelper.delete('/machines/delete_list', body: {'ids': ids});
  }
}
