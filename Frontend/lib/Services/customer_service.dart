import 'http_helper.dart';

class CustomerService {
  static Future<Map<String, dynamic>> getAll({int? customerId}) async {
    final queryParams = customerId != null ? {'customer_id': customerId.toString()} : null;
    return await HttpHelper.get('/customers', queryParams: queryParams);
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return await HttpHelper.post('/customers', data);
  }

  static Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    return await HttpHelper.put('/customers/$id', data);
  }

  static Future<Map<String, dynamic>> updateList(List<Map<String, dynamic>> data) async {
    return await HttpHelper.put('/customers/update_list', data);
  }

  static Future<Map<String, dynamic>> delete(int id) async {
    return await HttpHelper.delete('/customers/$id');
  }

  static Future<Map<String, dynamic>> deleteList(List<int> ids) async {
    return await HttpHelper.delete('/customers/delete_list', body: {'ids': ids});
  }
}
