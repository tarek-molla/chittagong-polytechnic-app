import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../../models/notice_model.dart';
import '../../services/database_service.dart';

class AdminInputSheet extends StatefulWidget {
  const AdminInputSheet({super.key});

  @override
  State<AdminInputSheet> createState() => _AdminInputSheetState();
}

class _AdminInputSheetState extends State<AdminInputSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();

  String _category = 'GENERAL';
  String _actionType = 'none';
  bool _isSubmitting = false;

  // File attachments
  List<File> _selectedFiles = [];
  List<String> _fileNames = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final List<XFile>? results = await openFiles(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Documents',
            extensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
          ),
        ],
      );

      if (results != null && results.isNotEmpty) {
        setState(() {
          _selectedFiles = results.map((file) => File(file.path)).toList();
          _fileNames = results.map((file) => file.name).toList();
        });
      }
    } catch (e) {
      print('❌ File pick error: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _fileNames.removeAt(index);
    });
  }

  Future<void> _submitNotice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final notice = NoticeModel(
        id: '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _category,
        actionType: _actionType,
        actionUrl: _actionType == 'none' ? null : _urlController.text.trim(),
        attachments: const [],
        createdAt: DateTime.now(),
      );

      final databaseService = DatabaseService();

      if (_selectedFiles.isNotEmpty) {
        await databaseService.createNoticeWithAttachments(
          notice,
          _selectedFiles,
        );
      } else {
        await databaseService.createNotice(notice);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notice posted successfully!'),
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

                const Text(
                  'BROADCAST NEW NOTICE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Notice Title',
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
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Content
                TextFormField(
                  controller: _contentController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Content Brief',
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
                      ? 'Content is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Category & Action Type
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        dropdownColor: isDark
                            ? const Color(0xFF0D0E12)
                            : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        items:
                            ['GENERAL', 'EXAMINATION', 'ADMISSION', 'ROUTINE']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => _category = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _actionType,
                        dropdownColor: isDark
                            ? const Color(0xFF0D0E12)
                            : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Action Type',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        items: ['none', 'download', 'link']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _actionType = val!),
                      ),
                    ),
                  ],
                ),

                if (_actionType != 'none') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _urlController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: _actionType == 'download'
                          ? 'Attachment/File URL'
                          : 'External Link URL',
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
                        ? 'URL is required'
                        : null,
                  ),
                ],

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
                            'Attachments',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _pickFiles,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Files'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.cyanAccent,
                            ),
                          ),
                        ],
                      ),
                      if (_selectedFiles.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ..._fileNames.asMap().entries.map((entry) {
                          final index = entry.key;
                          final fileName = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
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
                                  _getFileIcon(fileName),
                                  size: 16,
                                  color: Colors.cyanAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fileName,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeFile(index),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                  color: Colors.red,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedFiles.length} file(s) attached',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitNotice,
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
                      : const Text(
                          'PUBLISH FEED',
                          style: TextStyle(
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

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      default:
        return Icons.attach_file_rounded;
    }
  }
}
