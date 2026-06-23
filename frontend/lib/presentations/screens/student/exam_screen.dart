import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/exam_provider.dart';
import '../../routes/app_routes.dart';
class QuestionPaperViewer extends StatefulWidget {
  const QuestionPaperViewer({super.key});
  @override
  State<QuestionPaperViewer> createState() => _QuestionPaperViewerState();
}
class _QuestionPaperViewerState extends State<QuestionPaperViewer> {
  late PageController _pageController;
  int _currentPage = 0;
  final int _totalPages = 3;
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }
  void _showFinishConfirmation(BuildContext context, ExamProvider examProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            "Finish Viewing Paper?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Confirm that you are done reading the question paper. Ensure you write down all answers on your physical answer booklets before exiting.",
            style: TextStyle(color: Color(0xFF94A3B8), height: 1.4),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              child: const Text("Finish Viewing"),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                
                // Finalize session
                examProvider.submitExam(); 
                
                // Route to success screen
                Navigator.pushReplacementNamed(context, AppRoutes.studentResult);
              },
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final examProvider = Provider.of<ExamProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevent navigation controls
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          examProvider.activeExamTitle ?? 'University Question Paper',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        centerTitle: false,
        actions: [
          // Timer Countdown display box
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFF818CF8), size: 16),
                const SizedBox(width: 6),
                Text(
                  examProvider.formattedTimer,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Upper details bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.5),
              border: const Border(bottom: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: Color(0xFF818CF8), size: 18),
                    SizedBox(width: 8),
                    Text(
                      "CS-302: Operating Systems (120 Mins)",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  "Page ${_currentPage + 1} of $_totalPages",
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Main Interactive Paper Area (Simulating PDF Pages)
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildPaperPage(
                  pageNumber: 1,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Document Header
                      const Center(
                        child: Column(
                          children: [
                            Text(
                              "FEDERAL INSTITUTE OF TECHNOLOGY",
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "DEPARTMENT OF COMPUTER SCIENCE & ENGINEERING",
                              style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Mid-Semester Examination - Spring 2026",
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              "Course Code: CS-302  |  Subject: Operating Systems",
                              style: TextStyle(color: Colors.black87, fontSize: 11, fontStyle: FontStyle.italic),
                            ),
                            SizedBox(height: 8),
                            Divider(color: Colors.black26, thickness: 1.5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Time Allowed: 2 Hours", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text("Maximum Marks: 50", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Divider(color: Colors.black26, thickness: 1.5),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Instructions Section
                      const Text(
                        "GENERAL INSTRUCTIONS:",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      _buildInstructionRow("1. All answers must be written on the provided physical answer sheets."),
                      _buildInstructionRow("2. Write the correct question identifiers (e.g. Q1, Q2) clearly before starting each solution."),
                      _buildInstructionRow("3. Drawing Gantt charts and diagrams where applicable is highly recommended."),
                      const SizedBox(height: 20),
                      // Section A
                      _buildSectionHeader("SECTION A: SHORT ANSWER QUESTIONS", "15 Marks"),
                      const SizedBox(height: 12),
                      _buildQuestionRow(
                        num: "Q1",
                        text: "Explain the architectural differences between a User-level thread and a Kernel-level thread. In what scenarios does each exhibit better performance?",
                        marks: "5 Marks",
                      ),
                      _buildQuestionRow(
                        num: "Q2",
                        text: "State and describe the four necessary conditions required for a system state to trigger a deadlock.",
                        marks: "5 Marks",
                      ),
                      _buildQuestionRow(
                        num: "Q3",
                        text: "Distinguish between Internal Fragmentation and External Fragmentation in physical memory allocation. How does Paging solve External Fragmentation?",
                        marks: "5 Marks",
                      ),
                    ],
                  ),
                ),
                _buildPaperPage(
                  pageNumber: 2,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("SECTION B: NUMERICAL PROBLEMS", "20 Marks"),
                      const SizedBox(height: 16),
                      _buildQuestionRow(
                        num: "Q4",
                        text: "Compare First-Come First-Served (FCFS), Shortest Job First (SJF), and Round Robin (RR) scheduling algorithms in terms of:\n"
                              "  a) Average Waiting Time\n"
                              "  b) Context-Switching Overhead\n"
                              "  c) Turnaround Time performance under uniform arrival times.\n"
                              "Specifically highlight the impact of time quantum choices on Round Robin.",
                        marks: "10 Marks",
                      ),
                      const SizedBox(height: 8),
                      _buildQuestionRow(
                        num: "Q5",
                        text: "Detail the paging memory management scheme. Explain the address translation mechanism from Logical Address to Physical Address. Draw a neat conceptual block diagram showing how the Translation Lookaside Buffer (TLB) speeds up access.",
                        marks: "10 Marks",
                      ),
                    ],
                  ),
                ),
                _buildPaperPage(
                  pageNumber: 3,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("SECTION C: LONG THEORY QUESTIONS", "15 Marks"),
                      const SizedBox(height: 16),
                      _buildQuestionRow(
                        num: "Q6",
                        text: "Consider the following table containing CPU arrival and burst times for four user processes:\n\n"
                              "  Process  |  Arrival Time  |  CPU Burst Time\n"
                              "  ------------------------------------------\n"
                              "    P1     |       0        |       8\n"
                              "    P2     |       1        |       4\n"
                              "    P3     |       2        |       9\n"
                              "    P4     |       3        |       5\n\n"
                              "Evaluate turnarounds and execute process states:\n"
                              "  1) Draw the scheduling Gantt chart illustrating execution sequence using Preemptive Shortest Remaining Time First (SRTF).\n"
                              "  2) Calculate the individual Waiting Time and Turnaround Time for each process.\n"
                              "  3) Compute the final average waiting time and average turnaround time for the schedule.",
                        marks: "15 Marks",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom Control Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(top: BorderSide(color: Color(0xFF334155), width: 1.2)),
            ),
            child: Row(
              children: [
                // Previous Page Button
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _currentPage > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.arrow_back_ios_new_rounded, size: 12),
                        SizedBox(width: 6),
                        Text("Prev", style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Finish Viewing Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFFEF4444), // Crimson Red
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showFinishConfirmation(context, examProvider),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle_outline_rounded, size: 16),
                        SizedBox(width: 6),
                        Text("Finish Paper", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Next Page Button
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _currentPage < _totalPages - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("Next", style: TextStyle(fontSize: 13)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // Simulated Sheet Paper Widget (A4 look and feel)
  Widget _buildPaperPage({required int pageNumber, required Widget content}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white, // Realistic A4 paper sheet background
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background watermark
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Transform.rotate(
                  angle: -0.4,
                  child: Text(
                    "SECURE REFERENCE ONLY",
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.02),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Main document sheet content
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: content,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Physical paper notice footer
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      "Write all answers on the physical answer sheets provided by the invigilator.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Footer Page Number Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "CS-302 OS PAPER",
                      style: TextStyle(color: Colors.black45, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Page $pageNumber of $_totalPages",
                      style: const TextStyle(color: Colors.black45, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInstructionRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black87, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSectionHeader(String title, String marks) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(left: BorderSide(color: Colors.black, width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            marks,
            style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  Widget _buildQuestionRow({required String num, required String text, required String marks}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$num.  ",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black87, fontSize: 11, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "($marks)",
            style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
