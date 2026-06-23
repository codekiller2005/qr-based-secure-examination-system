import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/qr_provider.dart';
import '../../routes/app_routes.dart';
class QRValidationScreen extends StatefulWidget {
  const QRValidationScreen({super.key});
  @override
  State<QRValidationScreen> createState() => _QRValidationScreenState();
}
class _QRValidationScreenState extends State<QRValidationScreen> {
  bool _initStarted = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Start validation process exactly once after context dependencies resolve
    if (!_initStarted) {
      _initStarted = true;
      final String qrData = ModalRoute.of(context)!.settings.arguments as String;
      _executeValidation(qrData);
    }
  }
  Future<void> _executeValidation(String qrData) async {
    final qrProvider = Provider.of<QRProvider>(context, listen: false);
    
    // Trigger validation and wait for completion
    final bool isValid = await qrProvider.validateQr(qrData);
    
    if (!mounted) return;
    if (isValid) {
      // Navigate to Success Screen
      Navigator.pushReplacementNamed(context, AppRoutes.studentQrSuccess);
    } else {
      // Navigate to Failure Screen
      Navigator.pushReplacementNamed(context, AppRoutes.studentQrFailure);
    }
  }
  @override
  Widget build(BuildContext context) {
    final qrProvider = Provider.of<QRProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Spinning Progress Indicator
                  const SizedBox(
                    height: 52,
                    width: 52,
                    child: CircularProgressIndicator(
                      color: Color(0xFF6366F1),
                      strokeWidth: 4.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  const Text(
                    "Verifying Entrance Key",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  const Text(
                    "Querying local cryptographic logs and validating session tokens...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  
                  if (qrProvider.scannedData != null) ...[
                    const SizedBox(height: 24),
                    // Developer payload view console
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Text(
                        "Payload: ${qrProvider.scannedData!}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
