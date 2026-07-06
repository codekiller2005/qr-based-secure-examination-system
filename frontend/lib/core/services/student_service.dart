import 'api_service.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
class StudentService {
  final ApiService _apiService;

  StudentService(this._apiService);

  Future<List<dynamic>> getMyExams() async {
    final response = await _apiService.dio.get(
      "/student/exams", 
    );

    return response.data;
  }
  Future<void> startExamOnServer(String examId) async {
  await _apiService.dio.post(
    "/student/exams/$examId/start",
  );
}
Future<String> downloadQuestionPaper(String examId) async {
  final response = await _apiService.dio.get(
    "/student/exams/$examId/question-paper",
    options: Options(
      responseType: ResponseType.bytes,
    ),
  );

  final Directory dir = await getApplicationDocumentsDirectory();

  final String filePath =
      "${dir.path}/question_paper_$examId.pdf";

  final File file = File(filePath);

  await file.writeAsBytes(response.data);

  return filePath;
}

Future<void> finishExam(String examId) async {
  await _apiService.dio.post(
    "/student/exams/$examId/finish",
  );
}
}