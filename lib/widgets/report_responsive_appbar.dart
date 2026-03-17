import 'package:flutter/material.dart';

/// 화면 크기에 따라 1줄 또는 2줄 레이아웃으로 자동 전환되는 보고서 AppBar.
///
/// width >= breakpoint: 1줄 — [메뉴] 제목 [필터들] [actions]
/// width < breakpoint:  2줄 — 1줄: [메뉴] 제목 [actions]
///                            2줄: [필터들 전체]
///
/// PreferredSizeWidget 구현으로 Scaffold(appBar:)에 직접 사용 가능.
/// preferredSize.height는 항상 kToolbarHeight * 2를 반환한다 (Scaffold 공간 예약).
/// 실제 렌더링 높이는 build()에서 MediaQuery로 결정된다.
class ReportResponsiveAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final Color color;

  /// 보고서별 필터 위젯 리스트 (타입 필터, 검색창 등)
  final List<Widget> filterWidgets;

  /// 오른쪽 액션 버튼 리스트 (공유 버튼 등)
  final List<Widget> actions;

  final VoidCallback? onMenuPressed;

  /// 1줄/2줄 전환 기준점 (기본 600.0 — 핸드폰 세로 기준)
  final double breakpoint;

  const ReportResponsiveAppBar({
    super.key,
    required this.title,
    required this.color,
    this.filterWidgets = const [],
    this.actions = const [],
    this.onMenuPressed,
    this.breakpoint = 600.0,
  });

  bool _isTwoLine(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpoint;
  }

  @override
  Size get preferredSize {
    // preferredSize는 BuildContext 없이 호출되므로
    // 고정 kToolbarHeight * 2를 반환한다.
    // Scaffold가 이 높이로 AppBar 공간을 예약한다.
    // 실제 렌더링 높이는 build()에서 twoLine 여부로 결정된다.
    return const Size.fromHeight(kToolbarHeight * 2);
  }

  @override
  Widget build(BuildContext context) {
    final twoLine = _isTwoLine(context);

    if (!twoLine) {
      // 1줄: 제목 + 필터 + actions 모두 한 줄
      return AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        leading: onMenuPressed != null
            ? IconButton(
                icon: const Icon(Icons.menu), onPressed: onMenuPressed)
            : null,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        actions: [
          ...filterWidgets.map((w) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: w,
              )),
          ...actions,
        ],
      );
    }

    // 2줄: 제목 행 + 필터 행
    return AppBar(
      backgroundColor: color,
      foregroundColor: Colors.white,
      toolbarHeight: kToolbarHeight * 2,
      leading: onMenuPressed != null
          ? IconButton(icon: const Icon(Icons.menu), onPressed: onMenuPressed)
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
              ...actions,
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (int i = 0; i < filterWidgets.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Flexible(child: filterWidgets[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
