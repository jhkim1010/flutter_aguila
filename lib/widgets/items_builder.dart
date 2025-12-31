import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'report_utils.dart';
import '../utils/platform_utils.dart';
import 'report_table_builder.dart';

/// Items 보고서 UI 빌더
class ItemsBuilder {
  /// Items 콘텐츠 빌드
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
      );
    }

    // products 테이블
    Widget? productsTable;
    if (data.containsKey('data') && 
        data['data'] is Map &&
        (data['data'] as Map).containsKey('products') &&
        (data['data'] as Map)['products'] is List) {
      var productsList = (data['data'] as Map)['products'] as List;
      
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
      }
      
      if (productsList.isNotEmpty) {
        productsTable = ReportTableBuilder.buildTableFromList(
          productsList,
          displayedItemsCount,
          itemsPerPage,
          scrollController,
          ReportType.items,
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
      }
    }

    // macOS, Windows, iPad 넓은 화면인지 확인
    final isLargeScreen = PlatformUtils.isDesktop() || 
                          PlatformUtils.isIPad(context) ||
                          (MediaQuery.of(context).size.width >= 1200);

    // 넓은 화면이고 summary 테이블들과 products 테이블이 모두 있는 경우 좌우 분할 레이아웃
    if (isLargeScreen && 
        (summaryByCompanyTable != null || summaryByCategoryTable != null) && 
        productsTable != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 부분 (summaryCard)
            if (summaryCard != null) ...[
              summaryCard,
              const SizedBox(height: 24),
            ],
            // 좌우 분할 레이아웃
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽: summary_by_company + summary_by_category (오른쪽의 절반 폭)
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            Expanded(
                              flex: 1,
                              child: summaryByCompanyTable,
                            ),
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
                            Expanded(
                              flex: 1,
                              child: summaryByCategoryTable,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // 오른쪽: products 테이블 (왼쪽의 2배 폭)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          child: SizedBox(
                            width: double.infinity,
                            child: productsTable,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 작은 화면 또는 summary 테이블이 없는 경우: 세로로 배치
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summaryCard != null) ...[
            summaryCard,
            const SizedBox(height: 24),
          ],
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
          if (productsTable != null) ...[
            const Text(
              'Productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: productsTable),
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
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
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

      return DataRow(
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
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
          headingRowColor: MaterialStateProperty.all(color.withOpacity(0.1)),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}

