================================================================================
                         🏛️ CPI COMMAND CENTER 🏛️
      The Ultimate Mobile Management Ecosystem for Chattogram Polytechnic
================================================================================

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen.svg?style=for-the-badge)](https://github.com/tarek-molla/chittagong-polytechnic-app/pulls)

--------------------------------------------------------------------------------
📌 OVERVIEW
--------------------------------------------------------------------------------
CPI Command Center bridges the communication gap between students, department 
faculty, and college administration at Chattogram Polytechnic Institute (CPI). 

Built with Flutter and backed by Supabase, it delivers real-time access to daily 
class routines, official notices, department updates, and academic resources 
through an ultra-responsive, modern dark-themed glassmorphic interface.


--------------------------------------------------------------------------------
✨ KEY FEATURES
--------------------------------------------------------------------------------
• 📅 Smart Class Routines
  Instant access to shift, group, and semester-specific class schedules with 
  live teacher update overlays.

• 📢 Real-time Notice Board
  Filterable official college notices, exam schedules, and department 
  announcements with low-latency push sync.

• 👨‍🎓 Student Hub
  Personalized dashboard for tracking academic schedules, syllabus guides, 
  and laboratory timetables.

• 👨‍🏫 Faculty & Admin Portal
  Admin control panel for real-time schedule adjustments, quick notice 
  publishing, and routine updates.

• ⚡ Realtime Sync & Cloud Storage
  Powered by Supabase PostgreSQL and Realtime sockets for instant updates 
  across all connected devices.

• 🎨 Modern Dark/Glassmorphic UI
  Crafted with deep slate foundations (#0F172A), frosted glass panels, and 
  vibrant cyan highlights.


--------------------------------------------------------------------------------
📱 SCREENSHOTS
--------------------------------------------------------------------------------
+---------------------------+---------------------------+---------------------------+
|      Dynamic Routine      |    Campus Notice Board    |     Student Dashboard     |
+---------------------------+---------------------------+---------------------------+
| [ Add Routine Screenshot ]|  [ Add Notice Screenshot ]| [ Add Dashboard Screenshot]|
+---------------------------+---------------------------+---------------------------+


--------------------------------------------------------------------------------
🛠️ TECH STACK
--------------------------------------------------------------------------------
• Frontend Framework : Flutter (Dart)
• Backend Service    : Supabase (BaaS)
  - Database        : PostgreSQL
  - Authentication  : Supabase Auth
  - Storage         : Supabase Buckets (Notices, Documents, Media)
• State Management   : Provider / Riverpod
• Local Storage      : shared_preferences / Hive


--------------------------------------------------------------------------------
🚀 GETTING STARTED
--------------------------------------------------------------------------------

1. Prerequisites:
   - Flutter SDK (>= 3.0.0)
   - Dart SDK
   - Git
   - A active Supabase project instance

2. Clone the Repository:
   $ git clone https://github.com/tarek-molla/chittagong-polytechnic-app.git
   $ cd chittagong-polytechnic-app

3. Install Dependencies:
   $ flutter pub get

4. Environment Setup:
   Create a .env file in the root directory and add your Supabase credentials:
   
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key

5. Run the Application:
   $ flutter run


--------------------------------------------------------------------------------
🏗️ PROJECT STRUCTURE
--------------------------------------------------------------------------------
lib/
├── core/
│   ├── constants/       # Color palettes, theme tokens, static assets
│   ├── services/        # Supabase client setup & backend services
│   └── utils/           # Helper functions & form validation rules
├── models/              # Data structures (Routine, Notice, User, Department)
├── providers/           # State management stores & reactive controllers
├── views/
│   ├── auth/            # Login, registration, & portal selection
│   ├── dashboard/       # Main landing pages & quick navigation
│   ├── routine/         # Class timetables & routine views
│   └── notices/         # Live feed & notice details view
└── main.dart            # App entrypoint & initial configurations


--------------------------------------------------------------------------------
🤝 CONTRIBUTING
--------------------------------------------------------------------------------
Contributions are welcome! If you want to contribute:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


--------------------------------------------------------------------------------
📜 LICENSE & AUTHOR
--------------------------------------------------------------------------------
Distributed under the MIT License.

Author: Tarek Molla
GitHub: https://github.com/tarek-molla
Institute: Chattogram Polytechnic Institute (Computer Technology)

--------------------------------------------------------------------------------
Crafted with ❤️ for the students and faculty of Chattogram Polytechnic Institute.
================================================================================
