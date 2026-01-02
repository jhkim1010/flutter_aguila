import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'report_utils.dart';
import '../utils/platform_utils.dart';
import 'report_table_builder.dart';

/// Ingresos 보고서 UI 빌더
class IngresosBuilder {
  /// Ingresos 콘텐츠 빌드 (화면 크기에 따라 적절한 레이아웃 선택)
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
    String? selectedCompanyCode,
    Function(String?)? onCompanySelected,
  }) {
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
      selectedCompanyCode: selectedCompanyCode,
      onCompanySelected: onCompanySelected,
    );

    // 화면 크기에 따라 적절한 레이아웃 선택
    if (PlatformUtils.isDesktop()) {
      // macOS, Windows 대형 화면
      return _buildContentForDesktop(extractedData);
    } else if (PlatformUtils.isIPad(context)) {
      // iPad 태블릿 화면
      return _buildContentForTablet(extractedData);
    } else {
      // 모바일 화면
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
    String? selectedCompanyCode,
    Function(String?)? onCompanySelected,
  }) {
    // summary 카드
    Widget? summaryCard;
    if (data.containsKey('summary') && data['summary'] is Map) {
      summaryCard = _buildSummaryCard(data['summary'] as Map<String, dynamic>);
    }

    // summary_by_company 테이블
    Widget? summaryByCompanyTable;
    if (data.containsKey('data') && 
        data['data'] is Map &&
        (data['data'] as Map).containsKey('summary_by_company') &&
        (data['data'] as Map)['summary_by_company'] is List) {
      final summaryByCompanyList = (data['data'] as Map)['summary_by_company'] as List;
      summaryByCompanyTable = _buildSummaryByCompanyTable(
        summaryByCompanyList,
        context,
        onSort: onSort,
        sortColumn: sortColumn,
        sortAscending: sortAscending,
        reportColor: reportColor,
        selectedCompanyCode: selectedCompanyCode,
        onCompanySelected: onCompanySelected,
      );
    }

    // summary_by_category 테이블
    Widget? summaryByCategoryTable;
    if (data.containsKey('data') && 
        data['data'] is Map &&
        (data['data'] as Map).containsKey('summary_by_category') &&
        (data['data'] as Map)['summary_by_category'] is List) {
      final summaryByCategoryList = (data['data'] as Map)['summary_by_category'] as List;
      summaryByCategoryTable = _buildSummaryByCategoryTable(
        summaryByCategoryList,
        context,
        onSort: onSort,
        sortColumn: sortColumn,
        sortAscending: sortAscending,
        reportColor: reportColor,
        selectedCategoryCode: selectedCategoryCode,
        onCategorySelected: onCategorySelected,
      );
    }

    // products 테이블
    Widget? productsTable;
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📊 [IngresosBuilder] productsTable 추출 시작');
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
                  final codigo = item['codigo']?.toString().toLowerCase() ?? '';
                  final descripcion = item['descripcion']?.toString().toLowerCase() ?? '';
                  final productName = item['ProductName']?.toString().toLowerCase() ?? '';
                  return codigo.contains(filterLower) || 
                         descripcion.contains(filterLower) || 
                         productName.contains(filterLower);
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
            
            // selectedCompanyCode 필터 적용
            if (selectedCompanyCode != null && selectedCompanyCode.isNotEmpty) {
              debugPrint('   → selectedCompanyCode: $selectedCompanyCode');
              productsList = productsList.where((item) {
                if (item is Map<String, dynamic>) {
                  final companyCode = item['CompanyCode']?.toString() ?? '';
                  return companyCode == selectedCompanyCode;
                }
                return false;
              }).toList();
              debugPrint('   → productsList.length (selectedCompanyCode 필터링 후): ${productsList.length}');
            }
            
            if (productsList.isNotEmpty) {
              debugPrint('═══════════════════════════════════════════════════════');
              debugPrint('📊 [IngresosBuilder] productsTable 생성 시작');
              debugPrint('   → productsList.length: ${productsList.length}');
              debugPrint('   → displayedItemsCount: $displayedItemsCount');
              debugPrint('   → itemsPerPage: $itemsPerPage');
              debugPrint('   → scrollController: ${scrollController != null}');
              debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');
              
              productsTable = ReportTableBuilder.buildTableFromList(
                productsList,
                displayedItemsCount,
                itemsPerPage,
                scrollController,
                ReportType.ingresos,
                sortColumn: sortColumn,
                sortAscending: sortAscending,
                horizontalScrollController: horizontalScrollController,
                reportColor: reportColor,
                onSort: (columnIndex, ascending) {
                  final allKeys = productsList.isNotEmpty 
                      ? (productsList.first as Map<String, dynamic>).keys.toList()
                      : <String>[];
                  if (columnIndex >= 0 && columnIndex < allKeys.length) {
                    final key = allKeys[columnIndex];
                    onSort(key, ascending);
                  }
                },
              );
              
              debugPrint('   → productsTable: 생성됨 (타입: ${productsTable.runtimeType})');
            } else {
              debugPrint('   ⚠️ [IngresosBuilder] productsList가 비어있습니다! (필터링 후)');
            }
          } else {
            debugPrint('   ⚠️ [IngresosBuilder] data["data"]["products"]가 List가 아닙니다!');
          }
        } else {
          debugPrint('   ⚠️ [IngresosBuilder] data["data"]에 "products" 키가 없습니다!');
        }
      } else {
        debugPrint('   ⚠️ [IngresosBuilder] data["data"]가 Map가 아닙니다!');
      }
    } else {
      debugPrint('   ⚠️ [IngresosBuilder] data에 "data" 키가 없습니다!');
    }
    debugPrint('═══════════════════════════════════════════════════════');

    return _ExtractedData(
      summaryCard: summaryCard,
      summaryByCompanyTable: summaryByCompanyTable,
      summaryByCategoryTable: summaryByCategoryTable,
      productsTable: productsTable,
    );
  }

  /// macOS/Windows 대형 화면용 레이아웃 (좌우 분할 레이아웃)
  static Widget _buildContentForDesktop(_ExtractedData data) {
    // 좌우 분할 레이아웃이 가능한 경우
    if ((data.summaryByCompanyTable != null || data.summaryByCategoryTable != null) && 
        data.productsTable != null) {
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
              child: _ResizableSplitView(
                leftChild: _buildLeftPanel(
                  summaryByCompanyTable: data.summaryByCompanyTable,
                  summaryByCategoryTable: data.summaryByCategoryTable,
                ),
                rightChild: _buildRightPanel(
                  productsTable: data.productsTable!,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // summary 테이블이 없는 경우: 세로로 배치
    return _buildVerticalLayout(data);
  }

  /// iPad 태블릿 화면용 레이아웃 (현재는 desktop과 동일하게 처리)
  static Widget _buildContentForTablet(_ExtractedData data) {
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
  }) {
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
        ],
      ],
    );
  }

  /// 오른쪽 패널 빌드 (재사용 가능한 헬퍼 함수)
  static Widget _buildRightPanel({
    required Widget productsTable,
  }) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📊 [IngresosBuilder] _buildRightPanel 시작');
    debugPrint('   → productsTable 타입: ${productsTable.runtimeType}');
    debugPrint('═══════════════════════════════════════════════════════');
    
    return LayoutBuilder(
      builder: (context, constraints) {
        debugPrint('📊 [IngresosBuilder] _buildRightPanel LayoutBuilder');
        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
        debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            const Text(
              'Productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, expandedConstraints) {
                  debugPrint('📊 [IngresosBuilder] _buildRightPanel Expanded LayoutBuilder');
                  debugPrint('   → expandedConstraints.maxWidth: ${expandedConstraints.maxWidth}');
                  debugPrint('   → expandedConstraints.maxHeight: ${expandedConstraints.maxHeight}');
                  
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: expandedConstraints.maxWidth,
                      maxWidth: expandedConstraints.maxWidth,
                    ),
                    child: SizedBox(
                      width: expandedConstraints.maxWidth,
                      child: productsTable,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// 세로 배치 레이아웃 (재사용 가능한 헬퍼 함수)
  static Widget _buildVerticalLayout(_ExtractedData data) {
    return Padding(
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
          if (data.productsTable != null) ...[
            const Text(
              'Productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: data.productsTable!),
          ],
        ],
      ),
    );
  }

  /// Summary 카드 빌드
  static Widget _buildSummaryCard(Map<String, dynamic> summary) {
    final totalCompanies = summary['total_companies']?.toString() ?? '0';
    final totalCategories = summary['total_categories']?.toString() ?? '0';
    final totalProducts = summary['total_products']?.toString() ?? '0';
    final totalCantidad = summary['total_cantidad']?.toString() ?? '0';
    
    final cantidadNum = num.tryParse(totalCantidad.toString().replaceAll(',', '')) ?? 0;
    final formattedCantidad = NumberFormat('#,##0').format(cantidadNum);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Total Empresas', totalCompanies, Icons.business, Colors.blue),
            _buildSummaryItem('Total Categorías', totalCategories, Icons.category, Colors.green),
            _buildSummaryItem('Total Productos', totalProducts, Icons.inventory, Colors.orange),
            _buildSummaryItem('Total Cantidad', formattedCantidad, Icons.shopping_cart, Colors.purple),
          ],
        ),
      ),
    );
  }

  /// 요약 아이템 빌드
  static Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
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
    String? selectedCompanyCode,
    Function(String?)? onCompanySelected,
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
      
      final isSelected = selectedCompanyCode != null && companyCode == selectedCompanyCode;

      return DataRow(
        selected: isSelected,
        onSelectChanged: onCompanySelected != null ? (selected) {
          if (selected != null && selected) {
            // 선택된 경우: 해당 회사 코드로 필터링
            onCompanySelected(companyCode);
          } else {
            // 선택 해제된 경우: 필터 제거
            onCompanySelected(null);
          }
        } : null,
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
          dataRowMinHeight: 32,  // items 보고서와 동일하게 2/3로 조정 (48 * 2/3 = 32)
          dataRowMaxHeight: 37,  // items 보고서와 동일하게 2/3로 조정 (56 * 2/3 ≈ 37)
          headingRowColor: MaterialStateProperty.all(color.withOpacity(0.1)),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }

  /// 카테고리별 요약 테이블 빌드
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
    if (summaryByCategoryList.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = reportColor ?? Colors.green;
    
    // 정렬 적용
    List<dynamic> sortedList = List.from(summaryByCategoryList);
    if (sortColumn != null && onSort != null) {
      sortedList.sort((a, b) {
        if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
          return 0;
        }

        dynamic aValue;
        dynamic bValue;

        if (sortColumn == 'CategoryCode') {
          aValue = a['CategoryCode'];
          bValue = b['CategoryCode'];
        } else if (sortColumn == 'CategoryName') {
          aValue = a['CategoryName']?.toString() ?? '';
          bValue = b['CategoryName']?.toString() ?? '';
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
            if (sortColumn == 'CategoryCode' && onSort != null)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
          ],
        ),
        onSort: onSort != null ? (columnIndex, ascending) {
          if (sortColumn == 'CategoryCode') {
            onSort('CategoryCode', !sortAscending);
          } else {
            onSort('CategoryCode', true);
          }
        } : null,
      ),
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Categoría',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sortColumn == 'CategoryName' && onSort != null)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
          ],
        ),
        onSort: onSort != null ? (columnIndex, ascending) {
          if (sortColumn == 'CategoryName') {
            onSort('CategoryName', !sortAscending);
          } else {
            onSort('CategoryName', true);
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
      
      final categoryCode = item['CategoryCode']?.toString() ?? '';
      final categoryName = item['CategoryName']?.toString() ?? '';
      final totalCantidad = item['totalCantidad']?.toString() ?? '0';
      
      final cantidadNum = num.tryParse(totalCantidad.toString().replaceAll(',', '')) ?? 0;
      final formattedCantidad = NumberFormat('#,##0').format(cantidadNum);
      
      final isSelected = selectedCategoryCode != null && categoryCode == selectedCategoryCode;

      return DataRow(
        selected: isSelected,
        onSelectChanged: onCategorySelected != null ? (selected) {
          if (selected != null && selected) {
            // 선택된 경우: 해당 카테고리 코드로 필터링
            onCategorySelected(categoryCode);
          } else {
            // 선택 해제된 경우: 필터 제거
            onCategorySelected(null);
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
          dataRowMinHeight: 32,  // items 보고서와 동일하게 2/3로 조정 (48 * 2/3 = 32)
          dataRowMaxHeight: 37,  // items 보고서와 동일하게 2/3로 조정 (56 * 2/3 ≈ 37)
          headingRowColor: MaterialStateProperty.all(color.withOpacity(0.1)),
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
  final Widget? productsTable;

  const _ExtractedData({
    this.summaryCard,
    this.summaryByCompanyTable,
    this.summaryByCategoryTable,
    this.productsTable,
  });
}

/// 크기 조정 가능한 분할 뷰 위젯 (Ingresos용)
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
  static const String _prefsKey = 'ingresos_report_left_panel_width';
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
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽 패널
            SizedBox(
              width: _leftWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SingleChildScrollView(
                  child: widget.leftChild,
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
              child: widget.rightChild,
            ),
          ],
        );
      },
    );
  }
}
