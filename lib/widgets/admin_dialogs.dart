// =============================================================================
// lib/widgets/admin_dialogs.dart
// Reusable Glassmorphism Dialogs for CPI Admin Panel
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme_provider.dart';

/// Show Admin Confirmation Dialog
Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required Color color,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
}) async {
  final isDark = AppThemeController.isDarkMode;

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _AdminConfirmDialog(
          title: title,
          message: message,
          color: color,
          confirmText: confirmText,
          cancelText: cancelText,
          isDark: isDark,
        ),
      ) ??
      false;
}

class _AdminConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final Color color;
  final String confirmText;
  final String cancelText;
  final bool isDark;

  const _AdminConfirmDialog({
    required this.title,
    required this.message,
    required this.color,
    required this.confirmText,
    required this.cancelText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                    fontFamily: 'Geist',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Form field configuration for admin form dialog
class FormFieldConfig {
  final String key;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final List<String>? dropdownItems;
  final String? initialValue;

  const FormFieldConfig({
    required this.key,
    required this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.dropdownItems,
    this.initialValue,
  });
}

/// Show Admin Form Dialog
Future<Map<String, dynamic>?> showAdminFormDialog(
  BuildContext context, {
  required String title,
  required List<FormFieldConfig> fields,
  required String submitText,
  Map<String, dynamic>? initialValues,
}) async {
  final isDark = AppThemeController.isDarkMode;

  return await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _AdminFormDialog(
      title: title,
      fields: fields,
      submitText: submitText,
      initialValues: initialValues,
      isDark: isDark,
    ),
  );
}

class _AdminFormDialog extends StatefulWidget {
  final String title;
  final List<FormFieldConfig> fields;
  final String submitText;
  final Map<String, dynamic>? initialValues;
  final bool isDark;

  const _AdminFormDialog({
    required this.title,
    required this.fields,
    required this.submitText,
    this.initialValues,
    required this.isDark,
  });

  @override
  State<_AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<_AdminFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _dropdownValues = {};

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      _controllers[field.key] = TextEditingController(
        text:
            widget.initialValues?[field.key]?.toString() ??
            field.initialValue ??
            '',
      );
      if (field.dropdownItems != null) {
        _dropdownValues[field.key] =
            widget.initialValues?[field.key]?.toString() ??
            field.initialValue ??
            field.dropdownItems!.first;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final result = <String, dynamic>{};
      for (final field in widget.fields) {
        if (field.dropdownItems != null) {
          result[field.key] = _dropdownValues[field.key];
        } else {
          result[field.key] = _controllers[field.key]!.text;
        }
      }
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...widget.fields
                        .map((field) => _buildField(field))
                        .toList(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: widget.isDark
                                    ? Colors.white70
                                    : Colors.black54,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.submitText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(FormFieldConfig field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: TextStyle(
              color: widget.isDark ? Colors.white70 : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          if (field.dropdownItems != null)
            DropdownButtonFormField<String>(
              value: _dropdownValues[field.key],
              dropdownColor: widget.isDark
                  ? const Color(0xFF0D0E12)
                  : Colors.white,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: field.hint,
                hintStyle: TextStyle(
                  color: widget.isDark ? Colors.white38 : Colors.black54,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF59E0B)),
                ),
                filled: true,
                fillColor: widget.isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.white.withOpacity(0.85),
              ),
              items: field.dropdownItems!
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _dropdownValues[field.key] = val);
                }
              },
              validator: field.validator,
            )
          else
            TextFormField(
              controller: _controllers[field.key],
              obscureText: field.obscureText,
              keyboardType: field.keyboardType,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: field.hint,
                hintStyle: TextStyle(
                  color: widget.isDark ? Colors.white38 : Colors.black54,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF59E0B)),
                ),
                filled: true,
                fillColor: widget.isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.white.withOpacity(0.85),
              ),
              validator: field.validator,
            ),
        ],
      ),
    );
  }
}

/// Show Admin Toast/SnackBar
void showAdminToast(
  BuildContext context, {
  required String message,
  bool isError = false,
  bool isSuccess = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError
          ? const Color(0xFFEF4444)
          : isSuccess
          ? const Color(0xFF10B981)
          : const Color(0xFFF59E0B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          Icon(
            isError
                ? Icons.error_rounded
                : isSuccess
                ? Icons.check_circle_rounded
                : Icons.info_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Geist',
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
