import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/admin_provider.dart';
import '../../routes/app_routes.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}
class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Form keys and controllers for exam creation
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _durationController = TextEditingController();
  final _marksController = TextEditingController();
  // Dropdown states for proctor assignments
 String? _selectedAssignExamId;
 String? _selectedInvigilatorId;
 String? _selectedInvigilatorName;
  // Dropdown states for PDF upload simulation
  String? _selectedUploadExamId;
  String? _uploadedPdfName;
  File? _selectedQuestionPaper;
  // Dropdown states for passcode session generation
  String? _selectedSessionExamId;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _codeController.dispose();
    _durationController.dispose();
    _marksController.dispose();
    super.dispose();
  }
  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }
   
 Future<void> _submitCreateExam(AdminProvider provider) async {

     print("Before createExam: $_selectedQuestionPaper");
    if (!_formKey.currentState!.validate()) return;
    await provider.createExam(
  title: _titleController.text.trim(),
  subjectCode: _codeController.text.trim().toUpperCase(),
  durationMinutes: int.parse(_durationController.text.trim()),
  totalMarks: int.parse(_marksController.text.trim()),
  questionPaper: _selectedQuestionPaper,
);
    print("DASHBOARD STEP 2");
    // Reset Form fields
    _titleController.clear();
    _codeController.clear();
    _durationController.clear();
    _marksController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("New examination registered successfully!"),
        backgroundColor: Color(0xFF10B981),
      ),
    );
    // Auto navigate to the ledger/reports tab to verify
    _tabController.animateTo(3);
  }
  Future<void> _simulatePdfUpload(AdminProvider provider) async {
  if (_selectedUploadExamId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select an exam first."),
      ),
    );
    return;
  }

  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result == null) {
    return;
  }

  File file = File(result.files.single.path!);

  final pdfPath = await provider.uploadPdfToServer( _selectedUploadExamId!,file);

  if (pdfPath == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Upload failed."),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    _uploadedPdfName = file.path.split('/').last;
  });

  provider.uploadPdf(
    _selectedUploadExamId!,
    _uploadedPdfName!,
  );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Uploaded successfully!\n$pdfPath"),
      backgroundColor: Colors.green,
    ),
  );
}
 Future<void> _assignProctor(AdminProvider provider) async {
    if (_selectedAssignExamId == null || _selectedInvigilatorId == null)  {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both an Exam and an Invigilator.")),
      );
      return;
    }
   await provider.assignInvigilator(
  examId: _selectedAssignExamId!,
  invigilatorId: _selectedInvigilatorId!,
  invigilatorName: _selectedInvigilatorName!,
);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
      content: Text(
  "Assigned $_selectedInvigilatorName to selected exam session.",
),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }
  Future<void> _generatePasscode(AdminProvider provider) async {
    if (_selectedSessionExamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an exam target first.")),
      );
      return;
    }
    await provider.generateSessionPasscode(_selectedSessionExamId!);
    final updatedExam = provider.exams.firstWhere((e) => e.id == _selectedSessionExamId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Generated Passcode: ${updatedExam.sessionPasscode}"),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Admin Console',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFCA5A5)),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: "Analytics"),
            Tab(icon: Icon(Icons.note_add_outlined), text: "Create Exam"),
            Tab(icon: Icon(Icons.assignment_ind_outlined), text: "Sessions"),
            Tab(icon: Icon(Icons.assignment_outlined), text: "Reports"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalyticsTab(adminProvider, authProvider),
          _buildCreateExamTab(adminProvider),
          _buildSessionManagementTab(adminProvider),
          _buildReportsTab(adminProvider),
        ],
      ),
    );
  }
  /// 1. Analytics & Violation Logs Tab
  Widget _buildAnalyticsTab(AdminProvider provider, AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greeting Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.admin_panel_settings_rounded, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${authProvider.username ?? "Admin"}!',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Role: System Administrator (Mock Environment)',
                        style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Analytics Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _buildStatCard("Total Exams Registered", "${provider.totalExamsCount}", Icons.book_rounded, const Color(0xFF3B82F6)),
              _buildStatCard("Total Enrolled Students", "${provider.totalStudentsCount}", Icons.groups_outlined, const Color(0xFF10B981)),
              _buildStatCard("Active Proctor Desks", "${provider.activeProctorsCount}", Icons.shield_outlined, const Color(0xFFF59E0B)),
              _buildStatCard("Security Intrusion Flags", "${provider.totalViolationsCount}", Icons.warning_amber_rounded, const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 28),
          // Live Violation Logs
          Row(
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 8),
              const Text(
                "LIVE HARDWARE INTRUSION LOGS",
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.violations.length,
            itemBuilder: (context, index) {
              final log = provider.violations[index];
              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF334155)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEF4444).withOpacity(0.15),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFCA5A5), size: 20),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(log.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.violationType,
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Exam: ${log.examTitle}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      Text("Triggered: ${log.timestamp}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                      const SizedBox(height: 4),
                      Text("Details: ${log.details}", style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  /// 2. Create Exam & Question Paper Upload Tab
  Widget _buildCreateExamTab(AdminProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Registration Form
          const Text(
            "REGISTER NEW EXAMINATION",
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: _buildInputDecoration("Exam Session Title", Icons.title),
                    validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                     Expanded(
  child: DropdownButtonFormField<String>(
    value: _codeController.text.isEmpty ? null : _codeController.text,
    decoration: _buildInputDecoration("Subject", Icons.code),
    dropdownColor: const Color(0xFF1E293B),
    style: const TextStyle(color: Colors.white),
    items: provider.subjects.map<DropdownMenuItem<String>>((subject) {
      return DropdownMenuItem<String>(
        value: subject["code"],
        child: Text(
          "${subject["code"]} - ${subject["name"]}",
          style: const TextStyle(color: Colors.white),
        ),
      );
    }).toList(),
    onChanged: (value) {
      setState(() {
        _codeController.text = value!;
      });
    },
    validator: (value) =>
        value == null || value.isEmpty ? "Required" : null,
  ),
),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration("Duration (Mins)", Icons.timer_outlined),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return "Required";
                            if (int.tryParse(val.trim()) == null) return "Invalid";
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _marksController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration("Total Maximum Marks", Icons.grade_outlined),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return "Required";
                      if (int.tryParse(val.trim()) == null) return "Invalid Number";
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
onPressed: () async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result != null) {
    setState(() {
      _selectedQuestionPaper = File(result.files.single.path!);
    });

    print("PDF SELECTED: ${_selectedQuestionPaper!.path}");
  } else {
    print("NO PDF SELECTED");
  }
},
  icon: const Icon(Icons.picture_as_pdf),
  label: Text(
    _selectedQuestionPaper == null
        ? "Choose Question Paper PDF"
        : _selectedQuestionPaper!.path.split('/').last,
  ),
),

const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _submitCreateExam(provider),
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    label: const Text("Create Examination Session", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        
          // Question Paper Mock PDF Uploader
          
        ],
      ),
    );
  }
  /// 3. Assign Invigilator & Passcode generator Tab
  Widget _buildSessionManagementTab(AdminProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Proctor Assignment Card
          const Text(
            "ASSIGN EXAM INVIGILATOR / PROCTOR",
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedAssignExamId,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration("Select Target Exam", Icons.bookmark_added_outlined),
                  items: provider.exams.map((exam) {
                    return DropdownMenuItem(
                      value: exam.id,
                      child: Text("${exam.subjectCode} - ${exam.title}"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedAssignExamId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
               DropdownButtonFormField<String>(value: _selectedInvigilatorId,dropdownColor: const Color(0xFF1E293B),
               style: const TextStyle(color: Colors.white),
               decoration: _buildInputDecoration("Select Assigned Invigilator",Icons.person_outline_rounded,),
               items: provider.invigilators.map<DropdownMenuItem<String>>((user) {
                return DropdownMenuItem<String>(value: user["id"] as String,child: Text(user["username"] as String),);
                }).toList(),onChanged: (value) {
    final selected = provider.invigilators.firstWhere(
      (user) => user["id"] == value,
    );

    setState(() {
      _selectedInvigilatorId = selected["id"];
      _selectedInvigilatorName = selected["username"];
    });
  },
),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _assignProctor(provider),
                  icon: const Icon(Icons.assignment_ind_outlined, color: Colors.white),
                  label: const Text("Assign Proctor", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Session generation Card
          const Text(
            "GENERATE EXAM SESSION PASSCODE",
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedSessionExamId,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration("Select Exam Target", Icons.lock_open_rounded),
                  items: provider.exams.map((exam) {
                    return DropdownMenuItem(
                      value: exam.id,
                      child: Text("${exam.subjectCode} - ${exam.title}"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSessionExamId = val;
                    });
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Emerald
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {await _generatePasscode(provider);},
                  icon: const Icon(Icons.key_rounded, color: Colors.white),
                  label: const Text("Activate Session Passcode", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  /// 4. Exam Reports Ledger Tab
  Widget _buildReportsTab(AdminProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "EXAMINATION LEDGER & AUDIT REPORTS",
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          
          provider.exams.isEmpty
              ? const Center(child: Text("No exams found.", style: TextStyle(color: Color(0xFF64748B))))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.exams.length,
                  itemBuilder: (context, index) {
                    final exam = provider.exams[index];
                    
                    Color statusColor = const Color(0xFF6366F1);
                    if (exam.status == 'Ready') statusColor = const Color(0xFF10B981);
                    if (exam.status == 'Active') statusColor = const Color(0xFFF59E0B);
                    if (exam.status == 'Completed') statusColor = const Color(0xFF64748B);
                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF334155)),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    exam.status.toUpperCase(),
                                    style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              exam.title,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Color(0xFF334155), height: 1),
                            const SizedBox(height: 12),
                            
                            _buildLedgerRow("Exam Duration", "${exam.durationMinutes} Minutes"),
                            _buildLedgerRow("Total Evaluation Marks", "${exam.totalMarks} Marks"),
                            _buildLedgerRow("Question Paper File", exam.questionPaperPdfName ?? "Not Uploaded (Pending)"),
                            _buildLedgerRow("Assigned Invigilator", exam.assignedInvigilator ?? "Unassigned (Pending)"),
                            _buildLedgerRow("Session Passcode", exam.sessionPasscode ?? "Inactive (Pending)"),
                            const SizedBox(height: 16),

ElevatedButton.icon(
  onPressed: () async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      await provider.uploadPdfToExistingExam(
        exam.id,
        File(result.files.single.path!),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Question paper uploaded successfully!"),
        ),
      );
      setState(() {});
    }
  },
  icon: const Icon(Icons.upload_file),
  label: const Text("Upload Question Paper"),
),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
  Widget _buildLedgerRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
  InputDecoration _buildInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: const Color(0xFF818CF8), size: 18),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
