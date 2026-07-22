import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/user.dart';
import '../../core/theme_provider.dart';
import '../../core/colors.dart';
import '../../services/supabase_service.dart';
import 'package:cpi_app/widgets/animated_background_painter.dart';

// Check if running on web
import 'package:flutter/foundation.dart' show kIsWeb;

class AdmitCardView extends StatefulWidget {
  final AppUser user;

  const AdmitCardView({super.key, required this.user});

  @override
  State<AdmitCardView> createState() => _AdmitCardViewState();
}

class _AdmitCardViewState extends State<AdmitCardView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  bool _isLoading = true;
  bool _isGenerating = false;
  String? _errorMessage;
  Map<String, dynamic>? _admitCardData;
  List<Map<String, String>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _fetchAdmitCardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdmitCardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rollNumber = widget.user.rollNumber ?? '';
      if (rollNumber.isEmpty) {
        setState(() {
          _errorMessage = 'No roll number found for this user';
          _isLoading = false;
        });
        return;
      }

      print('🔍 Fetching admit card for roll number: $rollNumber');

      final admitCard = await SupabaseService.instance.fetchAdmitCard(
        rollNumber,
      );

      print('📋 Admit Card Data: $admitCard');

      if (admitCard == null) {
        setState(() {
          _errorMessage = 'No admit card found for roll number: $rollNumber';
          _isLoading = false;
        });
        return;
      }

      final subjects = await SupabaseService.instance.fetchAdmitCardSubjects(
        rollNumber,
      );

      setState(() {
        _admitCardData = admitCard;
        _subjects = subjects;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _errorMessage = 'Failed to load admit card: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ===========================================================================
  // PDF GENERATION
  // ===========================================================================

  Future<void> _generatePDF() async {
    if (_admitCardData == null) return;

    setState(() => _isGenerating = true);

    try {
      final pdf = pw.Document();

      final String studentName = _admitCardData?['student_name'] ?? 'N/A';
      final String rollNo = _admitCardData?['roll_number'] ?? 'N/A';
      final String regNo = _admitCardData?['registration_no'] ?? 'N/A';
      final String semester = _admitCardData?['semester'] ?? 'N/A';
      final String session = _admitCardData?['session'] ?? 'N/A';
      final String regulation = _admitCardData?['regulation'] ?? 'N/A';
      final String techName = _admitCardData?['technology_name'] ?? 'N/A';
      final String instName = _admitCardData?['institution_name'] ?? 'N/A';
      final String instCode = _admitCardData?['institution_code'] ?? 'N/A';
      final String examName = _admitCardData?['exam_name'] ?? 'N/A';
      final String examTimeline = _admitCardData?['exam_timeline'] ?? 'N/A';
      final String examinerStatus = _admitCardData?['examiner_status'] ?? 'N/A';
      final String boardName =
          _admitCardData?['board_name'] ??
          'Bangladesh Technical Education Board, Dhaka';
      final String curriculumCode =
          _admitCardData?['exam_curriculum_code'] ?? '15';
      final String fatherName = _admitCardData?['father_name'] ?? 'N/A';
      final String motherName = _admitCardData?['mother_name'] ?? 'N/A';
      final String dateOfBirth = _admitCardData?['date_of_birth'] ?? 'N/A';
      final String principalName = _admitCardData?['principal_name'] ?? 'N/A';
      final String principalTitle =
          _admitCardData?['principal_title'] ?? 'Principal (In-Charge)';
      final String institutionAddress =
          _admitCardData?['institution_address'] ?? 'N/A';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        boardName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        examName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        examTimeline,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "Curriculum Code: $curriculumCode",
                        style: pw.TextStyle(fontSize: 11),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        width: double.infinity,
                        height: 2,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        "Admit Card",
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Container(
                        width: double.infinity,
                        height: 1,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Center Code and Name",
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            "$instCode-$instName",
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Institute Code and Name",
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            "$instCode-$instName",
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  "Name of the Examinee",
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  studentName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "Father's Name",
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(fatherName, style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 4),
                pw.Text(
                  "Mother's Name",
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(motherName, style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 4),
                pw.Text(
                  "Date of Birth",
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(dateOfBirth, style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 12),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          _buildTableCell("Roll No.", 0.2),
                          _buildTableCell(rollNo, 0.3),
                          _buildTableCell("Semester:", 0.2),
                          _buildTableCell(semester.toUpperCase(), 0.3),
                        ],
                      ),
                      pw.Row(
                        children: [
                          _buildTableCell("Reg. No.", 0.2),
                          _buildTableCell(regNo, 0.3),
                          _buildTableCell("Session:", 0.2),
                          _buildTableCell(session, 0.3),
                        ],
                      ),
                      pw.Row(
                        children: [
                          _buildTableCell("Examinee Type", 0.2),
                          _buildTableCell(examinerStatus, 0.3),
                          _buildTableCell("Regulation:", 0.2),
                          _buildTableCell(regulation, 0.3),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  "Technology Code and Name",
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  techName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  "Subject(s) Code and Name",
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                ..._subjects.map((subject) {
                  return pw.Text(
                    "${subject['code']}-${subject['name']}",
                    style: pw.TextStyle(fontSize: 11),
                  );
                }),
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Signature and Seal",
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 30),
                          pw.Text(
                            principalName,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            principalTitle,
                            style: pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(instName, style: pw.TextStyle(fontSize: 10)),
                          pw.Text(
                            institutionAddress,
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 100,
                            height: 100,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                color: PdfColors.black,
                                width: 1,
                              ),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                "SEAL",
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  "Directions:",
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "1. The examinee must bring the Registration Card along with the Admit Card in the examination hall.",
                  style: pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  "2. The examinee must sign in the attendance sheet for each subject in examination hall otherwise examinee will be treated as absent in the respective subject(s).",
                  style: pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  "3. It is the responsibility of the examinee to be informed about the examination schedule.",
                  style: pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  "4. Examiner must be followed the exam rules and disciplinary rules stated by BTEB.",
                  style: pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    "Generated on: ${DateTime.now().toString().substring(0, 10)}",
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      await _savePdf(pdfBytes, rollNo, studentName);

      setState(() => _isGenerating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ PDF saved successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _savePdf(
    Uint8List pdfBytes,
    String rollNo,
    String studentName,
  ) async {
    final fileName =
        'Admit_Card_${rollNo}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    try {
      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: pdfBytes,
          fileExtension: 'pdf',
          mimeType: MimeType.pdf,
        );
        return;
      }

      final Directory directory = await getApplicationDocumentsDirectory();
      final String savePath = '${directory.path}/$fileName';
      final File file = File(savePath);
      await file.writeAsBytes(pdfBytes);
      await OpenFile.open(savePath);
    } catch (e) {
      print('❌ Error saving PDF: $e');
      rethrow;
    }
  }

  pw.Widget _buildTableCell(String text, double widthFactor) {
    return pw.Expanded(
      flex: (widthFactor * 10).toInt(),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(border: pw.Border.all()),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  // ===========================================================================
  // UI BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;

    final Color accentColor = isDark
        ? const Color(0xFF0891B2)
        : const Color(0xFF0E7490);
    final Color secondaryText = isDark ? Colors.white60 : Colors.black54;
    final Color primaryText = isDark ? Colors.white : Colors.black87;

    final String studentName =
        _admitCardData?['student_name'] ?? widget.user.name;
    final String techName = _admitCardData?['technology_name'] ?? 'N/A';
    final String rollNo =
        _admitCardData?['roll_number'] ?? widget.user.rollNumber ?? 'N/A';
    final String regNo = _admitCardData?['registration_no'] ?? 'N/A';
    final String semester = _admitCardData?['semester'] ?? 'N/A';
    final String session = _admitCardData?['session'] ?? 'N/A';
    final String regulation = _admitCardData?['regulation'] ?? 'N/A';
    final String examinerStatus = _admitCardData?['examiner_status'] ?? 'N/A';
    final String instName = _admitCardData?['institution_name'] ?? 'N/A';
    final String instCode = _admitCardData?['institution_code'] ?? 'N/A';
    final String examName = _admitCardData?['exam_name'] ?? 'N/A';
    final String examTimeline = _admitCardData?['exam_timeline'] ?? 'N/A';
    final String fatherName = _admitCardData?['father_name'] ?? 'N/A';
    final String motherName = _admitCardData?['mother_name'] ?? 'N/A';
    final String dateOfBirth = _admitCardData?['date_of_birth'] ?? 'N/A';

    final List<Map<String, String>> subjects = _subjects.isNotEmpty
        ? _subjects
        : [];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070B19)
          : AppColors.lightBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: AnimatedBackgroundPainter(
                animation: _animationController,
                isLightMode: !isDark,
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? _buildLoadingState(isDark)
                : _errorMessage != null
                ? _buildErrorState(isDark)
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Sub-page interactive header row matching Image 1 format natively
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 12,
                                    sigmaY: 12,
                                  ),
                                  child: Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.04)
                                          : Colors.black.withOpacity(0.04),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.08)
                                            : Colors.black.withOpacity(0.08),
                                      ),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: primaryText,
                                        size: 16,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Exam Pass Portal",
                                      style: TextStyle(
                                        fontFamily: 'Geist',
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                        fontSize: 26,
                                        color: primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "Digital Crypted Verification Records",
                                      style: TextStyle(
                                        fontFamily: 'Geist',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Premium Header Shield
                            _buildGlassCard(
                              isDark: isDark,
                              glowColor: accentColor,
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.black.withOpacity(0.03),
                                        border: Border.all(
                                          color: accentColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Image.asset(
                                        'assets/cpi_logo.png',
                                        height: 55,
                                        errorBuilder: (c, e, s) => Icon(
                                          Icons.shield_rounded,
                                          size: 45,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      "BANGLADESH TECHNICAL EDUCATION BOARD",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      examName.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 11,
                                        color: accentColor,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      examTimeline,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 10,
                                        color: secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Profile Panel - Stray avatar duplicate error fully resolved
                            _buildGlassCard(
                              isDark: isDark,
                              glowColor: const Color(0xFF7B61FF),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                accentColor,
                                                const Color(0xFF7B61FF),
                                              ],
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 26,
                                            backgroundColor: isDark
                                                ? const Color(0xFF0F172A)
                                                : Colors.white,
                                            child: Text(
                                              studentName.isNotEmpty
                                                  ? studentName
                                                        .substring(0, 1)
                                                        .toUpperCase()
                                                  : "S",
                                              style: TextStyle(
                                                fontFamily: 'Geist',
                                                fontWeight: FontWeight.w900,
                                                color: primaryText,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                studentName.toUpperCase(),
                                                style: TextStyle(
                                                  fontFamily: 'Geist',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.0,
                                                  color: primaryText,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                techName,
                                                style: TextStyle(
                                                  fontFamily: 'Geist',
                                                  fontSize: 11,
                                                  color: accentColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16.0,
                                      ),
                                      child: Divider(
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.black12,
                                        height: 1,
                                      ),
                                    ),

                                    // Meta Info Grid
                                    _buildMetaDataRow(
                                      "ROLL NUMBER",
                                      rollNo,
                                      "REGISTRATION NO",
                                      regNo,
                                      isDark,
                                      primaryText,
                                      secondaryText,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildMetaDataRow(
                                      "SEMESTER RUN",
                                      semester.toUpperCase(),
                                      "OFFICIAL SESSION",
                                      session,
                                      isDark,
                                      primaryText,
                                      secondaryText,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildMetaDataRow(
                                      "BTEB REGULATION",
                                      regulation,
                                      "EXAMINER STATUS",
                                      examinerStatus,
                                      isDark,
                                      primaryText,
                                      secondaryText,
                                    ),
                                    const SizedBox(height: 16),

                                    _buildMetaDataRow(
                                      "FATHER'S NAME",
                                      fatherName,
                                      "MOTHER'S NAME",
                                      motherName,
                                      isDark,
                                      primaryText,
                                      secondaryText,
                                    ),
                                    const SizedBox(height: 16),

                                    _buildMetaDataRow(
                                      "DATE OF BIRTH",
                                      dateOfBirth,
                                      "INSTITUTION",
                                      "$instCode-$instName",
                                      isDark,
                                      primaryText,
                                      secondaryText,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Module Section Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "VERIFIED MODULES (${subjects.length})",
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: primaryText,
                                  ),
                                ),
                                Icon(
                                  Icons.verified_user_rounded,
                                  color: accentColor,
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Module Lists
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: subjects.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: _buildGlassCard(
                                    isDark: isDark,
                                    glowColor: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.02),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                      leading: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accentColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: accentColor.withOpacity(
                                              0.25,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          subjects[index]['code']!,
                                          style: TextStyle(
                                            fontFamily: 'Geist',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: accentColor,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        subjects[index]['name']!,
                                        style: TextStyle(
                                          fontFamily: 'Geist',
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: primaryText,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.check_circle_rounded,
                                        color: accentColor,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // Generation Actions
                            _isGenerating
                                ? _buildGeneratingButton(isDark)
                                : _buildGenerateButton(isDark, accentColor),
                          ]),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(bool isDark, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [accentColor, const Color(0xFF7B61FF)],
          ),
        ),
        child: ElevatedButton.icon(
          onPressed: _generatePDF,
          icon: const Icon(
            Icons.picture_as_pdf_rounded,
            color: Colors.white,
            size: 20,
          ),
          label: const Text(
            "GENERATE DIGITAL ENCRYPTED PASS",
            style: TextStyle(
              fontFamily: 'Geist',
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratingButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "GENERATING...",
                style: TextStyle(
                  fontFamily: 'Geist',
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0891B2),
              ),
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading admit card...",
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: isDark
                  ? Colors.red.withOpacity(0.6)
                  : Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 14,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0891B2), Color(0xFF7B61FF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _fetchAdmitCardData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required bool isDark,
    required Widget child,
    required Color glowColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withOpacity(0.7)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? glowColor.withOpacity(0.15)
                  : AppColors.lightCardBorder.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMetaDataRow(
    String label1,
    String val1,
    String label2,
    String val2,
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMetaColumn(
            label1,
            val1,
            isDark,
            primaryColor,
            secondaryColor,
          ),
        ),
        Expanded(
          child: _buildMetaColumn(
            label2,
            val2,
            isDark,
            primaryColor,
            secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMetaColumn(
    String label,
    String value,
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 9,
            color: secondaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }
}
