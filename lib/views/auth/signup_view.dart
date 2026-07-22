import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Form Fields State Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _sscRollController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedDept = 'CST';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _sscRollController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final applicationData = {
        'full_name': _nameController.text.trim(),
        'email_address': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'father_name': 'Not Provided',
        'mother_name': 'Not Provided',
        'nationality': 'Bangladeshi',
        'date_of_birth': '2006-02-03',
        'religion': 'Islam',
        'department_choice': _selectedDept,
      };

      await SupabaseService.instance.submitAdmissionApplication(
        applicationData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Admission application successfully uploaded to Supabase!',
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
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
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Admission Portal',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: const Color(0xFF0F172A),
                colorScheme: const ColorScheme.dark(primary: Color(0xFF3B82F6)),
              ),
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 2) {
                    setState(() => _currentStep += 1);
                  } else {
                    _submitApplication();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep -= 1);
                  }
                },
                steps: [
                  Step(
                    title: const Text(
                      'Personal Data',
                      style: TextStyle(color: Colors.white),
                    ),
                    isActive: _currentStep >= 0,
                    content: Column(
                      children: [
                        _buildInputField(
                          'Full Name',
                          _nameController,
                          Icons.person_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          'Email Address',
                          _emailController,
                          Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          'Phone Number',
                          _phoneController,
                          Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text(
                      'Academic History',
                      style: TextStyle(color: Colors.white),
                    ),
                    isActive: _currentStep >= 1,
                    content: Column(
                      children: [
                        _buildInputField(
                          'SSC Roll Number',
                          _sscRollController,
                          Icons.pin_rounded,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          dropdownColor: const Color(0xFF0F172A),
                          decoration: _buildInputDecoration(
                            'Gender',
                            Icons.wc_rounded,
                          ),
                          items: ['Male', 'Female', 'Other']
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedGender = val!),
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text(
                      'CPI Intentions',
                      style: TextStyle(color: Colors.white),
                    ),
                    isActive: _currentStep >= 2,
                    content: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDept,
                          dropdownColor: const Color(0xFF0F172A),
                          decoration: _buildInputDecoration(
                            'Preferred Department',
                            Icons.lan_rounded,
                          ),
                          items:
                              [
                                    'CST',
                                    'AT',
                                    'CVT',
                                    'ELT',
                                    'ECT',
                                    'ET',
                                    'MCT',
                                    'PT',
                                  ]
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedDept = val!),
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          'Home Address Details',
                          _addressController,
                          Icons.home_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSubmitting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(150),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Submitting application...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white38, size: 18),
      filled: true,
      fillColor: Colors.white.withAlpha(5),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withAlpha(10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _buildInputDecoration(label, icon),
      validator: (val) => val == null || val.isEmpty ? 'Field required' : null,
    );
  }
}
