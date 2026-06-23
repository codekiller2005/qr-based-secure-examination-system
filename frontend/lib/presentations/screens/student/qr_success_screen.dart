import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/qr_provider.dart';
import '../../routes/app_routes.dart';
class QRSuccessScreen extends StatelessWidget {
  const QRSuccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final qrProvider = Provider.of<QRProvider>(context);
    final examData = qrProvider.validatedExamData;
    final String examId = examData?['examId'] ?? 'CS101';
    final String subjectName = examData?['subject'] ?? 'Artificial Intelligence';
    final String startTime = examData?['startTime'] ?? '09:00 AM';
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Checkmark Icon
              const CircleAvatar(
                radius: 46,
                backgroundColor: Color(0xFF10B981), // Green
                child: Icon(Icons.check_rounded, size: 54, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                "Entrance Key Verified",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                "You are authorized to enter this exam room.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 32),
              // Exam Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "VERIFIED EXAMINATION DETAILS",
                      style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(label: "Course Subject", value: subjectName),
                    const Divider(color: Color(0xFF334155), height: 24),
                    _buildDetailRow(label: "Exam Identifier", value: examId),
                    const Divider(color: Color(0xFF334155), height: 24),
                    _buildDetailRow(label: "Scheduled Time", value: startTime),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Proceed Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  // Reset scanner state to be clean for future operations
                  qrProvider.resetState();
                  
                  // Route to the Exam Instructions Screen passing the parsed details
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.studentInstructions,
                    arguments: {
                      'id': examId,
                      'title': '$subjectName Midterm',
                      'subject_code': examId,
                      'duration': 120, // default/fallback duration
                    },
                  );
                },
                child: const Text(
                  "Proceed to Instructions",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDetailRow({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
