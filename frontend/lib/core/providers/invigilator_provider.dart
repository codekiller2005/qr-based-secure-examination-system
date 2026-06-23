import 'package:flutter/material.dart';
import '../models/exam_session.dart';
import '../services/invigilator_service.dart';
class InvigilatorProvider extends ChangeNotifier {
  final InvigilatorService _service;
  List<ExamSession> _exams = [];
  List<ProctoredStudent> _students = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  String? _activeQrContent;
  ExamSession? _activeQrExam;
  InvigilatorProvider(this._service) {
    loadDashboardData();
  }
  // Getters
  List<ExamSession> get exams => _exams;
  List<ProctoredStudent> get students => _students;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get activeQrContent => _activeQrContent;
  ExamSession? get activeQrExam => _activeQrExam;
  // Computed Statistics
  int get totalStudentsCount {
    return _exams.fold(0, (sum, e) => sum + e.totalStudents);
  }
  int get activeStudentsCount {
    return _exams.fold(0, (sum, e) => sum + e.activeStudents);
  }
  int get activeExamsCount {
    return _exams.where((e) => e.status == 'active').length;
  }
  int get completedExamsCount {
    return _exams.where((e) => e.status == 'completed').length;
  }
  /// Initial load of invigilator assignments and statistics.
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _exams = await _service.getAssignedExams();
    } catch (e) {
      _errorMessage = 'Failed to load examination schedules.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  /// Generates the QR validation token for students to start.
  Future<void> generateQrCode(ExamSession exam) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _activeQrContent = await _service.generateExamQrContent(exam);
      _activeQrExam = exam;
    } catch (e) {
      _errorMessage = 'Failed to generate access QR token.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  /// Clears the active projected QR code.
  void stopProjectingQr() {
    _activeQrContent = null;
    _activeQrExam = null;
    notifyListeners();
  }
  /// Starts the examination.
  Future<void> startExam(String examId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final success = await _service.updateExamStatus(examId, 'active');
      if (success) {
        final idx = _exams.indexWhere((e) => e.id == examId);
        if (idx != -1) {
          _exams[idx].status = 'active';
          // Simulate initial student checkins
          _exams[idx].activeStudents = 8; 
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to start the examination.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  /// Ends the examination.
  Future<void> endExam(String examId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final success = await _service.updateExamStatus(examId, 'completed');
      if (success) {
        final idx = _exams.indexWhere((e) => e.id == examId);
        if (idx != -1) {
          _exams[idx].status = 'completed';
          _exams[idx].activeStudents = 0;
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to end the examination.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  /// Fetches proctored student connection details for a specific active exam.
  Future<void> loadConnectedStudents(String examId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _students = await _service.getConnectedStudents(examId);
    } catch (e) {
      _errorMessage = 'Failed to fetch proctored student roster.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
