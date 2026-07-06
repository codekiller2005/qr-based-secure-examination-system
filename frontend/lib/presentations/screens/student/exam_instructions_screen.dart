import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/exam_provider.dart';
import '../../routes/app_routes.dart';
import 'question_paper_viewer_screen.dart';
class ExamInstructionsScreen extends StatelessWidget {
  const ExamInstructionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Read the passed route arguments (Map containing exam details)
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String examId = args['id'] ?? '1';
    
    final String examTitle = args['title'] ?? 'Operating Systems Midterm 2026';
    final String subjectCode = args['subject_code'] ?? 'CS-302';
    final int durationMinutes = args['duration'] ?? 120;
 
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Exam Instructions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exam Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          subjectCode,
                          style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Color(0xFF94A3B8), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$durationMinutes Mins',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    examTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Format: Descriptive Theory & Numerical Questions (Physical Answer Sheets)',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: const [
                Icon(Icons.gavel_rounded, color: Color(0xFFEF4444), size: 18),
                SizedBox(width: 8),
                Text(
                  "CRITICAL EXAMINATION INTEGRITY RULES",
                  style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Rules Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155), width: 1.2),
              ),
              child: const Column(
                children: [
                  _buildRuleRow(number: "1", text: "Ensure your device is in Airplane Mode and all wireless signals (Wi-Fi, Bluetooth, Data) are disabled. Periodic scans are executed automatically."),
                  Divider(color: Color(0xFF334155), height: 28),
                  _buildRuleRow(number: "2", text: "Do NOT attempt to background, exit, or lock the app during the exam. Leaving the focus area logs an immediate security warning."),
                  Divider(color: Color(0xFF334155), height: 28),
                  _buildRuleRow(number: "3", text: "Screenshots, screen recordings, and USB debug plug-ins are strictly prohibited. These triggers are logged as critical violations."),
                  Divider(color: Color(0xFF334155), height: 28),
                  _buildRuleRow(number: "4", text: "Each violation is cryptographically hash-chained in the local database. Deleting or modifying logs triggers a verification audit failure on submission."),
                  Divider(color: Color(0xFF334155), height: 28),
                  _buildRuleRow(number: "5", text: "Write all answers on the physical answer sheets provided by the invigilator. Finish the timer before exiting the viewing console."),
                ],
              ),
            ),
            const SizedBox(height: 36),
            // Start Button
            ElevatedButton(
              onPressed: () async {

  final examProvider =
      Provider.of<ExamProvider>(context, listen: false);
  final String? pdfPath =
    examProvider.cachedPdfPath;

    if (pdfPath == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Question paper not found. Please scan the QR again.",
      ),
    ),
  );
  return;
}

 await examProvider.startOfflineExam(
  examId,
  examTitle,
  durationMinutes,
);

if (!context.mounted) return;

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => QuestionPaperViewerScreen(
      pdfPath: pdfPath,
    ),
  ),
);
},
              child: const Text("I Understand, Start Exam"),
            ),
          ],
        ),
      ),
    );
  }
}
class _buildRuleRow extends StatelessWidget {
  final String number;
  final String text;
  const _buildRuleRow({required this.number, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: const Color(0xFFEF4444).withOpacity(0.2),
          child: Text(
            number,
            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}
