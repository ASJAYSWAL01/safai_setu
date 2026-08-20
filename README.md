# Safai Setu — Smart Waste Management System

**Bridging Citizens, Workers and Department Heads for a Cleaner Tomorrow**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5.4-0175C2?logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Notifications-FFCA28?logo=firebase&logoColor=black)
![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Version](https://img.shields.io/badge/Version-1.0.0-blue)

---

## Table of Contents

- [About the Project](#about-the-project)
- [Objective](#objective)
- [Key Features](#key-features)
- [User Roles](#user-roles)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Setup and Installation](#setup-and-installation)
- [Login Instructions](#login-instructions)
- [Current Implementation Status](#current-implementation-status)
- [Team and Contact](#team-and-contact)

---

## About the Project

**Safai Setu** (meaning *Cleanliness Bridge*) is a Flutter-based Android application designed to streamline urban sanitation and waste management. It connects three key stakeholders — **citizens**, **sanitation workers**, and **department heads** — on a single digital platform to make waste reporting, task management, and oversight fast, transparent, and efficient.

---

## Objective

The core objective of Safai Setu is to:

- Empower **citizens** to report waste issues in their locality with photo evidence and live GPS location.
- Enable **department heads** to monitor complaints, manage workers, assign collection tasks, and track live progress.
- Allow **sanitation workers** to receive assigned tasks, navigate to waste sites, and submit proof of completion.
- Reduce response time to waste complaints and improve accountability across the sanitation chain.

---

## Key Features

### Citizen Features

- **Google Sign-In** — Secure and quick authentication using any Google account.
- **Report Waste Complaint** — Submit complaints with category selection, photo upload (camera), and GPS-pinned location on an interactive map.
- **Track Complaint Status** — View real-time status updates of submitted complaints (Pending → Assigned → Resolved).
- **Complaint History** — Browse all previously submitted complaints with details.
- **Waste Hotspot Map** — View a live map highlighting active waste complaint hotspots in the area.
- **Push Notifications** — Receive Firebase notifications when complaint status is updated.
- **Profile Management** — Complete profile with phone number for the department to contact.
- **Multilingual Support** — App supports multiple languages via Flutter localizations.
- **Dark / Light Theme** — Switch between dark and light modes for comfort.

### Department Head Features

- **Secure Head Login** — Pre-registered Google account linked to the Head role.
- **Head Dashboard** — Overview statistics: total complaints, pending tasks, active workers, resolved issues.
- **Citizen Complaints Management** — View, filter, and act on all reported citizen complaints.
- **Worker Management** — Add, edit, view details, and generate unique Worker IDs for sanitation staff.
- **Task Assignment** — Assign collection tasks to specific workers with location details and instructions.
- **Task Oversight** — View all assigned tasks and their current status.
- **Completion Proofs Review** — Review photo proofs submitted by workers upon task completion.
- **Live Worker Map** — Track active workers in real time on an interactive Google Map.
- **Send Notifications** — Push targeted notifications to workers or citizens.
- **Route Optimization** — Optimized waste collection routes for workers.

### Sanitation Worker Features

- **Secure Worker Login** — Pre-registered Google account linked to a Worker ID.
- **My Tasks** — View all tasks assigned by the Head, with status and location.
- **Task Detail and Navigation** — View full task details and navigate to the waste site.
- **Submit Proof** — Upload a photo as proof of task completion directly from the app.
- **Real-time Status Updates** — Task statuses update live when the Head makes changes.

---

## User Roles

The application supports **three distinct user roles**, each with its own dedicated interface and permissions:

| Role | Access Level | Login Method |
|------|-------------|--------------|
| **Citizen** | Complaint reporting and tracking | Any Google account via Google Sign-In |
| **Department Head** | Full admin: workers, tasks, map, reports | Pre-registered Head Google account |
| **Sanitation Worker** | Assigned tasks, proof submission | Pre-registered Worker Google account |

> Role assignment is determined by the Google account used to sign in. Head and Worker roles are linked to specific pre-registered email addresses in the Supabase backend for security.

---

## Technology Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter 3.x (Dart 3.5.4) |
| **Backend and Database** | Supabase (PostgreSQL) |
| **Authentication** | Supabase Auth + Google Sign-In |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Local Notifications** | flutter_local_notifications |
| **Maps** | Google Maps Flutter |
| **Location Services** | Geolocator |
| **Image Handling** | Image Picker (Camera) |
| **Storage** | Supabase Storage (photo uploads) |
| **State Management** | Flutter StatefulWidget + Services pattern |
| **Local Storage** | Shared Preferences |
| **Icons** | Font Awesome Flutter + Cupertino Icons |
| **Vector Assets** | Flutter SVG |
| **Web Views** | WebView Flutter |
| **URL Handling** | URL Launcher |

---

## Project Structure

```
safai_setu/
├── lib/
│   ├── main.dart                          # App entry point and Firebase/Supabase init
│   ├── data/                              # Static data repositories (categories, etc.)
│   ├── l10n/                              # Localization / multilingual support
│   ├── models/                            # Data models (Complaint, Task, User, etc.)
│   ├── screens/
│   │   ├── auth/                          # Authentication screens
│   │   ├── complaints/                    # Report and view complaint screens
│   │   ├── head/                          # Head dashboard and management screens
│   │   ├── home/                          # Citizen home screen
│   │   ├── hotspots/                      # Waste hotspot map screen
│   │   ├── map/                           # General map screens
│   │   ├── notifications/                 # Notification center
│   │   ├── profile/                       # User profile screen
│   │   ├── splash/                        # Splash/loading screen
│   │   ├── support/                       # Help and support
│   │   ├── tracking/                      # Complaint tracking
│   │   ├── worker/                        # Worker task screens
│   │   ├── about/                         # About / manual
│   │   ├── login_page.dart                # Unified login page (role-based)
│   │   └── main_shell.dart                # Bottom nav shell for citizens
│   ├── services/                          # Business logic and API services
│   │   ├── auth_service.dart              # Authentication and session management
│   │   ├── complaint_service.dart         # Complaint CRUD operations
│   │   ├── task_service.dart              # Worker task management
│   │   ├── notification_service.dart      # FCM and local notifications
│   │   ├── location_service.dart          # GPS and location utilities
│   │   ├── hotspot_service.dart           # Waste hotspot detection
│   │   ├── profile_service.dart           # User profile management
│   │   └── route_optimization_service.dart # Collection route optimizer
│   ├── theme/                             # App theme, colors and typography
│   ├── utils/                             # Validators and utility functions
│   └── widgets/                           # Reusable UI components
├── assets/
│   └── images/                            # App images and mascot
├── android/                               # Android native configuration
├── supabase/                              # Supabase edge functions / config
├── supabase_setup.sql                     # Full database schema and setup SQL
└── pubspec.yaml                           # Dependencies and asset declarations
```

---

## Setup and Installation

### For Citizens (General Users)

Getting started as a citizen is extremely simple — **no technical setup required!**

1. **Download the APK**
   - Download the safai_setu.apk file onto your Android device.

2. **Install the APK**
   - Open the downloaded APK file.
   - If prompted, allow installation from unknown sources in your Android settings:
     Settings → Security → Install Unknown Apps → Allow

3. **Launch the App**
   - Open **Safai Setu** from your app drawer.

4. **Sign In**
   - Tap **Sign in with Google**.
   - Select **any of your Google (Gmail) accounts**.
   - You will be automatically registered as a **Citizen** and can start reporting waste complaints immediately.

> **No registration form needed!** Your Google account handles everything securely.

---

## Login Instructions

### For Department Head and Sanitation Worker Login

The **Head** and **Worker** roles are protected by pre-registered email addresses for security. To log in as a Head or Worker:

### Official Login Credentials

| Role | Email ID | Password |
|------|----------|----------|
| **Department Head** | head.safaisetu@gmail.com | Head@123 |
| **Sanitation Worker** | worker.safaisetu@gmail.com | worker@123 |

> Keep these credentials confidential. Share only with authorized personnel.

#### Step 1 — Add the Account to Your Phone

Before signing in to the app, the designated Google account must be **added to your Android device**:

1. Go to `Settings → Accounts → Add Account → Google`
2. Enter the **Head or Worker email and password** from the table above.

#### Step 2 — Sign In to the App

1. Open **Safai Setu**.
2. On the login screen, tap **Sign in with Google**.
3. Select the **Head or Worker email** you just added to your device.
4. The app will automatically detect the role linked to that account and open the correct dashboard.

> **Why this process?** This two-step flow ensures that only authorized personnel with access to the designated email accounts can access sensitive Head or Worker features. It is a deliberate security design of the app.

---

### For Developers — Running from Source

If you want to run the project from source code, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (Dart SDK ^3.5.4)
- [Android Studio](https://developer.android.com/studio) with an Android emulator or physical device (API 21+)
- A configured google-services.json in ndroid/app/ (Firebase)
- Supabase project credentials configured in lib/main.dart

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd safai_setu

# 2. Install Flutter dependencies
flutter pub get

# 3. Run the app on a connected device/emulator
flutter run
```

---

## Current Implementation Status

| Feature | Status |
|---------|--------|
| Google Sign-In Authentication | Complete |
| Role-based access (Citizen / Head / Worker) | Complete |
| Citizen — Report Waste Complaint | Complete |
| Citizen — Photo Upload via Camera | Complete |
| Citizen — GPS and Map Location Picker | Complete |
| Citizen — Complaint Tracking | Complete |
| Citizen — Waste Hotspot Map | Complete |
| Citizen — Push Notifications (FCM) | Complete |
| Citizen — Profile Completion | Complete |
| Head — Dashboard with Statistics | Complete |
| Head — View and Manage Citizen Complaints | Complete |
| Head — Worker Management (Add/Edit/View) | Complete |
| Head — Generate Worker ID | Complete |
| Head — Assign Tasks to Workers | Complete |
| Head — Review Completion Proofs | Complete |
| Head — Live Worker Map | Complete |
| Head — Send Notifications | Complete |
| Worker — View Assigned Tasks | Complete |
| Worker — Task Detail and Navigation | Complete |
| Worker — Submit Proof of Completion | Complete |
| Multilingual Support | Complete |
| Dark / Light Theme | Complete |
| Route Optimization | Complete |
| Supabase Backend and Database | Complete |
| Network Connectivity Handling | Complete |

---

## Team and Contact

This project was developed by a dedicated team:

- Ashish
- Het
- Hrisit
- Nihar
- Harsh
- Preeyanshi

If you encounter any issues during installation or while using the app, feel free to reach out:

**Contact: +91 72838 81430**

We are happy to help with any inconvenience!

---

*Made with care for a cleaner, smarter city.*
