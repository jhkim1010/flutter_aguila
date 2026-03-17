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
