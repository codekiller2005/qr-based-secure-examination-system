import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../routes/app_routes.dart';
import '../../../core/providers/qr_provider.dart';
class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});
  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}
class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  
  bool _isNavigating = false;
  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }
  void _onDetect(BarcodeCapture capture) {
    if (_isNavigating) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? rawValue = barcodes.first.rawValue;
      if (rawValue != null) {
        _navigateToValidation(rawValue);
      }
    }
  }
  void _navigateToValidation(String qrData) {
    setState(() {
      _isNavigating = true;
    });
    
    // Deactivate/stop scanner to prevent double captures
    _scannerController.stop();
    // Route to validation view passing scanned data as string parameter
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.studentQrValidation,
      arguments: qrData,
    );
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Scan Exam QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // Live camera preview layer using mobile_scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // styled laser scanning viewfinder overlay box
          // styled laser scanning viewfinder overlay box
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25), width: 1.5),
              ),
              child: Stack(
                children: [
                  // Top-Left Corner
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF818CF8), width: 4),
                          left: BorderSide(color: Color(0xFF818CF8), width: 4),
                        ),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
                      ),
                    ),
                  ),
                  // Top-Right Corner
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF818CF8), width: 4),
                          right: BorderSide(color: Color(0xFF818CF8), width: 4),
                        ),
                        borderRadius: BorderRadius.only(topRight: Radius.circular(16)),
                      ),
                    ),
                  ),
                  // Bottom-Left Corner
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF818CF8), width: 4),
                          left: BorderSide(color: Color(0xFF818CF8), width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16)),
                      ),
                    ),
                  ),
                  // Bottom-Right Corner
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF818CF8), width: 4),
                          right: BorderSide(color: Color(0xFF818CF8), width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // User Guidelines layout
          const Positioned(
            top: 48,
            left: 24,
            right: 24,
            child: Text(
              "Center the Invigilator's start QR code inside the frame to unlock the exam paper.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 6, color: Colors.black)],
              ),
            ),
          ),
          // Simulation fallback footer buttons (Crucial for emulators)
          ],
      ),
    );
  }
}
