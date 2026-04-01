# Codebase Structure

**Analysis Date:** 2026-04-01

## Directory Layout

```
flutter_aguila/
├── android/                    # Android native code
├── ios/                        # iOS native code
├── windows/                    # Windows desktop native code
├── macos/                      # macOS desktop native code
├── linux/                      # Linux desktop native code
├── lib/                        # Dart application source
│   ├── main.dart              # App entry point, MaterialApp setup
│   ├── models/                # Data model classes (API responses)
│   ├── services/              # Business logic and API layer
│   │   ├── api/               # HTTP API client classes
│   │   ├── config_service.dart
│   │   ├── database_service.dart
│   │   ├── local_database_service.dart
│   │   ├── connection_storage_service.dart
│   │   ├── secure_storage_helper.dart
│   │   ├── excel_service.dart
│   │   ├── pdf_service.dart
│   │   └── *_column_width_storage.dart
│   ├── screens/               # Page widgets and screen logic
│   │   ├── main_connection_screen.dart
│   │   ├── helpers/           # Screen-specific helper classes
│   │   ├── reports/           # Report section components
│   │   └── *.dart             # Other screen implementations
│   ├── widgets/               # Reusable UI components
│   │   ├── report_table/      # Data table components
│   │   └── *_builder.dart     # Report builders
│   ├── utils/                 # Utilities and platform helpers
│   ├── l10n/                  # Localization strings
│   └── generated/             # Generated localization code
├── test/                      # Widget and unit tests
├── assets/                    # Images, configs, static data
│   ├── logo.jpg
│   ├── config.json            # Runtime configuration
│   └── icon.png
├── pubspec.yaml              # Dependencies and metadata
└── analysis_options.yaml     # Dart linter rules
```

## Directory Purposes

**lib/models/:**
- Purpose: Data classes representing API responses and domain objects
- Contains: Immutable model classes with factory constructors from JSON maps
- Key files:
  - `stocks_response.dart`: StocksResponse, StockResumenItem, StocksPagination
  - `todocodigos_response.dart`: TodocodigosResponse
  - `ventas_response.dart`: VentasResponse
  - `connection_info.dart`: ConnectionInfo (saved connection metadata)
  - `item.dart`: Item model

**lib/services/:**
- Purpose: Business logic abstraction and data access
- Contains: API clients, credential management, configuration, export services
- Key files:
  - `database_service.dart`: Main facade for all backend API calls (2 types: raw Map, typed Response)
  - `config_service.dart`: Singleton for runtime configuration from assets + SharedPreferences
  - `local_database_service.dart`: SQLite database for offline/large dataset caching (200MB optimization)
  - `connection_storage_service.dart`: Manages saved connections list persistence
  - `secure_storage_helper.dart`: Platform-aware credential encryption (macOS/iOS/Android)
  - `excel_service.dart`: Export data to Excel format
  - `pdf_service.dart`: Export data to PDF with headers/totals
  - `*_column_width_storage.dart`: Persist resizable column widths (codigos, gastos, items, stocks, reports)

**lib/services/api/:**
- Purpose: HTTP client implementations for specific API endpoints
- Contains: Request formatting, response parsing, endpoint-specific logic
- Key files:
  - `http_request_handler.dart`: Base HTTP client with common headers (x-db-name, x-db-user, x-db-password), error handling, timeouts
  - `database_connection_api.dart`: POST /api/database_connection (test connection, returns success/error)
  - `reports_api.dart`: GET/POST various /api/reporte/* endpoints (ventas, stocks, items, gastos, etc.)
  - `stocks_api.dart`: GET /api/stocks (pagination, filtering, sorting)
  - `codigos_api.dart`: GET/PUT /api/codigos/* (product codes management)
  - `todocodigos_api.dart`: GET/PUT /api/todocodigos/* (parent product codes)

**lib/screens/:**
- Purpose: Page-level widgets managing screen layout and user interaction
- Contains: Stateful widgets, form inputs, report displays, navigation
- Key files:
  - `main_connection_screen.dart`: Connection form + report selection UI (2000+ lines, main hub)
  - `resumen_del_dia_screen.dart`: Daily summary report (5200+ lines, complex multi-sucursal layout)
  - `report_screen.dart`: Generic report container dispatching to section components
  - `connection_screen.dart`: Connection dialog form (extracted to separate file)
  - `biometric_auth_screen.dart`: iOS biometric authentication (Touch ID/Face ID)
  - `celebration_screen.dart`: Celebratory animation on successful connection

**lib/screens/helpers/:**
- Purpose: Screen-specific business logic extracted from widget classes
- Contains: Data loading, filtering, sharing, biometric auth, connection management
- Key files:
  - `auto_connection_handler.dart`: Auto-login logic with saved credentials
  - `connection_manager.dart`: Manage saved connections list (CRUD + status check)
  - `biometric_auth_handler.dart`: iOS biometric authentication wrapper
  - `report_data_loader.dart`: Orchestrate API calls and filter application
  - `report_filter_helper.dart`: Filter expression parsing and application logic
  - `report_share_helper.dart`: Export/share report data (PDF, Excel)
  - `report_utils_mixin.dart`: Common report UI logic (column names, formatting)

**lib/screens/reports/:**
- Purpose: Reusable report section components (similar to widget builders)
- Contains: Report-type-specific widgets and filters
- Key files:
  - `ventas_report_section.dart`: Sales report with payment method filtering
  - `stocks_report_section.dart`: Inventory report with search/filtering
  - `codigos_report_section.dart`: Product codes maintenance
  - `clientes_report_section.dart`: Clients/customers report
  - `report_view_connector.dart`: Connect report sections to data loaders
  - `ventas_controls_section.dart`: Shared controls for sales filters (date range, sucursal)

**lib/widgets/:**
- Purpose: Reusable UI components for reports and tables
- Contains: Data table builders, filters, pickers, sizing logic
- Key files (82 lines each on average):
  - `report_table_builder.dart`: Main table layout orchestrator (1852 lines, core report rendering)
  - `items_builder.dart`: Items report data rows + totals (2069 lines)
  - `stocks_builder.dart`: Stocks report data rows + totals (943 lines)
  - `gastos_builder.dart`: Expenses report data rows + totals (1296 lines)
  - `ingresos_builder.dart`: Income report data rows + totals (1702 lines)
  - `codigos_builder.dart`: Product codes data rows (552 lines)
  - `report_table_header_footer.dart`: Table header with filters + footer totals (1097 lines)
  - `report_table_measured_columns.dart`: Column sizing and alignment logic (946 lines)
  - `report_table_data_rows.dart`: Data cell rendering with truncation (771 lines)
  - `report_table_column_widths.dart`: Persistence of column widths
  - `report_filter_widgets.dart`: Filter input components (date, text, checkbox)
  - `report_appbar_builders.dart`: Top bar with export/settings buttons
  - `resizable_data_table.dart`: DataTable with drag-to-resize columns
  - `items_date_range_selector.dart`: Date range picker for items report
  - `toggle_date_range_picker.dart`: Toggle between single date and date range
  - `report_responsive_appbar.dart`: Responsive app bar (mobile/tablet/desktop)

**lib/widgets/report_table/:**
- Purpose: Encapsulated table rendering sub-components
- Contains: Column management, rendering logic
- Key files:
  - `report_table_column_manager.dart`: Manage visible columns and widths
  - `report_table_renderer.dart`: Render table rows with optimal performance

**lib/utils/:**
- Purpose: Cross-cutting utilities and platform-specific helpers
- Contains: Logging, device info, layout helpers, platform detection
- Key files:
  - `log_file_writer.dart`: Debug file logging to app documents (7.6 KB, writes platform info)
  - `device_info_helper.dart`: Get device name/model for display
  - `mobile_layout_helper.dart`: Detect screen size for responsive UI (phone/tablet/desktop)
  - `platform_utils.dart`: Platform-specific constant definitions
  - `ssl_client_helper.dart`: Create unsafe HTTP client for self-signed certificates
  - `debug_config.dart`: Debug environment configuration
  - `report_data_utils.dart`: Report data formatting helpers

**lib/l10n/:**
- Purpose: Localization data and delegates
- Contains: Language files, generated localization classes
- Key files:
  - `app_localizations.dart`: Generated localization delegate and lookup

**lib/generated/:**
- Purpose: Generated code (not manually edited)
- Contains: Localization generation output

**assets/:**
- Purpose: Static resources for app
- Contents:
  - `config.json`: Report configuration (field visibility toggles), loaded in ConfigService.initialize()
  - `logo.jpg`: App logo for splash screen
  - `icon.png`: App icon for launcher icons

**test/:**
- Purpose: Unit and widget tests
- Key files:
  - `widget_test.dart`: Main app widget smoke test
  - `widgets/report_responsive_appbar_test.dart`: Responsive app bar tests
  - `widgets/resizable_data_table_test.dart`: Resizable table tests

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Application entry point, MaterialApp configuration, platform-specific initialization

**Configuration:**
- `lib/services/config_service.dart`: Runtime configuration management (singleton)
- `assets/config.json`: Asset-based configuration template

**Core Logic:**
- `lib/services/database_service.dart`: Main API facade (all backend operations)
- `lib/screens/main_connection_screen.dart`: Connection management + report routing

**Testing:**
- `test/widget_test.dart`: App-level widget test
- `test/widgets/`: Component-specific tests

## Naming Conventions

**Files:**
- Screens: `lib/screens/*_screen.dart` (main_connection_screen.dart, report_screen.dart)
- Widgets/Builders: `lib/widgets/*_builder.dart` (items_builder.dart, report_table_builder.dart)
- Services: `lib/services/*_service.dart` (database_service.dart, config_service.dart)
- API: `lib/services/api/*_api.dart` (reports_api.dart, stocks_api.dart)
- Helpers: `lib/screens/helpers/*_handler.dart` or `*_helper.dart` (auto_connection_handler.dart)
- Models: `lib/models/*.dart` (stocks_response.dart, connection_info.dart)
- Utilities: `lib/utils/*_helper.dart` or `*_utils.dart` (log_file_writer.dart, report_data_utils.dart)

**Dart Classes:**
- Screens/Widgets: PascalCase, ends with "Screen" or "Widget" (MainConnectionScreen, ReportTableBuilder)
- Services: PascalCase ending in "Service" (DatabaseService, ConfigService)
- API: PascalCase ending in "Api" (ReportsApi, StocksApi)
- Models: PascalCase ending in "Response" or "Item" (StocksResponse, ConnectionInfo)
- Helpers: PascalCase ending in "Handler" or "Helper" (AutoConnectionHandler, LogFileWriter)
- Enums: lowercase_with_underscores (e.g., ServerType.hostinger)
- Constants: lowercase_with_underscores (e.g., _databaseName)

**Functions/Methods:**
- Camel case: getReportData(), fetchStocksData(), _initDatabase()
- Private methods: Leading underscore _privateMethod()
- Async methods: No special naming, just async keyword (Future<Type> methodName())

**Variables:**
- Local: camelCase (serverUrl, itemCount, _isLoading)
- Private: Leading underscore (_savedConnections, _httpClient)
- Constants: UPPER_SNAKE_CASE (const String _configAssetPath, const int _databaseVersion)

## Where to Add New Code

**New Report Type:**
- API endpoint: Create new method in `lib/services/api/reports_api.dart` (follow pattern of getStocksReport())
- Service method: Add to DatabaseService in `lib/services/database_service.dart` (proxy to API)
- Model: Create response model in `lib/models/new_report_response.dart` with factory.fromMap()
- Section widget: Create `lib/screens/reports/new_report_section.dart` extending StatefulWidget
- Builder widget: Create `lib/widgets/new_report_builder.dart` static factory methods
- Routing: Add case in MainConnectionScreen._currentReport logic

**New Filter Type:**
- Widget: Add to `lib/widgets/report_filter_widgets.dart` (e.g., TextFilterInput, DateRangeFilter)
- Logic: Add filter parsing to `lib/screens/helpers/report_filter_helper.dart`
- Config: Add field visibility toggle to `assets/config.json` and ConfigService methods

**New Column in Report:**
- Visibility config: Add key to `assets/config.json` report section
- ConfigService: Add shouldShowField() case if visibility is configurable
- Builder: Add column key to builder's column list in `*_builder.dart`
- Model: Add field to response model if coming from new API field

**New Export Format:**
- Service: Create `lib/services/new_export_service.dart` (follow PdfService pattern)
- UI: Add export button to `lib/widgets/report_appbar_builders.dart`
- Integration: Wire in MainConnectionScreen._onExport()

**Platform-Specific Code:**
- Helpers: `lib/utils/platform_utils.dart` for feature detection (isDesktop(), isIos(), etc.)
- Services: Platform-aware implementations (e.g., SecureStorageHelper hybrid approach)
- Screens: Use defaultTargetPlatform + conditional rendering in build() methods
- Packages: Use conditional imports if needed (flutter/foundation.dart for kDebugMode)

**Shared Utilities:**
- Helpers: `lib/utils/` for cross-layer utilities (logging, device info, layout)
- Mixins: `lib/screens/helpers/report_utils_mixin.dart` for report-specific shared logic
- Extensions: Add to models or utils (none currently, but pattern: extension NameOnType { ... })

## Special Directories

**lib/generated/:**
- Purpose: Generated localization code
- Generated: Yes (by flutter gen-l10n)
- Committed: Yes (checked in to version control)
- Do not edit manually

**lib/l10n/:**
- Purpose: Localization configuration
- Contains: ARB files and custom LocalizationsDelegate
- Do not auto-generate; manually written delegate for custom logic

**assets/:**
- Purpose: Static resources bundled with app
- Committed: Yes
- Special: config.json must exist (loaded in ConfigService)

---

*Structure analysis: 2026-04-01*
