import 'package:flutter/material.dart';
import 'report_utils.dart';

class ReportTableBuilder {
  static Widget buildTableFromList(
    List<dynamic> dataList,
    int displayedItemsCount,
    int itemsPerPage,
    ScrollController scrollController,
    ReportType reportType, {
    String? sortColumn,
    bool sortAscending = true,
    Function(int columnIndex, bool ascending)? onSort,
  }) {
    if (dataList.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final displayedList = dataList.take(displayedItemsCount).toList();
    final totalCount = dataList.length;
    final reportColor = ReportUtils.getReportColor(reportType);

    final firstItem = displayedList.first as Map<String, dynamic>;
    final keys = firstItem.keys.toList();
    final columns = keys.asMap().entries.map((entry) {
      final index = entry.key;
      final key = entry.value;
      final isSorted = sortColumn == key;
      final isSortable = reportType == ReportType.items && (key == 'codigo' || key == 'desc1' || key == 'tprendas' || key == 'timporte');
      
      return DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              key.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (isSorted && isSortable)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: reportColor,
              ),
          ],
        ),
        onSort: isSortable && onSort != null
            ? (columnIndex, ascending) {
                // DataTable이 전달하는 columnIndex는 columns 리스트의 인덱스이므로
                // keys 리스트의 인덱스와 동일합니다
                onSort(columnIndex, ascending);
              }
            : null,
      );
    }).toList();

    // Items 보고서의 경우 합계 행을 화면 하단에 고정하면서 수직 스크롤 가능
    if (reportType == ReportType.items) {
      return Column(
        children: [
          Expanded(
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 8,
                    headingRowColor: MaterialStateProperty.all(
                      reportColor.withOpacity(0.1),
                    ),
                    sortColumnIndex: sortColumn != null && keys.contains(sortColumn) 
                        ? keys.indexOf(sortColumn) 
                        : null,
                    sortAscending: sortAscending,
                    columns: columns,
                    rows: displayedList.map((item) {
                      if (item is Map<String, dynamic>) {
                        return DataRow(
                          cells: firstItem.keys.map((key) {
                            final value = item[key];
                            // codigo 관련 칼럼은 문자로 처리 (숫자 포맷팅 제외)
                            final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
                            final formattedValue = isCodigoColumn 
                                ? (value?.toString() ?? 'N/A')
                                : ReportUtils.formatValue(value);
                            final isNumeric = isCodigoColumn ? false : ReportUtils.isNumeric(value);
                            return DataCell(
                              Align(
                                alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                                child: Text(
                                  formattedValue,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }
                      final formattedValue = ReportUtils.formatValue(item);
                      final isNumeric = ReportUtils.isNumeric(item);
                      return DataRow(
                        cells: [
                          DataCell(
                            Align(
                              alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                              child: Text(
                                formattedValue,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          // 고정된 합계 행 (현재 화면에 보이는 항목들의 합계)
          _buildFixedTotalRow(firstItem.keys.toList(), displayedList, reportColor),
        ],
      );
    }

    // 다른 보고서는 기존 방식 유지
    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 8,
                headingRowColor: MaterialStateProperty.all(
                  reportColor.withOpacity(0.1),
                ),
                columns: columns,
                rows: [
                  ...displayedList.map((item) {
                    if (item is Map<String, dynamic>) {
                      return DataRow(
                        cells: firstItem.keys.map((key) {
                          final value = item[key];
                          // codigo 관련 칼럼은 문자로 처리 (숫자 포맷팅 제외)
                          final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
                          final formattedValue = isCodigoColumn 
                              ? (value?.toString() ?? 'N/A')
                              : ReportUtils.formatValue(value);
                          final isNumeric = isCodigoColumn ? false : ReportUtils.isNumeric(value);
                          return DataCell(
                            Align(
                              alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                              child: Text(
                                formattedValue,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }
                    final formattedValue = ReportUtils.formatValue(item);
                    final isNumeric = ReportUtils.isNumeric(item);
                    return DataRow(
                      cells: [
                        DataCell(
                          Align(
                            alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                            child: Text(
                              formattedValue,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  // 합계 행 추가
                  _buildTotalRow(firstItem.keys.toList(), dataList, reportColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 고정된 합계 행 빌드 (화면 하단에 고정, 현재 보이는 항목들의 합계)
  static Widget _buildFixedTotalRow(List<String> keys, List<dynamic> displayedList, Color reportColor) {
    // 각 칼럼별 합계 계산 (현재 화면에 보이는 항목들만)
    final totals = <String, num>{};
    
    for (var key in keys) {
      final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
      if (isCodigoColumn) continue; // 문자 칼럼은 합계 계산 제외
      
      num sum = 0;
      for (var item in displayedList) {
        if (item is Map<String, dynamic> && item.containsKey(key)) {
          final value = item[key];
          if (ReportUtils.isNumeric(value)) {
            final numValue = num.tryParse(value.toString().replaceAll(',', '').replaceAll('\$', '').trim());
            if (numValue != null) {
              sum += numValue;
            }
          }
        }
      }
      totals[key] = sum;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: reportColor.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: reportColor.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: keys.map((key) {
            final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
            final cellWidth = 120.0; // 각 셀의 너비
            
            if (isCodigoColumn) {
              return SizedBox(
                width: cellWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Total',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }
            
            final total = totals[key] ?? 0;
            return SizedBox(
              width: cellWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    ReportUtils.formatValue(total),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 합계 행 빌드
  static DataRow _buildTotalRow(List<String> keys, List<dynamic> dataList, Color reportColor) {
    // 각 칼럼별 합계 계산
    final totals = <String, num>{};
    
    for (var key in keys) {
      final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
      if (isCodigoColumn) continue; // 문자 칼럼은 합계 계산 제외
      
      num sum = 0;
      for (var item in dataList) {
        if (item is Map<String, dynamic> && item.containsKey(key)) {
          final value = item[key];
          if (ReportUtils.isNumeric(value)) {
            final numValue = num.tryParse(value.toString().replaceAll(',', '').replaceAll('\$', '').trim());
            if (numValue != null) {
              sum += numValue;
            }
          }
        }
      }
      totals[key] = sum;
    }
    
    return DataRow(
      color: MaterialStateProperty.all(reportColor.withOpacity(0.1)),
      cells: keys.map((key) {
        final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
        if (isCodigoColumn) {
          return DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
        
        final total = totals[key] ?? 0;
        return DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              ReportUtils.formatValue(total),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Map 형태 테이블용 합계 행 빌드
  static DataRow _buildTotalRowForMapTable(Map<String, dynamic> data, Color reportColor) {
    final totals = <String, num>{};
    
    for (var key in data.keys) {
      final value = data[key];
      if (value is List) {
        num sum = 0;
        for (var item in value) {
          if (ReportUtils.isNumeric(item)) {
            final numValue = num.tryParse(item.toString().replaceAll(',', '').replaceAll('\$', '').trim());
            if (numValue != null) {
              sum += numValue;
            }
          }
        }
        totals[key] = sum;
      }
    }
    
    return DataRow(
      color: MaterialStateProperty.all(reportColor.withOpacity(0.1)),
      cells: data.keys.map((key) {
        final total = totals[key] ?? 0;
        return DataCell(
          Text(
            ReportUtils.formatValue(total),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  static bool isTableData(Map<String, dynamic> data) {
    return data.values.every((value) => value is List);
  }

  static Widget buildTable(
    Map<String, dynamic> data,
    ReportType reportType,
  ) {
    final columns = data.keys.map((key) {
      return DataColumn(
        label: Text(
          key.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }).toList();

    final firstKey = data.keys.first;
    final rowCount = (data[firstKey] as List).length;
    final reportColor = ReportUtils.getReportColor(reportType);

    final rows = List.generate(rowCount, (index) {
      return DataRow(
        cells: data.keys.map((key) {
          final value = data[key];
          if (value is List && index < value.length) {
            final cellValue = value[index];
            final formattedValue = ReportUtils.formatValue(cellValue);
            final isNumeric = ReportUtils.isNumeric(cellValue);
            return DataCell(
              Text(
                formattedValue,
                textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              ),
            );
          }
          return const DataCell(Text(''));
        }).toList(),
      );
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 8,
        headingRowColor: MaterialStateProperty.all(
          reportColor.withOpacity(0.1),
        ),
        columns: columns,
        rows: rows,
      ),
    );
  }
}

