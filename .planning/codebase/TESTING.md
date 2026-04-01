# Testing Patterns

**Analysis Date:** 2026-04-01

## Test Framework

**Runner:**
- `flutter_test` (built-in Flutter testing framework)
- Available via dev dependency in `pubspec.yaml`
- Run with `flutter test` command

**Assertion Library:**
- Matcher API from `flutter_test` package
- `expect()` function for assertions
- Built-in matchers: `findsOneWidget`, `findsNothing`, `findsWidgets`, `isNull`
- Text and widget finders: `find.text()`, `find.byType()`, `find.byKey()`, `find.byIcon()`

**Run Commands:**
```bash
flutter test                    # Run all tests
flutter test --watch           # Watch mode (automatic re-run on changes)
flutter test --coverage        # Generate coverage report
flutter test test/widgets/     # Run specific test directory
flutter test test/widget_test.dart  # Run specific test file
```

## Test File Organization

**Location:**
- Co-located with source code pattern: Tests in `test/` directory parallel to `lib/`
- Widget tests in `test/widgets/` subdirectory
- Test files found at:
  - `test/widget_test.dart`
  - `test/widgets/report_responsive_appbar_test.dart`
  - `test/widgets/resizable_data_table_test.dart`

**Naming:**
- Test files follow source file naming with `_test.dart` suffix
- Widget tests: `{widget_name}_test.dart` (e.g., `resizable_data_table_test.dart`)
- Test groups use descriptive names matching class names

**Structure:**
```
test/
├── widget_test.dart                    # Legacy smoke test
├── widgets/
│   ├── report_responsive_appbar_test.dart
│   └── resizable_data_table_test.dart
```

## Test Structure

**Suite Organization:**
```dart
void main() {
  group('WidgetClassName', () {
    // Shared test setup
    
    testWidgets('기능 설명 (Korean)', (tester) async {
      // Arrange
      
      // Act
      await tester.pumpWidget(...);
      
      // Assert
      expect(find.text(...), findsOneWidget);
    });
  });
}
```

**Patterns:**

**Widget Building Pattern:**
- Helper function to create subject widget with configuration
- Wraps in MaterialApp and Scaffold for Material context
- Example from `report_responsive_appbar_test.dart`:
```dart
Widget buildSubject({
  required double width,
  List<Widget> filterWidgets = const [],
  List<Widget> actions = const [],
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 812)),
      child: Scaffold(
        appBar: ReportResponsiveAppBar(
          title: 'Test Report',
          color: Colors.blue,
          filterWidgets: filterWidgets,
          actions: actions,
        ),
        body: const SizedBox(),
      ),
    ),
  );
}
```

**Setup & Assertions:**
- `testWidgets()` wrapper for async widget tests
- `await tester.pumpWidget()` to build and render
- `await tester.pump()` for additional frame renders
- `tester.getSize()` to measure rendered widgets
- `tester.widget<T>()` to access widget instances

## Mocking

**Framework:**
- No dedicated mocking library configured (Mockito, mocktail not in dependencies)
- Manual test doubles and fake implementations used

**Patterns:**
- Callback parameters for test verification:
```dart
String? resizedKey;
await tester.pumpWidget(MaterialApp(
  home: ResizableDataTable(
    onColumnResize: (key, width) {
      resizedKey = key;
    },
    ...
  ),
));
expect(resizedKey, isNull); // Verify callback not yet called
```

- Constructor injection of test dependencies:
```dart
const testColumns = [
  TableColumnDef(key: 'name', label: 'Name', defaultWidth: 100),
];
final testRows = [
  [const Text('Apple'), const Text('1000')],
];
final testWidths = {'name': 100.0};
```

**What to Mock:**
- User interactions (tap, scroll): Use `tester.tap()`, `tester.pumpWidget()`
- Widget properties and state
- Test data passed via constructor

**What NOT to Mock:**
- Flutter framework widgets (MaterialApp, Scaffold, Text, etc.)
- Build context and MediaQuery (use real MaterialApp wrapper)
- Widget tree rendering (use actual tester to pump widgets)

## Fixtures and Factories

**Test Data:**
- Inline constant definition for simple test data:
```dart
const testColumns = [
  TableColumnDef(
    key: 'test',
    label: 'Test',
    defaultWidth: 100,
  ),
];
```

- Simple factory methods within tests:
```dart
Widget buildSubject({
  required double width,
  List<Widget> filterWidgets = const [],
}) { ... }
```

**Location:**
- Test fixtures defined at top of test file, before `void main()`
- Shared test data in helper functions
- No separate fixtures directory

**Examples from codebase (`test/widgets/resizable_data_table_test.dart`):**
```dart
const testColumns = [
  TableColumnDef(key: 'name', label: 'Name', defaultWidth: 100, sortable: true),
  TableColumnDef(key: 'price', label: 'Price', defaultWidth: 80, textAlign: TextAlign.right),
];

final testRows = [
  [const Text('Apple'), const Text('1000')],
  [const Text('Banana'), const Text('500')],
];

final testWidths = {'name': 100.0, 'price': 80.0};
```

## Coverage

**Requirements:**
- No coverage target enforced in configuration
- Coverage can be generated but not required

**View Coverage:**
```bash
flutter test --coverage
# Generates coverage/lcov.info
```

## Test Types

**Unit Tests:**
- `test()` function for pure Dart logic (not used in current test files)
- Example structure:
```dart
test('기본값이 올바르게 설정된다', () {
  const col = TableColumnDef(
    key: 'test',
    label: 'Test',
    defaultWidth: 100,
  );
  expect(col.minWidth, 50.0);
  expect(col.maxWidth, 2000.0);
  expect(col.textAlign, TextAlign.left);
  expect(col.sortable, false);
});
```

**Widget Tests:**
- `testWidgets()` for UI component testing
- Used extensively in codebase
- Tests widget rendering, user interactions, state changes
- Examples:
  - `test/widgets/report_responsive_appbar_test.dart`: Tests responsive layout behavior
  - `test/widgets/resizable_data_table_test.dart`: Tests table rendering and column widths

**Integration Tests:**
- Not implemented in current codebase
- Would use `integration_test` package if added
- No E2E test infrastructure currently present

## Common Patterns

**Widget Lookup & Assertion:**
```dart
// Find by text
expect(find.text('Test Report'), findsOneWidget);

// Find by type
expect(find.byType(ReportResponsiveAppBar), findsOneWidget);

// Find by key
expect(find.byKey(const Key('report_appbar_1line')), findsOneWidget);

// Ancestor/descendant relationships
final nameHeaderFinder = find.ancestor(
  of: find.text('Name'),
  matching: find.byType(SizedBox),
).first;

// Assert nothing found
expect(find.byKey(const Key('report_appbar_2line')), findsNothing);
```

**Async Testing - Widget Rendering:**
```dart
await tester.pumpWidget(buildSubject(width: 800));  // Build and render
await tester.pump();                                 // Additional frame
expect(find.text('Filter1'), findsOneWidget);       // Assert
```

**Size/Layout Testing:**
```dart
final appBar = tester.widget<ReportResponsiveAppBar>(
  find.byType(ReportResponsiveAppBar),
);
expect(appBar.preferredSize.height, kToolbarHeight * 2);

final nameBox = tester.getSize(nameHeaderFinder);
expect(nameBox.width, 100.0);
```

**State/Callback Testing:**
```dart
String? resizedKey;

await tester.pumpWidget(MaterialApp(
  home: Scaffold(
    body: ResizableDataTable(
      columns: testColumns,
      rows: testRows,
      columnWidths: testWidths,
      onColumnResize: (key, width) {
        resizedKey = key;  // Capture callback argument
      },
      headerColor: Colors.blue,
    ),
  ),
));

expect(resizedKey, isNull); // Verify callback not called yet
```

## Test Examples from Codebase

**Example 1: Responsive Widget Test**
From `test/widgets/report_responsive_appbar_test.dart`:
```dart
testWidgets('width >= 600일 때 1줄 레이아웃이다', (tester) async {
  await tester.pumpWidget(buildSubject(
    width: 800,
    filterWidgets: [const Text('Filter1'), const Text('Filter2')],
  ));
  await tester.pump();
  expect(find.text('Filter1'), findsOneWidget);
  expect(find.text('Filter2'), findsOneWidget);
  expect(find.byKey(const Key('report_appbar_1line')), findsOneWidget);
  expect(find.byKey(const Key('report_appbar_2line')), findsNothing);
  final appBar = tester.widget<ReportResponsiveAppBar>(
    find.byType(ReportResponsiveAppBar),
  );
  expect(appBar.preferredSize.height, kToolbarHeight * 2);
});
```

**Example 2: Data Model Test**
From `test/widgets/resizable_data_table_test.dart`:
```dart
test('기본값이 올바르게 설정된다', () {
  const col = TableColumnDef(
    key: 'test',
    label: 'Test',
    defaultWidth: 100,
  );
  expect(col.minWidth, 50.0);
  expect(col.maxWidth, 2000.0);
  expect(col.textAlign, TextAlign.left);
  expect(col.sortable, false);
});
```

**Example 3: Widget Rendering Test**
From `test/widgets/resizable_data_table_test.dart`:
```dart
testWidgets('칼럼 헤더 라벨이 렌더링된다', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ResizableDataTable(
        columns: testColumns,
        rows: testRows,
        columnWidths: testWidths,
        onColumnResize: (_, __) {},
        headerColor: Colors.blue,
      ),
    ),
  ));
  await tester.pump();
  expect(find.text('Name'), findsOneWidget);
  expect(find.text('Price'), findsOneWidget);
});
```

## Test Documentation

**Comments in Tests:**
- Korean comments for clarity (follows project convention)
- Comments explain non-obvious test behavior or widget-framework interactions
- Example: `// 1줄 레이아웃의 AppBar 키 확인 (2줄 레이아웃이 아님을 보장)`

**Assertions Clarity:**
- Test names in Korean using grammar: `'제목이 표시된다'` (title is displayed)
- Descriptive expect statements with comment explanations
- Platform-specific notes documented inline

## Known Testing Gaps

**Not Tested:**
- Service layer (DatabaseService, API handlers)
- State management logic
- Integration between multiple screens
- Error handling paths in services
- Async operations and Future resolution
- User authentication flows

**Test Coverage Status:**
- Widget tests: Partial (3 test files covering responsive layouts and table rendering)
- Unit tests: Minimal (only data model tests)
- Integration tests: None
- Overall coverage: Likely <20% - focus on UI components only

## Recommended Testing Additions

**High Priority:**
- Service and API layer unit tests (database_service, http_request_handler)
- Error handling tests for HTTP failures
- Model deserialization tests (from JSON response handling)
- Config loading and merging logic tests

**Medium Priority:**
- Integration tests for screen flows
- State management tests for screen state callbacks
- Navigation and routing tests

**Low Priority:**
- Performance tests for large data rendering
- Accessibility tests
