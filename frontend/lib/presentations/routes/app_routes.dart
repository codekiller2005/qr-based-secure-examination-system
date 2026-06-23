import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/invigilator/invigilator_dashboard.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/student/exam_instructions_screen.dart';
import '../screens/student/exam_screen.dart';
import '../screens/student/result_screen.dart';
import '../screens/student/qr_scan_screen.dart';
import '../screens/student/qr_validation_screen.dart';
import '../screens/student/qr_success_screen.dart';
import '../screens/student/qr_failure_screen.dart';
class AppRoutes {
  static const String login = '/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String invigilatorDashboard = '/invigilator/dashboard';
  static const String studentDashboard = '/student/dashboard';
  static const String studentInstructions = '/student/instructions';
  static const String studentExam = '/student/exam-room';
  static const String studentResult = '/student/result';
  static const String studentQrScan = '/student/qr-scan';
  static const String studentQrValidation = '/student/qr-validation';
  static const String studentQrSuccess = '/student/qr-success';
  static const String studentQrFailure = '/student/qr-failure';
  /// Maps static paths to screen widgets.
  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        adminDashboard: (context) => const AdminDashboard(),
        invigilatorDashboard: (context) => const InvigilatorDashboard(),
        studentDashboard: (context) => const StudentDashboard(),
        studentInstructions: (context) => const ExamInstructionsScreen(),
        studentExam: (context) => const QuestionPaperViewer(),
        studentResult: (context) => const ResultScreen(),
        studentQrScan: (context) => const QRScanScreen(),
        studentQrValidation: (context) => const QRValidationScreen(),
        studentQrSuccess: (context) => const QRSuccessScreen(),
        studentQrFailure: (context) => const QRFailureScreen(),
      };
}
