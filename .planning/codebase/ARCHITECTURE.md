# Architecture

**Analysis Date:** 2026-04-01

## Pattern Overview

**Overall:** Layered MVC with Service-Locator pattern for dependency injection

**Key Characteristics:**
- Service layer abstraction for HTTP API and database operations
- Centralized connection management with singleton pattern
- Report-centric UI architecture with composable widget builders
- Offline-first design with local SQLite cache layer
- Platform-aware initialization (iOS biometric auth, desktop window management)

## Layers

**Presentation Layer (Screens & Widgets):**
- Purpose: Handle user interaction, display data, manage local UI state
- Location: `lib/screens/`, `lib/widgets/`
- Contains: Screen widgets, report builders, table components, filters, pickers
- Depends on: Services layer, Models, Utils
- Used by: MaterialApp routing via `lib/main.dart`
- Key responsibility: Compose API responses into data tables with resizable columns, pagination, filtering

**Service Layer:**
- Purpose: Manage business logic, HTTP communication, data persistence, configuration
- Location: `lib/services/`, `lib/services/api/`
- Contains: DatabaseService, ConfigService, LocalDatabaseService, API handlers
- Depends on: Models, Utils, external packages (http, sqflite, shared_preferences, flutter_secure_storage)
- Used by: Presentation layer for all data access
- Key responsibility: Abstract away HTTP implementation and credential management

**API Layer:**
- Purpose: Handle HTTP communication to remote backend
- Location: `lib/services/api/`
- Contains: HttpRequestHandler (base), ReportsApi, StocksApi, CodigosApi, TodocodigosApi, DatabaseConnectionApi
- Depends on: Http package, platform-specific SSL helpers
- Used by: DatabaseService for all remote operations
- Key responsibility: Request/response formatting, timeout handling, connection pooling

**Data Models:**
- Purpose: Represent API responses and internal data structures
- Location: `lib/models/`
- Contains: ConnectionInfo, StocksResponse, TodocodigosResponse, VentasResponse, Item
- Depends on: Nothing
- Used by: Service layer for response parsing, Presentation for type-safe data access

**Utilities & Helpers:**
- Purpose: Cross-cutting concerns and platform-specific functionality
- Location: `lib/utils/`, `lib/screens/helpers/`
- Contains: LogFileWriter, DeviceInfoHelper, MobileLayoutHelper, PlatformUtils, SslClientHelper, ReportDataUtils
- Depends on: Flutter framework, platform packages
- Used by: All layers as needed

**Configuration Management:**
- Purpose: Manage runtime settings and persisted preferences
- Location: `lib/services/config_service.dart`
- Contains: ConfigService (singleton) managing report visibility toggles via asset JSON + SharedPreferences
- Depends on: SharedPreferences, asset loader
- Used by: Report screens for field visibility logic

## Data Flow

**Connection Flow:**
1. App starts → `main.dart` initializes LogFileWriter and ConfigService
2. MainConnectionScreen checks saved credentials via AutoConnectionHandler
3. If saved credentials exist, autoConnectToDatabase() attempts connection
4. On success: DatabaseService instance created, Tipos/Temporadas cached
5. Screen shows report selection UI with connected server info
6. On failure: Manual connection form presented to user

**Report Data Loading Flow:**
1. User selects report type (Ventas, Stocks, Items, Gastos, etc.) in MainConnectionScreen
2. Appropriate report section opened (VentasReportSection, StocksReportView, etc.)
3. ReportDataLoader helper orchestrates API calls:
   - Fetches data via DatabaseService.getXxxReport()
   - Applies filters from FilterHelper
   - Formats data for display
4. Data passed to report table builders (ReportTableBuilder, ItemsBuilder, etc.)
5. Table builders render data with resizable columns via ReportTableMeasuredColumns
6. User can filter, sort, export (PDF/Excel via PdfService/ExcelService)

**State Management Flow:**
- Local UI state managed by StatefulWidget setState() calls
- Server state accessed via DatabaseService methods on-demand (no global state manager)
- Credentials persisted to SecureStorageHelper (for macOS) / flutter_secure_storage
- Configuration persisted to SharedPreferences via ConfigService.updateVentasConfig()

**State Persistence:**
- Active connection info: SecureStorageHelper (SQLite via shared_preferences on macOS)
- Report configuration: SharedPreferences via ConfigService
- Large report data: LocalDatabaseService (SQLite for offline access, 200MB+ optimization)

## Key Abstractions

**DatabaseService:**
- Purpose: Single entry point for all backend API operations
- Examples: `lib/services/database_service.dart`
- Pattern: Facade pattern wrapping multiple specialized API handlers
- Usage: All screens import and instantiate with serverUrl parameter
- Methods: getVentasReport(), getStocksReport(), getCodigos(), getResumenDelDia(), etc.

**HttpRequestHandler:**
- Purpose: Centralize HTTP request/response handling with common headers and error management
- Examples: `lib/services/api/http_request_handler.dart`
- Pattern: Base handler used by all API classes via composition
- Key feature: Reads DB credentials from storage, adds to headers (x-db-name, x-db-user, x-db-password), manages HTTP client lifecycle
- Timeout: 10 seconds default, 60 seconds for resumen_del_dia (POST)

**Report Builders:**
- Purpose: Transform API data into Flutter widgets with consistent styling
- Examples: `lib/widgets/report_table_builder.dart`, `lib/widgets/items_builder.dart`, `lib/widgets/stocks_builder.dart`
- Pattern: Static factory methods returning Widget trees
- Key feature: Handle column filtering, resizing, pagination with alignment debugging

**AutoConnectionHandler:**
- Purpose: Manage stored credentials and auto-reconnect on app launch
- Examples: `lib/screens/helpers/auto_connection_handler.dart`
- Pattern: Static method class with result enum pattern
- Key feature: Platform-aware credential storage (macOS uses SharedPreferences, others use SecureStorage for passwords)

**ConfigService:**
- Purpose: Manage report visibility configuration from asset JSON + runtime overrides
- Examples: `lib/services/config_service.dart`
- Pattern: Singleton with lazy initialization
- Key feature: Asset JSON merged with SharedPreferences for runtime changes, per-report field visibility toggles

## Entry Points

**main():**
- Location: `lib/main.dart`
- Triggers: App launch on iOS, Android, macOS, Windows, Linux
- Responsibilities:
  - Ensure Flutter bindings initialized
  - Initialize LogFileWriter (debug only)
  - Initialize ConfigService (asset JSON + SharedPreferences)
  - Initialize window_manager for desktop platforms
  - Route to BiometricAuthScreen (iOS Release only) or MainConnectionScreen (Android, Desktop, Debug)

**MyApp (StatefulWidget):**
- Location: `lib/main.dart` class _MyAppState
- Responsibilities: Set Material theme, localization delegates (Spanish/English/Korean), root navigation

**MainConnectionScreen:**
- Location: `lib/screens/main_connection_screen.dart`
- Triggers: After biometric auth (iOS) or directly (other platforms)
- Responsibilities:
  - Load saved connections via ConnectionManager
  - Auto-connect if credentials available (AutoConnectionHandler)
  - Show connection form or report selection UI
  - Manage navigation to report screens with DatabaseService instance

**Report Screens (e.g., VentasReportSection):**
- Location: `lib/screens/reports/ventas_report_section.dart`
- Triggers: After successful connection, user selects report type
- Responsibilities: Load report data, apply filters, display in table

## Error Handling

**Strategy:** Try-catch with user-facing error messages in UI

**Patterns:**
- HTTP errors: HttpRequestHandler.performGetRequest() catches timeouts (10s), connection errors, 4xx/5xx responses
- Parse errors: Model.fromMap() uses null-safety and _parseDouble() helper for type coercion
- Connection errors: AutoConnectionHandler returns AutoConnectionResult enum (success/failed/error/skipped)
- Missing credentials: HttpRequestHandler throws Exception with message "Invalid or missing database headers"
- File operations: LogFileWriter.initialize() wrapped in try-catch, falls back to console logging

## Cross-Cutting Concerns

**Logging:**
- Location: `lib/utils/log_file_writer.dart`
- Approach: Platform-aware file logging in debug mode, writes to app documents directory
- Usage: Initialize in main(), called by LogFileWriter.initialize(context: context)
- Output: Debug console + file (macOS/iOS show path)

**Authentication:**
- Location: `lib/screens/helpers/biometric_auth_handler.dart`, `lib/screens/biometric_auth_screen.dart`
- Approach: iOS Release mode only, uses local_auth package
- Flow: BiometricAuthScreen → authentication → MainConnectionScreen
- Fallback: Debug/Android/Desktop skip biometric

**Configuration Management:**
- Location: `lib/services/config_service.dart`
- Approach: ConfigService singleton reads asset JSON on init, merges with SharedPreferences
- Usage: Report screens call shouldShowField() to determine column visibility
- Example: shouldShowField('tpago') checks config['report']['ventas']['showTpago']

**Database Connection Pooling:**
- Location: `lib/services/api/http_request_handler.dart`, `lib/utils/ssl_client_helper.dart`
- Approach: Single http.Client instance per HttpRequestHandler, disposed after use
- Optimization: Connection: keep-alive header, SslClientHelper caches HttpClient to reuse
- Key: dispose() must be called to prevent connection pool exhaustion

**Credential Storage:**
- Location: `lib/services/secure_storage_helper.dart`
- Approach: Platform-aware hybrid storage
  - macOS: All credentials in SharedPreferences (development convenience)
  - iOS/Android: UserDefaults/SharedPreferences for username/database, SecureStorage for password
  - Windows/Linux: SecureStorage for passwords
- Encryption: flutter_secure_storage uses platform keychain

**Internationalization:**
- Location: `lib/l10n/app_localizations.dart`
- Approach: Localization delegates registered in MaterialApp
- Languages: Spanish (default), English, Korean
- Note: app forces Locale('es', '') in main.dart, ignores locale changes

---

*Architecture analysis: 2026-04-01*
