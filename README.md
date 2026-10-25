# Mlintex Shop Manager (Core Template)

A modern, high-performance store and bookkeeping management application built with Flutter, Riverpod, Hive (offline-first local database), and Firebase Cloud Sync. Supports Flutter Web (PWA), Android, and iOS.

---

## 📌 Architecture Notice for Developers & AI Agents

> **IMPORTANT**: This repository (`mlintex`) is the **Core Template Repository (`upstream`)** for multi-client white-label deployments.
>
> When working on this codebase or creating a new client deployment, **please read the architectural reference guide**:
> 📖 **[Multi-Client Architecture & Workflow Guide](docs/MULTI_CLIENT_ARCHITECTURE.md)**

### Key Workflow Rules:
1. **Core Improvements First**: Universal bug fixes and core engine improvements should be committed here in `mlintex` first.
2. **Selective Code Sharing**: Cloned client repositories use `git cherry-pick <commit-hash>` from this repo to pull only the specific features they need.
3. **Strict Client Isolation**: Client-specific credentials (Firebase, logos, bundle IDs) must never be merged into this template repository.

---

## Getting Started

### Prerequisites
- Flutter SDK (3.24+ recommended)
- Java 17+ (for Android builds)

### Run Locally
```bash
# Get dependencies
flutter pub get

# Run on Web (Chrome)
flutter run -d chrome

# Run on Android Device / Emulator
flutter run -d android
```

### Build Releases
```bash
# Build Web PWA
flutter build web --release

# Build Android APK
flutter build apk --release
```
