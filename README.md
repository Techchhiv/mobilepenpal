# Flutter Project Setup Guide

This document provides step-by-step instructions for setting up and running the Flutter project locally.

---

## Prerequisites

Before you begin, make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) or [Visual Studio Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/)
- A physical device or emulator for testing

---

## 1. Clone the Project

```bash
git clone https://gitlab.com/Techchhiv/mobilepenpal.git
cd mobilepenpal
```

## 2. Install Dependencies

```bash
flutter doctor
flutter pub get
```

## 3. Environment Configuration

The project uses a Dart environment file located at:

> lib/core/config/env.dart

***

Example Content:

```dart
static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.157:8000/api/mobile',
  );
```
> ⚠️ Important:
Before running the app, make sure to replace the default API URL (http://192.168.0.157:8000/api/mobile) with your computer’s local IP address.
This allows your mobile device or emulator to connect to the backend server running on your computer.

**How to find your IP address:**

Open terminal and look for your ip using

```cmd
ipconfig
```

**Update the environment:**

Replace the IP address in the `defaultValue` parameter with your computer's IP

```dart
static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://YOUR_IP_ADDRESS:8000/api/mobile', // Replace YOUR_IP_ADDRESS
  );
```

## 4. Backend Configuration

The Laravel backend server must be running on host `0.0.0.0` and port `8000`to accept connections from mobile devices and emulators.

**Start the Laravel backend server with:**

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

This will make the backend accessible to devices on your local network. Using `127.0.0.1` or `localhost` will only allow connections from the same machine.

## 5. Run the application

```bash
flutter run
```