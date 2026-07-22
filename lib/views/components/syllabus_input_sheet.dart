import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../../models/syllabus_model.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';

class SyllabusInputSheet extends StatefulWidget {
  final AppUser user;
  final SyllabusModel? syllabus;

  const SyllabusInputSheet({super.key, required this.user, this.syllabus});

  @override
  State<SyllabusInputSheet> createState() => _SyllabusInputSheetState();
}

class _SyllabusInputSheetState extends State<SyllabusInputSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  final _contentController = TextEditingController();

  File? _selectedFile;
  String? _fileName;
  bool _isSubmitting = false;
  bool _hasFile = false;
  String? _existingFileUrl;

  @override
  void initState() {
    super.initState();
    if (widget.syllabus != null) {
      _subjectNameController.text = widget.syllabus!.subjectName;
      _subjectCodeController.text = widget.syllabus!.subjectCode ?? '';
      _contentController.text = widget.syllabus!.content ?? '';
      _hasFile =
          widget.syllabus!.fileUrl != null &&
          widget.syllabus!.fileUrl!.isNotEmpty;
      _fileName = widget.syllabus!.fileName;
      _existingFileUrl = widget.syllabus!.fileUrl;
    }
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _subjectCodeController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final List<XFile>? results = await openFiles(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Documents',
            extensions: ['pdf', 'doc', 'docx'],
          ),
        ],
      );

      if (results != null && results.isNotEmpty) {
        setState(() {
          _selectedFile = File(results.first.path);
          _fileName = results.first.name;
          _hasFile = true;
          _existingFileUrl = null; // Clear existing if new file selected
        });
      }
    } catch (e) {
      print('❌ File pick error: $e');
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _hasFile = false;
      _existingFileUrl = null;
    });
  }

  Future<void> _submitSyllabus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final department = widget.user.department?.shortCode ?? 'CST';
      final semester = widget.user.semester ?? 6;

      String? fileUrl = _existingFileUrl;

      // Upload file if new file selected
      if (_selectedFile != null) {
        fileUrl = await DatabaseService().uploadSyllabusFile(
          _selectedFile!,
          _subjectNameController.text.trim(),
        );
      }

      final syllabus = SyllabusModel(
        id: widget.syllabus?.id ?? '',
        subjectName: _subjectNameController.text.trim(),
        department: department,
        semester: semester,
        subjectCode: _subjectCodeController.text.trim().isEmpty
            ? null
            : _subjectCodeController.text.trim(),
        content: _contentController.text.trim().isEmpty
            ? null
            : _contentController.text.trim(),
        fileUrl: fileUrl,
        fileName: _fileName ?? widget.syllabus?.fileName,
        uploadedBy: widget.user.name,
        isActive: true,
        createdAt: widget.syllabus?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.syllabus != null) {
        await DatabaseService().updateSyllabus(syllabus);
      } else {
        await DatabaseService().createSyllabus(syllabus);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.syllabus != null
                  ? '✅ Syllabus updated successfully!'
                  : '✅ Syllabus added successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D0E12) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.black.withOpacity(0.12),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.24)
                          : Colors.black.withOpacity(0.24),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  widget.syllabus != null ? 'EDIT SYLLABUS' : 'ADD SYLLABUS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 20),

                // Subject Name
                TextFormField(
                  controller: _subjectNameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Subject Name *',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.24)
                            : Colors.black.withOpacity(0.24),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Subject name is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Subject Code
                TextFormField(
                  controller: _subjectCodeController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Subject Code (Optional)',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.24)
                            : Colors.black.withOpacity(0.24),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Content
                TextFormField(
                  controller: _contentController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Content/Description',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.24)
                            : Colors.black.withOpacity(0.24),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                  validator: (val) {
                    if ((val == null || val.trim().isEmpty) && !_hasFile) {
                      return 'Either content or a file is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // File Upload Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.12),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Syllabus File (Optional)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          if (!_hasFile)
                            TextButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Upload PDF'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.cyanAccent,
                              ),
                            ),
                          if (_hasFile)
                            TextButton.icon(
                              onPressed: _removeFile,
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('Remove'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                      if (_hasFile) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 16,
                                color: Colors.cyanAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _fileName ?? 'File selected',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSyllabus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: isDark
                        ? const Color(0xFF0D0E12)
                        : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF0D0E12),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.syllabus != null
                              ? 'UPDATE SYLLABUS'
                              : 'ADD SYLLABUS',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
