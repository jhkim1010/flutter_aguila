# Coding Conventions

**Analysis Date:** 2026-04-01

## Naming Patterns

**Files:**
- Lowercase with underscores: `connection_info.dart`, `log_file_writer.dart`
- Screen files: `report_screen.dart`, `main_connection_screen.dart`
- Builder classes: `items_builder.dart`, `codigos_builder.dart`
- Service files: `database_service.dart`, `config_service.dart`
- Widget files grouped by functionality: `report_responsive_appbar.dart`, `resizable_data_table.dart`

**Classes:**
- PascalCase: `ConnectionInfo`, `LogFileWriter`, `VentasItem`, `DatabaseService`
- Widget classes: `ReportScreen`, `ReportResponsiveAppBar`, `MainConnectionScreen`
- Private implementation classes: `_ReportScreenState`, `_BiometricAuthScreenState`

**Functions & Methods:**
- camelCase: `performGetRequest()`, `getDatabaseHeaders()`, `buildColumnDefs()`, `loadLocale()`
- Private methods: `_buildRowCells()`, `_writeToFile()`, `_isTwoLine()`
- Helper functions in utils: `isDesktop()`, `isMobile()`, `getPlatformType()`

**Variables:**
- camelCase: `serverUrl`, `databaseName`, `connectionInfo`, `logBuffer`
- Private fields: `_logFile`, `_isInitialized`, `_platformInfo`, `_config`
- Late initialization: `late final HttpRequestHandler _httpHandler`
- Constants: `const List<String> itemsColumnKeys`, `static const String _configAssetPath`

**Types:**
- Generic types: `Future<Map<String, dynamic>>`, `List<TableColumnDef>`, `List<List<Widget>>`
- Enums: `PlatformType`, `ReportType`

## Code Style

**Formatting:**
- dart lint with flutter_lints package (standard Flutter linting rules)
- Configuration in `analysis_options.yaml` using `package:flutter_lints/flutter.yaml`
- No custom formatting configured; follows default Dart conventions

**Linting:**
- flutter_lints `^3.0.0` enforces recommended rules
- Allows `avoid_print` to be modified (commented out in analysis_options.yaml)
- `prefer_single_quotes` disabled by default

**Key Style Points:**
- `const` constructors required for widgets: `const ReportResponsiveAppBar(...)`
- `super.key` used in widget constructors: `const MyApp({super.key})`
- Prefer `final` over `var` for variable declarations
- Required fields marked with `required`: `required String serverUrl`
- Null-coalescing operator used: `item['id'] as int?`, `??`
- Null-safe assertion: `!.exists()`, `!.path`

## Import Organization

**Order:**
1. Dart imports: `import 'dart:io';`, `import 'dart:convert';`
2. Flutter imports: `import 'package:flutter/material.dart';`, `import 'package:flutter/foundation.dart'`
3. Package imports: `import 'package:http/http.dart' as http;`, `import 'package:intl/intl.dart'`
4. Relative imports: `import '../models/connection_info.dart';`, `import '../utils/platform_utils.dart'`
5. Exports: `export '../widgets/report_utils.dart' show ReportType;`

**Path Aliases:**
- No path aliases configured in pubspec.yaml
- All imports use relative paths

## Error Handling

**Patterns:**
- Try-catch blocks used throughout service APIs: `try { ... } catch (e) { print('❌ Error: $e'); }`
- Exception throwing for invalid states: `throw Exception('Invalid or missing database headers: ...')`
- Print statements for user-facing errors with emoji prefixes: `print('❌ ...')`, `print('⚠️ ...')`
- Error handling in HTTP requests with `_handleError()` method
- Graceful degradation in ConfigService: catches errors and uses default configuration
- Validation before operations: `if (databaseName.isEmpty || username.isEmpty) { throw Exception(...) }`

**Examples from codebase:**
- `lib/services/api/http_request_handler.dart`: Comprehensive error handling with validation
- `lib/services/config_service.dart`: Try-catch with default fallback configuration
- `lib/utils/log_file_writer.dart`: Catches errors to prevent infinite logging loops

## Logging

**Framework:** `print()` and `debugPrint()` from Flutter

**Patterns:**
- `print()`: Standard logging for important messages, used in services and initialization
- `debugPrint()`: Used in debug utilities like `mobile_layout_helper.dart` for layout information
- Emoji prefixes for different levels:
  - `'❌'` for errors/failures: `print('❌ GET $endpoint 오류: $e')`
  - `'⚠️'` for warnings: `print('⚠️ 저장된 데이터베이스 연결 정보가 없거나 불완전합니다.')`
  - `'📝'` for info: `print('📝 로그 파일 경로: $logPath')`
  - `'📱'` for platform info: `print('📱 플랫폼 정보: $platformInfo')`
- File logging available via `LogFileWriter` utility for debug mode only
- Conditional logging in debug mode: `if (kDebugMode) { debugPrint(...) }`

**Log File Writing:**
- File-based logging in `lib/utils/log_file_writer.dart` (debug mode only)
- Buffered writes to avoid performance impact
- Timestamped log files: `app_log_[ISO8601].txt`

## Comments

**When to Comment:**
- Class-level documentation comments for public classes and services
- Method documentation for complex or non-obvious behavior
- Algorithm explanations where business logic is not self-evident
- Platform-specific workarounds (e.g., macOS SecureStorage handling)
- UI layout decisions and breakpoints

**JSDoc/TSDoc:**
- Uses `///` for documentation comments on public members:
  ```dart
  /// 화면 크기에 따라 1줄 또는 2줄 레이아웃으로 자동 전환되는 보고서 AppBar.
  class ReportResponsiveAppBar extends StatelessWidget { ... }
  ```
- Parameter documentation in method comments:
  ```dart
  /// 보고서별 필터 위젯 리스트 (타입 필터, 검색창 등)
  final List<Widget> filterWidgets;
  ```
- Comments in Korean for all documentation (follows user preference in `.claude/CLAUDE.md`)

**Inline Comments:**
- Explains complex data transformations: `// 데이터 타입 캐스팅 및 기본값 처리`
- Notes for future improvements: `// 추후 타입별 분리 예정`
- Platform-specific notes: `// macOS 개발 환경: 모든 데이터를 SharedPreferences에서 읽기`

## Function Design

**Size:**
- Methods typically keep 5-30 lines
- Complex screens like `report_screen_legacy.dart` (6583 lines) split into builders and helpers
- Builder classes separate UI construction from logic (`items_builder.dart`, `ingresos_builder.dart`)

**Parameters:**
- Named parameters for clarity: `performGetRequest(String endpoint, {Map<String, String>? queryParameters})`
- Required fields marked: `required String serverUrl`, `required this.title`
- Optional parameters with defaults: `final double breakpoint = 600.0`
- Callback parameters for state management: `final Function(String?, String?, bool?)? onStateChanged`

**Return Values:**
- Explicit return types (no implicit `dynamic`): `Future<Map<String, dynamic>>`, `List<TableColumnDef>`
- Nullable returns marked with `?`: `String? getPlatformInfo()`, `String? read('key')`
- Future-based async returns for all async operations: `Future<void>`, `Future<bool>`

## Module Design

**Exports:**
- Barrel files used for model/widget exports
- Example: `export '../widgets/report_utils.dart' show ReportType;` in `report_screen.dart`
- Clean API surface by re-exporting key types

**Barrel Files:**
- Service modules export main handler: `export 'api/database_connection_api.dart';` from `database_service.dart`
- No dedicated barrel file directory; exports inline in main files

**Organization:**
- Services in `lib/services/` with sub-package `api/` for API-specific services
- Models in `lib/models/` with response-specific files (e.g., `ventas_response.dart`)
- Widgets in `lib/widgets/` with specialized builders (e.g., `items_builder.dart`)
- Screens in `lib/screens/` with sub-package `helpers/` for screen-specific helpers
- Utilities in `lib/utils/` for cross-cutting concerns (logging, platform detection, etc.)

**Dependency Injection:**
- Constructor injection pattern for services: `DatabaseService({required this.serverUrl})`
- Singleton pattern for config: `factory ConfigService() { _instance ??= ConfigService._(); }`
- Manual service instantiation in screens, not automated DI framework

## Null Safety

**Strict Compliance:**
- Sound null safety enforced with SDK `>=3.0.0 <4.0.0`
- All nullable fields marked with `?`: `String? vendedor`, `int? id`
- Non-nullable by default: `final String databaseName;` (no `?`)
- Safe navigation with `?.`: `item['key']?.toString()`, `_logFile?.exists()`
- Null coalescing: `username ?? ''`, `await SecureStorageHelper.read('key') ?? ''`
- Force unwrap only when guaranteed non-null: `_logFile!.path`, `_httpClient!.close()`

## Const and Final

**Usage:**
- `const` for compile-time constants and immutable widget constructors
- `final` for runtime variables that don't change after initialization
- `late final` for fields initialized after construction: `late final HttpRequestHandler _httpHandler`
- `static const` for class-level constants: `static const String _configAssetPath = 'assets/config.json'`
