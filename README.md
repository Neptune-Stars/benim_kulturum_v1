# Benim Kültürüm

**Benim Kültürüm** is a Flutter mobile campus assistant application designed for İstanbul Kültür University students and administrators. The app centralizes campus-related information such as classrooms, campus units, instructors, office hours, announcements, events, cafeteria menus, prices, support messages, and issue reports.

The project uses **Firebase Cloud Firestore as the single shared data source**. Student-facing screens and the admin panel read from and write to the same Firestore collections, so updates made by admins can be reflected on the student side.

**Hive is not used in the final version of this project.**

---

## Repository

```bash
git clone https://github.com/Neptune-Stars/benim_kulturum_v1.git
cd benim_kulturum_v1
```

---

## Project Purpose

The purpose of this application is to make campus life easier for students by providing one mobile platform where they can:

- Search for campus locations, classrooms, instructors, announcements, and events
- View classroom and laboratory information
- Follow announcements and campus events
- Check cafeteria menu and campus price information
- Save favorite instructors, classrooms, and events
- Join events
- Report campus or technical issues
- Contact admin support through live support
- Manage their profile avatar

Administrators can manage the shared app data through the admin panel, including classrooms, campus units, instructors, announcements, events, cafeteria menus, prices, issue reports, students, and support messages.

---

## Main Features

### Student Side

- Student login
- Home dashboard
- Campus unit guide
- Classroom and lab listing
- Instructor listing and detail pages
- Office hours screen
- Global search
- Announcements
- Events
- Cafeteria menu
- Campus prices
- Favorites
- Joined events
- Profile page
- Profile avatar selection
- Report issue form
- Live support chat
- Notifications
- Dark mode support

### Admin Side

- Admin dashboard overview
- Manage campus units
- Manage classrooms
- Manage instructors
- Manage events
- Manage announcements
- Manage cafeteria menus
- Manage price categories and prices
- Manage issue reports
- Manage students
- Update student profile avatar option
- Live support chat management
- Mark issues as resolved
- Delete and refresh Firestore-backed records
- Dark mode toggle

---

## Tech Stack

- Flutter
- Dart
- Firebase Core
- Cloud Firestore
- Provider
- GoRouter
- Google Fonts
- url_launcher

---

## Data Source Policy

The final version of the project uses **Firebase / Cloud Firestore** as the shared data source.

Shared data must be stored and managed through Firestore.

### Current shared data examples

| App Area | Firestore Source |
|---|---|
| Announcements | `announcements` |
| Events | `events` |
| Campus units | `buildings` |
| Classrooms / labs | `classrooms` |
| Instructors | `instructors` |
| Cafeteria settings | `settings/cafeteria` |
| Cafeteria daily menus | `cafeteriaMenus` |
| Cafeteria day status | `cafeteriaDayStatuses` |
| Prices | `prices` |
| Price categories | `priceCategories` |
| Issues | `issues` |
| Students | `students` |
| Notifications | `notifications` |
| Support chats | `support_chats` |

---

## Data Model Notes

### Campus Units vs Classrooms

The app separates general campus units from academic spaces.

Campus units should include:

- Library
- Cafeteria
- Faculty
- Department
- Administrative unit
- Student affairs
- Health unit
- Security
- Social area
- Service unit
- Auditorium / arts center / event venue

Classroom-related records should be managed under the classroom system:

- Classroom
- Lab
- Laboratory
- Computer lab
- Amphitheater
- Lecture hall
- Derslik
- Sınıf
- Amfi

This prevents the same real-world location from appearing twice in the app as both a campus unit and a classroom.

---

## Profile Avatar System

The project does not use Firebase Storage for profile pictures. Instead, students choose from predefined profile avatar options.

The selected avatar is saved in the student document:

```text
students/{studentDocId}
  profileAvatarId: "avatar_1"
  profileAvatarUpdatedAt: Timestamp
```

This avoids local-device-only image storage and keeps the selected avatar available across devices.

---

## Issue Reporting

Students can submit issue reports from the app. Reports are saved to Firestore and displayed in the admin panel.

Expected issue fields:

```text
id
title
description
category
status
priority
studentId
studentName
studentEmail
createdAt
updatedAt
```

Default values:

```text
status: "open"
priority: "normal"
createdAt: serverTimestamp()
updatedAt: serverTimestamp()
```

Admins can review and resolve issues from the admin dashboard.

---

## Favorites and Joined Events

Student favorites and joined events are stored in the related student document in Firestore.

Example:

```text
students/{studentDocId}
  favoriteIds: [...]
  joinedEventIds: [...]
  favoritesUpdatedAt: Timestamp
  joinedEventsUpdatedAt: Timestamp
```

This allows favorites and joined events to remain available after logout, app restart, or login from another device.

---

## Project Structure

```text
lib/
  data/
    data_service.dart

  providers/
    auth_provider.dart
    favorites_provider.dart
    joined_events_provider.dart
    notification_provider.dart
    profile_provider.dart
    theme_provider.dart

  screens/
    admin_dashboard_screen.dart
    admin_chat_detail_screen.dart
    admin_chat_list_screen.dart
    announcements_screen.dart
    building_detail_screen.dart
    buildings_screen.dart
    cafeteria_menu_screen.dart
    campus_prices_screen.dart
    classroom_detail_screen.dart
    classrooms_screen.dart
    event_detail_screen.dart
    events_screen.dart
    favorites_screen.dart
    help_support_screen.dart
    home_screen.dart
    instructor_detail_screen.dart
    instructors_screen.dart
    login_screen.dart
    main_screen.dart
    notifications_screen.dart
    office_hours_screen.dart
    privacy_policy_screen.dart
    profile_screen.dart
    report_issue_screen.dart
    search_screen.dart
    splash_screen.dart
    support_chat_screen.dart
    welcome_screen.dart

  theme/
    app_theme.dart

  widgets/
    badge_widget.dart
    custom_app_bar.dart
    filter_chip_widget.dart
    info_card.dart
    quick_action_card.dart
    search_bar_widget.dart
    section_header.dart
    settings_row.dart
```

---

## Setup Instructions

### 1. Clone the project

```bash
git clone https://github.com/Neptune-Stars/benim_kulturum_v1.git
cd benim_kulturum_v1
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

This project requires Firebase configuration files generated by FlutterFire.

Typical setup:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Required Firebase services:

- Firebase Core
- Cloud Firestore

Important Firebase configuration files:

```text
lib/firebase_options.dart
android/app/google-services.json
```

Do not paste actual Firebase config values, service account files, or private credentials into the README or a public repository.

### 4. Run the app

```bash
flutter run
```

### 5. Analyze the project

```bash
flutter analyze
```

The project may still contain non-blocking lint warnings such as `withOpacity` deprecation or `use_build_context_synchronously`. These do not prevent the app from compiling, but they can be cleaned in a later polishing phase.

---

## Running the Project with Android Studio

You can run this Flutter project directly from Android Studio using either an Android Emulator or a physical Android device.

### 1. Install required tools

Before opening the project, make sure these are installed:

- Flutter SDK
- Android Studio
- Android SDK tools
- Flutter plugin for Android Studio
- Dart plugin for Android Studio

You can verify the setup from a terminal with:

```bash
flutter doctor
```

If Flutter reports Android toolchain or Android Studio issues, fix them before running the app.

---

### 2. Open the project in Android Studio

1. Open **Android Studio**.
2. Click **Open**.
3. Select the project root folder:

```text
benim_kulturum_v1
```

4. Wait for Android Studio to index the project.
5. If Android Studio asks to get packages, click **Pub get**.

Do not open only the `android/` folder. Open the full Flutter project folder.

---

### 3. Install dependencies

In Android Studio, open the terminal at the bottom and run:

```bash
flutter pub get
```

Or open `pubspec.yaml` and click **Pub get**.

---

### 4. Select a device

You can run the app using either:

- Android Emulator
- Physical Android phone

#### Option A — Android Emulator

1. Open **Device Manager** in Android Studio.
2. Create or start an Android Virtual Device.
3. Select the emulator from the device dropdown at the top.

#### Option B — Physical Android Device

1. Enable **Developer Options** on the phone.
2. Enable **USB Debugging**.
3. Connect the phone with USB.
4. Accept the debugging permission popup on the phone.
5. Select the phone from the Android Studio device dropdown.

---

### 5. Run the app

Click the green **Run** button in Android Studio.

Or run from the Android Studio terminal:

```bash
flutter run
```

---

### 6. Firebase requirement

The app requires Firebase configuration files to be present.

Important files:

```text
lib/firebase_options.dart
android/app/google-services.json
```

If these files are missing, generate them using FlutterFire:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Do not commit private Firebase credentials or service account files to a public repository.

---

### 7. Useful Android Studio terminal commands

Run dependency install:

```bash
flutter pub get
```

Analyze project:

```bash
flutter analyze
```

Run app:

```bash
flutter run
```

Clean build files:

```bash
flutter clean
```

Build APK:

```bash
flutter build apk
```

---

### 8. Common Android Studio problems

#### Problem: No device selected

Open Android Studio Device Manager and start an emulator, or connect a physical Android device with USB debugging enabled.

#### Problem: Firebase initialization error

Check that these files exist:

```text
lib/firebase_options.dart
android/app/google-services.json
```

Then run:

```bash
flutter clean
flutter pub get
flutter run
```

#### Problem: Dependencies are not found

Run:

```bash
flutter pub get
```

#### Problem: Android SDK error

Open:

```text
Android Studio → Settings → Languages & Frameworks → Android SDK
```

Install the required Android SDK platform and tools.

#### Problem: App still shows old data

Run:

```bash
flutter clean
flutter pub get
flutter run
```

Also confirm the data exists in Firestore, because the final app uses Firestore as the shared source of truth.

---

## Firebase Setup Notes

Create the required Firestore collections before testing the full app flow:

```text
students
buildings
classrooms
instructors
events
announcements
prices
priceCategories
issues
notifications
settings
cafeteriaMenus
cafeteriaDayStatuses
support_chats
```

The cafeteria settings document should use:

```text
settings/cafeteria
```

---

## Admin Access

The app has an admin panel route:

```text
/admin
```

Admin login behavior is currently implemented in the app login flow. For real production usage, admin access should be moved to Firebase Authentication with proper role-based authorization.

---

### Admin and student screens must use the same collections

If an admin creates, updates, or deletes a record, the student side should read the same Firestore collection and reflect the change.

### Deleting data should update student screens

For example, when an announcement is deleted from the admin panel, it should no longer appear on:

- Student home screen
- Student announcements screen
- Search results

### Search should avoid duplicate results

The search screen combines records from multiple Firestore collections. It includes duplicate-prevention logic so the same real-world location does not appear twice as both a campus unit and a classroom.

---

## Testing Checklist

Before delivery, test these flows:

### Student Flow

- Login as student
- Open home screen
- Search for campus data
- View classroom details
- View instructor details
- Favorite an instructor
- Open favorites screen
- Join an event
- View joined event count
- Select profile avatar
- Submit issue report
- Open support chat

### Admin Flow

- Login as admin
- Add/edit/delete announcement
- Add/edit/delete event
- Add/edit/delete campus unit
- Add/edit/delete classroom
- Update cafeteria menu
- Update price data
- View submitted issue report
- Mark issue as resolved
- Open support chat list
- Edit student avatar option

### Synchronization Tests

- Admin adds an announcement → student sees it
- Admin deletes an announcement → student no longer sees it
- Student submits issue → admin sees it
- Student favorites instructor → favorite appears in profile and favorites screen
- Student changes avatar → admin sees updated avatar
- Admin changes student avatar → student sees updated avatar after login/reload
- Firestore record is changed manually → app reflects Firestore value after refresh/restart

---

## Known Limitations

- Student and admin login are currently custom app-level flows rather than full Firebase Authentication.
- Firebase Storage is not used for uploaded profile images.
- Profile images are handled through predefined avatar options.
- Some lint warnings may remain and can be cleaned during a later polish/refactor phase.
- `admin_dashboard_screen.dart` is large and should eventually be split into smaller admin tab files for maintainability.

---

## Recommended Future Improvements

- Migrate login system to Firebase Authentication
- Add Firestore security rules for students and admins
- Add role-based access control
- Split admin dashboard into smaller files
- Add loading skeletons to more screens
- Improve offline/error states
- Add Firestore indexes where needed
- Add integration tests for admin-student synchronization
- Add production-grade notification read tracking per user

---

## Build

For Android APK:

```bash
flutter build apk
```

For Android App Bundle:

```bash
flutter build appbundle
```

---

## Project Summary

Benim Kültürüm is a Firebase-backed Flutter campus assistant app. It provides students with access to real-time campus information and gives admins a centralized dashboard to manage the same data. The final data flow is designed around Firestore as the shared source of truth so that admin updates and student screens remain synchronized.
