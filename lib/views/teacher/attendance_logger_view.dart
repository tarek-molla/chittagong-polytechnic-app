// =============================================================================
// lib/views/teacher/attendance_logger_view.dart
// Interactive Roster Logging Portal for Faculty.
// Features:
//   • Animated present/absent row state selectors
//   • Symmetrical list views with student search filters
//   • Syncing status indicators and persistent headers
// =============================================================================

import 'package:flutter/material.dart';
import '../../models/user.dart';

class AttendanceLoggerView extends StatefulWidget {
  final AppUser teacher;
  final String subjectCode;
  final String className;
  final int semester;

  const AttendanceLoggerView({
    super.key,
    required this.teacher,
    required this.subjectCode,
    required this.className,
    required this.semester,
  });

  @override
  State<AttendanceLoggerView> createState() => _AttendanceLoggerViewState();
}

class _AttendanceLoggerViewState extends State<AttendanceLoggerView> {
  // Mock student roster for the target section
  final List<Map<String, String>> _students = [
    {'name': 'Mohammed Akash', 'roll': '508401'},
    {'name': 'Nasrin Akter', 'roll': '508402'},
    {'name': 'Sumaiya Khan', 'roll': '508403'},
    {'name': 'Tarek Molla', 'roll': '508412'},
    {'name': 'Ahsan Habib', 'roll': '508415'},
    {'name': 'Farhana Yeasmin', 'roll': '508418'},
  ];

  final Map<String, bool> _attendanceStates = {};
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    for (var student in _students) {
      _attendanceStates[student['roll']!] = true; // Default to present
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _students.where((s) {
      final name = s['name']!.toLowerCase();
      final roll = s['roll']!;
      return name.contains(_searchQuery.toLowerCase()) ||
          roll.contains(_searchQuery);
    }).toList();

    int presentCount = _attendanceStates.values.where((v) => v).length;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.className,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Code: ${widget.subjectCode} • Sem: ${widget.semester}th',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Synced: $presentCount Present / ${_students.length - presentCount} Absent',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text(
              'Sync Logs',
              style: TextStyle(
                color: Color(0xFF67E8F9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stat Bar & Search Panel
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Roster Summary: $presentCount/${_students.length} Present",
                      style: const TextStyle(
                        color: Color(0xFF67E8F9),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Search Input Field
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Search student by name or roll...",
                    hintStyle: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF475569),
                      size: 18,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Student List Builder
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: filteredStudents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                final roll = student['roll']!;
                final isPresent = _attendanceStates[roll] ?? true;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isPresent
                        ? Colors.white.withAlpha(6)
                        : Colors.redAccent.withAlpha(4),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isPresent
                          ? Colors.white.withAlpha(12)
                          : Colors.redAccent.withAlpha(30),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color:
                                  (isPresent
                                          ? const Color(0xFF10B981)
                                          : Colors.redAccent)
                                      .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                student['name']!
                                    .split(' ')
                                    .last
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: isPresent
                                      ? const Color(0xFF10B981)
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['name']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Roll: $roll',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(
                          () => _attendanceStates[roll] = !isPresent,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isPresent
                                ? const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.15)
                                : Colors.redAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isPresent
                                  ? const Color(0xFF10B981)
                                  : Colors.redAccent,
                              width: 0.8,
                            ),
                          ),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              isPresent ? 'Present' : 'Absent',
                              style: TextStyle(
                                color: isPresent
                                    ? const Color(0xFF10B981)
                                    : Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
}
