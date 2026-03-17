import 'package:flutter/material.dart';

/// 테이블 칼럼 정의 모델.
/// 각 보고서 builder가 이 리스트를 제공하면 ResizableDataTable이 레이아웃을 담당한다.
@immutable
class TableColumnDef {
  final String key;
  final String label;
  final double defaultWidth;
  final double minWidth;
  final double maxWidth;
  final TextAlign textAlign;
  final bool sortable;

  const TableColumnDef({
    required this.key,
    required this.label,
    required this.defaultWidth,
    this.minWidth = 50.0,
    this.maxWidth = 2000.0,
    this.textAlign = TextAlign.left,
    this.sortable = false,
  });
}

/// 칼럼 헤더 오른쪽 경계에 오버레이되는 리사이즈 핸들.
/// Stack + Positioned로 배치되므로 Row 레이아웃 너비에 영향을 주지 않는다.
/// 기존 버그(_StocksColumnResizeHandle, _ColumnResizeHandle)가 Row에 14px를 추가하던
/// 문제를 이 방식으로 해결한다.
class _TableResizeHandle extends StatefulWidget {
  final String columnKey;
  final double currentWidth;
  final double minWidth;
  final double maxWidth;
  final void Function(double newWidth) onResize;

  const _TableResizeHandle({
    required Key key,
    required this.columnKey,
    required this.currentWidth,
    required this.minWidth,
    required this.maxWidth,
    required this.onResize,
  }) : super(key: key);

  @override
  State<_TableResizeHandle> createState() => _TableResizeHandleState();
}

class _TableResizeHandleState extends State<_TableResizeHandle> {
  double _initialWidth = 0;
  double _initialPointerX = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: Tooltip(
        message: 'Arrastrar para ajustar ancho',
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            _initialWidth = widget.currentWidth;
            _initialPointerX = e.position.dx;
            setState(() => _isDragging = true);
          },
          onPointerMove: (e) {
            if (!_isDragging) return;
            final delta = e.position.dx - _initialPointerX;
            final newWidth = (_initialWidth + delta)
                .clamp(widget.minWidth, widget.maxWidth);
            widget.onResize(newWidth);
          },
          onPointerUp: (_) => setState(() => _isDragging = false),
          onPointerCancel: (_) => setState(() => _isDragging = false),
          child: SizedBox(
            width: 14,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border(
                    left: BorderSide(color: Colors.grey[500]!, width: 1),
                    right: BorderSide(color: Colors.grey[500]!, width: 1),
                  ),
                ),
                child: Icon(Icons.drag_indicator, size: 14, color: Colors.grey[700]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
