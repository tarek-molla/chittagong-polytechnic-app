================================================================================
🏛️ CPI COMMAND CENTER 🏛️
The Ultimate Management & Routine Portal for Chittagong Polytechnic
​[Flutter]  [Dart]  [Supabase]  [License: MIT]  [PRs Welcome]
​📖 OVERVIEW
​CPI Command Center bridges the daily communication gap between students, department
faculty, and college administration at Chattogram Polytechnic Institute (CPI).
​Built with Flutter and backed by Supabase, the app delivers fast, real-time access
to class routines, exam alerts, campus updates, and academic resources through an
intuitive, modern dark-themed mobile experience.
​✨ KEY FEATURES
​• 📅 Smart Class Routines
Instant access to shift, group, and semester-specific class schedules with
live teacher update overlays.
​• 📢 Real-Time Notice Board
Filterable official college notices, exam schedules, and department updates
with push notifications.
​• 👨‍🎓 Student Academic Hub
Personalized dashboard for tracking academic progress, syllabus guides, and
lab schedules.
​• 👨‍🏫 Faculty & Admin Portal
Admin tools for instant schedule updates, notice publication, and routine
management.
​• ⚡ Low-Latency Data Sync
Dynamic updates powered by Supabase PostgreSQL and Realtime sockets.
​🛠️ TECH STACK
​• Frontend: Flutter (Dart)
• Backend (BaaS): Supabase
​Database: PostgreSQL
​Auth: Supabase Auth
​Storage: Supabase Buckets (Notices, Documents, Profiles)
• State Management: Provider / Riverpod
• Local Cache: shared_preferences / Hive
​🚀 GETTING STARTED
​PREREQUISITES:
​Flutter SDK (>= 3.0.0)
​Dart SDK
​Git
​A Supabase project instance
​INSTALLATION:
​Clone the repository:
git clone https://github.com/tarek-molla/chittagong-polytechnic-app.git
cd chittagong-polytechnic-app
​Install dependencies:
flutter pub get
​Setup environment variables:
Create a .env file in the root directory and add your Supabase keys:
SUPABASE_URL=https://your-supabase-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
​Run the application:
flutter run
​📂 PROJECT STRUCTURE
​lib/
├── core/
│   ├── constants/       # App colors, themes, and configuration
│   ├── services/        # Supabase client & API services
│   └── utils/           # Helper functions & form validators
├── models/              # Data models (Routine, Notice, User, Department)
├── providers/           # State management & reactive logic
├── views/
│   ├── auth/            # Login & authentication views
│   ├── dashboard/       # Main navigation & landing screens
│   ├── routine/         # Class schedules & time tables
│   └── notices/         # Realtime notice feeds & details
└── main.dart            # Application entry point
​🤝 CONTRIBUTING
​Contributions make the open-source community an incredible place to learn,
inspire, and create. Any contributions are greatly appreciated!
​Fork the project
​Create your feature branch (git checkout -b feature/NewFeature)
​Commit your changes (git commit -m 'Add NewFeature')
​Push to the branch (git push origin feature/NewFeature)
​Open a Pull Request
​📜 LICENSE & AUTHOR
​Distributed under the MIT License.
​Author: Tarek Molla
GitHub: https://github.com/tarek-molla
Student at Chattogram Polytechnic Institute (Computer Technology)
​================================================================================
Crafted with ❤️ for the students and faculty of Chattogram Polytechnic.