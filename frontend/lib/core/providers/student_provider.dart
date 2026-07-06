import 'package:flutter/material.dart';
import '../services/student_service.dart';

class StudentProvider extends ChangeNotifier {
  final StudentService _studentService;

  StudentProvider(this._studentService) {
    loadMyExams();
  }

  List<dynamic> _exams = [];

  List<dynamic> get exams => _exams;

  Future<void> loadMyExams() async {
    try {
      _exams = await _studentService.getMyExams();

      print("===== STUDENT EXAMS =====");
      print(_exams);

      notifyListeners();
    } catch (e) {
      print("STUDENT EXAMS ERROR: $e");
    }
  }
}