import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/qr_provider.dart';
import '../../routes/app_routes.dart';
class QRFailureScreen extends StatelessWidget {
  const QRFailureScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final qrProvider = Provider.of<QRProvider>(context);
    final String errorMessage = qrProvider.validationError ?? 
        "Invalid entrance token signature or malformed credentials payload.";
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning Failure Icon
              const CircleAvatar(
                radius: 46,
                backgroundColor: Color(0xFFEF4444), // Red
                child: Icon(Icons.warning_amber_rounded, size: 54, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                "Verification Failed",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                "We were unable to validate this exam key.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 32),
              // Error Description Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ERROR DIAGNOSTICS",
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Please ensure you are scanning the correct QR projected by the invigilator and try again. If the issue persists, request a new passcode card.",
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Action Buttons
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text(
                  "Scan Again",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () {
                  qrProvider.resetState();
                  Navigator.pushReplacementNamed(context, AppRoutes.studentQrScan);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF334155)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  qrProvider.resetState();
                  Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard);
                },
                child: const Text(
                  "Return to Dashboard",
                  style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
