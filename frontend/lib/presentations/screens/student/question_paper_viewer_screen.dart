import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../../core/providers/exam_provider.dart';
import '../../routes/app_routes.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class QuestionPaperViewerScreen extends StatefulWidget {
  final String pdfPath;

  const QuestionPaperViewerScreen({
    super.key,
    required this.pdfPath,
  });

  @override
  State<QuestionPaperViewerScreen> createState() =>
      _QuestionPaperViewerScreenState();
}

class _QuestionPaperViewerScreenState
    extends State<QuestionPaperViewerScreen>
    with WidgetsBindingObserver {
 
  Timer? _internetMonitor;
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);

  _internetMonitor = Timer.periodic(
    const Duration(seconds: 2),
    (_) => _checkInternetConnection(),
  );
}
@override
void dispose() {
  _internetMonitor?.cancel();
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}
Future<bool> _isOffline() async {
  final connectivityResult =
      await Connectivity().checkConnectivity();

  return !connectivityResult.contains(
    ConnectivityResult.mobile,
  ) &&
      !connectivityResult.contains(
        ConnectivityResult.wifi,
      ) &&
      !connectivityResult.contains(
        ConnectivityResult.ethernet,
      );
}
Future<void> _checkInternetConnection() async {

  final connectivityResult =
      await Connectivity().checkConnectivity();

  final bool offline =
      !connectivityResult.contains(ConnectivityResult.mobile) &&
      !connectivityResult.contains(ConnectivityResult.wifi) &&
      !connectivityResult.contains(ConnectivityResult.ethernet);

  if (offline) return;

  _internetMonitor?.cancel();

  if (!mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      title: Text("Security Violation"),
      content: Text(
        "Internet connection detected.\n\n"
        "Submitting examination...",
      ),
    ),
  );

  final examProvider =
      Provider.of<ExamProvider>(
    context,
    listen: false,
  );

  await examProvider.submitExam();

  if (!mounted) return;

  Navigator.pop(context);

  Navigator.pushReplacementNamed(
    context,
    AppRoutes.studentResult,
  );
}
Future<void> _validateOfflineMode() async {
  final offline = await _isOffline();

  if (!offline && mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Internet Detected"),
        content: const Text(
          "Internet connection is enabled.\n\n"
          "Please disable Wi-Fi and Mobile Data before starting the examination.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
@override
@override
void didChangeAppLifecycleState(AppLifecycleState state) {

  if (state == AppLifecycleState.paused) {

    debugPrint(
      "🚨 Student left the examination. Auto submitting...",
    );

    _internetMonitor?.cancel();

    final examProvider =
        Provider.of<ExamProvider>(
      context,
      listen: false,
    );

    examProvider.submitExam();

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.studentResult,
    );
  }
}
 

 @override
Widget build(BuildContext context) {
  return PopScope(
     canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Back button is disabled during the examination.",
        ),
        duration: Duration(seconds: 2),
      ),
    );
  },
    child: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Question Paper"),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Consumer<ExamProvider>(
  builder: (context, examProvider, child) {
    
    return Column(
      children: [

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.red.shade700,
          child: Text(
            "Time Remaining: ${examProvider.formattedTimer}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        Expanded(
          child: SfPdfViewer.file(
            File(widget.pdfPath),
          ),
        ),
        Padding(
  padding: const EdgeInsets.all(16),
  child: SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      icon: const Icon(Icons.check_circle),
      label: const Text("Finish Exam"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed:() async {
        _showFinishDialog(context);
      },
    ),
  ),
),

      ],
    );
  },
),
    ),
    );
  }
  void _showFinishDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Finish Examination"),
        content: const Text(
          "Are you sure you want to finish this examination? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed:  () {
              Navigator.pop(dialogContext);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed:() async   {
              Navigator.pop(dialogContext);

              final examProvider =
                  Provider.of<ExamProvider>(context, listen: false);

               await  examProvider.submitExam();

              Navigator.pushReplacementNamed(
                context,
                AppRoutes.studentResult,
              );
            },
            child: const Text("Finish"),
          ),
        ],
      );
    },
  );
}
}
    