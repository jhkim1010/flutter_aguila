# Technology Stack

**Analysis Date:** 2026-04-01

## Languages

**Primary:**
- Dart 3.0+ - Flutter application development
- TypeScript/JavaScript - Website documentation (Astro)

**Secondary:**
- Swift/Objective-C - iOS platform bindings
- Kotlin/Java - Android platform bindings
- C - Platform-specific native code

## Runtime

**Environment:**
- Flutter SDK (latest stable)
- Dart VM (3.0.0 to <4.0.0)

**Package Manager:**
- pub (Dart package manager)
- npm/pnpm (Node.js for website)

**Lockfiles:**
- `pubspec.lock` - Dart dependencies (present)
- `package-lock.json` - npm dependencies for website (present)

## Frameworks

**Core:**
- Flutter 3.x - Multi-platform UI framework (iOS, Android, macOS, Windows, Linux)
- Material Design - UI design system

**Website/Documentation:**
- Astro 5.6.1 - Static site generation
- Starlight 0.37.0 - Documentation template for Astro
- Tailwind CSS 4.1.17 - Utility-first CSS framework

**Dev/Build Tools:**
- flutter_launcher_icons 0.13.1 - App icon generation
- flutter_lints 3.0.0 - Dart linting standards

## Key Dependencies

**HTTP & Networking:**
- http 1.1.0 - HTTP client for API calls
- flutter_secure_storage 9.0.0 - Secure credential storage

**Local Storage:**
- shared_preferences 2.2.2 - Key-value preferences storage
- sqflite 2.3.0 - Local SQLite database
- path 1.8.3 - File path utilities
- path_provider 2.1.4 - System directories access

**Localization & Internationalization:**
- flutter_localizations - Flutter i18n support
- intl 0.20.2 - Internationalization library (Korean, Spanish, English support)

**Biometric Authentication:**
- local_auth 2.3.0 - Biometric authentication (Face ID, fingerprint)

**Document Generation:**
- pdf 3.11.1 - PDF generation
- excel 4.0.4 - Excel file generation

**Platform & Device:**
- window_manager 0.3.7 - Desktop window management (macOS, Windows, Linux)
- network_info_plus 7.0.0 - Network connectivity information
- device_info_plus 10.1.2 - Device information access

**UI Components:**
- cupertino_icons 1.0.6 - iOS-style icon library

**Utility:**
- share_plus 10.1.2 - Share functionality across platforms

## Configuration

**Environment:**
- Configuration sourced from `assets/config.json` at build time
- Runtime configuration modifiable via SharedPreferences
- Settings merged with asset defaults

**Configuration File:**
- `assets/config.json` - Report feature flags (Ventas, Gastos, Stocks, Codigos display settings)

**Build Configuration:**
- `pubspec.yaml` - Package manifest and asset configuration
- `analysis_options.yaml` - Dart analyzer and linting rules
- Flutter launcher icons config in `pubspec.yaml`
- MSIX configuration for Windows build

**Asset Management:**
- `assets/logo.jpg` - Application logo
- `assets/config.json` - Configuration file
- `assets/icon.png` - App icon

## Platform Requirements

**Development:**
- Dart SDK 3.0.0+
- Flutter SDK (latest stable)
- Xcode (macOS builds)
- Android SDK + NDK
- Visual Studio or MinGW (Windows builds)
- Linux build tools (GTK 3.0+)

**Supported Platforms:**
- iOS (iPhone/iPad)
- Android (5.0+)
- macOS (10.14+)
- Windows (10+)
- Linux (GTK-based desktops)
- Web (not primary target - experimental)

**Production Deployment:**
- iOS: TestFlight or App Store
- Android: Google Play Store
- macOS: App Store or direct distribution
- Windows/Linux: Executable distribution
- Mobile app name: "Be COOL" (from Info.plist)

---

*Stack analysis: 2026-04-01*
