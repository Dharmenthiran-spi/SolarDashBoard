import 'http_helper.dart';

class MachineStatusService {
  static Future<Map<String, dynamic>> getLatest(int machineId) async {
    return await HttpHelper.get('/machine-status/$machineId');
  }

  static Future<Map<String, dynamic>> updateStatus(Map<String, dynamic> data) async {
    return await HttpHelper.post('/machine-status', data);
  }

  static Future<Map<String, dynamic>> getAllLive() async {
    return await HttpHelper.get('/machine-status/all/live');
  }
}
