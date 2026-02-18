import 'http_helper.dart';

class CompanyService {
  static Future<Map<String, dynamic>> getAll() async {
    return await HttpHelper.get('/companies');
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return await HttpHelper.post('/companies', data);
  }

  static Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    return await HttpHelper.put('/companies/$id', data);
  }

  static Future<Map<String, dynamic>> updateList(List<Map<String, dynamic>> data) async {
    return await HttpHelper.put('/companies/update_list', data);
  }

  static Future<Map<String, dynamic>> delete(int id) async {
    return await HttpHelper.delete('/companies/$id');
  }

  static Future<Map<String, dynamic>> deleteList(List<int> ids) async {
    return await HttpHelper.delete('/companies/delete_list', body: {'ids': ids});
  }
}
