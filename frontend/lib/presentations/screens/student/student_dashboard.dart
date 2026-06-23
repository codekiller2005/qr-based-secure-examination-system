import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../routes/app_routes.dart';
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}
class _InvKey {
  static const String keyOS = 'e-exam-000000000000000000000000000001';
  static const String keyPython = 'e-exam-000000000000000000000000000002';
  static const String keyCalculus = 'e-exam-000000000000000000000000000003';
}
class _StudentDashboardState extends State<StudentDashboard> {
  // Mock Exam List
  final List<Map<String, dynamic>> _exams = [
    {
      'id': _InvKey.keyOS,
      'subject_code': 'CS-302',
      'title': 'Operating Systems Midterm 2026',
      'duration': 120,
      'time': 'Ongoing (09:00 - 11:00)',
      'status': 'Ready', // Ready to scan QR and start
    },
    {
      'id': _InvKey.keyPython,
      'subject_code': 'CS-101',
      'title': 'Python Fundamentals Final 2026',
      'duration': 180,
      'time': 'Scheduled: In 2 Days',
      'status': 'Scheduled',
    },
    {
      'id': _InvKey.keyCalculus,
      'subject_code': 'MATH-201',
      'title': 'Calculus I Midterm',
      'duration': 90,
      'time': 'Completed: Yesterday',
      'status': 'Completed',
    },
  ];
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Student Desk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFCA5A5)),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Student Profile header with premium gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.school_rounded, size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.username ?? 'Student',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Role: Registered Student (Secure Room Access)',
                          style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: const [
                Icon(Icons.assignment_outlined, color: Color(0xFF6366F1), size: 20),
                SizedBox(width: 8),
                Text(
                  "Your Examinations",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Render list of mock exams or Empty State
            _exams.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF64748B)),
                        SizedBox(height: 16),
                        Text(
                          "All Clear!",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "You have no examinations scheduled at this moment.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _exams.length,
                    itemBuilder: (context, index) {
                      final exam = _exams[index];
                      return _buildExamCard(exam);
                    },
                  ),
          ],
        ),
      ),
    );
  }
  Widget _buildExamCard(Map<String, dynamic> exam) {
    final String status = exam['status'];
    Color badgeColor;
    Color borderCol = const Color(0xFF334155);
    Widget actionButton;
    if (status == 'Ready') {
      badgeColor = const Color(0xFF10B981); // Green
      borderCol = const Color(0xFF6366F1);
      actionButton = ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.studentQrScan),
        icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: Colors.white),
        label: const Text("Unlock via QR Code"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      );
    } else if (status == 'Scheduled') {
      badgeColor = const Color(0xFFF59E0B); // Amber
      actionButton = OutlinedButton.icon(
        onPressed: null, // Disabled
        icon: const Icon(Icons.lock_clock_outlined, size: 18),
        label: const Text("Locked (Upcoming)"),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF334155)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      );
    } else {
      badgeColor = const Color(0xFF64748B); // Slate
      actionButton = OutlinedButton.icon(
        onPressed: null, // Disabled
        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
        label: const Text("Completed & Synced"),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF1E293B)),
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderCol, width: status == 'Ready' ? 1.5 : 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      exam['subject_code'],
                      style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                exam['title'],
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    exam['time'],
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              actionButton,
            ],
          ),
        ),
      ),
    );
  }
}
