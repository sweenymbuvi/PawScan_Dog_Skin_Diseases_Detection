import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pawscan/features/auth/data/models/user_model.dart';
import 'package:pawscan/features/auth/data/repository/user_repository.dart';
import 'package:pawscan/features/detection/data/models/detection_result_model.dart';
import 'package:pawscan/features/detection/data/repository/detection_repository.dart';
import '../../../home/widgets/nav_bar.dart';
import 'results_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DetectionRepository _detectionRepo = DetectionRepository.instance;
  final UserRepository _userRepo = UserRepository.instance;

  List<DetectionResult> _allResults = [];
  List<DetectionResult> _filteredResults = [];
  List<DogProfile> _dogProfiles = [];

  String? _selectedDogFilter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        // ✅ Use your existing method
        UserModel userModel = await _userRepo.getUserDetails(user.email!);

        // ✅ Dog profiles from user model
        _dogProfiles = userModel.dogProfiles;

        // ✅ Load all detection results
        final results = await _detectionRepo.getDetectionHistory();

        setState(() {
          _allResults = results;
          _filteredResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading history: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterByDog(String? dogProfileId) {
    setState(() {
      _selectedDogFilter = dogProfileId;

      if (dogProfileId == null || dogProfileId == 'all') {
        _filteredResults = _allResults;
      } else {
        _filteredResults = _allResults
            .where((result) => result.dogProfileId == dogProfileId)
            .toList();
      }
    });
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return const Color(0xFFE54D4D);
      case 'moderate':
        return const Color(0xFFF0BB22);
      case 'mild':
        return const Color(0xFF5CD15A);
      default:
        return const Color(0xFF666666);
    }
  }

  // 🆕 PDF Export Function
  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    // Get dog name for filtered view
    String filterTitle = 'All Dogs';
    if (_selectedDogFilter != null && _selectedDogFilter != 'all') {
      final dog = _dogProfiles.firstWhere(
        (d) => d.dogId == _selectedDogFilter,
        orElse: () => DogProfile(
          dogId: '',
          name: 'Unknown',
          breed: '',
          gender: '',
          age: 0,
        ),
      );
      filterTitle = dog.name;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PawScan Detection History',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Filter: $filterTitle',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Total Records: ${_filteredResults.length}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Results Table
            if (_filteredResults.isNotEmpty)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _pdfTableCell('Date', isHeader: true),
                      _pdfTableCell('Disease', isHeader: true),
                      _pdfTableCell('Dog', isHeader: true),
                      _pdfTableCell('Severity', isHeader: true),
                      _pdfTableCell('Confidence', isHeader: true),
                    ],
                  ),
                  // Table Rows
                  ..._filteredResults.map((result) {
                    return pw.TableRow(
                      children: [
                        _pdfTableCell(
                          DateFormat('MMM dd, yyyy').format(result.timestamp),
                        ),
                        _pdfTableCell(result.disease),
                        _pdfTableCell(result.dogName ?? 'N/A'),
                        _pdfTableCell(result.severity.toUpperCase()),
                        _pdfTableCell(
                          '${result.confidence.toStringAsFixed(1)}%',
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

            if (_filteredResults.isEmpty)
              pw.Center(child: pw.Text('No detection history available')),
          ];
        },
      ),
    );

    // Show print dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _pdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          margin: const EdgeInsets.only(top: 24),
          padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const Text(
                'Detection History',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const Spacer(),
              // 🆕 PDF Export Button
              IconButton(
                onPressed: _filteredResults.isEmpty ? null : _exportToPDF,
                icon: const Icon(Icons.picture_as_pdf),
                color: const Color(0xFF5CD15A),
                tooltip: 'Export to PDF',
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5CD15A)),
            )
          : SafeArea(
              child: Column(
                children: [
                  // 🔹 Filter Section
                  if (_dogProfiles.isNotEmpty) _buildFilterSection(),

                  // 🔹 Results List
                  Expanded(
                    child: _filteredResults.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: const Color(0xFF5CD15A),
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredResults.length,
                              itemBuilder: (context, index) =>
                                  _buildHistoryCard(_filteredResults[index]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/home');
          } else if (index == 1) {
            // Already on history, do nothing
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF5F5F5),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Color(0xFF5CD15A)),
          const SizedBox(width: 12),
          const Text(
            'Filter by dog:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF5CD15A)),
                color: Colors.white,
              ),
              child: DropdownButton<String>(
                value: _selectedDogFilter,
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text(
                      'All Dogs',
                      style: TextStyle(fontFamily: 'Inter'),
                    ),
                  ),
                  ..._dogProfiles.map(
                    (dog) => DropdownMenuItem(
                      value: dog.dogId,
                      child: Text(
                        dog.name,
                        style: const TextStyle(fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                ],
                onChanged: _filterByDog,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _selectedDogFilter != 'all'
                ? "No history for this dog"
                : "No detection history",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Start scanning to see results here",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(DetectionResult result) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResultsScreen(result: result)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.disease,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getSeverityColor(result.severity),
                        ),
                      ),
                      if (result.dogName != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.pets,
                              size: 16,
                              color: Color(0xFF666666),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              result.dogName!,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 🔹 Confidence + Severity
              Row(
                children: [
                  _buildTag(
                    '${result.confidence.toStringAsFixed(1)}%',
                    result.severity,
                  ),
                  const SizedBox(width: 8),
                  _buildTag(result.severity.toUpperCase(), result.severity),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, yyyy').format(result.timestamp),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                result.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResultsScreen(result: result),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF5CD15A),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Color(0xFF5CD15A),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, String severity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getSeverityColor(severity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getSeverityColor(severity),
        ),
      ),
    );
  }
}
