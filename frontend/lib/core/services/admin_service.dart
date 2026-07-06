import 'dart:io';

import 'package:dio/dio.dart';

import 'api_service.dart';

class AdminService {
  final ApiService _apiService;

  AdminService(this._apiService);

  Future<List<dynamic>> getExams() async {
    final response = await _apiService.dio.get('/admin/exams');
    return response.data;
  }
  Future<Map<String, dynamic>> createExam({
  required String subjectId,
  required String title,
  required String description,
  required String startTime,
  required String endTime,
  required int durationMinutes,
}) async {
  final response = await _apiService.dio.post(
    "/admin/exams",
    data: {
      "subject_id": subjectId,
      "title": title,
      "description": description,
      "start_time": startTime,
      "end_time": endTime,
      "duration_minutes": durationMinutes,
      "encrypted_questions_b64": "dGVzdA==",
      "passcode": "123456",
    },
  );

  return response.data;
}

  Future<String> uploadPdf(String examId, File file) async {
  FormData formData = FormData.fromMap({
    "file": await MultipartFile.fromFile(
      file.path,
      filename: file.path.split('/').last,
    ),
  });

  final response = await _apiService.dio.post(
    "/admin/upload-pdf/$examId",
    data: formData,
  );

  return response.data["pdf_path"];
}
Future<void> assignInvigilator(
    String examId,
    String invigilatorId,
) async {
  await _apiService.dio.post(
    "/admin/assign-invigilator",
    data: {
      "exam_id": examId,
      "invigilator_id": invigilatorId,
    },
  );
}
Future<List<dynamic>> getSubjects() async {
  final response = await _apiService.dio.get("/admin/subjects");
  return response.data;
}
Future<List<dynamic>> getInvigilators() async {
  final response = await _apiService.dio.get("/admin/invigilators");
  return response.data;
}
Future<String> generatePasscode(String examId) async {
  final response = await _apiService.dio.post(
    "/admin/exams/$examId/generate-passcode",
  );

  return response.data["passcode"];
}
Future<Map<String, dynamic>> getDashboardStats() async {
  final response = await _apiService.dio.get(
    "/admin/dashboard-stats",
  );

  return response.data;
}
Future<List<dynamic>> getRecentViolations() async {
  final response = await _apiService.dio.get(
    "/admin/recent-violations",
  );

  return response.data;
}
}