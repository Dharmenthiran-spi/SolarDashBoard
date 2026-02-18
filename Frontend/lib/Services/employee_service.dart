import 'http_helper.dart';

class EmployeeService {
  static Future<Map<String, dynamic>> getCompanyEmployees() async {
    return await HttpHelper.get('/employees/company');
  }

  static Future<Map<String, dynamic>> addCompanyEmployee(Map<String, dynamic> data) async {
    return await HttpHelper.post('/employees/company', data);
  }

  static Future<Map<String, dynamic>> updateCompanyEmployee(int id, Map<String, dynamic> data) async {
    return await HttpHelper.put('/employees/company/$id', data);
  }

  static Future<Map<String, dynamic>> updateCompanyEmployees(List<Map<String, dynamic>> data) async {
    return await HttpHelper.put('/employees/company/update_list', data);
  }

  static Future<Map<String, dynamic>> deleteCompanyEmployees(List<int> ids) async {
    return await HttpHelper.delete('/employees/company/delete_list', body: {'ids': ids});
  }

  static Future<Map<String, dynamic>> getCustomerUsers({int? customerId}) async {
    final queryParams = customerId != null ? {'customer_id': customerId.toString()} : null;
    return await HttpHelper.get('/employees/customer', queryParams: queryParams);
  }

  static Future<Map<String, dynamic>> addCustomerUser(Map<String, dynamic> data) async {
    return await HttpHelper.post('/employees/customer', data);
  }

  static Future<Map<String, dynamic>> updateCustomerUser(int id, Map<String, dynamic> data) async {
    return await HttpHelper.put('/employees/customer/$id', data);
  }

  static Future<Map<String, dynamic>> updateCustomerUsers(List<Map<String, dynamic>> data) async {
    return await HttpHelper.put('/employees/customer/update_list', data);
  }

  static Future<Map<String, dynamic>> deleteCustomerUsers(List<int> ids) async {
    return await HttpHelper.delete('/employees/customer/delete_list', body: {'ids': ids});
  }
}
