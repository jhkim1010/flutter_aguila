import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/platform_utils.dart';
import 'resizable_data_table.dart';

/// Items 보고서 UI 빌더
class ItemsBuilder {
  /// 칼럼 키 순서 (ResizableDataTable용 — start_date/end_date/sucursal 제외)
  static const List<String> itemsColumnKeys = [
    'codigo1', 'desc1', 'ProductName', 'totalCantidad',
    'CategoryCode', 'CompanyCode', 'tprendas', 'timporte',
  ];

  /// ResizableDataTable에 전달할 칼럼 정의 리스트.
  static List<TableColumnDef> buildColumnDefs() => [
    const TableColumnDef(key: 'codigo1',      label: 'Código',          defaultWidth: 300, sortable: true),
    const TableColumnDef(key: 'desc1',         label: 'Desc',             defaultWidth: 200, sortable: true),
    const TableColumnDef(key: 'ProductName',   label: 'Producto',         defaultWidth: 400, sortable: true),
    const TableColumnDef(key: 'totalCantidad', label: 'Total Cantidad',   defaultWidth: 156, textAlign: TextAlign.right, sortable: true),
    const TableColumnDef(key: 'CategoryCode',  label: 'Categoría',        defaultWidth: 150, sortable: true),
    const TableColumnDef(key: 'CompanyCode',   label: 'Empresa',          defaultWidth: 150, sortable: true),
    const TableColumnDef(key: 'tprendas',      label: 'T.Prendas',        defaultWidth: 100, textAlign: TextAlign.right),
    const TableColumnDef(key: 'timporte',      label: 'T.Importe',        defaultWidth: 120, textAlign: TextAlign.right),
  ];

  /// 데이터 리스트를 셀 위젯 리스트로 변환 (ResizableDataTable용).
  ///
  /// [columnKeys] 는 실제로 화면에 그려질 칼럼의 키 순서다. 셀은 반드시 이 목록에서
  /// 파생되어야 한다 — 셀 목록을 따로 하드코딩하면 칼럼이 데이터에 따라 늘거나 줄 때
  /// ResizableDataTable 의 `row.length == columns.length` assertion 이 깨진다.
  /// 생략하면 기본 칼럼 정의를 쓴다.
  static List<List<Widget>> buildRows(
    List<dynamic> data, {
    List<String>? columnKeys,
  }) {
    final keys = columnKeys ?? buildColumnDefs().map((c) => c.key).toList();
    return data
        .whereType<Map<String, dynamic>>()
        .map((item) => _buildRowCells(item, keys))
        .toList();
  }

  static List<Widget> _buildRowCells(
    Map<String, dynamic> item,
    List<String> keys,
  ) {
    return keys.map((key) => _buildRowCell(item, key)).toList();
  }

  /// 칼럼 키 하나에 대응하는 셀 위젯 생성
  static Widget _buildRowCell(Map<String, dynamic> item, String key) {
    final baseStyle = TextStyle(fontSize: 10, color: Colors.grey[700]);

    /// 콤마와 통화 기호를 걷어내고 천단위 구분 형식으로 되돌린다.
    String formatNumber(String field) {
      final raw = item[field]?.toString().replaceAll(',', '').replaceAll('\$', '');
      return NumberFormat('#,##0').format(num.tryParse(raw ?? '0') ?? 0);
    }

    switch (key) {
      case 'codigo1':
        return Text(
          item['codigo1']?.toString() ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

      case 'desc1':
      case 'ProductName':
        return Text(
          item[key]?.toString() ?? '',
          style: baseStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );

      case 'totalCantidad':
      case 'tprendas':
      case 'timporte':
        return Text(
          formatNumber(key),
          style: baseStyle,
          textAlign: TextAlign.right,
        );

      // CategoryCode / CompanyCode 및 서버가 새로 내려준 미지의 칼럼
      default:
        return Text(item[key]?.toString() ?? '', style: baseStyle);
    }
  }

  /// Items 콘텐츠 빌드 (화면 크기에 따라 적절한 레이아웃 선택)
  static Widget buildContent({
    required Map<String, dynamic> data,
    required BuildContext context,
    required ScrollController scrollController,
    required Function(String?, bool) onSort,
    String? sortColumn,
    bool sortAscending = true,
    String? filteringWord,
    int displayedItemsCount = 100,
    int itemsPerPage = 100,
    ScrollController? horizontalScrollController,
    Color? reportColor,
    String? selectedCategoryCode,
    Function(String?)? onCategorySelected,
    String? selectedColorCode,
    Function(String?)? onColorSelected,
    Map<String, double>? columnWidths,
    void Function(String columnKey, double newWidth)? onColumnResize,
  }) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [Items Builder] buildContent 시작');
    debugPrint('   → PlatformUtils.isDesktop(): ${PlatformUtils.isDesktop()}');
    debugPrint('   → PlatformUtils.isIPad(context): ${PlatformUtils.isIPad(context)}');
    debugPrint('   → MediaQuery.of(context).size: ${MediaQuery.of(context).size}');
    debugPrint('   → data.keys: ${data.keys.toList()}');
    debugPrint('   → selectedCategoryCode: $selectedCategoryCode');
    debugPrint('   → selectedColorCode: $selectedColorCode');
    
    // 공통 데이터 추출
    final extractedData = _extractCommonData(
      data: data,
      context: context,
      onSort: onSort,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
      filteringWord: filteringWord,
      displayedItemsCount: displayedItemsCount,
      itemsPerPage: itemsPerPage,
      scrollController: scrollController,
      horizontalScrollController: horizontalScrollController,
      reportColor: reportColor,
      selectedCategoryCode: selectedCategoryCode,
      onCategorySelected: onCategorySelected,
      selectedColorCode: selectedColorCode,
      onColorSelected: onColorSelected,
      columnWidths: columnWidths,
      onColumnResize: onColumnResize,
    );

    debugPrint('   → extractedData.summaryCard != null: ${extractedData.summaryCard != null}');
    debugPrint('   → extractedData.summaryByCompanyTable != null: ${extractedData.summaryByCompanyTable != null}');
    debugPrint('   → extractedData.summaryByCategoryTable != null: ${extractedData.summaryByCategoryTable != null}');
    debugPrint('   → extractedData.summaryByColorTable != null: ${extractedData.summaryByColorTable != null}');
    debugPrint('   → extractedData.productsTable != null: ${extractedData.productsTable != null}');

    // 화면 크기에 따라 적절한 레이아웃 선택
    if (PlatformUtils.isDesktop()) {
      // macOS, Windows 대형 화면
      debugPrint('   ✅ 대형 화면 레이아웃 선택: _buildContentForDesktop');
      return _buildContentForDesktop(extractedData);
    } else if (PlatformUtils.isIPad(context)) {
      // iPad 태블릿 화면
      debugPrint('   ✅ 태블릿 화면 레이아웃 선택: _buildContentForTablet');
      return _buildContentForTablet(extractedData);
    } else {
      // 모바일 화면
      debugPrint('   ✅ 모바일 화면 레이아웃 선택: _buildContentForMobile');
      return _buildContentForMobile(extractedData);
    }
  }

  /// 공통 데이터 추출 (재사용 가능한 헬퍼 함수)
  static _ExtractedData _extractCommonData({
    required Map<String, dynamic> data,
    required BuildContext context,
    required Function(String?, bool) onSort,
    String? sortColumn,
    bool sortAscending = true,
    String? filteringWord,
    int displayedItemsCount = 100,
    int itemsPerPage = 100,
    required ScrollController scrollController,
    ScrollController? horizontalScrollController,
    Color? reportColor,
    String? selectedCategoryCode,
    Function(String?)? onCategorySelected,
    String? selectedColorCode,
    Function(String?)? onColorSelected,
    Map<String, double>? columnWidths,
    void Function(String columnKey, double newWidth)? onColumnResize,
  }) {
    // summary 카드 (모바일 폰에서는 표시하지 않음)
    Widget? summaryCard;
    final platformType = PlatformUtils.getPlatformType(context);
    final isMobile = platformType == PlatformType.mobile;
    final isTablet = PlatformUtils.isIPad(context) || 
                     (platformType == PlatformType.mobile && MediaQuery.of(context).size.width >= 800);
    final isMobilePhone = isMobile && !isTablet;
    
    if (!isMobilePhone && data.containsKey('summary') && data['summary'] is Map) {
      summaryCard = _buildSummaryCard(data['summary'] as Map<String, dynamic>);
    }

    // summary_by_company 테이블
    Widget? summaryByCompanyTable;
    debugPrint('🔍 [Items Builder] summary_by_company 테이블 추출 시작');
    if (data.containsKey('data') && 
        data['data'] is Map &&
        (data['data'] as Map).containsKey('summary_by_company') &&
        (data['data'] as Map)['summary_by_company'] is List) {
      final summaryByCompanyList = (data['data'] as Map)['summary_by_company'] as List;
      debugPrint('   → summary_by_company 리스트 발견: length=${summaryByCompanyList.length}');
      // 데이터가 있을 때만 테이블 생성
      if (summaryByCompanyList.isNotEmpty) {
        summaryByCompanyTable = _buildSummaryByCompanyTable(
          summaryByCompanyList,
          context,
          onSort: onSort,
          sortColumn: sortColumn,
          sortAscending: sortAscending,
          reportColor: reportColor,
        );
        debugPrint('   → summaryByCompanyTable 생성됨');
      } else {
        debugPrint('   ⚠️ summary_by_company 리스트가 비어있음');
      }
    } else {
      debugPrint('   ⚠️ summary_by_company 데이터를 찾을 수 없음');
    }
    debugPrint('   → 최종 summaryByCompanyTable != null: ${summaryByCompanyTable != null}');

    // summary_by_category 테이블
    Widget? summaryByCategoryTable;
    debugPrint('🔍 [Items Builder] summary_by_category 테이블 추출 시작');
    if (data.containsKey('data') && 
        data['data'] is Map &&
        (data['data'] as Map).containsKey('summary_by_category') &&
        (data['data'] as Map)['summary_by_category'] is List) {
      final summaryByCategoryList = (data['data'] as Map)['summary_by_category'] as List;
      debugPrint('   → summary_by_category 리스트 발견: length=${summaryByCategoryList.length}');
      // 데이터가 있을 때만 테이블 생성
      if (summaryByCategoryList.isNotEmpty) {
        summaryByCategoryTable = _buildSummaryByCategoryTable(
          summaryByCategoryList,
          context,
          onSort: (categorySortColumn, categorySortAscending) {
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('🔍 [Items Builder] Category 테이블 onSort 콜백 호출');
            debugPrint('   → categorySortColumn: $categorySortColumn');
            debugPrint('   → categorySortAscending: $categorySortAscending');
            debugPrint('   → ⚠️ [문제 확인] Category 테이블 정렬이 다른 테이블에 영향을 주는지 확인');
            debugPrint('   → ⚠️ [해결] Category 테이블만 정렬되도록 독립적인 정렬 상태 필요');
            // Category 테이블은 자체 정렬 상태를 가지므로 onSort를 호출하지 않음
            // 대신 StatefulWidget으로 만들어서 자체 정렬 상태를 관리해야 함
            debugPrint('═══════════════════════════════════════════════════════');
          },
          sortColumn: null, // Category 테이블은 독립적인 정렬 상태를 가짐
          sortAscending: true,
          reportColor: reportColor,
          selectedCategoryCode: selectedCategoryCode,
          onCategorySelected: onCategorySelected,
        );
        debugPrint('   → summaryByCategoryTable 생성됨');
      } else {
        debugPrint('   ⚠️ summary_by_category 리스트가 비어있음');
      }
    } else {
      debugPrint('   ⚠️ summary_by_category 데이터를 찾을 수 없음');
    }
    debugPrint('   → 최종 summaryByCategoryTable != null: ${summaryByCategoryTable != null}');

    // summary_by_color 테이블
    Widget? summaryByColorTable;
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [Items Builder] summary_by_color 테이블 추출 시작');
    debugPrint('   → data.containsKey("data"): ${data.containsKey("data")}');
    if (data.containsKey('data') && 
        data['data'] is Map &&
        (data['data'] as Map).containsKey('summary_by_color') &&
        (data['data'] as Map)['summary_by_color'] is List) {
      final summaryByColorList = (data['data'] as Map)['summary_by_color'] as List;
      debugPrint('   → summary_by_color 리스트 발견: length=${summaryByColorList.length}');
      debugPrint('   → summaryByColorList.isNotEmpty: ${summaryByColorList.isNotEmpty}');
      
      // 대형화면에서는 데이터가 비어있어도 테이블 생성 (레이아웃 유지)
      final isDesktop = PlatformUtils.isDesktop();
      if (summaryByColorList.isNotEmpty || isDesktop) {
        debugPrint('   → summary_by_color 테이블 생성 (isNotEmpty: ${summaryByColorList.isNotEmpty}, isDesktop: $isDesktop)');
        summaryByColorTable = _buildSummaryByColorTable(
          summaryByColorList,
          context,
          onSort: (colorSortColumn, colorSortAscending) {
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('🔍 [Items Builder] Color 테이블 onSort 콜백 호출');
            debugPrint('   → colorSortColumn: $colorSortColumn');
            debugPrint('   → colorSortAscending: $colorSortAscending');
            debugPrint('   → ⚠️ [문제 확인] Color 테이블 정렬이 다른 테이블에 영향을 주는지 확인');
            debugPrint('   → ⚠️ [해결] Color 테이블만 정렬되도록 독립적인 정렬 상태 필요');
            // Color 테이블은 자체 정렬 상태를 가지므로 onSort를 호출하지 않음
            // 대신 StatefulWidget으로 만들어서 자체 정렬 상태를 관리해야 함
            debugPrint('═══════════════════════════════════════════════════════');
          },
          sortColumn: null, // Color 테이블은 독립적인 정렬 상태를 가짐
          sortAscending: true,
          reportColor: reportColor,
          selectedColorCode: selectedColorCode,
          onColorSelected: onColorSelected,
        );
      } else {
        debugPrint('   ⚠️ summary_by_color 리스트가 비어있고 모바일 화면이므로 테이블 생성 안 함');
      }
    } else {
      debugPrint('   ⚠️ summary_by_color 데이터를 찾을 수 없음');
      if (!data.containsKey('data')) {
        debugPrint('     → data에 "data" 키가 없음');
      } else if (data['data'] is! Map) {
        debugPrint('     → data["data"]가 Map이 아님: ${data["data"].runtimeType}');
      } else if (!(data['data'] as Map).containsKey('summary_by_color')) {
        debugPrint('     → data["data"]에 "summary_by_color" 키가 없음');
        debugPrint('     → data["data"].keys: ${(data['data'] as Map).keys.toList()}');
      }
    }
    debugPrint('   → 최종 summaryByColorTable != null: ${summaryByColorTable != null}');
    debugPrint('═══════════════════════════════════════════════════════');

    // products 테이블
    Widget? productsTable;
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📊 [ItemsBuilder] productsTable 추출 시작');
    debugPrint('   → data.keys: ${data.keys.toList()}');
    debugPrint('   → data.containsKey("data"): ${data.containsKey("data")}');
    
    if (data.containsKey('data')) {
      debugPrint('   → data["data"] 타입: ${data["data"].runtimeType}');
      if (data['data'] is Map) {
        final dataMap = data['data'] as Map;
        debugPrint('   → data["data"].keys: ${dataMap.keys.toList()}');
        debugPrint('   → data["data"].containsKey("products"): ${dataMap.containsKey("products")}');
        
        if (dataMap.containsKey('products')) {
          debugPrint('   → data["data"]["products"] 타입: ${dataMap["products"].runtimeType}');
          if (dataMap['products'] is List) {
            var productsList = dataMap['products'] as List;
            debugPrint('   → productsList.length (필터링 전): ${productsList.length}');
            
            // filteringWord 필터 적용
            if (filteringWord != null && filteringWord.isNotEmpty) {
              final filterLower = filteringWord.toLowerCase();
              productsList = productsList.where((item) {
                if (item is Map<String, dynamic>) {
                  final codigo1 = item['codigo1']?.toString().toLowerCase() ?? '';
                  final productName = item['ProductName']?.toString().toLowerCase() ?? '';
                  return codigo1.contains(filterLower) || productName.contains(filterLower);
                }
                return false;
              }).toList();
              debugPrint('   → productsList.length (filteringWord 필터링 후): ${productsList.length}');
            }
            
            // selectedCategoryCode 필터 적용
            if (selectedCategoryCode != null && selectedCategoryCode.isNotEmpty) {
              debugPrint('   → selectedCategoryCode: $selectedCategoryCode');
              productsList = productsList.where((item) {
                if (item is Map<String, dynamic>) {
                  final categoryCode = item['CategoryCode']?.toString() ?? '';
                  return categoryCode == selectedCategoryCode;
                }
                return false;
              }).toList();
              debugPrint('   → productsList.length (selectedCategoryCode 필터링 후): ${productsList.length}');
            }
            
            // selectedColorCode 필터: 서버가 색상별 products/수량을 안 주는 경우, 클라이언트에서 색상별 행만 필터
            if (selectedColorCode != null && selectedColorCode.isNotEmpty && productsList.isNotEmpty) {
              final first = productsList.first;
              final hasColorField = first is Map<String, dynamic> &&
                  (first.containsKey('ColorCode') || first.containsKey('ColorName') || first.containsKey('color_id'));
              if (hasColorField) {
                final beforeCount = productsList.length;
                productsList = productsList.where((item) {
                  if (item is! Map<String, dynamic>) return false;
                  final colorCode = (item['ColorCode']?.toString().trim() ?? '').toLowerCase();
                  final colorName = (item['ColorName']?.toString().trim() ?? '').toLowerCase();
                  final colorId = (item['color_id']?.toString().trim() ?? '').toLowerCase();
                  final selected = selectedColorCode.trim().toLowerCase();
                  return colorCode == selected || colorName == selected || colorId == selected;
                }).toList();
                debugPrint('🔍 [Items Builder] selectedColorCode 클라이언트 필터: $selectedColorCode → ${productsList.length}행 (전 $beforeCount)');
              }
            }
            
            // productsTable 생성 (빈 리스트여도 대형화면에서는 테이블 표시)
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('📊 [ItemsBuilder] productsTable 생성 시작');
            debugPrint('   → productsList.length: ${productsList.length}');
            debugPrint('   → displayedItemsCount: $displayedItemsCount');
            debugPrint('   → itemsPerPage: $itemsPerPage');
            debugPrint('   → scrollController: present');
            debugPrint('   → horizontalScrollController: $horizontalScrollController');
            debugPrint('   → PlatformUtils.isDesktop(): ${PlatformUtils.isDesktop()}');
            
            if (productsList.isNotEmpty) {
              debugPrint('   ✅ productsList가 비어있지 않음 - 테이블 생성');
              
              debugPrint('═══════════════════════════════════════════════════════');
              debugPrint('🔍 [Items Builder] buildTableFromList 호출 전 - 헤더 중복 및 정렬 디버깅');
              debugPrint('   → productsList.length: ${productsList.length}');
              debugPrint('   → sortColumn: $sortColumn');
              debugPrint('   → sortAscending: $sortAscending');
              debugPrint('   → onSort: $onSort');
              
              // keys 확인
              final allKeys = productsList.isNotEmpty 
                  ? (productsList.first as Map<String, dynamic>).keys.toList()
                  : <String>[];
              debugPrint('   → allKeys: $allKeys');
              debugPrint('   → allKeys.length: ${allKeys.length}');
              debugPrint('   → ⚠️ [중복 확인] buildTableFromList 내부에서 별도 헤더가 생성되는지 확인');
              debugPrint('   → ⚠️ [정렬 확인] onSort 콜백이 제대로 전달되는지 확인');
              debugPrint('═══════════════════════════════════════════════════════');
              
              // ResizableDataTable을 사용한 products 테이블 빌드
              final colDefs = buildColumnDefs();
              // 실제 데이터에 존재하는 키 기준으로 활성 칼럼 결정
              final dataKeys = productsList.isNotEmpty
                  ? (productsList.first as Map<String, dynamic>).keys.toSet()
                  : <String>{};
              final activeColDefs = colDefs
                  .where((c) => dataKeys.contains(c.key) || productsList.isEmpty)
                  .toList();
              // colDefs에 없는 새로운 키 추가 (start_date/end_date/sucursal 제외)
              final excludedKeys = <String>{
                'start_date', 'end_date', 'startDate', 'endDate', 'sucursal'
              };
              for (final key in dataKeys) {
                if (!excludedKeys.contains(key) &&
                    !activeColDefs.any((c) => c.key == key)) {
                  activeColDefs.add(TableColumnDef(
                    key: key,
                    label: key,
                    defaultWidth: 120,
                  ));
                }
              }

              final defaults = {for (final c in activeColDefs) c.key: c.defaultWidth};
              final mergedWidths = Map<String, double>.from(defaults)
                ..addAll(columnWidths ?? {});

              // 칼럼은 응답 키에서 파생되므로 서버 스키마가 바뀌면 개수가 달라진다.
              // 어떤 키가 승격·탈락했는지 남겨두지 않으면 assertion 이 터졌을 때
              // 응답을 다시 받아보기 전까지 원인을 알 수 없다.
              final activeKeys = activeColDefs.map((c) => c.key).toList();
              final definedKeys = colDefs.map((c) => c.key).toSet();
              final promotedKeys = activeKeys.where((k) => !definedKeys.contains(k)).toList();
              final droppedKeys = definedKeys
                  .where((k) => !activeKeys.contains(k))
                  .toList();

              debugPrint('───────────────────────────────────────────────────────');
              debugPrint('🧮 [ItemsBuilder] 칼럼 구성 진단');
              debugPrint('   → 활성 칼럼 ${activeKeys.length}개: $activeKeys');
              debugPrint('   → 응답 키 ${dataKeys.length}개: ${dataKeys.toList()}');
              if (promotedKeys.isNotEmpty) {
                debugPrint('   → ➕ 응답에만 있어 칼럼으로 추가된 키: $promotedKeys');
              }
              if (droppedKeys.isNotEmpty) {
                debugPrint('   → ➖ 응답에 없어 빠진 칼럼: $droppedKeys');
              }

              final rows = buildRows(
                productsList.take(displayedItemsCount).toList(),
                columnKeys: activeKeys,
              );

              // 셀은 activeKeys 에서 파생되므로 정상적으로는 항상 일치한다.
              // 어긋난다면 buildRows 쪽이 깨진 것이므로 assertion 전에 잡아낸다.
              final firstRowLength = rows.isNotEmpty ? rows.first.length : activeKeys.length;
              if (firstRowLength != activeColDefs.length) {
                debugPrint('   → ⚠️ 불일치! 행 셀 $firstRowLength개 vs 칼럼 ${activeColDefs.length}개');
              } else {
                debugPrint('   → ✅ 행 셀 $firstRowLength개 = 칼럼 ${activeColDefs.length}개');
              }
              debugPrint('───────────────────────────────────────────────────────');

              productsTable = ResizableDataTable(
                columns: activeColDefs,
                rows: rows,
                columnWidths: mergedWidths,
                onColumnResize: onColumnResize ?? (_, __) {},
                sortColumn: sortColumn,
                sortAscending: sortAscending,
                onSort: (column, ascending) => onSort(column, ascending),
                headerColor: reportColor ?? Colors.blue,
                scrollController: scrollController,
              );

              debugPrint('   → productsTable: ResizableDataTable 생성됨 (rows: ${rows.length})');
            } else {
              debugPrint('   ⚠️ [ItemsBuilder] productsList가 비어있습니다! (필터링 후)');
              
              // 대형화면에서는 빈 테이블이라도 표시 (레이아웃 유지)
              if (PlatformUtils.isDesktop()) {
                debugPrint('   → 대형화면: 빈 ResizableDataTable 생성 (레이아웃 유지)');
                final colDefs = buildColumnDefs();
                final defaults = {for (final c in colDefs) c.key: c.defaultWidth};
                final mergedWidths = Map<String, double>.from(defaults)
                  ..addAll(columnWidths ?? {});
                productsTable = ResizableDataTable(
                  columns: colDefs,
                  rows: const [],
                  columnWidths: mergedWidths,
                  onColumnResize: onColumnResize ?? (_, __) {},
                  sortColumn: sortColumn,
                  sortAscending: sortAscending,
                  onSort: (column, ascending) => onSort(column, ascending),
                  headerColor: reportColor ?? Colors.blue,
                  scrollController: scrollController,
                );
                debugPrint('   → 빈 productsTable 생성 완료');
              } else {
                debugPrint('   → 모바일/태블릿: productsTable을 null로 유지');
              }
            }
          } else {
            debugPrint('   ⚠️ [ItemsBuilder] data["data"]["products"]가 List가 아닙니다!');
          }
        } else {
          debugPrint('   ⚠️ [ItemsBuilder] data["data"]에 "products" 키가 없습니다!');
        }
      } else {
        debugPrint('   ⚠️ [ItemsBuilder] data["data"]가 Map가 아닙니다!');
      }
    } else {
      debugPrint('   ⚠️ [ItemsBuilder] data에 "data" 키가 없습니다!');
    }
    debugPrint('═══════════════════════════════════════════════════════');

    return _ExtractedData(
      summaryCard: summaryCard,
      summaryByCompanyTable: summaryByCompanyTable,
      summaryByCategoryTable: summaryByCategoryTable,
      summaryByColorTable: summaryByColorTable,
      productsTable: productsTable,
      scrollController: scrollController,
      columnWidths: columnWidths,
      onColumnResize: onColumnResize,
    );
  }

  /// macOS/Windows 대형 화면용 레이아웃 (좌우 분할 레이아웃)
  static Widget _buildContentForDesktop(_ExtractedData data) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [큰 화면 디버깅] _buildContentForDesktop 시작');
    debugPrint('   → summaryCard != null: ${data.summaryCard != null}');
    debugPrint('   → summaryByCompanyTable != null: ${data.summaryByCompanyTable != null}');
    debugPrint('   → summaryByCategoryTable != null: ${data.summaryByCategoryTable != null}');
    debugPrint('   → summaryByColorTable != null: ${data.summaryByColorTable != null}');
    debugPrint('   → productsTable != null: ${data.productsTable != null}');
    debugPrint('   → productsTable 타입: ${data.productsTable?.runtimeType}');
    
    // 조건 체크 상세 디버깅
    final hasSummaryTable = data.summaryByCompanyTable != null || 
                           data.summaryByCategoryTable != null || 
                           data.summaryByColorTable != null;
    final hasProductsTable = data.productsTable != null;
    
    debugPrint('   → hasSummaryTable: $hasSummaryTable');
    debugPrint('   → hasProductsTable: $hasProductsTable');
    debugPrint('   → summaryByCompanyTable != null: ${data.summaryByCompanyTable != null}');
    debugPrint('   → summaryByCategoryTable != null: ${data.summaryByCategoryTable != null}');
    debugPrint('   → summaryByColorTable != null: ${data.summaryByColorTable != null}');
    debugPrint('   → 조건1 (summary && products): ${hasSummaryTable && hasProductsTable}');
    debugPrint('   → 조건2 (!summary && products): ${!hasSummaryTable && hasProductsTable}');
    debugPrint('   → 조건3 (summary && !products): ${hasSummaryTable && !hasProductsTable}');
    debugPrint('   → PlatformUtils.isDesktop(): ${PlatformUtils.isDesktop()}');
    
    // summary 테이블이 하나라도 있고 products 테이블이 있는 경우: 좌우 분할 레이아웃
    // 대형화면에서는 productsTable이 null이어도 빈 테이블로 표시 (레이아웃 유지)
    if (hasSummaryTable && hasProductsTable) {
      debugPrint('   ✅ 좌우 분할 레이아웃 사용');
      debugPrint('   → Column children 개수: ${data.summaryCard != null ? 2 : 1}');
      debugPrint('   → Expanded 사용: true');
      
      return LayoutBuilder(
        builder: (context, constraints) {
          debugPrint('   → LayoutBuilder constraints: ${constraints.maxWidth} x ${constraints.maxHeight}');
          debugPrint('   → constraints.isTight: ${constraints.isTight}');
          debugPrint('   → constraints.hasBoundedHeight: ${constraints.hasBoundedHeight}');
          debugPrint('   → constraints.hasBoundedWidth: ${constraints.hasBoundedWidth}');
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 부분 (summaryCard)
                if (data.summaryCard != null) ...[
                  data.summaryCard!,
                  const SizedBox(height: 24),
                ],
                // 좌우 분할 레이아웃 (크기 조정 가능)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, expandedConstraints) {
                      debugPrint('   → Expanded 내부 constraints: ${expandedConstraints.maxWidth} x ${expandedConstraints.maxHeight}');
                      debugPrint('   → Expanded constraints.isTight: ${expandedConstraints.isTight}');
                      debugPrint('   → Expanded constraints.hasBoundedHeight: ${expandedConstraints.hasBoundedHeight}');
                      
                      return _ResizableSplitView(
                        leftChild: _buildLeftPanel(
                          summaryByCompanyTable: data.summaryByCompanyTable,
                          summaryByCategoryTable: data.summaryByCategoryTable,
                          summaryByColorTable: data.summaryByColorTable,
                        ),
                        rightChild: _buildRightPanel(
                          productsTable: data.productsTable!,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // summary 테이블이 모두 없고 products 테이블만 있는 경우
    // 대형화면에서는 왼쪽 패널을 유지하기 위해 좌우 분할 레이아웃 사용
    if (!hasSummaryTable && hasProductsTable) {
      final isDesktop = PlatformUtils.isDesktop();
      
      if (isDesktop) {
        debugPrint('   ✅ 대형화면: summary 없어도 좌우 분할 레이아웃 사용 (왼쪽 패널 유지)');
        debugPrint('   → Column children 개수: ${data.summaryCard != null ? 2 : 1}');
        debugPrint('   → Expanded 사용: true');
        
        return LayoutBuilder(
          builder: (context, constraints) {
            debugPrint('   → LayoutBuilder constraints: ${constraints.maxWidth} x ${constraints.maxHeight}');
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더 부분 (summaryCard)
                  if (data.summaryCard != null) ...[
                    data.summaryCard!,
                    const SizedBox(height: 24),
                  ],
                  // 좌우 분할 레이아웃 (빈 왼쪽 패널 + products 테이블)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, expandedConstraints) {
                        debugPrint('   → Expanded 내부 constraints: ${expandedConstraints.maxWidth} x ${expandedConstraints.maxHeight}');
                        
                        return _ResizableSplitView(
                          leftChild: _buildLeftPanel(
                            summaryByCompanyTable: data.summaryByCompanyTable,
                            summaryByCategoryTable: data.summaryByCategoryTable,
                            summaryByColorTable: data.summaryByColorTable,
                          ),
                          rightChild: _buildRightPanel(
                            productsTable: data.productsTable!,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        debugPrint('   ✅ 모바일/태블릿: 100% 폭 레이아웃 사용 (summary 없음)');
        debugPrint('   → Column children 개수: ${data.summaryCard != null ? 2 : 1}');
        debugPrint('   → Expanded 사용: false');
        
        return LayoutBuilder(
          builder: (context, constraints) {
            debugPrint('   → LayoutBuilder constraints: ${constraints.maxWidth} x ${constraints.maxHeight}');
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더 부분 (summaryCard)
                  if (data.summaryCard != null) ...[
                    data.summaryCard!,
                    const SizedBox(height: 24),
                  ],
                  // products 테이블만 100% 폭으로 표시
                  _buildRightPanel(
                    productsTable: data.productsTable!,
                    useExpanded: false,
                  ),
                ],
              ),
            );
          },
        );
      }
    }

    // summary 테이블이 있고 products 테이블이 없는 경우: 대형화면에서는 빈 테이블 표시
    if (hasSummaryTable && !hasProductsTable) {
      debugPrint('   ⚠️ summary는 있지만 productsTable이 null');
      debugPrint('   → 대형화면: 좌우 분할 레이아웃 유지 (빈 productsTable 표시)');
      
      // 빈 productsTable 생성 (ResizableDataTable)
      final emptyColDefs = buildColumnDefs();
      final emptyDefaults = {for (final c in emptyColDefs) c.key: c.defaultWidth};
      final emptyMergedWidths = Map<String, double>.from(emptyDefaults)
        ..addAll(data.columnWidths ?? {});
      final emptyProductsTable = ResizableDataTable(
        columns: emptyColDefs,
        rows: const [],
        columnWidths: emptyMergedWidths,
        onColumnResize: data.onColumnResize ?? (_, __) {},
        sortColumn: null,
        sortAscending: true,
        onSort: (column, ascending) {},
        headerColor: Colors.blue,
        scrollController: data.scrollController,
      );
      
      return LayoutBuilder(
        builder: (context, constraints) {
          debugPrint('   → LayoutBuilder constraints: ${constraints.maxWidth} x ${constraints.maxHeight}');
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 부분 (summaryCard)
                if (data.summaryCard != null) ...[
                  data.summaryCard!,
                  const SizedBox(height: 24),
                ],
                // 좌우 분할 레이아웃 (빈 productsTable 사용)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, expandedConstraints) {
                      debugPrint('   → Expanded 내부 constraints: ${expandedConstraints.maxWidth} x ${expandedConstraints.maxHeight}');
                      
                      return _ResizableSplitView(
                        leftChild: _buildLeftPanel(
                          summaryByCompanyTable: data.summaryByCompanyTable,
                          summaryByCategoryTable: data.summaryByCategoryTable,
                          summaryByColorTable: data.summaryByColorTable,
                        ),
                        rightChild: _buildRightPanel(
                          productsTable: emptyProductsTable,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // 그 외의 경우: 세로로 배치
    debugPrint('   ⚠️ 세로 배치 레이아웃 사용 (기본) - 예상치 못한 케이스');
    debugPrint('   → hasSummaryTable: $hasSummaryTable');
    debugPrint('   → hasProductsTable: $hasProductsTable');
    debugPrint('═══════════════════════════════════════════════════════');
    return _buildVerticalLayout(data);
  }

  /// iPad 태블릿 화면용 레이아웃 (현재는 desktop과 동일하게 처리)
  static Widget _buildContentForTablet(_ExtractedData data) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [큰 화면 디버깅] _buildContentForTablet 시작');
    debugPrint('   → 태블릿 화면: desktop과 동일하게 처리');
    debugPrint('═══════════════════════════════════════════════════════');
    // 현재는 desktop과 동일하게 처리 (나중에 별도 레이아웃으로 변경 가능)
    return _buildContentForDesktop(data);
  }

  /// 모바일 화면용 레이아웃 (세로 배치)
  static Widget _buildContentForMobile(_ExtractedData data) {
    return _buildVerticalLayout(data);
  }

  /// 왼쪽 패널 빌드 (재사용 가능한 헬퍼 함수)
  static Widget _buildLeftPanel({
    Widget? summaryByCompanyTable,
    Widget? summaryByCategoryTable,
    Widget? summaryByColorTable,
  }) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [큰 화면 디버깅] _buildLeftPanel 시작');
    debugPrint('   → summaryByCompanyTable != null: ${summaryByCompanyTable != null}');
    debugPrint('   → summaryByCategoryTable != null: ${summaryByCategoryTable != null}');
    debugPrint('   → summaryByColorTable != null: ${summaryByColorTable != null}');
    
    final childrenCount = (summaryByCompanyTable != null ? 1 : 0) +
                         (summaryByCategoryTable != null ? 1 : 0) +
                         (summaryByColorTable != null ? 1 : 0);
    debugPrint('   → 예상 children 개수: $childrenCount');
    debugPrint('═══════════════════════════════════════════════════════');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (summaryByCompanyTable != null) ...[
          const Text(
            'Resumen por Empresa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          summaryByCompanyTable,
          const SizedBox(height: 24),
        ],
        if (summaryByCategoryTable != null) ...[
          const Text(
            'Resumen por Categoría',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          summaryByCategoryTable,
          const SizedBox(height: 24),
        ],
        if (summaryByColorTable != null) ...[
          const Text(
            'Resumen x Color',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          summaryByColorTable,
        ],
      ],
    );
  }

  /// 오른쪽 패널 빌드 (재사용 가능한 헬퍼 함수)
  static Widget _buildRightPanel({
    required Widget productsTable,
    bool useExpanded = true,
  }) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [큰 화면 디버깅] _buildRightPanel 시작');
    debugPrint('   → productsTable 타입: ${productsTable.runtimeType}');
    debugPrint('   → useExpanded: $useExpanded');
    debugPrint('═══════════════════════════════════════════════════════');
    
    return LayoutBuilder(
      builder: (context, constraints) {
        debugPrint('🔍 [큰 화면 디버깅] _buildRightPanel LayoutBuilder');
        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
        debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
        debugPrint('   → constraints.minWidth: ${constraints.minWidth}');
        debugPrint('   → constraints.minHeight: ${constraints.minHeight}');
        debugPrint('   → constraints.isTight: ${constraints.isTight}');
        debugPrint('   → constraints.hasBoundedHeight: ${constraints.hasBoundedHeight}');
        debugPrint('   → constraints.hasBoundedWidth: ${constraints.hasBoundedWidth}');
        
        // 제약 조건 검증
        if (useExpanded && !constraints.hasBoundedHeight) {
          debugPrint('   ⚠️ 경고: useExpanded=true인데 높이가 제한되지 않았습니다!');
        }
        if (constraints.maxHeight.isInfinite && useExpanded) {
          debugPrint('   ⚠️ 경고: useExpanded=true인데 maxHeight가 무한대입니다!');
        }
        
        final content = Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: useExpanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              const Text(
                'Productos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            if (useExpanded)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, expandedConstraints) {
                    debugPrint('🔍 [큰 화면 디버깅] _buildRightPanel 내부 Expanded');
                    debugPrint('   → expandedConstraints.maxWidth: ${expandedConstraints.maxWidth}');
                    debugPrint('   → expandedConstraints.maxHeight: ${expandedConstraints.maxHeight}');
                    debugPrint('   → expandedConstraints.isTight: ${expandedConstraints.isTight}');
                    debugPrint('   → expandedConstraints.hasBoundedHeight: ${expandedConstraints.hasBoundedHeight}');
                    
                    if (!expandedConstraints.hasBoundedHeight) {
                      debugPrint('   ❌ 오류: Expanded 내부 높이가 제한되지 않았습니다!');
                    }
                    if (expandedConstraints.maxHeight.isInfinite) {
                      debugPrint('   ❌ 오류: Expanded 내부 maxHeight가 무한대입니다!');
                    }
                    // 오버플로우 방지: 패널 너비로 제한 + 가로 스크롤로 넓은 테이블 대응
                    final maxW = expandedConstraints.hasBoundedWidth && expandedConstraints.maxWidth.isFinite
                        ? expandedConstraints.maxWidth
                        : null;
                    if (maxW == null) return productsTable;
                    return SizedBox(
                      width: maxW,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ClipRect(
                          clipBehavior: Clip.hardEdge,
                          child: productsTable,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              productsTable,
            ],
          ),
        );
        
        debugPrint('🔍 [큰 화면 디버깅] _buildRightPanel 최종 위젯');
        debugPrint('   → useExpanded: $useExpanded');
        debugPrint('   → content 타입: ${content.runtimeType}');
        
        // useExpanded가 true일 때는 이미 Column 내부에 Expanded가 있으므로
        // 추가로 감쌀 필요 없음
        final result = content;
        
        debugPrint('   → result 타입: ${result.runtimeType}');
        debugPrint('═══════════════════════════════════════════════════════');
        
        return result;
      },
    );
  }

  /// 세로 배치 레이아웃 (재사용 가능한 헬퍼 함수)
  static Widget _buildVerticalLayout(_ExtractedData data) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [큰 화면 디버깅] _buildVerticalLayout 시작');
    debugPrint('   → summaryByCompanyTable != null: ${data.summaryByCompanyTable != null}');
    debugPrint('   → summaryByCategoryTable != null: ${data.summaryByCategoryTable != null}');
    debugPrint('   → summaryByColorTable != null: ${data.summaryByColorTable != null}');
    debugPrint('   → productsTable != null: ${data.productsTable != null}');
    debugPrint('   → scrollController: 있음');
    
    // summary 테이블이 모두 없고 products 테이블만 있는 경우: 100% 폭으로 표시
    if (data.summaryByCompanyTable == null && 
        data.summaryByCategoryTable == null && 
        data.summaryByColorTable == null && 
        data.productsTable != null) {
      debugPrint('   ✅ 세로 배치: products만 있음 (100% 폭)');
      return SingleChildScrollView(
        controller: data.scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.summaryCard != null) ...[
                data.summaryCard!,
                const SizedBox(height: 24),
              ],
              _buildRightPanel(
                productsTable: data.productsTable!,
                useExpanded: false,
              ),
            ],
          ),
        ),
      );
    }

    // summary 테이블이 있는 경우: 세로로 배치
    debugPrint('   ✅ 세로 배치: summary 테이블 포함');
    return SingleChildScrollView(
      controller: data.scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.summaryCard != null) ...[
              data.summaryCard!,
              const SizedBox(height: 24),
            ],
            if (data.summaryByCompanyTable != null) ...[
              const Text(
                'Resumen por Empresa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              data.summaryByCompanyTable!,
              const SizedBox(height: 24),
            ],
            if (data.summaryByCategoryTable != null) ...[
              const Text(
                'Resumen por Categoría',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              data.summaryByCategoryTable!,
              const SizedBox(height: 24),
            ],
            if (data.summaryByColorTable != null) ...[
              const Text(
                'Resumen x Color',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              data.summaryByColorTable!,
              const SizedBox(height: 24),
            ],
            if (data.productsTable != null) ...[
              const Text(
                'Productos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              data.productsTable!,
            ],
          ],
        ),
      ),
    );
  }

  /// Summary 카드 빌드
  static Widget _buildSummaryCard(Map<String, dynamic> summary) {
    final totalCompanies = summary['total_companies']?.toString() ?? '0';
    final totalCategories = summary['total_categories']?.toString() ?? '0';
    final totalColors = summary['total_colors']?.toString() ?? '0';
    final totalProducts = summary['total_products']?.toString() ?? '0';
    final totalCantidad = summary['total_cantidad']?.toString() ?? '0';
    
    final cantidadNum = num.tryParse(totalCantidad.toString().replaceAll(',', '')) ?? 0;
    final formattedCantidad = NumberFormat('#,##0').format(cantidadNum);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 모바일 폰 체크
        final platformType = PlatformUtils.getPlatformType(context);
        final isMobile = platformType == PlatformType.mobile;
        final isTablet = PlatformUtils.isIPad(context) || 
                         (platformType == PlatformType.mobile && constraints.maxWidth >= 800);
        final isMobilePhone = isMobile && !isTablet;
        
        // 모바일 폰일 때 크기 조정
        final itemSpacing = isMobilePhone ? 6.0 : 12.0;
        
        return Wrap(
          spacing: itemSpacing,
          runSpacing: itemSpacing,
          alignment: WrapAlignment.spaceEvenly,
          children: [
            _buildSummaryBox('Total Empresas', totalCompanies, Icons.business, Colors.blue, isMobilePhone),
            _buildSummaryBox('Total Categorías', totalCategories, Icons.category, Colors.green, isMobilePhone),
            _buildSummaryBox('Total Colores', totalColors, Icons.palette, Colors.pink, isMobilePhone),
            _buildSummaryBox('Total Productos', totalProducts, Icons.inventory, Colors.orange, isMobilePhone),
            _buildSummaryBox('Total Cantidad', formattedCantidad, Icons.shopping_cart, Colors.purple, isMobilePhone),
          ],
        );
      },
    );
  }

  /// 요약 박스 빌드 (개별 박스 형태)
  static Widget _buildSummaryBox(String label, String value, IconData icon, Color color, bool isMobilePhone) {
    // 모바일 폰일 때 크기를 절반으로 줄이기
    final padding = isMobilePhone ? 8.0 : 16.0;
    final iconSize = isMobilePhone ? 20.0 : 32.0;
    final labelFontSize = isMobilePhone ? 10.0 : 12.0;
    final valueFontSize = isMobilePhone ? 16.0 : 24.0;
    final borderRadius = isMobilePhone ? 8.0 : 12.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          SizedBox(height: isMobilePhone ? 4.0 : 8.0),
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobilePhone ? 2.0 : 4.0),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 회사별 요약 테이블 빌드
  static Widget _buildSummaryByCompanyTable(
    List summaryByCompanyList,
    BuildContext context, {
    Function(String?, bool)? onSort,
    String? sortColumn,
    bool sortAscending = true,
    Color? reportColor,
  }) {
    if (summaryByCompanyList.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = reportColor ?? Colors.blue;
    
    // 정렬 적용
    List<dynamic> sortedList = List.from(summaryByCompanyList);
    if (sortColumn != null && onSort != null) {
      sortedList.sort((a, b) {
        if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
          return 0;
        }

        dynamic aValue;
        dynamic bValue;

        if (sortColumn == 'CompanyCode') {
          aValue = a['CompanyCode'];
          bValue = b['CompanyCode'];
        } else if (sortColumn == 'CompanyName') {
          aValue = a['CompanyName']?.toString() ?? '';
          bValue = b['CompanyName']?.toString() ?? '';
        } else if (sortColumn == 'totalCantidad') {
          aValue = num.tryParse(a['totalCantidad']?.toString().replaceAll(',', '') ?? '0') ?? 0;
          bValue = num.tryParse(b['totalCantidad']?.toString().replaceAll(',', '') ?? '0') ?? 0;
        } else {
          return 0;
        }

        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return sortAscending ? -1 : 1;
        if (bValue == null) return sortAscending ? 1 : -1;

        if (aValue is num && bValue is num) {
          final comparison = aValue.compareTo(bValue);
          return sortAscending ? comparison : -comparison;
        }

        final aStr = aValue.toString().toLowerCase();
        final bStr = bValue.toString().toLowerCase();
        final comparison = aStr.compareTo(bStr);
        return sortAscending ? comparison : -comparison;
      });
    }
    
    // 컬럼 정의
    final columns = [
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Código',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sortColumn == 'CompanyCode' && onSort != null)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
          ],
        ),
        onSort: onSort != null ? (columnIndex, ascending) {
          if (sortColumn == 'CompanyCode') {
            onSort('CompanyCode', !sortAscending);
          } else {
            onSort('CompanyCode', true);
          }
        } : null,
      ),
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Empresa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sortColumn == 'CompanyName' && onSort != null)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
          ],
        ),
        onSort: onSort != null ? (columnIndex, ascending) {
          if (sortColumn == 'CompanyName') {
            onSort('CompanyName', !sortAscending);
          } else {
            onSort('CompanyName', true);
          }
        } : null,
      ),
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Total Cantidad',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sortColumn == 'totalCantidad' && onSort != null)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
          ],
        ),
        numeric: true,
        onSort: onSort != null ? (columnIndex, ascending) {
          if (sortColumn == 'totalCantidad') {
            onSort('totalCantidad', !sortAscending);
          } else {
            onSort('totalCantidad', true);
          }
        } : null,
      ),
    ];

    // 데이터 행 생성
    final rows = sortedList.map<DataRow>((item) {
      if (item is! Map<String, dynamic>) {
        return DataRow(cells: columns.map((_) => const DataCell(Text(''))).toList());
      }
      
      final companyCode = item['CompanyCode']?.toString() ?? '';
      final companyName = item['CompanyName']?.toString() ?? '';
      final totalCantidad = item['totalCantidad']?.toString() ?? '0';
      
      final cantidadNum = num.tryParse(totalCantidad.toString().replaceAll(',', '')) ?? 0;
      final formattedCantidad = NumberFormat('#,##0').format(cantidadNum);

      return DataRow(
        cells: [
          DataCell(Text(companyCode)),
          DataCell(Text(companyName)),
          DataCell(
            Text(
              formattedCantidad,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 8,
          dataRowMinHeight: 32,  // 오른쪽 테이블과 동일하게 2/3로 조정 (48 * 2/3 = 32)
          dataRowMaxHeight: 37,  // 오른쪽 테이블과 동일하게 2/3로 조정 (56 * 2/3 ≈ 37)
          headingRowColor: WidgetStateProperty.all(color.withOpacity(0.1)),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }

  /// 카테고리별 요약 테이블 빌드 (독립적인 정렬 상태를 가짐)
  static Widget _buildSummaryByCategoryTable(
    List summaryByCategoryList,
    BuildContext context, {
    Function(String?, bool)? onSort,
    String? sortColumn,
    bool sortAscending = true,
    Color? reportColor,
    String? selectedCategoryCode,
    Function(String?)? onCategorySelected,
  }) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [Items Builder] _buildSummaryByCategoryTable 시작');
    debugPrint('   → summaryByCategoryList.length: ${summaryByCategoryList.length}');
    debugPrint('   → sortColumn: $sortColumn');
    debugPrint('   → sortAscending: $sortAscending');
    debugPrint('   → onSort != null: ${onSort != null}');
    debugPrint('   → ⚠️ [문제 확인] Category 테이블이 독립적인 정렬 상태를 가지는지 확인');
    debugPrint('═══════════════════════════════════════════════════════');
    
    if (summaryByCategoryList.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = reportColor ?? Colors.green;
    
    // Category 테이블은 독립적인 정렬 상태를 가지도록 StatefulWidget으로 래핑
    debugPrint('   → ✅ Category 테이블을 StatefulWidget으로 래핑하여 독립적인 정렬 상태 제공');
    return _CategoryTableWithIndependentSort(
      summaryByCategoryList: summaryByCategoryList,
      color: color,
      selectedCategoryCode: selectedCategoryCode,
      onCategorySelected: onCategorySelected,
    );
  }

  /// 색상별 요약 테이블 빌드 (독립적인 정렬 상태를 가짐)
  static Widget _buildSummaryByColorTable(
    List summaryByColorList,
    BuildContext context, {
    Function(String?, bool)? onSort,
    String? sortColumn,
    bool sortAscending = true,
    Color? reportColor,
    String? selectedColorCode,
    Function(String?)? onColorSelected,
  }) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [Items Builder] _buildSummaryByColorTable 시작');
    debugPrint('   → summaryByColorList.length: ${summaryByColorList.length}');
    debugPrint('   → selectedColorCode: $selectedColorCode');
    debugPrint('   → onColorSelected != null: ${onColorSelected != null}');
    
    // 대형화면에서는 빈 리스트여도 테이블 표시 (레이아웃 유지)
    final isDesktop = PlatformUtils.isDesktop();
    if (summaryByColorList.isEmpty && !isDesktop) {
      debugPrint('   ⚠️ summaryByColorList가 비어있고 모바일 화면이므로 빈 위젯 반환');
      return const SizedBox.shrink();
    }
    
    if (summaryByColorList.isEmpty && isDesktop) {
      debugPrint('   ⚠️ summaryByColorList가 비어있지만 대형화면이므로 빈 테이블 표시 (레이아웃 유지)');
      // 빈 테이블 반환 (헤더만 표시)
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 8,
            dataRowMinHeight: 32,
            dataRowMaxHeight: 37,
            headingRowColor: WidgetStateProperty.all((reportColor ?? Colors.purple).withOpacity(0.1)),
            columns: const [
              DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Color', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                label: Text('Total Cantidad', style: TextStyle(fontWeight: FontWeight.bold)),
                numeric: true,
              ),
            ],
            rows: const [
              DataRow(
                cells: [
                  DataCell(Text('No hay datos')),
                  DataCell(Text('')),
                  DataCell(Text('')),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final color = reportColor ?? Colors.purple;
    
    // Color 테이블은 독립적인 정렬 상태를 가지도록 StatefulWidget으로 래핑
    debugPrint('   → ✅ Color 테이블을 StatefulWidget으로 래핑하여 독립적인 정렬 상태 제공');
    return _ColorTableWithIndependentSort(
      summaryByColorList: summaryByColorList,
      color: color,
      selectedColorCode: selectedColorCode,
      onColorSelected: onColorSelected,
    );
  }
}

/// Category 테이블을 위한 독립적인 정렬 상태를 가진 StatefulWidget
class _CategoryTableWithIndependentSort extends StatefulWidget {
  final List summaryByCategoryList;
  final Color color;
  final String? selectedCategoryCode;
  final Function(String?)? onCategorySelected;

  const _CategoryTableWithIndependentSort({
    required this.summaryByCategoryList,
    required this.color,
    this.selectedCategoryCode,
    this.onCategorySelected,
  });

  @override
  State<_CategoryTableWithIndependentSort> createState() => _CategoryTableWithIndependentSortState();
}

class _CategoryTableWithIndependentSortState extends State<_CategoryTableWithIndependentSort> {
  String? _sortColumn;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [Category Table StatefulWidget] build');
    debugPrint('   → _sortColumn: $_sortColumn');
    debugPrint('   → _sortAscending: $_sortAscending');
    debugPrint('   → ⚠️ [해결] Category 테이블이 독립적인 정렬 상태를 가짐');
    debugPrint('═══════════════════════════════════════════════════════');
    
    final color = widget.color;
    
    // 정렬 적용 (Category 테이블만의 독립적인 정렬)
    List<dynamic> sortedList = List.from(widget.summaryByCategoryList);
    if (_sortColumn != null) {
      sortedList.sort((a, b) {
        if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
          return 0;
        }

        dynamic aValue;
        dynamic bValue;

        if (_sortColumn == 'CategoryCode') {
          aValue = a['CategoryCode'];
          bValue = b['CategoryCode'];
        } else if (_sortColumn == 'CategoryName') {
          aValue = a['CategoryName']?.toString() ?? '';
          bValue = b['CategoryName']?.toString() ?? '';
        } else if (_sortColumn == 'totalCantidad') {
          aValue = num.tryParse(a['totalCantidad']?.toString().replaceAll(',', '') ?? '0') ?? 0;
          bValue = num.tryParse(b['totalCantidad']?.toString().replaceAll(',', '') ?? '0') ?? 0;
        } else {
          return 0;
        }

        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return _sortAscending ? -1 : 1;
        if (bValue == null) return _sortAscending ? 1 : -1;

        if (aValue is num && bValue is num) {
          final comparison = aValue.compareTo(bValue);
          return _sortAscending ? comparison : -comparison;
        }

        final aStr = aValue.toString().toLowerCase();
        final bStr = bValue.toString().toLowerCase();
        final comparison = aStr.compareTo(bStr);
        return _sortAscending ? comparison : -comparison;
      });
    }
    
    // 컬럼 정의
    final columns = [
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Código',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_sortColumn == 'CategoryCode')
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
          ],
        ),
        onSort: (columnIndex, ascending) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [Category Table StatefulWidget] CategoryCode 칼럼 클릭');
          debugPrint('   → columnIndex: $columnIndex');
          debugPrint('   → ascending: $ascending');
          debugPrint('   → 현재 _sortColumn: $_sortColumn');
          debugPrint('   → 현재 _sortAscending: $_sortAscending');
          debugPrint('   → ✅ [해결] Category 테이블만 정렬됨 (독립적인 정렬 상태)');
          setState(() {
            if (_sortColumn == 'CategoryCode') {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = 'CategoryCode';
              _sortAscending = true;
            }
          });
          debugPrint('   → 새 _sortColumn: $_sortColumn');
          debugPrint('   → 새 _sortAscending: $_sortAscending');
          debugPrint('═══════════════════════════════════════════════════════');
        },
      ),
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Categoría',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_sortColumn == 'CategoryName')
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
          ],
        ),
        onSort: (columnIndex, ascending) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [Category Table StatefulWidget] CategoryName 칼럼 클릭');
          debugPrint('   → columnIndex: $columnIndex');
          debugPrint('   → ascending: $ascending');
          debugPrint('   → 현재 _sortColumn: $_sortColumn');
          debugPrint('   → 현재 _sortAscending: $_sortAscending');
          debugPrint('   → ✅ [해결] Category 테이블만 정렬됨 (독립적인 정렬 상태)');
          setState(() {
            if (_sortColumn == 'CategoryName') {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = 'CategoryName';
              _sortAscending = true;
            }
          });
          debugPrint('   → 새 _sortColumn: $_sortColumn');
          debugPrint('   → 새 _sortAscending: $_sortAscending');
          debugPrint('═══════════════════════════════════════════════════════');
        },
      ),
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Total Cantidad',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_sortColumn == 'totalCantidad')
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
          ],
        ),
        numeric: true,
        onSort: (columnIndex, ascending) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [Category Table StatefulWidget] totalCantidad 칼럼 클릭');
          debugPrint('   → columnIndex: $columnIndex');
          debugPrint('   → ascending: $ascending');
          debugPrint('   → 현재 _sortColumn: $_sortColumn');
          debugPrint('   → 현재 _sortAscending: $_sortAscending');
          debugPrint('   → ✅ [해결] Category 테이블만 정렬됨 (독립적인 정렬 상태)');
          debugPrint('   → ⚠️ [주의] totalCantidad는 Products 테이블과 같은 키지만 독립적으로 정렬됨');
          setState(() {
            if (_sortColumn == 'totalCantidad') {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = 'totalCantidad';
              _sortAscending = true;
            }
          });
          debugPrint('   → 새 _sortColumn: $_sortColumn');
          debugPrint('   → 새 _sortAscending: $_sortAscending');
          debugPrint('═══════════════════════════════════════════════════════');
        },
      ),
    ];

    // 데이터 행 생성
    final rows = sortedList.map<DataRow>((item) {
      if (item is! Map<String, dynamic>) {
        return DataRow(cells: columns.map((_) => const DataCell(Text(''))).toList());
      }
      
      final categoryCode = item['CategoryCode']?.toString() ?? '';
      final categoryName = item['CategoryName']?.toString() ?? '';
      final totalCantidad = item['totalCantidad']?.toString() ?? '0';
      
      final cantidadNum = num.tryParse(totalCantidad.toString().replaceAll(',', '')) ?? 0;
      final formattedCantidad = NumberFormat('#,##0').format(cantidadNum);
      
      final isSelected = widget.selectedCategoryCode != null && categoryCode == widget.selectedCategoryCode;

      return DataRow(
        selected: isSelected,
        onSelectChanged: widget.onCategorySelected != null ? (selected) {
          if (selected != null && selected) {
            widget.onCategorySelected!(categoryCode);
          } else {
            widget.onCategorySelected!(null);
          }
        } : null,
        cells: [
          DataCell(Text(categoryCode)),
          DataCell(Text(categoryName)),
          DataCell(
            Text(
              formattedCantidad,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 8,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 37,
          headingRowColor: WidgetStateProperty.all(color.withOpacity(0.1)),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}

/// Color 테이블을 위한 독립적인 정렬 상태를 가진 StatefulWidget
class _ColorTableWithIndependentSort extends StatefulWidget {
  final List summaryByColorList;
  final Color color;
  final String? selectedColorCode;
  final Function(String?)? onColorSelected;

  const _ColorTableWithIndependentSort({
    required this.summaryByColorList,
    required this.color,
    this.selectedColorCode,
    this.onColorSelected,
  });

  @override
  State<_ColorTableWithIndependentSort> createState() => _ColorTableWithIndependentSortState();
}

class _ColorTableWithIndependentSortState extends State<_ColorTableWithIndependentSort> {
  String? _sortColumn;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [Color Table StatefulWidget] build');
    debugPrint('   → _sortColumn: $_sortColumn');
    debugPrint('   → _sortAscending: $_sortAscending');
    debugPrint('   → ⚠️ [해결] Color 테이블이 독립적인 정렬 상태를 가짐');
    debugPrint('═══════════════════════════════════════════════════════');
    
    final color = widget.color;
    
    // 정렬 적용 (Color 테이블만의 독립적인 정렬)
    List<dynamic> sortedList = List.from(widget.summaryByColorList);
    if (_sortColumn != null) {
      sortedList.sort((a, b) {
        if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
          return 0;
        }

        dynamic aValue;
        dynamic bValue;

        if (_sortColumn == 'ColorCode') {
          aValue = a['ColorCode'];
          bValue = b['ColorCode'];
        } else if (_sortColumn == 'ColorName') {
          aValue = a['ColorName']?.toString() ?? '';
          bValue = b['ColorName']?.toString() ?? '';
        } else if (_sortColumn == 'totalCantidad') {
          aValue = num.tryParse(a['totalCantidad']?.toString().replaceAll(',', '') ?? '0') ?? 0;
          bValue = num.tryParse(b['totalCantidad']?.toString().replaceAll(',', '') ?? '0') ?? 0;
        } else {
          return 0;
        }

        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return _sortAscending ? -1 : 1;
        if (bValue == null) return _sortAscending ? 1 : -1;

        if (aValue is num && bValue is num) {
          final comparison = aValue.compareTo(bValue);
          return _sortAscending ? comparison : -comparison;
        }

        final aStr = aValue.toString().toLowerCase();
        final bStr = bValue.toString().toLowerCase();
        final comparison = aStr.compareTo(bStr);
        return _sortAscending ? comparison : -comparison;
      });
    }
    
    // 컬럼 정의
    final columns = [
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Código',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_sortColumn == 'ColorCode')
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
          ],
        ),
        onSort: (columnIndex, ascending) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [Color Table StatefulWidget] ColorCode 칼럼 클릭');
          debugPrint('   → columnIndex: $columnIndex');
          debugPrint('   → ascending: $ascending');
          debugPrint('   → 현재 _sortColumn: $_sortColumn');
          debugPrint('   → 현재 _sortAscending: $_sortAscending');
          debugPrint('   → ✅ [해결] Color 테이블만 정렬됨 (독립적인 정렬 상태)');
          setState(() {
            if (_sortColumn == 'ColorCode') {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = 'ColorCode';
              _sortAscending = true;
            }
          });
          debugPrint('   → 새 _sortColumn: $_sortColumn');
          debugPrint('   → 새 _sortAscending: $_sortAscending');
          debugPrint('═══════════════════════════════════════════════════════');
        },
      ),
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Color',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_sortColumn == 'ColorName')
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
          ],
        ),
        onSort: (columnIndex, ascending) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [Color Table StatefulWidget] ColorName 칼럼 클릭');
          debugPrint('   → columnIndex: $columnIndex');
          debugPrint('   → ascending: $ascending');
          debugPrint('   → 현재 _sortColumn: $_sortColumn');
          debugPrint('   → 현재 _sortAscending: $_sortAscending');
          debugPrint('   → ✅ [해결] Color 테이블만 정렬됨 (독립적인 정렬 상태)');
          setState(() {
            if (_sortColumn == 'ColorName') {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = 'ColorName';
              _sortAscending = true;
            }
          });
          debugPrint('   → 새 _sortColumn: $_sortColumn');
          debugPrint('   → 새 _sortAscending: $_sortAscending');
          debugPrint('═══════════════════════════════════════════════════════');
        },
      ),
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Total Cantidad',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_sortColumn == 'totalCantidad')
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
          ],
        ),
        numeric: true,
        onSort: (columnIndex, ascending) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [Color Table StatefulWidget] totalCantidad 칼럼 클릭');
          debugPrint('   → columnIndex: $columnIndex');
          debugPrint('   → ascending: $ascending');
          debugPrint('   → 현재 _sortColumn: $_sortColumn');
          debugPrint('   → 현재 _sortAscending: $_sortAscending');
          debugPrint('   → ✅ [해결] Color 테이블만 정렬됨 (독립적인 정렬 상태)');
          debugPrint('   → ⚠️ [주의] totalCantidad는 Products 테이블과 같은 키지만 독립적으로 정렬됨');
          setState(() {
            if (_sortColumn == 'totalCantidad') {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = 'totalCantidad';
              _sortAscending = true;
            }
          });
          debugPrint('   → 새 _sortColumn: $_sortColumn');
          debugPrint('   → 새 _sortAscending: $_sortAscending');
          debugPrint('═══════════════════════════════════════════════════════');
        },
      ),
    ];

    // 데이터 행 생성
    final rows = sortedList.map<DataRow>((item) {
      if (item is! Map<String, dynamic>) {
        return DataRow(cells: columns.map((_) => const DataCell(Text(''))).toList());
      }
      
      final colorCode = item['ColorCode']?.toString() ?? '';
      final colorName = item['ColorName']?.toString() ?? '';
      final totalCantidad = item['totalCantidad']?.toString() ?? '0';
      
      final cantidadNum = num.tryParse(totalCantidad.toString().replaceAll(',', '')) ?? 0;
      final formattedCantidad = NumberFormat('#,##0').format(cantidadNum);
      
      final isSelected = widget.selectedColorCode != null && colorCode == widget.selectedColorCode;

      return DataRow(
        selected: isSelected,
        onSelectChanged: widget.onColorSelected != null ? (selected) {
          if (selected != null && selected) {
            widget.onColorSelected!(colorCode);
          } else {
            widget.onColorSelected!(null);
          }
        } : null,
        cells: [
          DataCell(Text(colorCode)),
          DataCell(Text(colorName)),
          DataCell(
            Text(
              formattedCantidad,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 8,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 37,
          headingRowColor: WidgetStateProperty.all(color.withOpacity(0.1)),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}

/// 추출된 데이터를 담는 클래스 (재사용 가능)
class _ExtractedData {
  final Widget? summaryCard;
  final Widget? summaryByCompanyTable;
  final Widget? summaryByCategoryTable;
  final Widget? summaryByColorTable;
  final Widget? productsTable;
  final ScrollController scrollController;
  final Map<String, double>? columnWidths;
  final void Function(String columnKey, double newWidth)? onColumnResize;

  const _ExtractedData({
    this.summaryCard,
    this.summaryByCompanyTable,
    this.summaryByCategoryTable,
    this.summaryByColorTable,
    this.productsTable,
    required this.scrollController,
    this.columnWidths,
    this.onColumnResize,
  });
}

/// 크기 조정 가능한 분할 뷰 위젯
class _ResizableSplitView extends StatefulWidget {
  final Widget leftChild;
  final Widget rightChild;

  const _ResizableSplitView({
    required this.leftChild,
    required this.rightChild,
  });

  @override
  State<_ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<_ResizableSplitView> {
  static const String _prefsKey = 'items_report_left_panel_width';
  static const double _defaultLeftWidth = 350.0;
  static const double _minLeftWidth = 200.0;
  static const double _maxLeftWidth = 800.0;
  static const double _dividerWidth = 4.0;

  double _leftWidth = _defaultLeftWidth;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadSavedWidth();
  }

  Future<void> _loadSavedWidth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedWidth = prefs.getDouble(_prefsKey);
      if (savedWidth != null && savedWidth >= _minLeftWidth && savedWidth <= _maxLeftWidth) {
        setState(() {
          _leftWidth = savedWidth;
        });
      }
    } catch (e) {
      debugPrint('⚠️ 왼쪽 패널 폭 로드 실패: $e');
    }
  }

  Future<void> _saveWidth(double width) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsKey, width);
    } catch (e) {
      debugPrint('⚠️ 왼쪽 패널 폭 저장 실패: $e');
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    final newWidth = _leftWidth + details.delta.dx;
    final clampedWidth = newWidth.clamp(_minLeftWidth, _maxLeftWidth);
    
    if (clampedWidth != _leftWidth) {
      setState(() {
        _leftWidth = clampedWidth;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    _saveWidth(_leftWidth);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [큰 화면 디버깅] _ResizableSplitView build');
        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
        debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
        debugPrint('   → constraints.isTight: ${constraints.isTight}');
        debugPrint('   → constraints.hasBoundedHeight: ${constraints.hasBoundedHeight}');
        debugPrint('   → constraints.hasBoundedWidth: ${constraints.hasBoundedWidth}');
        debugPrint('   → _leftWidth: $_leftWidth');
        debugPrint('   → _minLeftWidth: $_minLeftWidth');
        debugPrint('   → _maxLeftWidth: $_maxLeftWidth');
        debugPrint('   → _dividerWidth: $_dividerWidth');
        debugPrint('   → leftChild 타입: ${widget.leftChild.runtimeType}');
        debugPrint('   → rightChild 타입: ${widget.rightChild.runtimeType}');
        
        // 제약 조건 검증
        if (constraints.maxWidth.isInfinite) {
          debugPrint('   ⚠️ 경고: constraints.maxWidth가 무한대입니다!');
        }
        if (constraints.maxHeight.isInfinite) {
          debugPrint('   ⚠️ 경고: constraints.maxHeight가 무한대입니다!');
        }
        if (!constraints.hasBoundedHeight) {
          debugPrint('   ⚠️ 경고: 높이가 제한되지 않았습니다!');
        }
        if (!constraints.hasBoundedWidth) {
          debugPrint('   ⚠️ 경고: 너비가 제한되지 않았습니다!');
        }
        
        final availableWidth = constraints.maxWidth - _leftWidth - _dividerWidth;
        debugPrint('   → 사용 가능한 오른쪽 패널 너비: $availableWidth');
        
        if (availableWidth < 0) {
          debugPrint('   ❌ 오류: 사용 가능한 너비가 음수입니다!');
        }
        
        debugPrint('═══════════════════════════════════════════════════════');
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽 패널 (너비 제한 + 가로/세로 오버플로우 방지)
            SizedBox(
              width: _leftWidth,
              child: ClipRect(
                clipBehavior: Clip.hardEdge,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: widget.leftChild,
                    ),
                  ),
                ),
              ),
            ),
            // 구분선 (드래그 가능)
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: (details) => _onPanUpdate(details, constraints.maxWidth),
              onPanEnd: _onPanEnd,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: _dividerWidth,
                  color: _isDragging 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                      : Colors.grey[300],
                  child: Center(
                    child: Container(
                      width: 2,
                      height: double.infinity,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
            // 오른쪽 패널
            Expanded(
              child: LayoutBuilder(
                builder: (context, rightConstraints) {
                  debugPrint('🔍 [큰 화면 디버깅] 오른쪽 패널 Expanded 내부');
                  debugPrint('   → rightConstraints.maxWidth: ${rightConstraints.maxWidth}');
                  debugPrint('   → rightConstraints.maxHeight: ${rightConstraints.maxHeight}');
                  debugPrint('   → rightConstraints.isTight: ${rightConstraints.isTight}');
                  
                  return widget.rightChild;
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

