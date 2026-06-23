import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/exam_provider.dart';
import '../../routes/app_routes.dart';
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExamProvider>(context);
    final results = provider.examResult;
    // Safety fallback if results aren't populated yet
    if (results == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("No exam details found.", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard),
                child: const Text("Go to Dashboard"),
              ),
            ],
          ),
        ),
      );
    }
    final String examTitle = results['exam_title'] ?? 'Descriptive Examination';
    final String submissionTime = results['submission_time'] ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevent navigation back
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Paper View Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                
                // Big Glowing Document Icon Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1), // Emerald opacity
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF10B981),
                      size: 80,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Success Title & Subtitles
                const Text(
                  "Question Paper Opened Successfully.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Please write answers on the provided physical answer sheets.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFCA5A5), // Soft red/pink warning highlight
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 36),
                // Exam Submission Details Panel
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
                      const Text(
                        "SESSION METADATA",
                        style: TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      _buildDetailRow(label: 'Examination Name', value: examTitle),
                      const Divider(color: Color(0xFF334155), height: 24),
                      
                      _buildDetailRow(label: 'Access Timestamp', value: submissionTime),
                      const Divider(color: Color(0xFF334155), height: 24),
                      
                      _buildDetailRow(
                        label: 'Hand-In Policy', 
                        value: 'Hand over physical sheets to invigilator', 
                        isHighlightValue: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Return to Dashboard Button
                ElevatedButton(
                  onPressed: () {
                    provider.resetExamState(); // Clear cached provider data
                    Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard);
                  },
                  child: const Text("Return to Dashboard"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildDetailRow({
    required String label,
    required String value,
    bool isHighlightValue = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isHighlightValue ? const Color(0xFFF59E0B) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
