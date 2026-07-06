  import 'package:flutter/material.dart';
  import '../services/admin_service.dart';
  import 'dart:io';

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
    final AdminService _adminService;

    AdminProvider(this._adminService) {
     

  loadSubjects().then((_) async {
   
    await testBackendConnection();
    await loadInvigilators();
    await loadDashboardStats(); 
     await loadRecentViolations();

   
  });
}

  Future<void> testBackendConnection() async {
    try {
      final exams = await _adminService.getExams();

      _exams.clear();

      for (final exam in exams) {
        final subject = _subjects.firstWhere(
          (s) => s["id"] == exam["subject_id"],
          orElse: () => {"code": "UNKNOWN"},
        );

        _exams.add(
          MockExam(
            id: exam["id"],
            title: exam["title"],
            subjectCode: subject["code"],
            durationMinutes: exam["duration_minutes"],
            totalMarks: 0,
            questionPaperPdfName: exam["pdf_path"],
            status: exam["status"],
          ),
        );
      }

      print("========== EXAMS FROM BACKEND ==========");
      print(_exams.length);

      notifyListeners();
    } catch (e) {
      print("ADMIN API ERROR: $e");
    }
  }
    Future<String?> uploadPdfToServer(String examId, File file) async {
    try {
      final pdfPath = await _adminService.uploadPdf(examId, file);

      print("PDF uploaded successfully");
      print(pdfPath);

      return pdfPath;
    } catch (e) {
      print("UPLOAD ERROR: $e");
      return null;
    }
  }
  Future<void> uploadPdfToExistingExam(
  String examId,
  File file,
) async {

  final path = await _adminService.uploadPdf(
    examId,
    file,
  );

  final index = _exams.indexWhere(
    (e) => e.id == examId,
  );

  if (index != -1) {
    _exams[index].questionPaperPdfName = path;
    notifyListeners();
  }
}
    final List<MockExam> _exams = [];

final List<MockViolationLog> _violations = [];
    List<dynamic> _subjects = [];
    int _totalExams = 0;
    int _totalStudents = 0;
    int _activeProctors = 0;
    int _totalViolations = 0;

  List<dynamic> get subjects => _subjects;

  Future<void> loadSubjects() async {
    try {
      _subjects = await _adminService.getSubjects();

      print("========== SUBJECTS ==========");
      print(_subjects);

      notifyListeners();
    } catch (e) {
      print("LOAD SUBJECTS ERROR: $e");
    }
  }
    // Getters
    List<MockExam> get exams => _exams;
  
    List<MockViolationLog> get violations => _violations;
    // Analytics getters
    int get totalExamsCount => _totalExams;
    int get totalStudentsCount => _totalStudents;
    int get activeProctorsCount => _activeProctors;
    int get totalViolationsCount => _totalViolations;
    /// Creates a new exam session record.
  Future<void> createExam({
    required String title,
    required String subjectCode,
    required int durationMinutes,
    required int totalMarks,
    File? questionPaper,
  }) async {

    print("STEP 1: createExam() called");

      try {

      final subject = _subjects.firstWhere(
        (s) => s["code"] == subjectCode,
        orElse: () => throw Exception("Subject not found"),
      );

      String subjectId = subject["id"];



      print("STEP 2: Calling backend...");

      final exam = await _adminService.createExam(
        subjectId: subjectId,
        title: title,
        description: "",
        startTime: DateTime.now().toIso8601String(),
        endTime: DateTime.now()
            .add(Duration(minutes: durationMinutes))
            .toIso8601String(),
        durationMinutes: durationMinutes,
      );

      print("STEP 3: Backend responded");
      print(exam);
      print("Question Paper received: $questionPaper");

String? uploadedPdfPath;

if (questionPaper != null) {
  uploadedPdfPath = await uploadPdfToServer(
    exam["id"],
    questionPaper,
  );
}

final newExam = MockExam(
  id: exam["id"],
  title: exam["title"],
  subjectCode: subjectCode,
  durationMinutes: exam["duration_minutes"],
  totalMarks: totalMarks,
  status: exam["status"],
  questionPaperPdfName: uploadedPdfPath,
);

      _exams.add(newExam);

      notifyListeners();
    } catch (e) {
      print("CREATE EXAM ERROR: $e");
    }
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
    Future<void> assignInvigilator({
  required String examId,
  required String invigilatorId,
  required String invigilatorName,
}) async {
  try {
    await _adminService.assignInvigilator(
      examId,
      invigilatorId,
    );

    final idx = _exams.indexWhere((e) => e.id == examId);

    if (idx != -1) {
      _exams[idx].assignedInvigilator = invigilatorName;
      notifyListeners();
    }

    print("Invigilator assigned successfully");
  } catch (e) {
    print("ASSIGN INVIGILATOR ERROR: $e");
  }
}
    /// Generates the secure access passcode for an exam session.
    Future<void> generateSessionPasscode(String examId) async {
  try {
    final passcode = await _adminService.generatePasscode(examId);

    final idx = _exams.indexWhere((e) => e.id == examId);

    if (idx != -1) {
      _exams[idx].sessionPasscode = passcode;
      _exams[idx].status = "Ready";
      notifyListeners();
    }

    print("PASSCODE GENERATED");
    print(passcode);
  } catch (e) {
    print("PASSCODE ERROR: $e");
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
    List<dynamic> _invigilators = [];

  List<dynamic> get invigilators => _invigilators;

  Future<void> loadInvigilators() async {
    try {
      _invigilators = await _adminService.getInvigilators();

      print("========== INVIGILATORS ==========");
      print(_invigilators);

      notifyListeners();
    } catch (e) {
      print("INVIGILATOR ERROR: $e");
    }
  }
  Future<void> loadDashboardStats() async {
  try {
    final stats = await _adminService.getDashboardStats();

    _totalExams = stats["total_exams"];
    _totalStudents = stats["total_students"];
    _activeProctors = stats["active_proctors"];
    _totalViolations = stats["total_violations"];

    print("===== DASHBOARD STATS =====");
    print(stats);

    notifyListeners();
  } catch (e) {
    print("DASHBOARD ERROR: $e");
  }
}
Future<void> loadRecentViolations() async {
  try {
    final data = await _adminService.getRecentViolations();

    print("===== RECENT VIOLATIONS =====");
    print(data);

    _violations.clear();

    for (final item in data) {
      _violations.add(
        MockViolationLog(
          id: item["id"],
          studentName: item["student_name"],
          examTitle: item["exam_title"],
          violationType: item["violation_type"],
          timestamp: item["timestamp"],
          details: item["details"] ?? "",
        ),
      );
    }

    notifyListeners();
  } catch (e) {
    print("RECENT VIOLATIONS ERROR: $e");
  }
}
  }
