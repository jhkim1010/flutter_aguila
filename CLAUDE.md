<!-- GSD:project-start source:PROJECT.md -->
## Project

**Flutter Aguila — 비즈니스 리포트 앱**

멀티플랫폼(iOS, Android, macOS, Windows, Linux) Flutter 비즈니스 리포트 앱.
원격 PostgreSQL 서버에 연결하여 판매(Ventas), 재고(Stocks), 아이템(Items), 지출(Gastos) 등의 리포트를 조회하고 PDF/Excel로 내보내기 가능.
오프라인 SQLite 캐시, 바이오메트릭 인증(iOS), 다국어(스페인어/영어/한국어) 지원.

**Core Value:** 리포트 테이블이 정확하고 일관되게 표시되어야 한다 — 헤더와 행의 칼럼 폭/위치가 항상 완벽히 일치해야 함.

### Constraints

- **Tech Stack**: Flutter + Dart, 기존 서비스 레이어 유지
- **Platform**: iOS, Android, macOS, Windows, Linux 전체 지원 유지
- **API**: 기존 백엔드 API 인터페이스 변경 없음
- **Riverpod**: flutter_riverpod 패키지 사용, 리포트 화면에 한정
- **호환성**: 기존 기능 동작에 영향 없이 개선
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Dart 3.0+ - Flutter application development
- TypeScript/JavaScript - Website documentation (Astro)
- Swift/Objective-C - iOS platform bindings
- Kotlin/Java - Android platform bindings
- C - Platform-specific native code
## Runtime
- Flutter SDK (latest stable)
- Dart VM (3.0.0 to <4.0.0)
- pub (Dart package manager)
- npm/pnpm (Node.js for website)
- `pubspec.lock` - Dart dependencies (present)
- `package-lock.json` - npm dependencies for website (present)
## Frameworks
- Flutter 3.x - Multi-platform UI framework (iOS, Android, macOS, Windows, Linux)
- Material Design - UI design system
- Astro 5.6.1 - Static site generation
- Starlight 0.37.0 - Documentation template for Astro
- Tailwind CSS 4.1.17 - Utility-first CSS framework
- flutter_launcher_icons 0.13.1 - App icon generation
- flutter_lints 3.0.0 - Dart linting standards
## Key Dependencies
- http 1.1.0 - HTTP client for API calls
- flutter_secure_storage 9.0.0 - Secure credential storage
- shared_preferences 2.2.2 - Key-value preferences storage
- sqflite 2.3.0 - Local SQLite database
- path 1.8.3 - File path utilities
- path_provider 2.1.4 - System directories access
- flutter_localizations - Flutter i18n support
- intl 0.20.2 - Internationalization library (Korean, Spanish, English support)
- local_auth 2.3.0 - Biometric authentication (Face ID, fingerprint)
- pdf 3.11.1 - PDF generation
- excel 4.0.4 - Excel file generation
- window_manager 0.3.7 - Desktop window management (macOS, Windows, Linux)
- network_info_plus 7.0.0 - Network connectivity information
- device_info_plus 10.1.2 - Device information access
- cupertino_icons 1.0.6 - iOS-style icon library
- share_plus 10.1.2 - Share functionality across platforms
## Configuration
- Configuration sourced from `assets/config.json` at build time
- Runtime configuration modifiable via SharedPreferences
- Settings merged with asset defaults
- `assets/config.json` - Report feature flags (Ventas, Gastos, Stocks, Codigos display settings)
- `pubspec.yaml` - Package manifest and asset configuration
- `analysis_options.yaml` - Dart analyzer and linting rules
- Flutter launcher icons config in `pubspec.yaml`
- MSIX configuration for Windows build
- `assets/logo.jpg` - Application logo
- `assets/config.json` - Configuration file
- `assets/icon.png` - App icon
## Platform Requirements
- Dart SDK 3.0.0+
- Flutter SDK (latest stable)
- Xcode (macOS builds)
- Android SDK + NDK
- Visual Studio or MinGW (Windows builds)
- Linux build tools (GTK 3.0+)
- iOS (iPhone/iPad)
- Android (5.0+)
- macOS (10.14+)
- Windows (10+)
- Linux (GTK-based desktops)
- Web (not primary target - experimental)
- iOS: TestFlight or App Store
- Android: Google Play Store
- macOS: App Store or direct distribution
- Windows/Linux: Executable distribution
- Mobile app name: "Be COOL" (from Info.plist)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- Lowercase with underscores: `connection_info.dart`, `log_file_writer.dart`
- Screen files: `report_screen.dart`, `main_connection_screen.dart`
- Builder classes: `items_builder.dart`, `codigos_builder.dart`
- Service files: `database_service.dart`, `config_service.dart`
- Widget files grouped by functionality: `report_responsive_appbar.dart`, `resizable_data_table.dart`
- PascalCase: `ConnectionInfo`, `LogFileWriter`, `VentasItem`, `DatabaseService`
- Widget classes: `ReportScreen`, `ReportResponsiveAppBar`, `MainConnectionScreen`
- Private implementation classes: `_ReportScreenState`, `_BiometricAuthScreenState`
- camelCase: `performGetRequest()`, `getDatabaseHeaders()`, `buildColumnDefs()`, `loadLocale()`
- Private methods: `_buildRowCells()`, `_writeToFile()`, `_isTwoLine()`
- Helper functions in utils: `isDesktop()`, `isMobile()`, `getPlatformType()`
- camelCase: `serverUrl`, `databaseName`, `connectionInfo`, `logBuffer`
- Private fields: `_logFile`, `_isInitialized`, `_platformInfo`, `_config`
- Late initialization: `late final HttpRequestHandler _httpHandler`
- Constants: `const List<String> itemsColumnKeys`, `static const String _configAssetPath`
- Generic types: `Future<Map<String, dynamic>>`, `List<TableColumnDef>`, `List<List<Widget>>`
- Enums: `PlatformType`, `ReportType`
## Code Style
- dart lint with flutter_lints package (standard Flutter linting rules)
- Configuration in `analysis_options.yaml` using `package:flutter_lints/flutter.yaml`
- No custom formatting configured; follows default Dart conventions
- flutter_lints `^3.0.0` enforces recommended rules
- Allows `avoid_print` to be modified (commented out in analysis_options.yaml)
- `prefer_single_quotes` disabled by default
- `const` constructors required for widgets: `const ReportResponsiveAppBar(...)`
- `super.key` used in widget constructors: `const MyApp({super.key})`
- Prefer `final` over `var` for variable declarations
- Required fields marked with `required`: `required String serverUrl`
- Null-coalescing operator used: `item['id'] as int?`, `??`
- Null-safe assertion: `!.exists()`, `!.path`
## Import Organization
- No path aliases configured in pubspec.yaml
- All imports use relative paths
## Error Handling
- Try-catch blocks used throughout service APIs: `try { ... } catch (e) { print('❌ Error: $e'); }`
- Exception throwing for invalid states: `throw Exception('Invalid or missing database headers: ...')`
- Print statements for user-facing errors with emoji prefixes: `print('❌ ...')`, `print('⚠️ ...')`
- Error handling in HTTP requests with `_handleError()` method
- Graceful degradation in ConfigService: catches errors and uses default configuration
- Validation before operations: `if (databaseName.isEmpty || username.isEmpty) { throw Exception(...) }`
- `lib/services/api/http_request_handler.dart`: Comprehensive error handling with validation
- `lib/services/config_service.dart`: Try-catch with default fallback configuration
- `lib/utils/log_file_writer.dart`: Catches errors to prevent infinite logging loops
## Logging
- `print()`: Standard logging for important messages, used in services and initialization
- `debugPrint()`: Used in debug utilities like `mobile_layout_helper.dart` for layout information
- Emoji prefixes for different levels:
- File logging available via `LogFileWriter` utility for debug mode only
- Conditional logging in debug mode: `if (kDebugMode) { debugPrint(...) }`
- File-based logging in `lib/utils/log_file_writer.dart` (debug mode only)
- Buffered writes to avoid performance impact
- Timestamped log files: `app_log_[ISO8601].txt`
## Comments
- Class-level documentation comments for public classes and services
- Method documentation for complex or non-obvious behavior
- Algorithm explanations where business logic is not self-evident
- Platform-specific workarounds (e.g., macOS SecureStorage handling)
- UI layout decisions and breakpoints
- Uses `///` for documentation comments on public members:
- Parameter documentation in method comments:
- Comments in Korean for all documentation (follows user preference in `.claude/CLAUDE.md`)
- Explains complex data transformations: `// 데이터 타입 캐스팅 및 기본값 처리`
- Notes for future improvements: `// 추후 타입별 분리 예정`
- Platform-specific notes: `// macOS 개발 환경: 모든 데이터를 SharedPreferences에서 읽기`
## Function Design
- Methods typically keep 5-30 lines
- Complex screens like `report_screen_legacy.dart` (6583 lines) split into builders and helpers
- Builder classes separate UI construction from logic (`items_builder.dart`, `ingresos_builder.dart`)
- Named parameters for clarity: `performGetRequest(String endpoint, {Map<String, String>? queryParameters})`
- Required fields marked: `required String serverUrl`, `required this.title`
- Optional parameters with defaults: `final double breakpoint = 600.0`
- Callback parameters for state management: `final Function(String?, String?, bool?)? onStateChanged`
- Explicit return types (no implicit `dynamic`): `Future<Map<String, dynamic>>`, `List<TableColumnDef>`
- Nullable returns marked with `?`: `String? getPlatformInfo()`, `String? read('key')`
- Future-based async returns for all async operations: `Future<void>`, `Future<bool>`
## Module Design
- Barrel files used for model/widget exports
- Example: `export '../widgets/report_utils.dart' show ReportType;` in `report_screen.dart`
- Clean API surface by re-exporting key types
- Service modules export main handler: `export 'api/database_connection_api.dart';` from `database_service.dart`
- No dedicated barrel file directory; exports inline in main files
- Services in `lib/services/` with sub-package `api/` for API-specific services
- Models in `lib/models/` with response-specific files (e.g., `ventas_response.dart`)
- Widgets in `lib/widgets/` with specialized builders (e.g., `items_builder.dart`)
- Screens in `lib/screens/` with sub-package `helpers/` for screen-specific helpers
- Utilities in `lib/utils/` for cross-cutting concerns (logging, platform detection, etc.)
- Constructor injection pattern for services: `DatabaseService({required this.serverUrl})`
- Singleton pattern for config: `factory ConfigService() { _instance ??= ConfigService._(); }`
- Manual service instantiation in screens, not automated DI framework
## Null Safety
- Sound null safety enforced with SDK `>=3.0.0 <4.0.0`
- All nullable fields marked with `?`: `String? vendedor`, `int? id`
- Non-nullable by default: `final String databaseName;` (no `?`)
- Safe navigation with `?.`: `item['key']?.toString()`, `_logFile?.exists()`
- Null coalescing: `username ?? ''`, `await SecureStorageHelper.read('key') ?? ''`
- Force unwrap only when guaranteed non-null: `_logFile!.path`, `_httpClient!.close()`
## Const and Final
- `const` for compile-time constants and immutable widget constructors
- `final` for runtime variables that don't change after initialization
- `late final` for fields initialized after construction: `late final HttpRequestHandler _httpHandler`
- `static const` for class-level constants: `static const String _configAssetPath = 'assets/config.json'`
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- Service layer abstraction for HTTP API and database operations
- Centralized connection management with singleton pattern
- Report-centric UI architecture with composable widget builders
- Offline-first design with local SQLite cache layer
- Platform-aware initialization (iOS biometric auth, desktop window management)
## Layers
- Purpose: Handle user interaction, display data, manage local UI state
- Location: `lib/screens/`, `lib/widgets/`
- Contains: Screen widgets, report builders, table components, filters, pickers
- Depends on: Services layer, Models, Utils
- Used by: MaterialApp routing via `lib/main.dart`
- Key responsibility: Compose API responses into data tables with resizable columns, pagination, filtering
- Purpose: Manage business logic, HTTP communication, data persistence, configuration
- Location: `lib/services/`, `lib/services/api/`
- Contains: DatabaseService, ConfigService, LocalDatabaseService, API handlers
- Depends on: Models, Utils, external packages (http, sqflite, shared_preferences, flutter_secure_storage)
- Used by: Presentation layer for all data access
- Key responsibility: Abstract away HTTP implementation and credential management
- Purpose: Handle HTTP communication to remote backend
- Location: `lib/services/api/`
- Contains: HttpRequestHandler (base), ReportsApi, StocksApi, CodigosApi, TodocodigosApi, DatabaseConnectionApi
- Depends on: Http package, platform-specific SSL helpers
- Used by: DatabaseService for all remote operations
- Key responsibility: Request/response formatting, timeout handling, connection pooling
- Purpose: Represent API responses and internal data structures
- Location: `lib/models/`
- Contains: ConnectionInfo, StocksResponse, TodocodigosResponse, VentasResponse, Item
- Depends on: Nothing
- Used by: Service layer for response parsing, Presentation for type-safe data access
- Purpose: Cross-cutting concerns and platform-specific functionality
- Location: `lib/utils/`, `lib/screens/helpers/`
- Contains: LogFileWriter, DeviceInfoHelper, MobileLayoutHelper, PlatformUtils, SslClientHelper, ReportDataUtils
- Depends on: Flutter framework, platform packages
- Used by: All layers as needed
- Purpose: Manage runtime settings and persisted preferences
- Location: `lib/services/config_service.dart`
- Contains: ConfigService (singleton) managing report visibility toggles via asset JSON + SharedPreferences
- Depends on: SharedPreferences, asset loader
- Used by: Report screens for field visibility logic
## Data Flow
- Local UI state managed by StatefulWidget setState() calls
- Server state accessed via DatabaseService methods on-demand (no global state manager)
- Credentials persisted to SecureStorageHelper (for macOS) / flutter_secure_storage
- Configuration persisted to SharedPreferences via ConfigService.updateVentasConfig()
- Active connection info: SecureStorageHelper (SQLite via shared_preferences on macOS)
- Report configuration: SharedPreferences via ConfigService
- Large report data: LocalDatabaseService (SQLite for offline access, 200MB+ optimization)
## Key Abstractions
- Purpose: Single entry point for all backend API operations
- Examples: `lib/services/database_service.dart`
- Pattern: Facade pattern wrapping multiple specialized API handlers
- Usage: All screens import and instantiate with serverUrl parameter
- Methods: getVentasReport(), getStocksReport(), getCodigos(), getResumenDelDia(), etc.
- Purpose: Centralize HTTP request/response handling with common headers and error management
- Examples: `lib/services/api/http_request_handler.dart`
- Pattern: Base handler used by all API classes via composition
- Key feature: Reads DB credentials from storage, adds to headers (x-db-name, x-db-user, x-db-password), manages HTTP client lifecycle
- Timeout: 10 seconds default, 60 seconds for resumen_del_dia (POST)
- Purpose: Transform API data into Flutter widgets with consistent styling
- Examples: `lib/widgets/report_table_builder.dart`, `lib/widgets/items_builder.dart`, `lib/widgets/stocks_builder.dart`
- Pattern: Static factory methods returning Widget trees
- Key feature: Handle column filtering, resizing, pagination with alignment debugging
- Purpose: Manage stored credentials and auto-reconnect on app launch
- Examples: `lib/screens/helpers/auto_connection_handler.dart`
- Pattern: Static method class with result enum pattern
- Key feature: Platform-aware credential storage (macOS uses SharedPreferences, others use SecureStorage for passwords)
- Purpose: Manage report visibility configuration from asset JSON + runtime overrides
- Examples: `lib/services/config_service.dart`
- Pattern: Singleton with lazy initialization
- Key feature: Asset JSON merged with SharedPreferences for runtime changes, per-report field visibility toggles
## Entry Points
- Location: `lib/main.dart`
- Triggers: App launch on iOS, Android, macOS, Windows, Linux
- Responsibilities:
- Location: `lib/main.dart` class _MyAppState
- Responsibilities: Set Material theme, localization delegates (Spanish/English/Korean), root navigation
- Location: `lib/screens/main_connection_screen.dart`
- Triggers: After biometric auth (iOS) or directly (other platforms)
- Responsibilities:
- Location: `lib/screens/reports/ventas_report_section.dart`
- Triggers: After successful connection, user selects report type
- Responsibilities: Load report data, apply filters, display in table
## Error Handling
- HTTP errors: HttpRequestHandler.performGetRequest() catches timeouts (10s), connection errors, 4xx/5xx responses
- Parse errors: Model.fromMap() uses null-safety and _parseDouble() helper for type coercion
- Connection errors: AutoConnectionHandler returns AutoConnectionResult enum (success/failed/error/skipped)
- Missing credentials: HttpRequestHandler throws Exception with message "Invalid or missing database headers"
- File operations: LogFileWriter.initialize() wrapped in try-catch, falls back to console logging
## Cross-Cutting Concerns
- Location: `lib/utils/log_file_writer.dart`
- Approach: Platform-aware file logging in debug mode, writes to app documents directory
- Usage: Initialize in main(), called by LogFileWriter.initialize(context: context)
- Output: Debug console + file (macOS/iOS show path)
- Location: `lib/screens/helpers/biometric_auth_handler.dart`, `lib/screens/biometric_auth_screen.dart`
- Approach: iOS Release mode only, uses local_auth package
- Flow: BiometricAuthScreen → authentication → MainConnectionScreen
- Fallback: Debug/Android/Desktop skip biometric
- Location: `lib/services/config_service.dart`
- Approach: ConfigService singleton reads asset JSON on init, merges with SharedPreferences
- Usage: Report screens call shouldShowField() to determine column visibility
- Example: shouldShowField('tpago') checks config['report']['ventas']['showTpago']
- Location: `lib/services/api/http_request_handler.dart`, `lib/utils/ssl_client_helper.dart`
- Approach: Single http.Client instance per HttpRequestHandler, disposed after use
- Optimization: Connection: keep-alive header, SslClientHelper caches HttpClient to reuse
- Key: dispose() must be called to prevent connection pool exhaustion
- Location: `lib/services/secure_storage_helper.dart`
- Approach: Platform-aware hybrid storage
- Encryption: flutter_secure_storage uses platform keychain
- Location: `lib/l10n/app_localizations.dart`
- Approach: Localization delegates registered in MaterialApp
- Languages: Spanish (default), English, Korean
- Note: app forces Locale('es', '') in main.dart, ignores locale changes
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
