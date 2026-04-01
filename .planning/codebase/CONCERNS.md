# Codebase Concerns

**Analysis Date:** 2026-04-01

## Tech Debt

**Excessive Debug Logging - Production Performance Risk:**
- Issue: 983 `print()` statements throughout codebase with mixed debugging emoji and verbose output
- Files: Primary offenders include:
  - `lib/widgets/report_table_builder.dart` (23 print calls)
  - `lib/widgets/report_table_data_rows.dart` (37 print calls)
  - `lib/screens/helpers/report_data_loader.dart` (63 print calls)
  - `lib/services/api/http_request_handler.dart` (86 print calls)
  - `lib/screens/resumen_del_dia_screen.dart` (28 print calls)
- Impact: Console output floods logs during runtime, slows performance in large table renders (300+ rows), no production log rotation
- Fix approach: Replace `print()` with `debugPrint()` or conditional logging; implement proper logging service with log levels and file rotation

**Monolithic Screen Components:**
- Issue: Giant State classes lack separation of concerns
- Files:
  - `lib/screens/resumen_del_dia_screen.dart` (5,206 lines)
  - `lib/screens/report_screen_legacy.dart` (6,583 lines)
- Impact: Difficult to test, maintain, and refactor; high cognitive load; tight coupling between logic and UI
- Fix approach: Extract data loading into mixins (partially done in `report_utils_mixin.dart`), create dedicated view models

**Unsafe SSL Certificate Validation:**
- Issue: `badCertificateCallback` always returns `true` for development convenience
- Files: `lib/utils/ssl_client_helper.dart` (lines 13-20)
- Impact: Accepts all self-signed certificates without verification; no environment-based toggle for production
- Fix approach: Add build config flag to disable in production; implement certificate pinning option

**Type Casting Without Null Safety:**
- Issue: 2,037 `!` (null assertion) operators throughout codebase, 1,197 `as` casts
- Files: Widespread across all layers
- Impact: Runtime crashes if assertions fail; no null safety guarantees
- Fix approach: Use `as?` (soft cast) and null-coalescing operators; add pre-cast validation

**Unused "report_screen_legacy.dart":**
- Issue: 6,583-line legacy screen still in codebase but may not be actively used
- Files: `lib/screens/report_screen_legacy.dart`
- Impact: Dead code increases maintenance burden; unclear if functionality was migrated
- Fix approach: Audit active imports and remove if truly deprecated

## Known Issues

**SSL Timeout on Weak Networks:**
- Symptoms: `Error: Timeout on SSL handshake after 30 seconds` on mobile/low-bandwidth
- Files: `lib/utils/ssl_client_helper.dart` (line 23)
- Trigger: Network latency >5s or weak signal
- Workaround: Currently hardcoded 30s timeout; can only increase manually and rebuild

**API Response Timeout Mismatch:**
- Symptoms: Some endpoints timeout at 10s, resumen_del_dia at 60s, but inconsistent error messages
- Files:
  - `lib/services/api/reports_api.dart` (line 42: 60s timeout)
  - `lib/services/api/http_request_handler.dart` (line 105: 10s timeout)
- Trigger: Large data aggregation or slow DB queries
- Workaround: Manual endpoint-specific timeout increases; no adaptive timeout strategy

**"Empty reply from server" Network Errors:**
- Symptoms: Connection pool exhaustion or premature server closure on large data requests
- Files: `lib/services/api/http_request_handler.dart` (HTTP client management)
- Trigger: Rapid successive requests or large response bodies (>10MB)
- Workaround: Manual connection pool tuning; documented in `EMPTY_REPLY_DIAGNOSIS.md`

**Unhandled TextEditingController Disposal in Edge Cases:**
- Symptoms: Memory leak warnings in debug mode on rapid screen transitions
- Files:
  - `lib/screens/resumen_del_dia_screen.dart` (lines 79-85 controllers)
  - `lib/screens/connection_screen.dart` (password controller)
- Trigger: Navigate away before widget fully initializes
- Workaround: Added `mounted` checks and explicit disposal (line 5193-5201 in resumen_del_dia_screen.dart)

## Security Considerations

**Database Credentials Transmitted in Headers:**
- Risk: Database password, username, database name passed in plain HTTP headers (x-db-password, x-db-user, x-db-name)
- Files:
  - `lib/services/api/http_request_handler.dart` (lines 45-53)
  - `lib/services/secure_storage_helper.dart` (credential storage)
- Current mitigation: Connection must use HTTPS (enforced by server); password stored in OS-specific secure storage (Keychain/Keystore)
- Recommendations:
  - Implement connection token exchange (OAuth-style) instead of direct credential headers
  - Add certificate pinning for SSL/TLS
  - Use HTTP/2 with mandatory encryption
  - Document credential handling in security guide

**Credentials in SecureStorage (Hybrid Model):**
- Risk: macOS uses SharedPreferences (less secure) for password; other platforms use OS secure storage
- Files: `lib/services/api/http_request_handler.dart` (lines 34-36)
- Current mitigation: Comment explains platform differences; iOS uses Keychain with accessibility restrictions
- Recommendations: Unify to use SecureStorage across all platforms; remove macOS special case

**Print Statements Exposing Sensitive Data:**
- Risk: Database connection info, headers, SSL cert details logged to console
- Files:
  - `lib/utils/ssl_client_helper.dart` (lines 16-18 print cert subject/issuer)
  - `lib/services/api/http_request_handler.dart` (lines 94-99 print headers)
- Current mitigation: Development environment only (should be)
- Recommendations: Mask sensitive fields in debug output; use environment-aware logging

**Insecure Biometric Storage:**
- Risk: Biometric unlock grants full app access without credential re-entry
- Files: `lib/screens/biometric_auth_screen.dart`
- Current mitigation: No explicit token expiry after biometric unlock
- Recommendations: Implement session timeout, require re-authentication for sensitive operations

## Performance Bottlenecks

**Large Table Renders (300+ rows):**
- Problem: DataTable with 300+ items causes frame drops and scroll lag
- Files:
  - `lib/widgets/report_table_builder.dart` (layout calculation)
  - `lib/widgets/report_table_data_rows.dart` (37 print calls during render)
  - `lib/screens/resumen_del_dia_single_sucursal_view.dart` (1,971 lines with nested tables)
- Cause: Full table rebuild on scroll; excessive print() logging during render; column width recalculation per frame
- Improvement path:
  - Implement virtual scrolling (lazy load rows)
  - Batch print statements; remove per-row logging
  - Cache column width calculations

**API Response JSON Parsing for Large Datasets:**
- Problem: Parsing 50k+ item responses blocks UI thread (2-3 second freeze)
- Files:
  - `lib/services/api/http_request_handler.dart` (line 126: `json.decode()` on main thread)
  - `lib/screens/helpers/report_data_loader.dart` (1,449 lines of data transformation)
- Cause: Synchronous JSON parsing on main isolate; no streaming or chunked processing
- Improvement path:
  - Use `compute()` to parse JSON on background isolate
  - Implement pagination at API level (add limit/offset parameters)
  - Cache parsed responses

**Memory Usage with Multiple DatabaseService Instances:**
- Problem: Each report screen creates new DatabaseService; no singleton pattern or cleanup on unload
- Files:
  - `lib/screens/resumen_del_dia_screen.dart` (line 90: creates new instance)
  - `lib/services/database_service.dart` (late final APIs not lazily initialized)
- Cause: No instance reuse; HTTP client not pooled across screens
- Improvement path:
  - Implement ServiceLocator/GetIt singleton pattern
  - Add reference counting for HTTP client disposal
  - Implement lazy initialization for rarely-used APIs

**Excessive `mounted` Checks (162 occurrences):**
- Problem: Defensive programming adds overhead; many could be consolidated with proper Future error handling
- Files: Widespread throughout screens and helpers
- Cause: Fighting race conditions between async operations and widget disposal
- Improvement path: Implement proper cancellation tokens or use `unawaited()` with error handlers

## Fragile Areas

**Report Data Loading Pipeline:**
- Files: `lib/screens/helpers/report_data_loader.dart` (1,449 lines)
- Why fragile:
  - Complex state management with multiple async operations
  - 19 `try-catch` blocks with generic error handling
  - Tightly coupled to specific API response structures
  - No validation of expected fields before access
- Safe modification:
  - Add schema validation before data transformation
  - Create typed response models (partially done for StocksResponse, TodocodigosResponse)
  - Break into smaller, testable functions
- Test coverage: Only 2 basic tests in `test/` directory; integration tests missing

**Report Filter and Sort Logic:**
- Files:
  - `lib/widgets/report_filters.dart`
  - `lib/screens/helpers/report_filter_helper.dart`
  - `lib/widgets/report_table_builder.dart` (getDisplayedColumns method, 150+ lines of conditional logic)
- Why fragile:
  - Column visibility determined by magic field names (e.g., `containsKey('vcode')`)
  - Multiple contradictory sorting implementations across builders
  - No schema definition; relies on field presence inference
- Safe modification: Create unified ColumnSchema model; move column definitions to single source of truth
- Test coverage: Minimal; column selection logic untested

**Resizable Table Synchronization:**
- Files: `lib/widgets/resizable_data_table.dart`
- Why fragile:
  - Dual scroll controllers (header/data) require race condition prevention with delta checks
  - Column width persistence split across multiple services (gastos_column_width_storage, items_column_width_storage, etc.)
  - Resize handle positioning uses Stack + Positioned (brittle layout)
- Safe modification:
  - Add synchronization tests with rapid scroll events
  - Consolidate width storage into single ColumnWidthStorage service
  - Add bounds checking for resize deltas
- Test coverage: Widget test exists but incomplete (`test/widgets/resizable_data_table_test.dart`)

**Excel/PDF Export:**
- Files:
  - `lib/services/excel_service.dart` (780 lines)
  - `lib/services/pdf_service.dart`
- Why fragile:
  - Hard-coded column ordering; breaks if API response structure changes
  - No column selection passed to export functions
  - Large files (10k+ rows) may exceed memory limits
- Safe modification: Pass column list and ordering to export functions; implement streaming export
- Test coverage: None

## Scaling Limits

**HTTP Connection Pool Exhaustion:**
- Current capacity: Single HttpClient per DatabaseService (no explicit pool size limit)
- Limit: If >50 concurrent requests from same service, connection timeout risk
- Scaling path:
  - Implement connection pooling with configurable max connections
  - Add request queuing mechanism
  - Monitor connection usage metrics

**In-Memory Cache of Tipos and Temporadas:**
- Current capacity: Full dataset cached in `_cachedTipos` and `_cachedTemporadas` lists
- Limit: If dataset grows to >100k items, memory usage becomes problematic
- Scaling path: Implement LRU cache with size limits; add cache invalidation strategy

**Single-Server Architecture (No Failover):**
- Current: Hardcoded serverUrl; no fallback servers or load balancing
- Limit: Server downtime = app downtime
- Scaling path: Implement server health checks; add failover URLs; implement circuit breaker pattern

## Dependencies at Risk

**http ^1.1.0 (Outdated):**
- Risk: Package hasn't received updates; known timeout issues with large bodies
- Impact: SSL handshake timeouts, connection pool exhaustion
- Migration plan: Upgrade to `http: ^2.0.0` (breaking changes: no automatic redirects by default)

**sqflite: ^2.3.0 (Android/iOS offline DB):**
- Risk: Package maintenance sporadic; SQLite version varies by platform
- Impact: Schema migration issues across OS versions
- Migration plan: Consider riverpod/drift for type-safe DB access (if offline DB needed)

**pdf: ^3.11.1 (PDF Generation):**
- Risk: Large document generation blocks UI; no streaming support
- Impact: Export hangs on 10k+ row reports
- Migration plan: Implement chunked PDF generation; consider server-side PDF rendering

**flutter_secure_storage: ^9.0.0:**
- Risk: Platform implementation differences (Keychain vs Keystore API changes)
- Impact: Credential access fails on OS updates
- Migration plan: Add fallback to SharedPreferences with encryption if secure storage unavailable

## Missing Critical Features

**No Request Cancellation Mechanism:**
- Problem: Long-running requests (60s resumen_del_dia) cannot be cancelled by user
- Blocks: User experience when query is clearly stuck; no way to retry without re-opening entire screen
- Fix: Add CancelToken to all API calls; implement UI "Cancel" button

**No Offline Mode:**
- Problem: App completely non-functional without server connection
- Blocks: Mobile users on flaky networks; field sales use cases
- Fix: Implement local SQLite cache; add sync-on-reconnect

**No Error Analytics or Reporting:**
- Problem: Silent failures hidden in debug logs; no visibility into production errors
- Blocks: Debugging customer issues; identifying systemic problems
- Fix: Integrate error tracking service (e.g., Sentry); implement remote logging

**No Automatic Retry with Exponential Backoff:**
- Problem: Network glitches cause immediate failure; no resilience
- Blocks: Mobile network reliability (e.g., switching between cellular/WiFi)
- Fix: Add RetryPolicy to HttpRequestHandler; make configurable per endpoint

**No User Session Timeout:**
- Problem: App stays logged in indefinitely; credential reuse risk
- Blocks: Security hardening; compliance requirements
- Fix: Implement session tracking; add inactivity timeout with re-authentication

## Test Coverage Gaps

**API Integration Tests Missing:**
- What's not tested: HttpRequestHandler error cases, timeout handling, SSL certificate validation
- Files: `lib/services/api/http_request_handler.dart`
- Risk: Regressions in error handling; timeout behavior undefined
- Priority: High (critical data loading path)

**Report Data Transformation Untested:**
- What's not tested: Data filtering, sorting, column visibility logic for all 8+ report types
- Files: `lib/screens/helpers/report_data_loader.dart`, `lib/widgets/report_table_builder.dart`
- Risk: Silent data corruption; wrong aggregations displayed
- Priority: High (user-visible data)

**Widget Rebuild Edge Cases:**
- What's not tested: Rapid connection switching, large data loads, screen rotation with active requests
- Files: `lib/screens/resumen_del_dia_screen.dart`, report screens
- Risk: Race conditions, memory leaks, null pointer crashes
- Priority: High (complex state machine)

**Biometric Auth Flow:**
- What's not tested: Fallback to password when biometric unavailable, timeout behavior, cancellation
- Files: `lib/screens/biometric_auth_screen.dart`
- Risk: Authentication bypass or lockout
- Priority: Medium

**Column Width Persistence:**
- What's not tested: Concurrent writes from multiple screens, storage corruption recovery
- Files: `lib/services/gastos_column_width_storage.dart`, `lib/services/items_column_width_storage.dart`, etc.
- Risk: Lost user preferences, UI corruption
- Priority: Medium

---

*Concerns audit: 2026-04-01*
