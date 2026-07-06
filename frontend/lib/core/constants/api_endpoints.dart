class ApiEndpoints {
  // Base URL pointing to the FastAPI backend server.
  // Note: Replace with 'http://10.0.2.2:8000/api/v1' when testing in Android Emulator.
 static const String baseUrl = "http://10.53.192.196:8000/api/v1";
  // Core Authentication Endpoints
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String me = '/auth/me';
  // Admin Management Endpoints
  static const String adminSubjects = '/admin/subjects';
  static const String adminExams = '/admin/exams';
  static const String adminCredentials = '/admin/invigilators/credentials';
  static String adminQrToken(String examId) => '/admin/exams/$examId/qr-token';
  // Invigilator Endpoints
  static const String invigilatorLogin = '/invigilator/login';
  static const String invigilatorExams = '/invigilator/exams';
  static const String invigilatorSubjects = '/invigilator/subjects';
  static String invigilatorQr(String examId) => '/invigilator/exams/$examId/qr-code';
  static const String invigilatorValidate = '/invigilator/validate-credential';
  // Student Endpoints
  static const String studentLogin = '/student/login';
  static const String studentProfile = '/student/profile';
  static const String studentValidateQr = '/student/validate-qr';
  static String studentStartExam(String examId) => '/student/exams/$examId/start';
  static const String studentSubmit = '/student/submit';
  // QR Token Validation Endpoints (Direct Access)
  static const String qrValidate = '/qr/validate';
  static const String qrUse = '/qr/use';
}
