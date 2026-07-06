import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/invigilator_provider.dart';
import '../../../core/models/exam_session.dart';
import '../../routes/app_routes.dart';
import 'package:qr_flutter/qr_flutter.dart';
class InvigilatorDashboard extends StatefulWidget {
  const InvigilatorDashboard({super.key});
  @override
  State<InvigilatorDashboard> createState() => _InvigilatorDashboardState();
}
class _InvigilatorDashboardState extends State<InvigilatorDashboard> {
  ExamSession? _monitoredExam; // Active proctor monitoring target
  bool _showQrDialog = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InvigilatorProvider>(context, listen: false).loadDashboardData();
    });
  }
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }
  void _openQrProjection(InvigilatorProvider provider, ExamSession exam) async {
    await provider.generateQrCode(exam);
    setState(() {
      _showQrDialog = true;
    });
  }
  void _closeQrProjection(InvigilatorProvider provider) {
    provider.stopProjectingQr();
    setState(() {
      _showQrDialog = false;
    });
  }
  void _startExamSession(InvigilatorProvider provider, ExamSession exam) async {
    await provider.startExam(exam.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Exam session '${exam.title}' is now ACTIVE."),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }
  void _endExamSession(InvigilatorProvider provider, ExamSession exam) async {
    await provider.endExam(exam.id);
    if (_monitoredExam?.id == exam.id) {
      setState(() {
        _monitoredExam = null;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Exam session '${exam.title}' has been COMPLETED."),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final invigilatorProvider = Provider.of<InvigilatorProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          _monitoredExam == null ? 'Invigilator Console' : 'Proctor Monitoring',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: _monitoredExam != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _monitoredExam = null;
                  });
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFCA5A5)),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: invigilatorProvider.isLoading && invigilatorProvider.exams.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _monitoredExam == null
                    ? _buildDashboardView(invigilatorProvider, authProvider)
                    : _buildMonitoringView(invigilatorProvider, _monitoredExam!),
                
                // Floating QR code generator modal dialog overlay
                if (_showQrDialog && invigilatorProvider.activeQrContent != null)
                  _buildQrProjectionOverlay(invigilatorProvider),
              ],
            ),
    );
  }
  /// 1. Main Dashboard View (Stats + Exam Status Tabs)
  Widget _buildDashboardView(InvigilatorProvider provider, AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Proctor profile greeting with premium emerald gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.2),
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
                  child: Icon(Icons.shield_rounded, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.username ?? 'Invigilator Desk',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Role: Head Proctor / Invigilator (Secure Roster Console)',
                        style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Statistics Dashboard Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                label: "Assigned Students",
                value: "${provider.totalStudentsCount}",
                icon: Icons.group_outlined,
                color: const Color(0xFF6366F1), // Indigo
              ),
              _buildStatCard(
                label: "Online Roster",
                value: "${provider.activeStudentsCount}",
                icon: Icons.wifi_tethering,
                color: const Color(0xFF10B981), // Emerald
              ),
              _buildStatCard(
                label: "Active Papers",
                value: "${provider.activeExamsCount}",
                icon: Icons.play_circle_outline,
                color: const Color(0xFFF59E0B), // Amber
              ),
              _buildStatCard(
                label: "Closed Logs",
                value: "${provider.completedExamsCount}",
                icon: Icons.check_circle_outline,
                color: const Color(0xFF64748B), // Slate
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Exam Categories Schedule Tabs
          DefaultTabController(
            length: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TabBar(
                  indicatorColor: Color(0xFF6366F1),
                  labelColor: Colors.white,
                  unselectedLabelColor: Color(0xFF94A3B8),
                  tabs: [
                    Tab(text: "Active"),
                    Tab(text: "Upcoming"),
                    Tab(text: "Completed"),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 380,
                  child: TabBarView(
                    children: [
                      _buildExamListFiltered(provider, 'active'),
                      _buildExamListFiltered(provider, 'upcoming'),
                      _buildExamListFiltered(provider, 'completed'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildExamListFiltered(InvigilatorProvider provider, String filterStatus) {
    final filtered = provider.exams.where((e) => e.status == filterStatus).toList();
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 48, color: const Color(0xFF334155)),
            const SizedBox(height: 12),
            Text(
              "No ${filterStatus} examinations found.",
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final exam = filtered[index];
        return _buildExamCard(provider, exam);
      },
    );
  }
  Widget _buildExamCard(InvigilatorProvider provider, ExamSession exam) {
    final bool isActive = exam.status == 'active';
    final bool isUpcoming = exam.status == 'upcoming';
    final bool isCompleted = exam.status == 'completed';
    Color borderCol = const Color(0xFF334155);
    if (isActive) borderCol = const Color(0xFF10B981);
    if (isUpcoming) borderCol = const Color(0xFF6366F1);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderCol, width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                      exam.subjectCode,
                      style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFF94A3B8), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${exam.durationMinutes} mins",
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                exam.title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                exam.timeDisplay,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 16),
              // Dynamic proctor actions depending on status
              Row(
                children: [
                  if (isUpcoming) ...[
                    ElevatedButton.icon(
                      onPressed: () => _startExamSession(provider, exam),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text("Start Session"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openQrProjection(provider, exam),
                      icon: const Icon(Icons.qr_code_rounded, size: 18),
                      label: const Text("Access QR"),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                  if (isActive) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.loadConnectedStudents(exam.id);
                        setState(() {
                          _monitoredExam = exam;
                        });
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text("Monitor Roster"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openQrProjection(provider, exam),
                      icon: const Icon(Icons.qr_code_rounded, size: 18),
                      label: const Text("Show QR"),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.stop_circle_outlined, color: Color(0xFFEF4444)),
                      onPressed: () => _endExamSession(provider, exam),
                      tooltip: "End Session",
                    ),
                  ],
                  if (isCompleted) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Color(0xFF94A3B8), size: 16),
                          SizedBox(width: 6),
                          Text("Session Log Closed", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  /// 2. Student Monitoring Roster View
  Widget _buildMonitoringView(InvigilatorProvider provider, ExamSession exam) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Monitored Header Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      exam.subjectCode,
                      style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "LIVE MONITORING",
                        style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  exam.title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Assigned: ${exam.totalStudents} Students",
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _endExamSession(provider, exam),
                      icon: const Icon(Icons.power_settings_new_rounded, size: 14),
                      label: const Text("End Session", style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Roster statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CONNECTED STUDENT ROSTER",
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF818CF8), size: 20),
                onPressed: () => provider.loadConnectedStudents(exam.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Student Live Grid/List View
          Expanded(
            child: provider.students.isEmpty
                ? const Center(child: Text("Waiting for student connections...", style: TextStyle(color: Color(0xFF64748B))))
                : ListView.builder(
                    itemCount: provider.students.length,
                    itemBuilder: (context, index) {
                      final student = provider.students[index];
                      final bool isOnline = student.connectionStatus == 'online';
                      final bool isValidated = student.qrValidationStatus == 'validated';
                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF334155)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isOnline ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFF64748B).withOpacity(0.15),
                            child: Icon(
                              isOnline ? Icons.school_rounded : Icons.school_outlined,
                              color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            "ID: ${student.id}",
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Online / Offline Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isOnline ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isOnline ? "ONLINE" : "OFFLINE",
                                  style: TextStyle(
                                    color: isOnline ? const Color(0xFF34D399) : const Color(0xFFFCA5A5),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Validation status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isValidated ? const Color(0xFF6366F1).withOpacity(0.1) : const Color(0xFFF59E0B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isValidated ? "VALIDATED" : "PENDING QR",
                                  style: TextStyle(
                                    color: isValidated ? const Color(0xFF818CF8) : const Color(0xFFFBBF24),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  /// 3. Overlay Modal QR code generator layout
  Widget _buildQrProjectionOverlay(InvigilatorProvider provider) {
    final exam = provider.activeQrExam!;
    final payload = provider.activeQrContent!;
    return Container(
      color: Colors.black.withOpacity(0.75),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "QR CODE DESK PROJECTOR",
                  style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => _closeQrProjection(provider),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              exam.title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              "Subject: ${exam.subjectCode}  |  Status: ${exam.status.toUpperCase()}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
            const SizedBox(height: 24),
            // Realistic Pixel Grid QR Generator Simulator
           Center(
  child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: QrImageView(
      data: payload,
      version: QrVersions.auto,
      size: 200,
      backgroundColor: Colors.white,
    ),
  ),
),
            const SizedBox(height: 20),
            // Real payload details console display for developers
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Generated JSON Validation Content:", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                  const SizedBox(height: 4),
                  SelectableText(
                    payload,
                    style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Start Session Quick trigger from QR projection page
            if (exam.status == 'upcoming')
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  _startExamSession(provider, exam);
                  _closeQrProjection(provider);
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text("Start Examination Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF334155)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _closeQrProjection(provider),
              child: const Text("Close Reference Projection", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
