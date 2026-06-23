class ExamSession {
  final String id;
  final String title;
  final String subjectCode;
  final int durationMinutes;
  final String timeDisplay;
  String status; // 'upcoming', 'active', 'completed'
  int totalStudents;
  int activeStudents;
  ExamSession({
    required this.id,
    required this.title,
    required this.subjectCode,
    required this.durationMinutes,
    required this.timeDisplay,
    required this.status,
    required this.totalStudents,
    required this.activeStudents,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subjectCode': subjectCode,
        'durationMinutes': durationMinutes,
        'timeDisplay': timeDisplay,
        'status': status,
        'totalStudents': totalStudents,
        'activeStudents': activeStudents,
      };
  factory ExamSession.fromJson(Map<String, dynamic> json) => ExamSession(
        id: json['id'],
        title: json['title'],
        subjectCode: json['subjectCode'],
        durationMinutes: json['durationMinutes'],
        timeDisplay: json['timeDisplay'],
        status: json['status'],
        totalStudents: json['totalStudents'],
        activeStudents: json['activeStudents'],
      );
}
class ProctoredStudent {
  final String id;
  final String name;
  final String examId;
  String connectionStatus; // 'online', 'offline'
  String qrValidationStatus; // 'validated', 'pending'
  ProctoredStudent({
    required this.id,
    required this.name,
    required this.examId,
    required this.connectionStatus,
    required this.qrValidationStatus,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'examId': examId,
        'connectionStatus': connectionStatus,
        'qrValidationStatus': qrValidationStatus,
      };
  factory ProctoredStudent.fromJson(Map<String, dynamic> json) => ProctoredStudent(
        id: json['id'],
        name: json['name'],
        examId: json['examId'],
        connectionStatus: json['connectionStatus'],
        qrValidationStatus: json['qrValidationStatus'],
      );
}
