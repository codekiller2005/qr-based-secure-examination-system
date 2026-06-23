import 'dart:convert';
import '../models/exam_session.dart';
import './api_service.dart';
class InvigilatorService {
    final ApiService _apiService;
    InvigilatorService(this._apiService);
final List<ExamSession> _mockExams = [
  ExamSession(
    id: 'CS302-OS',
    title: 'Operating Systems Midterm 2026',
    subjectCode: 'CS-302',
    durationMinutes: 120,
    timeDisplay: 'Ongoing (09:00 - 11:00)',
    status: 'active',
    totalStudents: 15,
    activeStudents: 8,
  ),
  ExamSession(
    id: 'CS101-PYTHON',
    title: 'Python Fundamentals Final 2026',
    subjectCode: 'CS-101',
    durationMinutes: 180,
    timeDisplay: 'Scheduled: In 2 Days',
    status: 'upcoming',
    totalStudents: 22,
    activeStudents: 0,
  ),
];
  
 
  
  // Mock Database of Proctored Students
  final List<ProctoredStudent> _mockStudents = [
    // Operating Systems Students
    ProctoredStudent(id: 'S101', name: 'Alice Smith', examId: 'CS302-OS', connectionStatus: 'online', qrValidationStatus: 'validated'),
    ProctoredStudent(id: 'S102', name: 'Bob Johnson', examId: 'CS302-OS', connectionStatus: 'online', qrValidationStatus: 'validated'),
    ProctoredStudent(id: 'S103', name: 'Charlie Brown', examId: 'CS302-OS', connectionStatus: 'online', qrValidationStatus: 'validated'),
    ProctoredStudent(id: 'S104', name: 'Diana Prince', examId: 'CS302-OS', connectionStatus: 'online', qrValidationStatus: 'validated'),
    ProctoredStudent(id: 'S105', name: 'Evan Wright', examId: 'CS302-OS', connectionStatus: 'online', qrValidationStatus: 'pending'),
    ProctoredStudent(id: 'S106', name: 'Fiona Gallagher', examId: 'CS302-OS', connectionStatus: 'offline', qrValidationStatus: 'pending'),
    ProctoredStudent(id: 'S107', name: 'George Costanza', examId: 'CS302-OS', connectionStatus: 'online', qrValidationStatus: 'validated'),
    ProctoredStudent(id: 'S108', name: 'Hannah Baker', examId: 'CS302-OS', connectionStatus: 'online', qrValidationStatus: 'validated'),
    ProctoredStudent(id: 'S109', name: 'Ian Malcolm', examId: 'CS302-OS', connectionStatus: 'offline', qrValidationStatus: 'pending'),
    ProctoredStudent(id: 'S110', name: 'Julia Roberts', examId: 'CS302-OS', connectionStatus: 'online', qrValidationStatus: 'validated'),
    // Python Students
    ProctoredStudent(id: 'S201', name: 'Kevin Hart', examId: 'CS101-PYTHON', connectionStatus: 'offline', qrValidationStatus: 'pending'),
    ProctoredStudent(id: 'S202', name: 'Lara Croft', examId: 'CS101-PYTHON', connectionStatus: 'offline', qrValidationStatus: 'pending'),
  ];
  /// Simulates fetching exams assigned to the proctor.
 Future<List<ExamSession>> getAssignedExams() async {
  final response = await _apiService.dio.get('/invigilator/exams');

  final List<dynamic> data = response.data;

  return data.map((exam) {
    return ExamSession(
      id: exam['id'],
      title: exam['title'],
      subjectCode: exam['subject_id'],
      durationMinutes: exam['duration_minutes'],
      timeDisplay: exam['start_time'].toString(),
      status: exam['status'] == 'ongoing'
          ? 'active'
          : exam['status'] == 'scheduled'
              ? 'upcoming'
              : 'completed',
      totalStudents: 0,
      activeStudents: 0,
    );
  }).toList();
}
  /// Simulates fetching connected student details for monitoring.
  Future<List<ProctoredStudent>> getConnectedStudents(String examId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockStudents.where((s) => s.examId == examId).toList();
  }
  /// Simulates modifying exam status.
  Future<bool> updateExamStatus(String examId, String newStatus) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockExams.indexWhere((e) => e.id == examId);
    if (index != -1) {
      _mockExams[index].status = newStatus;
      if (newStatus == 'completed') {
        _mockExams[index].activeStudents = 0;
      }
      return true;
    }
    return false;
  }
  /// Simulates generating a secure JSON QR token.
 Future<String> generateExamQrContent(ExamSession exam) async {
  try {
    print("REQUESTING QR FOR EXAM = ${exam.id}");

    final response =
        await _apiService.dio.get('/invigilator/exams/${exam.id}/qr-code');

    print("QR RESPONSE = ${response.data}");

    return response.data['token_value'];
  } catch (e) {
    print("QR ERROR = $e");
    rethrow;
  }
}
}
