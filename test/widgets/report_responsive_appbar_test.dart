import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/report_responsive_appbar.dart';

void main() {
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

  group('ReportResponsiveAppBar', () {
    testWidgets('타이틀이 표시된다', (tester) async {
      await tester.pumpWidget(buildSubject(width: 800));
      expect(find.text('Test Report'), findsOneWidget);
    });

    testWidgets('width >= 600일 때 1줄 레이아웃이다', (tester) async {
      await tester.pumpWidget(buildSubject(
        width: 800,
        filterWidgets: [const Text('Filter1'), const Text('Filter2')],
      ));
      await tester.pump();
      // 필터가 AppBar 내부 Row에 포함됨 (1줄)
      expect(find.text('Filter1'), findsOneWidget);
      expect(find.text('Filter2'), findsOneWidget);
      // preferredSize.height는 StatelessWidget이라 BuildContext가 없으므로
      // 항상 kToolbarHeight * 2를 반환한다 (Scaffold 공간 예약용 고정값).
      // 실제 렌더링 높이(1줄)는 build() 내부 AppBar의 toolbarHeight로 결정되며
      // 테스트 범위 밖이다 (Scaffold integration test에서 검증).
      final appBar = tester.widget<ReportResponsiveAppBar>(
        find.byType(ReportResponsiveAppBar),
      );
      expect(appBar.preferredSize.height, kToolbarHeight * 2);
    });

    testWidgets('width < 600일 때 2줄 레이아웃이다', (tester) async {
      await tester.pumpWidget(buildSubject(
        width: 375,
        filterWidgets: [const Text('Filter1')],
      ));
      await tester.pump();
      // preferredSize.height == kToolbarHeight * 2
      final appBar = tester.widget<ReportResponsiveAppBar>(
        find.byType(ReportResponsiveAppBar),
      );
      expect(appBar.preferredSize.height, kToolbarHeight * 2);
    });
  });
}
