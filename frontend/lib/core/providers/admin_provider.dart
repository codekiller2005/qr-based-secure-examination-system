import 'package:flutter/material.dart';
class MockExam {
  final String id;
  final String title;
  final String subjectCode;
  final int durationMinutes;
  final int totalMarks;
  String? assignedInvigilator;
  String? questionPaperPdfName;
  String? sessionPasscode;
  String status; // 'Created', 'Ready', 'Active', 'Completed'
  MockExam({
    required this.id,
    required this.title,
    required this.subjectCode,
    required this.durationMinutes,
    required this.totalMarks,
    this.assignedInvigilator,
    this.questionPaperPdfName,
    this.sessionPasscode,
    this.status = 'Created',
  });
}
class MockViolationLog {
  final String id;
  final String studentName;
  final String examTitle;
  final String violationType; // 'APP_SWITCH', 'SCREENSHOT', 'SCREEN_RECORDING', etc.
  final String timestamp;
  final String details;
  MockViolationLog({
    required this.id,
    required this.studentName,
    required this.examTitle,
    required this.violationType,
    required this.timestamp,
    required this.details,
  });
}
class AdminProvider extends ChangeNotifier {
  final List<MockExam> _exams = [
    MockExam(
      id: 'EXAM-001',
      title: 'Operating Systems Midterm 2026',
      subjectCode: 'CS-302',
      durationMinutes: 120,
      totalMarks: 50,
      assignedInvigilator: 'Dr. John Smith',
      questionPaperPdfName: 'CS302_OS_Midterm_2026.pdf',
      sessionPasscode: 'PASS-FIT-OS-302',
      status: 'Active',
    ),
    MockExam(
      id: 'EXAM-002',
      title: 'Python Fundamentals Final 2026',
      subjectCode: 'CS-101',
      durationMinutes: 180,
      totalMarks: 100,
      assignedInvigilator: 'Prof. Sarah Davis',
      questionPaperPdfName: 'CS101_Python_Final.pdf',
      sessionPasscode: 'PASS-PYTHON-101',
      status: 'Ready',
    ),
    MockExam(
      id: 'EXAM-003',
      title: 'Calculus I Midterm',
      subjectCode: 'MATH-201',
      durationMinutes: 90,
      totalMarks: 50,
      assignedInvigilator: 'Dr. John Smith',
      questionPaperPdfName: 'MATH201_Calc_Mid.pdf',
      sessionPasscode: 'PASS-CALC-201',
      status: 'Completed',
    ),
  ];
  final List<String> _invigilators = [
    'Dr. John Smith',
    'Prof. Sarah Davis',
    'Dr. Emily Taylor',
    'Prof. Michael Brown',
  ];
  final List<MockViolationLog> _violations = [
    MockViolationLog(
      id: 'V-101',
      studentName: 'Evan Wright',
      examTitle: 'Operating Systems Midterm 2026',
      violationType: 'APP_SWITCH',
      timestamp: '09:22 AM - 10/06/2026',
      details: 'App lost system focus (State: paused).',
    ),
    MockViolationLog(
      id: 'V-102',
      studentName: 'Fiona Gallagher',
      examTitle: 'Operating Systems Midterm 2026',
      violationType: 'SCREENSHOT',
      timestamp: '09:45 AM - 10/06/2026',
      details: 'Hardware screenshot capture detected.',
    ),
    MockViolationLog(
      id: 'V-103',
      studentName: 'Alice Smith',
      examTitle: 'Operating Systems Midterm 2026',
      violationType: 'INTERNET_ENABLED',
      timestamp: '10:02 AM - 10/06/2026',
      details: 'Active internet connectivity interface transition.',
    ),
  ];
  // Getters
  List<MockExam> get exams => _exams;
  List<String> get invigilators => _invigilators;
  List<MockViolationLog> get violations => _violations;
  // Analytics getters
  int get totalExamsCount => _exams.length;
  int get totalStudentsCount => 55; // Mock overall database volume
  int get activeProctorsCount => _exams.where((e) => e.status == 'Active').map((e) => e.assignedInvigilator).toSet().length;
  int get totalViolationsCount => _violations.length;
  /// Creates a new exam session record.
  void createExam({
    required String title,
    required String subjectCode,
    required int durationMinutes,
    required int totalMarks,
  }) {
    final newExam = MockExam(
      id: 'EXAM-00${_exams.length + 1}',
      title: title,
      subjectCode: subjectCode,
      durationMinutes: durationMinutes,
      totalMarks: totalMarks,
    );
    _exams.add(newExam);
    notifyListeners();
  }
  /// Simulates uploading a question paper PDF to an exam record.
  void uploadPdf(String examId, String pdfName) {
    final idx = _exams.indexWhere((e) => e.id == examId);
    if (idx != -1) {
      _exams[idx].questionPaperPdfName = pdfName;
      _updateStatus(idx);
      notifyListeners();
    }
  }
  /// Assigns an invigilator to an exam session.
  void assignInvigilator(String examId, String invigilator) {
    final idx = _exams.indexWhere((e) => e.id == examId);
    if (idx != -1) {
      _exams[idx].assignedInvigilator = invigilator;
      _updateStatus(idx);
      notifyListeners();
    }
  }
  /// Generates the secure access passcode for an exam session.
  void generateSessionPasscode(String examId) {
    final idx = _exams.indexWhere((e) => e.id == examId);
    if (idx != -1) {
      final code = 'PASS-FIT-${_exams[idx].subjectCode.replaceAll('-', '')}-${_exams[idx].id.split('-').last}';
      _exams[idx].sessionPasscode = code;
      _exams[idx].status = 'Ready';
      notifyListeners();
    }
  }
  /// Private status updater helper.
  void _updateStatus(int idx) {
    final exam = _exams[idx];
    if (exam.assignedInvigilator != null && exam.questionPaperPdfName != null) {
      if (exam.sessionPasscode == null) {
        exam.status = 'Created';
      }
    }
  }
}
