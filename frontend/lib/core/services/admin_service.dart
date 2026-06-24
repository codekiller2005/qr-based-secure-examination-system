import 'api_service.dart';

class AdminService {
  final ApiService _apiService;

  AdminService(this._apiService);

  Future<List<dynamic>> getExams() async {
    final response = await _apiService.dio.get('/admin/exams');
    return response.data;
  }
}