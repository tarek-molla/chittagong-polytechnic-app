import 'package:supabase_flutter/supabase_flutter.dart';

class RoutineEntry {
  final String subjectName;
  final String teacherName;
  final String room;
  final String startTime;
  final String endTime;
  final int day; // 1 for Monday, 7 for Sunday
  final String type;
  final String color;

  RoutineEntry({
    required this.subjectName,
    required this.teacherName,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.day,
    required this.type,
    required this.color,
  });

  factory RoutineEntry.fromJson(Map<String, dynamic> json) {
    return RoutineEntry(
      subjectName: json['subject_name'] ?? 'Unknown',
      teacherName: json['teacher_name'] ?? 'Unknown',
      room: json['room'] ?? 'Unknown',
      startTime: json['start_time'] ?? '00:00',
      endTime: json['end_time'] ?? '00:00',
      day: json['day'] is int ? json['day'] : _getDayNumber(json['day']),
      type: json['type'] ?? 'Theory',
      color: json['color'] ?? '#00E5FF',
    );
  }

  static int _getDayNumber(String dayStr) {
    final map = {
      'SUN': 7,
      'MON': 1,
      'TUE': 2,
      'WED': 3,
      'THU': 4,
      'FRI': 5,
      'SAT': 6,
    };
    return map[dayStr] ?? 1;
  }
}

class RoutineService {
  final SupabaseClient _supabase;

  RoutineService(this._supabase);

  static const _dayMap = {
    1: 'MON',
    2: 'TUE',
    3: 'WED',
    4: 'THU',
    5: 'FRI',
    6: 'SAT',
    7: 'SUN',
  };

  String getDayName(int day) {
    return _dayMap[day] ?? 'UNKNOWN';
  }

  int getDayNumber(String dayName) {
    final map = {
      'SUN': 7,
      'MON': 1,
      'TUE': 2,
      'WED': 3,
      'THU': 4,
      'FRI': 5,
      'SAT': 6,
    };
    return map[dayName] ?? 1;
  }

  /// Fetches the entire routine for a given department and semester.
  Future<List<RoutineEntry>> fetchRoutine(
    String department,
    int semester,
  ) async {
    try {
      final response = await _supabase
          .from('routine')
          .select()
          .eq('department', department)
          .eq('semester', semester)
          .eq('is_active', true)
          .order('day', ascending: true)
          .order('start_time', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      return (response as List)
          .map((json) => RoutineEntry.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching routine: $e');
      return [];
    }
  }

  /// Fetches the currently ongoing class.
  Future<RoutineEntry?> fetchCurrentClass(
    String department,
    int semester,
  ) async {
    try {
      final now = DateTime.now();
      final currentDay = now.weekday;
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('routine')
          .select()
          .eq('department', department)
          .eq('semester', semester)
          .eq('day', currentDay)
          .eq('is_active', true)
          .lte('start_time', currentTime)
          .gte('end_time', currentTime)
          .limit(1);

      if (response.isNotEmpty) {
        return RoutineEntry.fromJson(response.first);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching current class: $e');
      return null;
    }
  }

  /// Fetches the next upcoming class.
  Future<RoutineEntry?> fetchNextClass(String department, int semester) async {
    try {
      final now = DateTime.now();
      final currentDay = now.weekday;
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // First, check for classes later today
      final todayResponse = await _supabase
          .from('routine')
          .select()
          .eq('department', department)
          .eq('semester', semester)
          .eq('day', currentDay)
          .eq('is_active', true)
          .gt('start_time', currentTime)
          .order('start_time')
          .limit(1);

      if (todayResponse.isNotEmpty) {
        return RoutineEntry.fromJson(todayResponse.first);
      }

      // If no classes today, check for the next day
      for (int i = 1; i <= 7; i++) {
        final nextDay = (currentDay % 7) + i;
        if (nextDay == currentDay) continue;

        final nextDayResponse = await _supabase
            .from('routine')
            .select()
            .eq('department', department)
            .eq('semester', semester)
            .eq('day', nextDay)
            .eq('is_active', true)
            .order('start_time')
            .limit(1);

        if (nextDayResponse.isNotEmpty) {
          return RoutineEntry.fromJson(nextDayResponse.first);
        }
      }

      return null;
    } catch (e) {
      print('❌ Error fetching next class: $e');
      return null;
    }
  }

  /// Provides a stream that immediately fetches data, then refreshes every 30 seconds
  /// This fixes the long loading time issue
  Stream<List<RoutineEntry>> getRoutineStream(String department, int semester) async* {
    // ✅ IMMEDIATELY yield data on first subscription (no waiting)
    try {
      yield await fetchRoutine(department, semester);
    } catch (e) {
      print('❌ Initial fetch error: $e');
      yield [];
    }
    
    // Then refresh every 30 seconds
    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        yield await fetchRoutine(department, semester);
      } catch (e) {
        print('❌ Refresh error: $e');
        // Yield previous data on error (don't break the stream)
      }
    }
  }
}
