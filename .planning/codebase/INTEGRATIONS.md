# External Integrations

**Analysis Date:** 2026-04-01

## APIs & External Services

**Database Backend:**
- Custom PostgreSQL REST API
  - Base URL: User-configurable via connection screen
  - SDK/Client: `http` package with custom `HttpRequestHandler`
  - Auth: Custom headers (database name, username, password)

**Core API Endpoints:**
- `/api/stocks` - Stock/inventory data (via `StocksApi`)
- `/api/codigos` - Product codes (via `CodigosApi`)
- `/api/todocodigos` - All product codes (via `TodocodigosApi`)
- `/api/reports` - Report generation (via `ReportsApi`)
- `/api/disconnect` - Connection teardown (via `DatabaseConnectionApi`)
- `/api/test_connection` - Connection validation

## Data Storage

**Databases:**
- PostgreSQL (remote)
  - Connection: Via HTTP API at user-configured server URL
  - Client: Custom HTTP API layer (`DatabaseService`)
  - Headers: `x-db-name`, `x-db-user`, `x-db-password`, `x-db-ssl`
  - Connection pooling: Managed via `HttpRequestHandler` to prevent pool waste

- SQLite (local)
  - Provider: sqflite 2.3.0
  - Database: `app_local_database.db`
  - Service: `LocalDatabaseService`
  - Purpose: Offline-first caching for 200MB+ datasets
  - Tables: Items with indexes on name, category, created_at

**File Storage:**
- Local filesystem only
  - PDFs: Generated to app documents directory via `path_provider`
  - Excel: Generated to app documents directory
  - Logs: Written to app documents directory (debug mode only)

**Caching:**
- In-memory caching (Tipos and Temporadas)
  - `_cachedTipos`, `_cachedTemporadas` in `DatabaseService`
- SharedPreferences caching
  - App configuration via `config_service.dart`
  - Database connection info (database_name, username, password)

## Authentication & Identity

**Auth Provider:**
- Custom database-based authentication
  - Implementation: Username/password sent via HTTP headers
  - Biometric overlay: local_auth package (Face ID, fingerprint)
  - Secure storage: flutter_secure_storage with platform-specific handling

**Credential Storage:**
- macOS: SharedPreferences (all credentials)
- iOS/Android: Hybrid approach (SharedPreferences for public data, Keychain/SecureEnclave for passwords)
- Windows/Linux: flutter_secure_storage

**Biometric Authentication:**
- Framework: local_auth 2.3.0
- Screen: `BiometricAuthScreen`
- Fallback: Manual password authentication

## Configuration & Secrets

**Configuration Management:**
- `ConfigService` - Singleton pattern
- Asset file: `assets/config.json`
- Runtime override: SharedPreferences (`app_config` key)

**Secrets Management:**
- Database credentials stored in secure storage
- SSL certificate validation: Custom bypass for self-signed certificates in development
- Helper: `SslClientHelper.createUnsafeClient()` for dev environments

## Monitoring & Observability

**Error Tracking:**
- None detected in integrations

**Logs:**
- File-based logging in debug mode
- Service: `LogFileWriter`
- Path: App documents directory
- Access: `LogFileWriter.getLogFilePath()`
- Console logging: Via `print()` statements with emoji prefixes (🔄, ❌, ℹ️, ⚠️)

**Debug Configuration:**
- Service: `DebugConfig`
- Log file writing (debug mode only)
- Device info collection

## CI/CD & Deployment

**Hosting:**
- Platform-specific:
  - iOS: Apple ecosystem
  - Android: Google Play ecosystem
  - macOS: Apple App Store or direct distribution
  - Windows/Linux: Direct executable distribution
- Backend: Custom PostgreSQL server (user-provided)

**CI Pipeline:**
- None detected - no GitHub Actions or similar found

**Build Configuration:**
- MSIX for Windows packaging
- Flutter launcher icons for multi-platform
- Platform-specific Info.plist (iOS) with biometric permissions

## Environment Configuration

**Required Environment Vars:**
- None detected - Configuration via UI or `assets/config.json`

**Configuration Sources:**
1. `assets/config.json` (asset-based defaults)
2. SharedPreferences (runtime overrides)
3. SecureStorage (credential storage)
4. UI input (connection dialog)

**Settings Structure:**
```json
{
  "report": {
    "ventas": { "showTpago": true },
    "resumenDelDia": { "showAmounts": true },
    "gastos": { "modificarGasto": true },
    "stocks": { "modificarStock": true },
    "codigos_todocodigos": { "modificarCodigo": true }
  }
}
```

## Webhooks & Callbacks

**Incoming:**
- None detected

**Outgoing:**
- PDF/Excel export to local storage
- Device sharing via share_plus (system share sheet)

## Platform-Specific Integration Details

**iOS/macOS:**
- BiometricAuth: Face ID, Touch ID
- Secure storage: Keychain
- Local auth fallback included

**Android:**
- Biometric: Fingerprint, Face recognition
- Secure storage: Android Keystore
- Network info: Connectivity info via platform channels

**Desktop (Windows/Linux/macOS):**
- Window manager for resize/maximize control
- Network detection via network_info_plus
- Local file access via path_provider

## Network Security

**SSL/TLS:**
- Custom SSL client: Allows self-signed certificates in development
- Helper: `SslClientHelper.createUnsafeClient()`
- Connection timeout: 30 seconds
- Idle timeout: 30 seconds
- Keep-Alive: Enabled via 'Connection' header

**HTTP Headers:**
- Content-Type: application/json
- Connection: keep-alive
- Custom auth headers: x-db-name, x-db-user, x-db-password

## Localization & Multi-Language Support

**Languages Supported:**
- English
- Korean (한국어)
- Spanish (Español)

**Framework:**
- flutter_localizations
- intl 0.20.2
- AppLocalizations auto-generated

---

*Integration audit: 2026-04-01*
