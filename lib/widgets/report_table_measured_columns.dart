// Items/Ingresos measured-column StatefulWidget and its resize handle.
import 'package:flutter/material.dart';
import 'report_utils.dart';
import 'report_table_builder.dart';

/// Items/Ingresos 보고서용 StatefulWidget: DataTable의 실제 칼럼 너비를 측정하여 헤더와 푸터에 적용
class ItemsTableWithMeasuredColumns extends StatefulWidget {
  final List<String> keys;
  final List<DataColumn> columns;
  final Color color;
  final String? sortColumn;
  final bool sortAscending;
  final Function(int columnIndex, bool ascending)? onSort;
  final Map<String, double>? columnWidths;
  final List<dynamic> displayedList;
  final List<dynamic> dataList;
  final ReportType reportType;
  final Function(Map<String, dynamic>)? onRowDoubleTap;
  final Function(Map<String, dynamic>)? onRowTap;
  final String? unit;
  final ScrollController scrollController;
  final ScrollController? horizontalScrollController;
  final void Function(String columnKey, double newWidth)? onColumnResize;

  const ItemsTableWithMeasuredColumns({
    super.key,
    required this.keys,
    required this.columns,
    required this.color,
    this.sortColumn,
    this.sortAscending = true,
    this.onSort,
    this.columnWidths,
    required this.displayedList,
    required this.dataList,
    required this.reportType,
    this.onRowDoubleTap,
    this.onRowTap,
    this.unit,
    required this.scrollController,
    this.horizontalScrollController,
    this.onColumnResize,
  });

  @override
  State<ItemsTableWithMeasuredColumns> createState() => _ItemsTableWithMeasuredColumnsState();
}

class _ItemsTableWithMeasuredColumnsState extends State<ItemsTableWithMeasuredColumns> {
  Map<String, double>? _measuredColumnWidths;
  final GlobalKey _dataTableKey = GlobalKey();
  bool _hasMeasured = false; // 측정 완료 플래그 추가

  @override
  void initState() {
    super.initState();
    // 초기 칼럼 너비는 전달된 값 또는 기본값 사용
    _measuredColumnWidths = widget.columnWidths;
  }

  @override
  void didUpdateWidget(ItemsTableWithMeasuredColumns oldWidget) {
    super.didUpdateWidget(oldWidget);
    // unit이나 keys가 변경되면 측정값을 초기화하여 다시 측정하도록 함
    if (oldWidget.unit != widget.unit || 
        !_listEquals(oldWidget.keys, widget.keys) ||
        oldWidget.displayedList.length != widget.displayedList.length) {
      debugPrint('🔍 [report_table_builder.dart:4542] [didUpdateWidget] unit 또는 keys 변경 감지 - 측정값 초기화');
      debugPrint('   → 라인: 4542');
      debugPrint('   → oldWidget.unit: ${oldWidget.unit}');
      debugPrint('   → widget.unit: ${widget.unit}');
      debugPrint('   → oldWidget.keys: ${oldWidget.keys}');
      debugPrint('   → widget.keys: ${widget.keys}');
      debugPrint('   → oldWidget.displayedList.length: ${oldWidget.displayedList.length}');
      debugPrint('   → widget.displayedList.length: ${widget.displayedList.length}');
      print('🔍 [report_table_builder.dart:4542] [didUpdateWidget] unit 또는 keys 변경 감지 - 측정값 초기화');
      print('   → 라인: 4542');
      print('   → oldWidget.unit: ${oldWidget.unit}');
      print('   → widget.unit: ${widget.unit}');
      print('   → oldWidget.keys: ${oldWidget.keys}');
      print('   → widget.keys: ${widget.keys}');
      print('   → oldWidget.displayedList.length: ${oldWidget.displayedList.length}');
      print('   → widget.displayedList.length: ${widget.displayedList.length}');
      _measuredColumnWidths = null;
      _hasMeasured = false;
    }
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _measureColumnWidths() {
    // 이미 측정이 완료되었으면 다시 측정하지 않음
    if (_hasMeasured) {
      debugPrint('   → [report_table_builder.dart:4574] [측정] 이미 측정 완료됨. 재측정 건너뜀');
      debugPrint('      → 라인: 4574');
      return;
    }
    
    final RenderBox? renderBox = _dataTableKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // DataTable의 RenderTable 찾기
    RenderBox? tableBox;
    void findTable(RenderBox? box, int depth) {
      if (box == null || depth > 5) return;
      if (box.runtimeType.toString().contains('RenderTable')) {
        tableBox = box;
        return;
      }
      box.visitChildren((child) {
        if (child is RenderBox) {
          findTable(child, depth + 1);
        }
      });
    }
    findTable(renderBox, 0);

    if (tableBox == null) return;

    // RenderTable의 자식들을 직접 순회하여 첫 번째 데이터 행의 칼럼 너비 측정
    // 로그를 보면 RenderTable의 자식들이 RenderSemanticsAnnotations로 나타나고,
    // 헤더 행은 height=0.0, 데이터 행은 height=37.0입니다.
    // 각 행은 keys.length개의 칼럼을 가지고 있습니다.
    final measuredWidths = <String, double>{};
    final tableChildren = <RenderBox>[];
    tableBox!.visitChildren((child) {
      if (child is RenderBox) {
        tableChildren.add(child);
      }
    });

    // 첫 번째 데이터 행 찾기 (height > 0인 첫 번째 행)
    int dataRowStartIndex = -1;
    for (int i = 0; i < tableChildren.length; i++) {
      if (tableChildren[i].size.height > 0) {
        dataRowStartIndex = i;
        break;
      }
    }

    if (dataRowStartIndex == -1 || dataRowStartIndex + widget.keys.length > tableChildren.length) {
      debugPrint('   ⚠️ [report_table_builder.dart:4621] [측정] 첫 번째 데이터 행을 찾을 수 없습니다');
      debugPrint('      → 라인: 4621');
      debugPrint('      → dataRowStartIndex: $dataRowStartIndex');
      debugPrint('      → widget.keys.length: ${widget.keys.length}');
      debugPrint('      → tableChildren.length: ${tableChildren.length}');
      return;
    }

    // 기본 칼럼 너비 (최대값 제한용)
    // ventas day/month/year 유닛의 경우 기본 칼럼 너비를 포함
    final isVentasDayMonthYear = widget.reportType == ReportType.ventas && 
                                 widget.unit != null && 
                                 widget.unit != 'vcode';
    
    final defaultColumnWidths = widget.columnWidths ?? <String, double>{
      'codigo1': 300,  // 200 * 1.5 (items/ingresos 50% 더 넓게)
      'desc1': 300,
      'ProductName': 450,  // ProductName 칼럼 너비 유지
      'totalCantidad': 195,  // 150 * 1.3 (30% 넓게)
      'CategoryCode': 180,  // 120 * 1.5
      'CompanyCode': 180,  // 120 * 1.5
      'tprendas': 120,
      'timporte': 150,
      // Ventas 보고서 - day/month/year 유닛용 칼럼 너비
      // 큰 숫자를 표시하기 위해 기본값을 크게 설정
      'eventcount': 200, 'eventCount': 200,  // 큰 숫자 표시를 위해 100 -> 200으로 증가
      'tvents': 250, 'tVents': 250,  // 큰 숫자 표시를 위해 120 -> 250으로 증가
      'tventas': 250, 'tVentas': 250,  // 큰 숫자 표시를 위해 120 -> 250으로 증가
      'tcntropas': 200, 'tCntRopas': 200,  // 큰 숫자 표시를 위해 120 -> 200으로 증가
      'tefectivo': 306, 'tcredito': 306, 'tbanco': 306,  // 180 * 1.7 (70% 증가)
      'treservado': 306, 'tfavor': 255,  // 180 * 1.7, 150 * 1.7 (70% 증가)
      'month': 204, 'year': 204,  // 120 * 1.7 (70% 증가)
      'nencargado': 204,  // 120 * 1.7 (70% 증가)
      'fecha': 255,  // 150 * 1.7 (70% 증가)
      'sucursal': 136,  // 80 * 1.7 (70% 증가)
    };
    
    // month 유닛인 경우 tefectivo, tcredito, tbanco 칼럼 너비를 30% 증가
    final isMonthUnitForMeasured = widget.unit == 'month';
    if (isMonthUnitForMeasured) {
      defaultColumnWidths['tefectivo'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
      defaultColumnWidths['tcredito'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
      defaultColumnWidths['tbanco'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
      debugPrint('📊 [측정 칼럼] month 유닛: tefectivo, tcredito, tbanco 칼럼 너비 30% 증가 (306 -> 398)');
    }
    
    // 칼럼별 최대 너비 제한
    final maxColumnWidths = <String, double>{};
    for (final key in widget.keys) {
      final keyLower = key.toLowerCase();
      // ventas day/month/year 유닛의 경우 대소문자 변형도 고려
      final defaultWidth = defaultColumnWidths[key] ?? 
                          defaultColumnWidths[keyLower] ??
                          (keyLower == 'eventcount' ? defaultColumnWidths['eventCount'] : null) ??
                          (keyLower == 'tvents' ? defaultColumnWidths['tVents'] : null) ??
                          (keyLower == 'tventas' ? defaultColumnWidths['tVentas'] : null) ??
                          (keyLower == 'tcntropas' ? defaultColumnWidths['tCntRopas'] : null) ??
                          150.0;
      // ProductName은 기본값을 유지하거나 최대 500px로 제한
      if (key == 'ProductName') {
        maxColumnWidths[key] = 500.0;
      } else {
        // 다른 칼럼은 기본값의 1.3배를 최대값으로 설정
        // ventas day/month/year 유닛의 경우 측정값을 그대로 사용하므로 최대값을 크게 설정
        maxColumnWidths[key] = isVentasDayMonthYear ? (defaultWidth * 2.0) : (defaultWidth * 1.3);
      }
    }
    
    // 첫 번째 데이터 행의 각 칼럼 너비 측정
    for (int i = 0; i < widget.keys.length; i++) {
      final cellBox = tableChildren[dataRowStartIndex + i];
      final key = widget.keys[i];
      final keyLower = key.toLowerCase();
      final measuredWidth = cellBox.size.width;
      
      // ProductName은 측정값을 사용하지 않고 항상 기본값 사용
      // ventas day/month/year 유닛의 경우 대소문자 변형도 고려
      final defaultWidth = defaultColumnWidths[key] ?? 
                          defaultColumnWidths[keyLower] ??
                          (keyLower == 'eventcount' ? defaultColumnWidths['eventCount'] : null) ??
                          (keyLower == 'tvents' ? defaultColumnWidths['tVents'] : null) ??
                          (keyLower == 'tventas' ? defaultColumnWidths['tVentas'] : null) ??
                          (keyLower == 'tcntropas' ? defaultColumnWidths['tCntRopas'] : null) ??
                          150.0;
      final maxWidth = maxColumnWidths[key] ?? 
                      maxColumnWidths[keyLower] ??
                      (defaultWidth * 1.3);
      
      double finalWidth;
      if (key == 'ProductName') {
        // ProductName은 항상 기본값(450px) 사용 (측정값 무시)
        finalWidth = defaultWidth;
      } else {
        // 다른 칼럼은 측정값이 최대값을 초과하면 기본값 사용
        // ventas day/month/year 유닛의 경우 측정값을 그대로 사용 (DataTable이 자동으로 계산한 실제 너비)
        finalWidth = measuredWidth > maxWidth ? defaultWidth : measuredWidth;
      }
      
      measuredWidths[key] = finalWidth;
      debugPrint('   → [report_table_builder.dart:4706] [측정] 칼럼 #$i: key="$key", 측정 width=$measuredWidth, 최종 width=$finalWidth (기본: $defaultWidth, 최대: $maxWidth, ventasDayMonthYear: $isVentasDayMonthYear)');
      debugPrint('      → 라인: 4706');
    }

    // 측정된 칼럼 너비가 있고, 이전 값과 다를 때만 상태 업데이트 (무한 루프 방지)
    if (measuredWidths.isNotEmpty && measuredWidths.length == widget.keys.length) {
      bool hasChanged = false;
      if (_measuredColumnWidths == null) {
        hasChanged = true;
      } else {
        for (final key in widget.keys) {
          final oldWidth = _measuredColumnWidths![key] ?? 0.0;
          final newWidth = measuredWidths[key] ?? 0.0;
          // 1픽셀 이상 차이가 있을 때만 변경으로 간주 (작은 변화 무시)
          if ((oldWidth - newWidth).abs() > 1.0) {
            hasChanged = true;
            break;
          }
        }
      }
      
      if (hasChanged) {
        // ProductName은 측정 결과에서 제외하고 항상 기본값 사용
        final defaultColumnWidths = widget.columnWidths ?? <String, double>{
          'ProductName': 450,
        };
        final finalMeasuredWidths = Map<String, double>.from(measuredWidths);
        // ProductName이 있으면 기본값으로 교체
        if (finalMeasuredWidths.containsKey('ProductName')) {
          finalMeasuredWidths['ProductName'] = defaultColumnWidths['ProductName'] ?? 450.0;
        }
        
        setState(() {
          _measuredColumnWidths = finalMeasuredWidths;
          _hasMeasured = true; // 측정 완료 표시
        });
        debugPrint('   → [report_table_builder.dart:4741] [측정 완료] 칼럼 너비: $finalMeasuredWidths (ProductName은 기본값 사용)');
        debugPrint('      → 라인: 4741');
        print('   → [report_table_builder.dart:4741] [측정 완료] 칼럼 너비: $finalMeasuredWidths (ProductName은 기본값 사용)');
        print('      → 라인: 4741');
      } else {
        // 변경이 없어도 측정은 완료된 것으로 간주
        _hasMeasured = true;
        debugPrint('   → [report_table_builder.dart:4745] [측정] 칼럼 너비 변경 없음 (무시, 측정 완료)');
        debugPrint('      → 라인: 4745');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [큰 화면 디버깅] _ItemsTableWithMeasuredColumns build 시작');
        debugPrint('   → reportType: ${widget.reportType}');
        debugPrint('   → displayedList.length: ${widget.displayedList.length}');
        debugPrint('   → dataList.length: ${widget.dataList.length}');
        debugPrint('   → keys.length: ${widget.keys.length}');
        debugPrint('   → scrollController: ${widget.scrollController != null}');
        debugPrint('   → horizontalScrollController: ${widget.horizontalScrollController != null}');
        debugPrint('   → sortColumn: ${widget.sortColumn}');
        debugPrint('   → sortAscending: ${widget.sortAscending}');
        debugPrint('   → onSort != null: ${widget.onSort != null}');
        debugPrint('   → columns.length: ${widget.columns.length}');
        
        // 각 칼럼의 정렬 기능 확인
        debugPrint('   → [정렬 기능 확인] 각 칼럼의 onSort 상태:');
        for (int i = 0; i < widget.columns.length; i++) {
          final column = widget.columns[i];
          final key = i < widget.keys.length ? widget.keys[i] : 'unknown';
          final hasOnSort = column.onSort != null;
          final isSorted = widget.sortColumn == key;
          debugPrint('      칼럼 #$i ($key): onSort=${hasOnSort ? "있음 ✅" : "없음 ❌"}, isSorted=$isSorted');
        }
        // items/ingresos 칼럼 정렬 디버깅: 테이블마다 한 번씩 헤더·데이터 실제 렌더 값 로깅을 위해 카운터·리스트 리셋
        ReportTableBuilder.alignmentHeaderLoggedCount = 0;
        ReportTableBuilder.alignmentDataLoggedCount = 0;
        ReportTableBuilder.alignmentHeaderDebugList.clear();
        ReportTableBuilder.alignmentDataDebugList.clear();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        debugPrint('🔍 [큰 화면 디버깅] LayoutBuilder constraints');
        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
        debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
        debugPrint('   → constraints.minWidth: ${constraints.minWidth}');
        debugPrint('   → constraints.minHeight: ${constraints.minHeight}');
        
        // 기본 칼럼 너비 정의 (ventas day/month/year 유닛용)
        // 헤더와 행 모두 동일한 고정 픽셀 값 사용 (70% 증가: 1.7배)
        final baseDefaultColumnWidths = <String, double>{
          'ProductName': 382.5,  // 225 * 1.7
          'eventcount': 127.5, 'eventCount': 127.5,  // 75 * 1.7
          'tvents': 153, 'tVents': 153,  // 90 * 1.7
          'tventas': 153, 'tVentas': 153,  // 90 * 1.7
          'tcntropas': 127.5, 'tCntRopas': 127.5,  // 75 * 1.7
          'tefectivo': 102, 'tcredito': 102, 'tbanco': 102,  // 60 * 1.7
          'treservado': 102, 'tfavor': 85,  // 60 * 1.7, 50 * 1.7
          'month': 85, 'year': 85,  // 50 * 1.7
          'fecha': 102,  // 60 * 1.7
          'sucursal': 51,  // 30 * 1.7
        };
        
        // month 유닛인 경우 tefectivo, tcredito, tbanco 칼럼 너비를 30% 증가
        final isMonthUnitForLargeScreen = widget.unit == 'month';
        if (isMonthUnitForLargeScreen) {
          baseDefaultColumnWidths['tefectivo'] = (102 * 1.3).roundToDouble(); // 102 * 1.3 = 133
          baseDefaultColumnWidths['tcredito'] = (102 * 1.3).roundToDouble(); // 102 * 1.3 = 133
          baseDefaultColumnWidths['tbanco'] = (102 * 1.3).roundToDouble(); // 102 * 1.3 = 133
          debugPrint('📊 [큰 화면] month 유닛: tefectivo, tcredito, tbanco 칼럼 너비 30% 증가 (102 -> 133)');
        }
        
        // ProductName은 항상 기본값 사용하도록 보장
        final defaultColumnWidths = widget.columnWidths ?? <String, double>{
          'ProductName': 225,
        };
        
        // ventas day/month/year 유닛인 경우 고정 픽셀 값 사용 (x 2 없이)
        final isVentasDayMonthYearForAdjustment = widget.reportType == ReportType.ventas && 
                                                   widget.unit != null && 
                                                   (widget.unit == 'day' || widget.unit == 'month' || widget.unit == 'year');
        
        debugPrint('🔍 [report_table_builder.dart:4979] 칼럼 너비 계산 (고정 픽셀 값 사용)');
        debugPrint('   → 라인: 4979');
        debugPrint('   → widget.reportType: ${widget.reportType}');
        debugPrint('   → widget.unit: ${widget.unit}');
        debugPrint('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        debugPrint('   → _measuredColumnWidths != null: ${_measuredColumnWidths != null}');
        print('🔍 [report_table_builder.dart:4979] 칼럼 너비 계산 (고정 픽셀 값 사용)');
        print('   → 라인: 4979');
        print('   → widget.reportType: ${widget.reportType}');
        print('   → widget.unit: ${widget.unit}');
        print('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        print('   → _measuredColumnWidths != null: ${_measuredColumnWidths != null}');
        
        // 최종 칼럼 너비 계산 (헤더와 데이터 테이블 모두 동일한 고정 픽셀 값 사용)
        Map<String, double> columnWidthsForHeader;
        
        if (isVentasDayMonthYearForAdjustment) {
          // ventas day/month/year 유닛인 경우 고정 픽셀 값 사용 (x 2 없이)
          final fixedWidths = <String, double>{};
          for (final key in widget.keys) {
            final keyLower = key.toLowerCase();
            final fixedWidth = baseDefaultColumnWidths[key] ?? 
                            baseDefaultColumnWidths[keyLower] ??
                            (keyLower == 'eventcount' ? baseDefaultColumnWidths['eventCount'] : null) ??
                            (keyLower == 'tvents' ? baseDefaultColumnWidths['tVents'] : null) ??
                            (keyLower == 'tventas' ? baseDefaultColumnWidths['tVentas'] : null) ??
                            (keyLower == 'tcntropas' ? baseDefaultColumnWidths['tCntRopas'] : null) ??
                            75.0;  // 기본값도 절반으로 줄임 (150 -> 75)
            
            fixedWidths[key] = fixedWidth;
            
            debugPrint('🔍 [report_table_builder.dart:5005] 고정 칼럼 너비 설정: key=$key, width=$fixedWidth');
            debugPrint('   → 라인: 5005');
            print('🔍 [report_table_builder.dart:5005] 고정 칼럼 너비 설정: key=$key, width=$fixedWidth');
            print('   → 라인: 5005');
          }
          columnWidthsForHeader = fixedWidths;
        } else {
          // 다른 보고서는 측정값 또는 기본값 사용
          debugPrint('🔍 [report_table_builder.dart:5011] 측정값 또는 기본값 사용');
          debugPrint('   → 라인: 5011');
          debugPrint('   → _measuredColumnWidths != null: ${_measuredColumnWidths != null}');
          debugPrint('   → widget.columnWidths != null: ${widget.columnWidths != null}');
          print('🔍 [report_table_builder.dart:5011] 측정값 또는 기본값 사용');
          print('   → 라인: 5011');
          print('   → _measuredColumnWidths != null: ${_measuredColumnWidths != null}');
          print('   → widget.columnWidths != null: ${widget.columnWidths != null}');
          columnWidthsForHeader = _measuredColumnWidths != null
              ? Map<String, double>.from(_measuredColumnWidths!)
              : Map<String, double>.from(widget.columnWidths ?? {});
        }
        
        // ProductName이 있으면 항상 기본값으로 교체
        columnWidthsForHeader['ProductName'] = baseDefaultColumnWidths['ProductName'] ?? 225.0;
        
        // 디버깅 정보 출력
        if (isVentasDayMonthYearForAdjustment) {
          debugPrint('🔍 [ventas day/month/year 고정 칼럼 너비]');
          debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYearForAdjustment');
          debugPrint('   → 고정 칼럼 너비: $columnWidthsForHeader');
          debugPrint('   → 각 키별 상세:');
          for (final key in widget.keys) {
            final fixedWidth = columnWidthsForHeader[key];
            debugPrint('     → $key: fixedWidth=$fixedWidth');
          }
          print('🔍 [ventas day/month/year 고정 칼럼 너비]');
          print('   → 고정 칼럼 너비: $columnWidthsForHeader');
        }
        
        debugPrint('   → 최종 columnWidthsForHeader: $columnWidthsForHeader');
        
        // constraints.maxWidth가 Infinity인 경우 ConstrainedBox를 사용하지 않음
        final hasValidWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0;
        // constraints.maxHeight가 bounded인지 확인 (Expanded 사용 가능 여부)
        final hasBoundedHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0;
        // 큰 화면인지 확인 (너비가 800 이상이면 큰 화면으로 간주)
        final isLargeScreen = constraints.maxWidth.isFinite && constraints.maxWidth >= 800;
        
        // 헤더와 푸터는 측정된 칼럼 너비 사용 (ProductName은 항상 기본값)
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [_ItemsTableWithMeasuredColumns] buildHeaderRow 호출 전');
        debugPrint('   → widget.keys: ${widget.keys}');
        debugPrint('   → widget.columns.length: ${widget.columns.length}');
        debugPrint('   → widget.sortColumn: ${widget.sortColumn}');
        debugPrint('   → widget.sortAscending: ${widget.sortAscending}');
        debugPrint('   → widget.onSort != null: ${widget.onSort != null}');
        debugPrint('   → columnWidthsForHeader: $columnWidthsForHeader');
        debugPrint('   → isLargeScreen: $isLargeScreen');
        
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [헤더 호출 전] 칼럼 너비 확인');
        debugPrint('   → columnWidthsForHeader: $columnWidthsForHeader');
        debugPrint('   → _measuredColumnWidths: $_measuredColumnWidths');
        debugPrint('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        debugPrint('   → useMeasuredWidths: ${_measuredColumnWidths != null}');
        debugPrint('   → widget.keys: ${widget.keys}');
        debugPrint('   → 각 키별 칼럼 너비:');
        for (final key in widget.keys) {
          final headerWidth = columnWidthsForHeader[key];
          final measuredWidth = _measuredColumnWidths?[key];
          debugPrint('     → $key: headerWidth=$headerWidth, measuredWidth=$measuredWidth');
        }
        debugPrint('═══════════════════════════════════════════════════════');
        
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [report_table_builder.dart:5072] 헤더와 데이터 행 칼럼 너비 일치 확인');
        debugPrint('   → 라인: 5072');
        debugPrint('   → columnWidthsForHeader (헤더에 전달될 값): $columnWidthsForHeader');
        debugPrint('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        debugPrint('   → useMeasuredWidths: ${_measuredColumnWidths != null}');
        debugPrint('   → 각 키별 헤더 칼럼 너비:');
        for (final key in widget.keys) {
          final headerWidth = columnWidthsForHeader[key];
          debugPrint('     → $key: $headerWidth');
        }
        debugPrint('   → ⚠️ [중요] 이 columnWidthsForHeader가 buildHeaderRow와 buildDataTable 모두에 전달됨');
        debugPrint('   → ⚠️ [중요] buildHeaderRow와 buildDataTable에서 동일한 columnWidths를 사용하는지 확인 필요');
        debugPrint('═══════════════════════════════════════════════════════');
        print('🔍 [report_table_builder.dart:5072] 헤더와 데이터 행 칼럼 너비 일치 확인');
        print('   → 라인: 5072');
        print('   → columnWidthsForHeader: $columnWidthsForHeader');
        print('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        print('   → useMeasuredWidths: ${_measuredColumnWidths != null}');
        
        // ventas day/month/year 유닛인 경우 고정 픽셀 값을 사용하므로 useMeasuredWidths를 false로 설정
        // (고정 픽셀 값에 padding이 추가되어야 하므로)
        final useMeasuredWidthsForHeader = isVentasDayMonthYearForAdjustment 
            ? false  // 고정 픽셀 값 사용 시 padding 추가 필요
            : (_measuredColumnWidths != null);  // 다른 보고서는 측정값 사용
        
        debugPrint('🔍 [report_table_builder.dart:5106] useMeasuredWidthsForHeader 설정');
        debugPrint('   → 라인: 5106');
        debugPrint('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        debugPrint('   → _measuredColumnWidths != null: ${_measuredColumnWidths != null}');
        debugPrint('   → useMeasuredWidthsForHeader: $useMeasuredWidthsForHeader');
        print('🔍 [report_table_builder.dart:5106] useMeasuredWidthsForHeader 설정');
        print('   → 라인: 5106');
        print('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        print('   → useMeasuredWidthsForHeader: $useMeasuredWidthsForHeader');
        
        final isItemsOrIngresosTable = widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos;
        final useCustomHeaderWithResize = isItemsOrIngresosTable && widget.onColumnResize != null;
        final headerRow = isItemsOrIngresosTable && !useCustomHeaderWithResize
            ? null  // items/ingresos는 DataTable 기본 헤더 사용 → 별도 헤더 미생성
            : ReportTableBuilder.buildHeaderRow(
                widget.keys,
                widget.columns,
                widget.color,
                widget.sortColumn,
                widget.sortAscending,
                widget.onSort,
                columnWidths: columnWidthsForHeader,
                reportType: widget.reportType,
                unit: widget.unit,
                useMeasuredWidths: useMeasuredWidthsForHeader,
                isLargeScreen: isLargeScreen,
                onColumnResize: widget.onColumnResize,
              );
        
        debugPrint('🔍 [_ItemsTableWithMeasuredColumns] buildHeaderRow 호출 후 (items/ingresos면 null)');
        debugPrint('   → headerRow != null: ${headerRow != null}');
        debugPrint('   → ⚠️ [중복 확인] DataTable의 headingRowHeight가 0이어야 함');
        debugPrint('   → ⚠️ [정렬 확인] headerRow의 각 칼럼이 column.onSort를 사용해야 함');
        debugPrint('═══════════════════════════════════════════════════════');
        
        // MediaQuery를 사용하여 화면 높이 확인 (footer 고정을 위해)
        // 단, constraints.maxHeight가 bounded이면 그것을 우선 사용 (resumen이 있을 때 패널 높이 사용)
        final mediaQuery = MediaQuery.of(context);
        final screenHeight = mediaQuery.size.height;
        final availableHeight = screenHeight - mediaQuery.padding.top - mediaQuery.padding.bottom;
        
        // 오버랩 디버깅: 화면 너비와 테이블 총 너비 비교
        double totalTableWidth = 0.0;
        for (int i = 0; i < widget.keys.length; i++) {
          final key = widget.keys[i];
          final columnWidth = columnWidthsForHeader[key] ?? 150.0;
          totalTableWidth += columnWidth;
          if (i < widget.keys.length - 1) {
            totalTableWidth += 8; // columnSpacing
          }
        }
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [오버랩 디버깅] _ItemsTableWithMeasuredColumns build');
        debugPrint('   → 화면 너비 (constraints.maxWidth): ${constraints.maxWidth}');
        debugPrint('   → 테이블 총 너비 (계산): $totalTableWidth');
        debugPrint('   → 칼럼 개수: ${widget.keys.length}');
        debugPrint('   → 각 칼럼 너비:');
        double cumulativeX = 0.0;
        for (int i = 0; i < widget.keys.length; i++) {
          final key = widget.keys[i];
          final columnWidth = columnWidthsForHeader[key] ?? 150.0;
          debugPrint('      칼럼 #$i ($key): width=$columnWidth, x=$cumulativeX');
          cumulativeX += columnWidth;
          if (i < widget.keys.length - 1) {
            cumulativeX += 8; // columnSpacing
          }
        }
        if (hasValidWidth) { // if: hasValidWidth
          final overflow = totalTableWidth - constraints.maxWidth;
          if (overflow > 0) { // if: overflow > 0
            debugPrint('   ⚠️ 오버랩 발생! 테이블이 화면보다 ${overflow.toStringAsFixed(1)}px 더 넓음');
            debugPrint('   → 오버랩 비율: ${(overflow / constraints.maxWidth * 100).toStringAsFixed(1)}%');
          } else { // if (overflow > 0) - else
            debugPrint('   ✅ 오버랩 없음. 여유 공간: ${(-overflow).toStringAsFixed(1)}px');
          } // if (overflow > 0) - else 끝
        } else { // if (hasValidWidth) - else
          debugPrint('   ⚠️ 화면 너비가 unbounded (Infinity)');
        } // if (hasValidWidth) - else 끝
        debugPrint('═══════════════════════════════════════════════════════');
        
        // 테이블 내용 위젯 생성
        // hasBoundedHeight가 true이면 수직 스크롤 포함 (데스크톱/패널)
        // false이면 수직 스크롤 제거 (모바일, 부모의 SingleChildScrollView가 처리)
        final tableContent = Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _measureColumnWidths();
            });
            
            // tableContent 내부에서도 isLargeScreen을 계산 (Builder 내부이므로 constraints에 직접 접근 불가)
            final screenWidth = MediaQuery.of(context).size.width;
            final isLargeScreenForTable = screenWidth >= 800;
            
            final dataTable = Builder(
              key: _dataTableKey,
              builder: (context) {
                debugPrint('═══════════════════════════════════════════════════════');
                debugPrint('🔍 [_ItemsTableWithMeasuredColumns] buildDataTable 호출 전');
                debugPrint('   → widget.reportType: ${widget.reportType}');
                debugPrint('   → widget.columns.length: ${widget.columns.length}');
                debugPrint('   → ⚠️ [중복 확인] buildDataTable 내부에서 headingRowHeight가 0인지 확인 필요');
                debugPrint('   → ⚠️ [정렬 확인] buildDataTable에서 sortColumn/sortAscending이 null/false로 하드코딩되어 있는지 확인 필요');
                debugPrint('🔍 [_ItemsTableWithMeasuredColumns] buildDataTable 호출 - 정렬 파라미터 전달');
                debugPrint('   → widget.sortColumn: ${widget.sortColumn}');
                debugPrint('   → widget.sortAscending: ${widget.sortAscending}');
                debugPrint('   → ⚠️ [해결] sortColumn과 sortAscending을 buildDataTable에 전달');
                debugPrint('   → isLargeScreenForTable: $isLargeScreenForTable (칼럼 간격 조정용)');
                
                debugPrint('═══════════════════════════════════════════════════════');
                debugPrint('🔍 [report_table_builder.dart:5200] buildDataTable 호출 전 - 칼럼 너비 확인');
                debugPrint('   → 라인: 5200');
                debugPrint('   → columnWidthsForHeader (데이터 행에 전달될 값): $columnWidthsForHeader');
                debugPrint('   → _measuredColumnWidths: $_measuredColumnWidths');
                debugPrint('   → isLargeScreenForTable: $isLargeScreenForTable');
                debugPrint('   → widget.reportType: ${widget.reportType}');
                debugPrint('   → widget.unit: ${widget.unit}');
                debugPrint('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
                debugPrint('   → useMeasuredWidths: ${_measuredColumnWidths != null}');
                debugPrint('   → 각 키별 칼럼 너비 (헤더와 데이터 행이 동일해야 함):');
                for (final key in widget.keys) {
                  final headerWidth = columnWidthsForHeader[key];
                  final measuredWidth = _measuredColumnWidths?[key];
                  debugPrint('     → $key: headerWidth=$headerWidth, measuredWidth=$measuredWidth');
                }
                debugPrint('   → ⚠️ [중요] columnWidthsForHeader가 buildDataTable의 columnWidths 파라미터로 전달됨');
                debugPrint('   → ⚠️ [중요] buildDataTable 내부에서 _buildDataRowFromMap에 columnWidths 전달 확인 필요');
                debugPrint('   → ⚠️ [매칭 확인] 헤더와 데이터 행이 동일한 columnWidths를 사용하는지 확인');
                debugPrint('   → ⚠️ [매칭 확인] 헤더의 headerSizedBoxWidth = 데이터 행의 실제 칼럼 너비 (finalCellWidth + padding)');
                debugPrint('═══════════════════════════════════════════════════════');
                print('🔍 [report_table_builder.dart:5200] buildDataTable 호출 전 - 칼럼 너비 확인');
                print('   → 라인: 5200');
                print('   → columnWidthsForHeader: $columnWidthsForHeader');
                print('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
                print('   → useMeasuredWidths: ${_measuredColumnWidths != null}');
                
                // ventas day/month/year 유닛인 경우 고정 픽셀 값을 사용하므로 useMeasuredWidths를 false로 설정
                // (헤더와 동일하게 설정)
                final useMeasuredWidthsForData = isVentasDayMonthYearForAdjustment 
                    ? false  // 고정 픽셀 값 사용 시 padding 추가 필요
                    : (_measuredColumnWidths != null);  // 다른 보고서는 측정값 사용
                
                debugPrint('🔍 [report_table_builder.dart:5226] useMeasuredWidthsForData 설정');
                debugPrint('   → 라인: 5226');
                debugPrint('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
                debugPrint('   → _measuredColumnWidths != null: ${_measuredColumnWidths != null}');
                debugPrint('   → useMeasuredWidthsForData: $useMeasuredWidthsForData');
                print('🔍 [report_table_builder.dart:5226] useMeasuredWidthsForData 설정');
                print('   → 라인: 5226');
                print('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
                print('   → useMeasuredWidthsForData: $useMeasuredWidthsForData');
                
                // 헤더와 DataTable 열 너비 강제: items/ingresos에서 columnWidths가 있으면 DataColumn에 FixedColumnWidth 적용 (products 포함)
                List<DataColumn> columnsToUse = widget.columns;
                final isItemsOrIngresosTable = widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos;
                if (isItemsOrIngresosTable && columnWidthsForHeader.isNotEmpty) {
                  columnsToUse = [];
                  final fixedWidths = <String, double>{};
                  for (int i = 0; i < widget.columns.length; i++) {
                    final key = i < widget.keys.length ? widget.keys[i] : null;
                    final keyLower = key?.toLowerCase();
                    final w = (key != null ? (columnWidthsForHeader[key] ??
                        columnWidthsForHeader[keyLower] ??
                        (keyLower == 'eventcount' ? columnWidthsForHeader['eventCount'] : null) ??
                        (keyLower == 'tvents' ? columnWidthsForHeader['tVents'] : null) ??
                        (keyLower == 'tventas' ? columnWidthsForHeader['tVentas'] : null) ??
                        (keyLower == 'tcntropas' ? columnWidthsForHeader['tCntRopas'] : null)) : null) ?? 100.0;
                    if (key != null) fixedWidths[key] = w;
                    final dc = widget.columns[i];
                    columnsToUse.add(DataColumn(
                      label: dc.label,
                      tooltip: dc.tooltip,
                      numeric: dc.numeric,
                      onSort: dc.onSort,
                      columnWidth: FixedColumnWidth(w),
                    ));
                  }
                  debugPrint('📐 [정렬디버그] FixedColumnWidth 적용됨 (앞 5칼럼): ${fixedWidths.entries.take(5).map((e) => '${e.key}=${e.value}').join(', ')}');
                } else if (isItemsOrIngresosTable) {
                  debugPrint('📐 [정렬디버그] FixedColumnWidth 미적용 (items/ingresos) columnWidthsEmpty=${columnWidthsForHeader.isEmpty}');
                }
                
                final table = ReportTableBuilder.buildDataTable(
                  reportType: widget.reportType,
                  displayedList: widget.displayedList,
                  keys: widget.keys,
                  columns: columnsToUse,
                  dataList: widget.dataList,
                  color: widget.color,
                  onRowDoubleTap: widget.onRowDoubleTap,
                  onRowTap: widget.onRowTap,
                  unit: widget.unit,
                  columnWidths: columnWidthsForHeader, // 헤더와 동일한 칼럼 너비 사용
                  sortColumn: widget.sortColumn,
                  sortAscending: widget.sortAscending,
                  isLargeScreen: isLargeScreenForTable,
                  useMeasuredWidths: useMeasuredWidthsForData,
                  hideHeadingRow: useCustomHeaderWithResize, // 커스텀 헤더(리사이즈) 사용 시 DataTable 헤더 숨김
                );
                
                debugPrint('═══════════════════════════════════════════════════════');
                debugPrint('🔍 [report_table_builder.dart:5136] buildDataTable 호출 후');
                debugPrint('   → 라인: 5136');
                debugPrint('   → table != null: ${table != null}');
                debugPrint('   → ⚠️ [확인 필요] buildDataTable 내부에서 columnWidths가 _buildDataRowFromMap에 제대로 전달되었는지 확인');
                debugPrint('═══════════════════════════════════════════════════════');
                
                debugPrint('🔍 [_ItemsTableWithMeasuredColumns] buildDataTable 호출 후');
                debugPrint('   → dataTable != null: ${table != null}');
                debugPrint('   → ⚠️ [중복 확인] DataTable의 headingRowHeight가 0이면 헤더가 표시되지 않음');
                debugPrint('   → ⚠️ [중복 확인] headingRowHeight가 0이 아니면 별도 헤더와 중복될 수 있음');
                debugPrint('═══════════════════════════════════════════════════════');
                
                return table;
              },
            );
            
            // 수평 스크롤은 전체 Column에서 처리하므로 여기서는 제거
            // bounded height일 때만 수직 스크롤 포함 (데스크톱/패널)
            if (hasBoundedHeight) {
              return Scrollbar(
                controller: widget.scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  scrollDirection: Axis.vertical,
                  child: dataTable,
                ),
              );
            } else { // if (hasBoundedHeight) - else: 모바일
              // 모바일: 수직 스크롤 없이 반환 (부모의 SingleChildScrollView가 처리)
              return dataTable;
            } // if (hasBoundedHeight) - else 끝
          },
        );
        
        // 푸터 위젯 생성
        final footer = ReportTableBuilder.buildFixedTotalRow(
          widget.keys,
          widget.displayedList,
          widget.color,
          columnWidths: columnWidthsForHeader,
          dataList: widget.dataList,
          reportType: widget.reportType,
          unit: widget.unit,
        );
        
        // 항상 footer를 화면/패널 하단에 고정하기 위해 높이 제약 사용
        // hasBoundedHeight가 true이면 constraints.maxHeight 사용 (resumen이 있을 때 패널 높이)
        // 아니면 MediaQuery의 availableHeight 사용 (전체 화면 높이)
        final effectiveMaxHeight = hasBoundedHeight 
            ? constraints.maxHeight // if: hasBoundedHeight
            : (availableHeight > 0 ? availableHeight : double.infinity); // else: hasBoundedHeight
        
        debugPrint('🔍 [Footer 고정] 높이 계산');
        debugPrint('   → hasBoundedHeight: $hasBoundedHeight');
        debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
        debugPrint('   → availableHeight: $availableHeight');
        debugPrint('   → effectiveMaxHeight: $effectiveMaxHeight');
        
        // ventas day/month/year 유닛인지 확인
        final isVentasDayMonthYear = widget.reportType == ReportType.ventas && 
                                     widget.unit != null && 
                                     widget.unit != 'vcode';
        
        // 전체를 하나의 수평 스크롤 컨테이너로 감싸서 헤더, 테이블, footer가 함께 스크롤되도록 함
        // SingleChildScrollView 안의 Column은 무한 너비를 받으므로 crossAxisAlignment를 start로 설정하고 명시적 너비 설정
        // ventas day/month/year 유닛의 경우 대형 화면에서 전체 너비 사용
        // items/ingresos는 테이블 너비만 사용 (기존 동작 유지)
        // 오버플로우 방지: 뷰포트가 유한하면 반드시 그 안으로 제한 (마지막 로그 기준)
        final viewportWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0 ? constraints.maxWidth : null;
        final effectiveWidth = isVentasDayMonthYear && isLargeScreen && hasValidWidth
            ? constraints.maxWidth
            : (totalTableWidth > 0 ? totalTableWidth : viewportWidth);
        
        debugPrint('🔍 [너비 설정] _ItemsTableWithMeasuredColumns (report_table_builder.dart)');
        debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
        debugPrint('   → isLargeScreen: $isLargeScreen');
        debugPrint('   → hasValidWidth: $hasValidWidth');
        debugPrint('   → totalTableWidth: $totalTableWidth');
        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
        debugPrint('   → effectiveWidth: $effectiveWidth');
        
        final columnContent = SizedBox(
          height: (effectiveMaxHeight.isFinite && effectiveMaxHeight > 0 && hasBoundedHeight) 
              ? effectiveMaxHeight 
              : null,
          width: effectiveWidth, // ventas day/month/year + 대형 화면: 전체 너비, 그 외: 테이블 너비
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 무한 너비 문제 해결
            mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // 헤더 (items/ingresos는 DataTable 기본 헤더 사용 → headerRow는 null)
              if (headerRow != null) headerRow,
              // 테이블 내용 (hasBoundedHeight일 때만 Expanded 사용)
              hasBoundedHeight
                  ? Expanded(child: tableContent)
                  : tableContent, // Expanded 없이 직접 표시
              // 푸터 (화면 하단에 고정)
              if (widget.horizontalScrollController != null)
                SingleChildScrollView(
                  controller: widget.horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: effectiveWidth ?? totalTableWidth, // ventas day/month/year + 대형 화면: 전체 너비
                    child: footer,
                  ),
                )
              else
                footer,
            ],
          ),
        );
        
        // 전체를 하나의 수평 스크롤 컨테이너로 감싸기 (헤더, 테이블, footer 동기화)
        // horizontalScrollController가 있으면 SingleChildScrollView 사용.
        // items/ingresos에서 테이블이 뷰포트보다 넓으면 오버플로우 방지를 위해 무조건 수평 스크롤 적용.
        final isItemsOrIngresos = widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos;
        final wouldOverflow = viewportWidth != null && totalTableWidth > viewportWidth;
        // 뷰포트가 있으면 항상 수평 스크롤 사용 → 오버플로우 방지
        final needsHorizontalScroll = widget.horizontalScrollController != null ||
            (viewportWidth != null && totalTableWidth > 0) ||
            wouldOverflow;
        
        debugPrint('🔍 [수평 스크롤] _ItemsTableWithMeasuredColumns (report_table_builder.dart)');
        debugPrint('   → needsHorizontalScroll: $needsHorizontalScroll');
        debugPrint('   → horizontalScrollController != null: ${widget.horizontalScrollController != null}');
        debugPrint('   → isItemsOrIngresos: $isItemsOrIngresos, wouldOverflow: $wouldOverflow');
        debugPrint('   → totalTableWidth > constraints.maxWidth: ${totalTableWidth > constraints.maxWidth}');
        
        final horizontallyScrollableContent = needsHorizontalScroll
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: widget.horizontalScrollController,
                child: columnContent,
              )
            : columnContent;
        
        debugPrint('🔍 [큰 화면 디버깅] 최종 위젯 구조');
        debugPrint('   → hasValidWidth: $hasValidWidth');
        debugPrint('   → hasBoundedHeight: $hasBoundedHeight');
        debugPrint('   → isLargeScreen: $isLargeScreen');
        debugPrint('   → effectiveMaxHeight: $effectiveMaxHeight');
        debugPrint('   → headerRow != null: ${headerRow != null}');
        debugPrint('   → footer != null: ${footer != null}');
        debugPrint('   → tableContent != null: ${tableContent != null}');
        debugPrint('   → horizontallyScrollableContent 타입: ${horizontallyScrollableContent.runtimeType}');
        
        // 오버플로우 방지: 뷰포트가 유한하면 무조건 maxWidth 제약 (마지막 로그 기준)
        final finalWidget = viewportWidth != null
            ? (isItemsOrIngresos
                ? ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: viewportWidth),
                    child: horizontallyScrollableContent,
                  )
                : (isVentasDayMonthYear && isLargeScreen
                    ? ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: viewportWidth,
                          maxWidth: viewportWidth,
                        ),
                        child: horizontallyScrollableContent,
                      )
                    : ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: viewportWidth),
                        child: horizontallyScrollableContent,
                      )))
            : horizontallyScrollableContent;
        
        debugPrint('   → finalWidget 타입: ${finalWidget.runtimeType}');
        debugPrint('═══════════════════════════════════════════════════════');
        
        // 오버플로우 시 예외 대신 클리핑 (뷰포트 있을 때만)
        if (viewportWidth != null) {
          return ClipRect(clipBehavior: Clip.hardEdge, child: finalWidget);
        }
        return finalWidget;
      },
    );
  }
}

/// ReportTable(Items/Ingresos) 칼럼 리사이즈 핸들
class ReportTableResizeHandle extends StatefulWidget {
  final String columnKey;
  final double currentWidth;
  final void Function(double newWidth) onResize;

  const ReportTableResizeHandle({
    super.key,
    required this.columnKey,
    required this.currentWidth,
    required this.onResize,
  });

  @override
  State<ReportTableResizeHandle> createState() => _ReportTableResizeHandleState();
}

class _ReportTableResizeHandleState extends State<ReportTableResizeHandle> {
  static const double _handleWidth = 14.0;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Arrastrar para ajustar ancho',
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            _initialWidth = widget.currentWidth;
            _initialPointerX = e.position.dx;
            _isDragging = true;
          },
          onPointerMove: (e) {
            if (!_isDragging) return;
            final totalDelta = e.position.dx - _initialPointerX;
            widget.onResize(_initialWidth + totalDelta);
          },
          onPointerUp: (_) => _isDragging = false,
          onPointerCancel: (_) => _isDragging = false,
          child: SizedBox(
            width: _handleWidth,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.25),
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

  double _initialWidth = 0;
  double _initialPointerX = 0;
  bool _isDragging = false;
}

