<p align="center">
  <img src="assets/cpi_logo.png" alt="CPI Logo" width="140" />
</p>

# 🏛️ CPI Command Center

> The ultimate, modern mobile management ecosystem for **Chattogram Polytechnic Institute (CPI)**. Streamlining class routines, instant campus notices, and academic administration into one sleek, high-performance application.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)
![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen.svg?style=for-the-badge)

---

## 🌟 Overview

**CPI Command Center** bridges the communication gap between students, department faculty, and college administration at Chattogram Polytechnic Institute. Built with Flutter and backed by Supabase, it provides real-time access to daily class routines, official notices, department updates, and academic resources through an ultra-responsive glassmorphic dark-themed interface.

---

## ✨ Key Features

- 📅 **Smart Class Routines:** Instant access to shift, group, and semester-specific class schedules with live teacher update overlays.
- 📢 **Real-time Notice Board:** Filterable official college notices, exam schedules, and department announcements with instant push notifications.
- 👨‍🎓 **Student Hub:** Personalized dashboard for tracking academic progress, syllabus guides, and lab schedules.
- 👨‍🏫 **Faculty & Admin Portal:** Admin tools for real-time schedule modifications, notice publication, and routine management.
- ⚡ **Realtime Database & Sync:** Low-latency dynamic updates powered by Supabase PostgreSQL and Realtime sockets.
- 🎨 **Modern Dark/Glassmorphism UI:** Built with deep slate foundations, frosted glass containers, and energetic glowing highlights.

---

## 📱 App Screenshots

| Dynamic Routine | Campus Notice Board | Student Dashboard |
| :---: | :---: | :---: |
| _`[ Add Routine Screenshot ]`_ | _`[ Add Notice Screenshot ]`_ | _`[ Add Dashboard Screenshot ]`_ |

---

## 🛠️ Tech Stack

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend as a Service (BaaS):** [Supabase](https://supabase.com/)
  - Database: PostgreSQL
  - Authentication: Supabase Auth
  - Storage: Supabase Buckets (Notices, Documents, Profiles)
- **State Management:** Provider / Riverpod
- **Local Storage:** `shared_preferences` / Hive

---

## 🚀 Getting Started

### Prerequisites

Before starting, ensure you have the following installed:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.0.0`)
* [Dart SDK](https://dart.dev/get-started/sdk)
* [Git](https://git-scm.com/)
* A [Supabase](https://supabase.com/) project instance

### Installation & Setup

1. **Clone the Repository:**
   ```bash
   git clone [https://github.com/tarek-molla/chittagong-polytechnic-app.git](https://github.com/tarek-molla/chittagong-polytechnic-app.git)
   cd chittagong-polytechnic-app

 * Install Dependencies:
   flutter pub get

 * Configure Environment Variables:
   Create a .env file in the root directory and insert your Supabase credentials:
   SUPABASE_URL=[https://your-supabase-project.supabase.co](https://your-supabase-project.supabase.co)
SUPABASE_ANON_KEY=your-supabase-anon-key

 * Run the Application:
   flutter run

🏗️ Project Architecture
lib/
├── core/
│   ├── constants/       # App colors, theme tokens, and API keys
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

🤝 Contributing
Contributions make the open-source community an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.
 * Fork the Project
 * Create your Feature Branch (git checkout -b feature/AmazingFeature)
 * Commit your Changes (git commit -m 'Add some AmazingFeature')
 * Push to the Branch (git push origin feature/AmazingFeature)
 * Open a Pull Request
📜 License
Distributed under the MIT License. See LICENSE for more information.
👨‍💻 Author
Tarek Molla
 * GitHub: @tarek-molla
 * Student at Chattogram Polytechnic Institute (Computer Technology)
<p align="center">
Crafted with ❤️ for the students and faculty of Chattogram Polytechnic Institute.
</p>