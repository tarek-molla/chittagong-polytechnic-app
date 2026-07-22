// =============================================================================
// lib/views/admin/routine_scheduler_view.dart
// Horizontal Routine Scheduling Matrix for System Admins.
// Features:
//   • Horizontal weekdays selection matrix
//   • Timeline list representing scheduled class slots
//   • Inline dialog form for adding new classes to the routine
// =============================================================================

import 'package:flutter/material.dart';
import '../../models/user.dart';

class RoutineSchedulerView extends StatefulWidget {
  final AppUser user;
  const RoutineSchedulerView({super.key, required this.user});

  @override
  State<RoutineSchedulerView> createState() => _RoutineSchedulerViewState();
}

class _RoutineSchedulerViewState extends State<RoutineSchedulerView> {
  String _selectedDay = 'SUN';

  // Schedule records cache simulation
  final Map<String, List<Map<String, String>>> _schedules = {
    'SUN': [
      {'time': '08:00 - 09:30', 'subject': 'Data Structures', 'class': 'CMT-3rd-A', 'room': 'Rm 302', 'teacher': 'Kamal Sir'},
      {'time': '10:00 - 12:15', 'subject': 'Microprocessor', 'class': 'CMT-5th-B', 'room': 'Lab 2', 'teacher': 'Ayesha Ma\'am'},
    ],
    'MON': [
      {'time': '09:30 - 11:00', 'subject': 'OOP in Java', 'class': 'CMT-3rd-B', 'room': 'Rm 204', 'teacher': 'Kamal Sir'},
    ],
    'TUE': [
      {'time': '08:00 - 09:30', 'subject': 'Data Structures', 'class': 'CMT-3rd-A', 'room': 'Rm 302', 'teacher': 'Kamal Sir'},
    ],
    'WED': [
      {'time': '11:00 - 12:30', 'subject': 'System Analysis', 'class': 'CMT-5th-A', 'room': 'Rm 401', 'teacher': 'Princy Ma\'am'},
    ],
    'THU': [
      {'time': '08:00 - 10:15', 'subject': 'OOP in Java', 'class': 'CMT-3rd-B', 'room': 'Lab 1', 'teacher': 'Kamal Sir'},
    ],
  };

  void _showAddSlotDialog() {
    final formKey = GlobalKey<FormState>();
    final subjectCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final teacherCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '08:00 - 09:30');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withAlpha(15)),
          ),
          title: const Text(
            'Schedule New Slot',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField('Subject Name', subjectCtrl),
                  const SizedBox(height: 12),
                  _buildDialogTextField('Class / Batch', classCtrl),
                  const SizedBox(height: 12),
                  _buildDialogTextField('Room Number', roomCtrl),
                  const SizedBox(height: 12),
                  _buildDialogTextField('Faculty Teacher', teacherCtrl),
                  const SizedBox(height: 12),
                  _buildDialogTextField('Time Slot (e.g. 08:00 - 09:30)', timeCtrl),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    if (!_schedules.containsKey(_selectedDay)) {
                      _schedules[_selectedDay] = [];
                    }
                    _schedules[_selectedDay]!.add({
                      'time': timeCtrl.text,
                      'subject': subjectCtrl.text,
                      'class': classCtrl.text,
                      'room': roomCtrl.text,
                      'teacher': teacherCtrl.text,
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New routine slot scheduled successfully.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
              child: const Text('Add Slot', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      validator: (val) => val == null || val.isEmpty ? 'Field required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        filled: true,
        fillColor: Colors.white.withAlpha(5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withAlpha(8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daySlots = _schedules[_selectedDay] ?? [];

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
          'Routine Scheduler Matrix',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSlotDialog,
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle context
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Text(
              'Select a day below to alter the live timetable dashboards.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11.5,
              ),
            ),
          ),

          // Horizontal Weekdays bar
          _buildWeekdaysBar(),

          const SizedBox(height: 20),

          // Day Timeline List
          Expanded(
            child: daySlots.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: daySlots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final slot = daySlots[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(10)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF67E8F9).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.access_time_rounded, color: Color(0xFF67E8F9), size: 16),
                                  const SizedBox(height: 6),
                                  Text(
                                    slot['time']!.split(' - ').first,
                                    style: const TextStyle(
                                      color: Color(0xFF67E8F9),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot['subject']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${slot['class']} • ${slot['teacher']}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                slot['room']!,
                                style: const TextStyle(
                                  color: Color(0xFF67E8F9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdaysBar() {
    final days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _selectedDay == day;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.18) : Colors.white.withAlpha(4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : Colors.white.withAlpha(8),
                ),
              ),
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF67E8F9) : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: Color(0xFF475569),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            "No scheduled classes for $_selectedDay",
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
