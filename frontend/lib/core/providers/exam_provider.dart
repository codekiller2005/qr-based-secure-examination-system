import 'dart:async';
import 'package:flutter/material.dart';
class Question {
  final int id;
  final String text;
  final String type; // 'Theory', 'Descriptive', 'Numerical'
  const Question({
    required this.id,
    required this.text,
    required this.type,
  });
}
class ExamProvider extends ChangeNotifier {
  String? _activeExamId;
  String? _activeExamTitle;
  bool _isExamStarted = false;
  
  // Timer States
  Timer? _timer;
  int _timerSecondsRemaining = 0;
  // Question States
  int _currentQuestionIndex = 0;
  final Set<int> _markedForReview = {}; // set of question.id
  // Result States
  Map<String, dynamic>? _examResult;
  // Mock Descriptive / Theory Questions
  final List<Question> _mockQuestions = const [
    Question(
      id: 1,
      text: "Explain process scheduling in Operating Systems. Detail the roles of Short-term, Medium-term, and Long-term schedulers, and explain how a process transitions between states.",
      type: "Theory",
    ),
    Question(
      id: 2,
      text: "Compare FCFS (First-Come First-Served) and Round Robin scheduling algorithms. Discuss their turnaround time, response time performance, and the impact of the time quantum size on Round Robin.",
      type: "Descriptive",
    ),
    Question(
      id: 3,
      text: "Solve the given CPU scheduling numerical:\n\nConsider four processes P1, P2, P3, and P4 with arrival times (0, 1, 2, 4) and CPU burst times (5, 4, 2, 3) respectively. Draw the Gantt chart and calculate the average waiting time and turnaround time using Preemptive Shortest Remaining Time First (SRTF) scheduling.",
      type: "Numerical",
    ),
  ];
  // Getters
  String? get activeExamId => _activeExamId;
  String? get activeExamTitle => _activeExamTitle;
  bool get isExamStarted => _isExamStarted;
  int get timerSecondsRemaining => _timerSecondsRemaining;
  int get currentQuestionIndex => _currentQuestionIndex;
  List<Question> get questions => _mockQuestions;
  Set<int> get markedForReview => _markedForReview;
  Map<String, dynamic>? get examResult => _examResult;
  String get formattedTimer {
    final minutes = (_timerSecondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timerSecondsRemaining % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
  /// Begins a new examination session and launches the countdown timer.
  void startExam(String examId, String examTitle, int durationMinutes) {
    _activeExamId = examId;
    _activeExamTitle = examTitle;
    _isExamStarted = true;
    _currentQuestionIndex = 0;
    _markedForReview.clear();
    _examResult = null;
    
    // Set timer
    _timerSecondsRemaining = durationMinutes * 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSecondsRemaining > 0) {
        _timerSecondsRemaining--;
        notifyListeners();
      } else {
        _timer?.cancel();
        submitExamAuto();
      }
    });
    notifyListeners();
  }
  /// Navigates questions index.
  void setCurrentQuestionIndex(int index) {
    if (index >= 0 && index < _mockQuestions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }
  /// Toggle review flag.
  void toggleMarkForReview(int questionId) {
    if (_markedForReview.contains(questionId)) {
      _markedForReview.remove(questionId);
    } else {
      _markedForReview.add(questionId);
    }
    notifyListeners();
  }
  /// Checks if a question is marked for review.
  bool isQuestionMarked(int questionId) {
    return _markedForReview.contains(questionId);
  }
  /// Processes score validation calculations.
  void submitExam() {
    _timer?.cancel();
    _calculateResults();
  }
  /// Auto-submission upon timer expiry.
  void submitExamAuto() {
    _timer?.cancel();
    _calculateResults();
  }
  void _calculateResults() {
    final now = DateTime.now().toLocal();
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    _examResult = {
      "exam_title": _activeExamTitle ?? 'Operating Systems Midterm 2026',
      "submission_time": timeString,
      "total_questions": _mockQuestions.length,
    };
    _isExamStarted = false;
    notifyListeners();
  }
  void resetExamState() {
    _activeExamId = null;
    _activeExamTitle = null;
    _isExamStarted = false;
    _timer?.cancel();
    _timerSecondsRemaining = 0;
    _currentQuestionIndex = 0;
    _markedForReview.clear();
    _examResult = null;
    notifyListeners();
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
