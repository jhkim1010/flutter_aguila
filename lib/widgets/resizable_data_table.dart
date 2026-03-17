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

/// 공통 리사이즈 가능 데이터 테이블.
///
/// 사용법:
/// ```dart
/// ResizableDataTable(
///   columns: MyBuilder.buildColumnDefs(),
///   rows: MyBuilder.buildRows(data),
///   columnWidths: _columnWidths,
///   onColumnResize: (key, w) => setState(() => _columnWidths[key] = w),
///   headerColor: Colors.blue,
/// )
/// ```
///
/// 버그 수정: 리사이즈 핸들을 Stack + Positioned 오버레이로 배치하여
/// 헤더 Row 레이아웃 너비에 영향을 주지 않는다.
/// 이전 방식(_StocksColumnResizeHandle, _ColumnResizeHandle)은 핸들(14px)을
/// Row에 추가 배치해 칼럼 N에서 N×14px의 누적 어긋남을 유발했다.
class ResizableDataTable extends StatefulWidget {
  final List<TableColumnDef> columns;

  /// 각 행의 셀 위젯 리스트. buildRows()가 반환한 결과를 그대로 전달한다.
  /// 셀 크기(SizedBox 래핑)는 이 위젯 내부에서 columnWidths를 기준으로 적용한다.
  final List<List<Widget>> rows;

  final Map<String, double> columnWidths;
  final void Function(String key, double newWidth) onColumnResize;
  final String? sortColumn;
  final bool sortAscending;
  final void Function(String column, bool ascending)? onSort;
  final Color headerColor;
  final Widget? footerWidget;
  final bool isLoadingMore;

  const ResizableDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.columnWidths,
    required this.onColumnResize,
    this.sortColumn,
    this.sortAscending = false,
    this.onSort,
    required this.headerColor,
    this.footerWidget,
    this.isLoadingMore = false,
  });

  @override
  State<ResizableDataTable> createState() => _ResizableDataTableState();
}

class _ResizableDataTableState extends State<ResizableDataTable> {
  late final ScrollController _headerScrollController;
  late final ScrollController _dataScrollController;

  @override
  void initState() {
    super.initState();
    _headerScrollController = ScrollController();
    _dataScrollController = ScrollController();
    _headerScrollController.addListener(_syncHeaderToData);
    _dataScrollController.addListener(_syncDataToHeader);
  }

  @override
  void dispose() {
    _headerScrollController.removeListener(_syncHeaderToData);
    _dataScrollController.removeListener(_syncDataToHeader);
    _headerScrollController.dispose();
    _dataScrollController.dispose();
    super.dispose();
  }

  /// 헤더 스크롤 → 데이터 스크롤 동기화 (race condition 방지: delta 임계값 사용)
  void _syncHeaderToData() {
    if (!_dataScrollController.hasClients) return;
    final delta = (_dataScrollController.offset - _headerScrollController.offset).abs();
    if (delta > 0.5) {
      _dataScrollController.jumpTo(_headerScrollController.offset);
    }
  }

  /// 데이터 스크롤 → 헤더 스크롤 동기화
  void _syncDataToHeader() {
    if (!_headerScrollController.hasClients) return;
    final delta = (_headerScrollController.offset - _dataScrollController.offset).abs();
    if (delta > 0.5) {
      _headerScrollController.jumpTo(_dataScrollController.offset);
    }
  }

  double _columnWidth(String key) =>
      widget.columnWidths[key] ?? widget.columns.firstWhere((c) => c.key == key).defaultWidth;

  /// 모든 칼럼 너비 + 칼럼 간격(8px × (n-1)) + 좌우 패딩(16 × 2)의 합계.
  /// 데이터 영역 SingleChildScrollView의 child SizedBox 너비로 사용한다.
  double _totalContentWidth() {
    final colWidths = widget.columns.fold<double>(0, (sum, c) => sum + _columnWidth(c.key));
    final gaps = widget.columns.length > 1 ? (widget.columns.length - 1) * 8.0 : 0.0;
    return colWidths + gaps + 32.0; // 32 = 좌우 패딩 16 × 2
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 로딩 인디케이터 (추가 데이터 로딩 중)
        if (widget.isLoadingMore)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: widget.headerColor.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: widget.headerColor),
                ),
                const SizedBox(width: 8),
                Text('Cargando...', style: TextStyle(fontSize: 12, color: widget.headerColor)),
              ],
            ),
          ),
        // 헤더 행 (가로 스크롤, 세로 고정)
        Container(
          decoration: BoxDecoration(
            color: widget.headerColor.withValues(alpha: 0.1),
            border: Border(bottom: BorderSide(color: Colors.grey[400]!, width: 2)),
          ),
          child: SingleChildScrollView(
            controller: _headerScrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < widget.columns.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _buildHeaderCell(widget.columns[i]),
                  ],
                ],
              ),
            ),
          ),
        ),
        // 데이터 행 리스트 (가로 스크롤 + 세로 스크롤)
        // _dataScrollController는 여기 단 하나의 SingleChildScrollView에만 연결된다.
        // ListView.builder 내부에 per-row SingleChildScrollView를 두면
        // Flutter StateError ("ScrollController attached to multiple scroll views")가 발생한다.
        Expanded(
          child: SingleChildScrollView(
            controller: _dataScrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: _totalContentWidth(),
              child: ListView.builder(
                itemCount: widget.rows.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (int i = 0; i < widget.columns.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            SizedBox(
                              width: _columnWidth(widget.columns[i].key),
                              child: widget.rows[index][i],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // 푸터 (합계 행 등, 선택사항)
        if (widget.footerWidget != null) widget.footerWidget!,
      ],
    );
  }

  Widget _buildHeaderCell(TableColumnDef col) {
    final isSorted = widget.sortColumn == col.key;
    final colWidth = _columnWidth(col.key);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 헤더 텍스트 (정확히 colWidth만 차지)
        SizedBox(
          width: colWidth,
          child: col.sortable
              ? InkWell(
                  onTap: () {
                    if (widget.onSort != null) {
                      widget.onSort!(col.key, isSorted ? !widget.sortAscending : false);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          col.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isSorted ? widget.headerColor : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSorted)
                        Icon(
                          widget.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: widget.headerColor,
                        ),
                    ],
                  ),
                )
              : Text(
                  col.label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        // 리사이즈 핸들 (Stack 오버레이 — 레이아웃 너비에 영향 없음)
        Positioned(
          right: -7,
          top: 0,
          bottom: 0,
          child: _TableResizeHandle(
            key: ValueKey('resize_${col.key}'),
            columnKey: col.key,
            currentWidth: colWidth,
            minWidth: col.minWidth,
            maxWidth: col.maxWidth,
            onResize: (w) => widget.onColumnResize(col.key, w),
          ),
        ),
      ],
    );
  }
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
