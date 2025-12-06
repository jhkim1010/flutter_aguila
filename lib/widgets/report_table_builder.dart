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
    ScrollController? horizontalScrollController,
  }) {
    if (dataList.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final displayedList = dataList.take(displayedItemsCount).toList();
    final totalCount = dataList.length;
    final reportColor = ReportUtils.getReportColor(reportType);
    
    print('📊 ReportTableBuilder.buildTableFromList - reportType: $reportType, dataList.length: ${dataList.length}, displayedItemsCount: $displayedItemsCount, displayedList.length: ${displayedList.length}');

    if (displayedList.isEmpty) {
      return const Center(child: Text('No items to display'));
    }

    final firstItem = displayedList.first as Map<String, dynamic>;
    
    // Ventas report의 경우 특정 컬럼만 특정 순서로 표시
    // Items report의 경우 start_date, end_date, sucursal 제외
    List<String> keys;
    if (reportType == ReportType.ventas) {
      // 지정된 순서의 컬럼 목록
      final orderedColumns = [
        'vcode',
        'tpago',
        'tefectivo',
        'tcredito',
        'tbanco',
        'treservado',
        'tfavor',
        'cntropas',
        'hora',
        'vendedor',
        'clientenombre',
      ];
      
      // 모든 행에서 공통으로 존재하는 컬럼만 필터링
      final commonKeys = <String>{};
      for (var item in displayedList) {
        if (item is Map<String, dynamic>) {
          if (commonKeys.isEmpty) {
            commonKeys.addAll(orderedColumns.where((key) => item.containsKey(key)));
          } else {
            commonKeys.removeWhere((key) => !item.containsKey(key));
          }
        }
      }
      
      // orderedColumns 순서 유지하면서 commonKeys에 있는 것만
      keys = orderedColumns.where((key) => commonKeys.contains(key)).toList();
    } else if (reportType == ReportType.items) {
      // Items 보고서: start_date, end_date, sucursal 제외
      keys = firstItem.keys
          .where((key) => key != 'start_date' && key != 'end_date' && key != 'sucursal')
          .toList();
    } else {
      keys = firstItem.keys.toList();
    }
    // 컬럼별 기본 너비 설정 (헤더와 일치하도록)
    final columnWidths = <String, double>{
      'codigo1': 120,
      'desc1': 250,
      'tprendas': 100,
      'timporte': 120,
      'start_date': 120,
      'end_date': 120,
      'sucursal': 100,
    };
    
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
      // 헤더를 별도로 분리하여 수평 스크롤 동기화
      final headerRow = _buildHeaderRow(keys, columns, reportColor, sortColumn, sortAscending, onSort);
      
      return Column(
        children: [
          // 헤더 (수평 스크롤 동기화)
          if (horizontalScrollController != null)
            SingleChildScrollView(
              controller: horizontalScrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: headerRow,
            )
          else
            headerRow,
          Expanded(
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // 데이터 부분의 수평 스크롤 이벤트를 헤더에 전달
                  if (notification is ScrollUpdateNotification && 
                      notification.depth == 0 && 
                      notification.metrics.axis == Axis.horizontal &&
                      horizontalScrollController != null &&
                      horizontalScrollController.hasClients) {
                    horizontalScrollController.jumpTo(notification.metrics.pixels);
                  }
                  return false;
                },
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.vertical,
                  child: horizontalScrollController != null
                      ? SingleChildScrollView(
                          controller: horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 8,
                            dataRowMinHeight: 48, // items 보고서는 행 높이를 48로 설정
                            dataRowMaxHeight: 48,
                            headingRowHeight: 0, // 헤더 높이를 0으로 설정하여 숨김
                    headingRowColor: MaterialStateProperty.all(
                              Colors.transparent, // 헤더 배경을 투명하게
                    ),
                    sortColumnIndex: sortColumn != null && keys.contains(sortColumn) 
                        ? keys.indexOf(sortColumn) 
                        : null,
                    sortAscending: sortAscending,
                    columns: columns,
                    rows: displayedList.map((item) {
                      if (item is Map<String, dynamic>) {
                        // 컬럼별 고정 너비 설정 (헤더와 일치)
                        final columnWidths = <String, double>{
                          'codigo1': 150,
                          'desc1': 300,
                          'tprendas': 120,
                          'timporte': 150,
                        };
                        
                        // keys의 각 키에 대해 셀 생성 (키가 없어도 셀은 생성)
                        final cells = keys.map((key) {
                          final value = item[key];
                          String formattedValue;
                          
                          // vcode는 오른쪽 5글자만 표시
                          if (key == 'vcode' && value != null) {
                            final vcodeStr = value.toString();
                            formattedValue = vcodeStr.length > 5 
                                ? vcodeStr.substring(vcodeStr.length - 5)
                                : vcodeStr;
                          } else {
                            // codigo 관련 칼럼은 문자로 처리 (숫자 포맷팅 제외)
                            final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
                            formattedValue = isCodigoColumn 
                                ? (value?.toString() ?? 'N/A')
                                : ReportUtils.formatValue(value);
                          }
                          
                          final isNumeric = (key != 'vcode' && key != 'codigo' && key != 'codigo1' && key != 'tcode' && key != 'id_codigo1') 
                              ? ReportUtils.isNumeric(value) 
                              : false;
                          return DataCell(
                            Align(
                              alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                              child: Text(
                                formattedValue,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList();
                        
                        // 셀 개수가 keys.length와 일치하는지 확인
                        assert(cells.length == keys.length, 
                          'Row cells count (${cells.length}) must match keys count (${keys.length})');
                        
                        return DataRow(cells: cells);
                      }
                      // Map이 아닌 경우에도 keys.length만큼 셀 생성
                      final formattedValue = ReportUtils.formatValue(item);
                      final isNumeric = ReportUtils.isNumeric(item);
                      return DataRow(
                        cells: List.generate(keys.length, (index) {
                          return DataCell(
                            Align(
                              alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                              child: Text(
                                index == 0 ? formattedValue : '',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        }),
                      );
                    }).toList(),
                          ),
                        )
                      : DataTable(
                          columnSpacing: 8,
                          dataRowMinHeight: 5,
                          dataRowMaxHeight: 5,
                          headingRowHeight: 0,
                          headingRowColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                          sortColumnIndex: sortColumn != null && keys.contains(sortColumn) 
                              ? keys.indexOf(sortColumn) 
                              : null,
                          sortAscending: sortAscending,
                          columns: columns,
                          rows: displayedList.map((item) {
                            if (item is Map<String, dynamic>) {
                              final cells = keys.map((key) {
                                final value = item[key];
                                String formattedValue;
                                if (key == 'vcode' && value != null) {
                                  final vcodeStr = value.toString();
                                  formattedValue = vcodeStr.length > 5 
                                      ? vcodeStr.substring(vcodeStr.length - 5)
                                      : vcodeStr;
                                } else {
                                  final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
                                  formattedValue = isCodigoColumn 
                                      ? (value?.toString() ?? 'N/A')
                                      : ReportUtils.formatValue(value);
                                }
                                final isNumeric = (key != 'vcode' && key != 'codigo' && key != 'codigo1' && key != 'tcode' && key != 'id_codigo1') 
                                    ? ReportUtils.isNumeric(value) 
                                    : false;
                                return DataCell(
                                  Align(
                                    alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Text(
                                      formattedValue,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                );
                              }).toList();
                              assert(cells.length == keys.length);
                              return DataRow(cells: cells);
                            }
                            final formattedValue = ReportUtils.formatValue(item);
                            final isNumeric = ReportUtils.isNumeric(item);
                            return DataRow(
                              cells: List.generate(keys.length, (index) {
                                return DataCell(
                                  Align(
                                    alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Text(
                                      index == 0 ? formattedValue : '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                );
                              }),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ),
          ),
          // 고정된 합계 행 (현재 화면에 보이는 항목들의 합계)
          _buildFixedTotalRow(keys, displayedList, reportColor),
        ],
      );
    }

    // 다른 보고서는 기존 방식 유지 (ventas 포함)
    // 헤더를 별도로 분리하여 수평 스크롤 동기화
    final headerRow = _buildHeaderRow(keys, columns, reportColor, sortColumn, sortAscending, onSort);
    
    return Column(
      children: [
        // 헤더 (수평 스크롤 동기화)
        if (horizontalScrollController != null)
          SingleChildScrollView(
            controller: horizontalScrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: headerRow,
          )
        else
          headerRow,
        Expanded(
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // 데이터 부분의 수평 스크롤 이벤트를 헤더에 전달
                if (notification is ScrollUpdateNotification && 
                    notification.depth == 0 && 
                    notification.metrics.axis == Axis.horizontal &&
                    horizontalScrollController != null &&
                    horizontalScrollController.hasClients) {
                  horizontalScrollController.jumpTo(notification.metrics.pixels);
                }
                return false;
              },
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.vertical,
                child: horizontalScrollController != null
                    ? SingleChildScrollView(
                        controller: horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 8,
                  dataRowMinHeight: 5,
                  dataRowMaxHeight: 5,
                  headingRowHeight: 0, // 헤더 높이를 0으로 설정하여 숨김
                  headingRowColor: MaterialStateProperty.all(
                    Colors.transparent, // 헤더 배경을 투명하게
                  ),
                  columns: columns,
                  rows: [
                  ...displayedList.map((item) {
                    if (item is Map<String, dynamic>) {
                      // keys의 각 키에 대해 셀 생성 (키가 없어도 셀은 생성)
                      final cells = keys.map((key) {
                        final value = item[key];
                        String formattedValue;
                        
                        // vcode는 오른쪽 5글자만 표시
                        if (key == 'vcode' && value != null) {
                          final vcodeStr = value.toString();
                          formattedValue = vcodeStr.length > 5 
                              ? vcodeStr.substring(vcodeStr.length - 5)
                              : vcodeStr;
                        } else {
                          // codigo 관련 칼럼은 문자로 처리 (숫자 포맷팅 제외)
                          final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
                          formattedValue = isCodigoColumn 
                              ? (value?.toString() ?? 'N/A')
                              : ReportUtils.formatValue(value);
                        }
                        
                        final isNumeric = (key != 'vcode' && key != 'codigo' && key != 'codigo1' && key != 'tcode' && key != 'id_codigo1') 
                            ? ReportUtils.isNumeric(value) 
                            : false;
                        return DataCell(
                          Align(
                            alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                            child: Text(
                              formattedValue,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        );
                      }).toList();
                      
                      // 셀 개수가 keys.length와 일치하는지 확인
                      assert(cells.length == keys.length, 
                        'Row cells count (${cells.length}) must match keys count (${keys.length})');
                      
                      return DataRow(cells: cells);
                    }
                    // Map이 아닌 경우에도 keys.length만큼 셀 생성
                    final formattedValue = ReportUtils.formatValue(item);
                    final isNumeric = ReportUtils.isNumeric(item);
                    return DataRow(
                      cells: List.generate(keys.length, (index) {
                        return DataCell(
                          Align(
                            alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                            child: Text(
                              index == 0 ? formattedValue : '',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                  // 합계 행 추가
                  _buildTotalRow(keys, dataList, reportColor),
                  ],
                        ),
                      )
                      : DataTable(
                          columnSpacing: 8,
                          dataRowMinHeight: 5,
                          dataRowMaxHeight: 5,
                          headingRowHeight: 0,
                          headingRowColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                          columns: columns,
                          rows: [
                            ...displayedList.map((item) {
                              if (item is Map<String, dynamic>) {
                                final cells = keys.map((key) {
                                  final value = item[key];
                                  String formattedValue;
                                  if (key == 'vcode' && value != null) {
                                    final vcodeStr = value.toString();
                                    formattedValue = vcodeStr.length > 5 
                                        ? vcodeStr.substring(vcodeStr.length - 5)
                                        : vcodeStr;
                                  } else {
                                    final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
                                    formattedValue = isCodigoColumn 
                                        ? (value?.toString() ?? 'N/A')
                                        : ReportUtils.formatValue(value);
                                  }
                                  final isNumeric = (key != 'vcode' && key != 'codigo' && key != 'codigo1' && key != 'tcode' && key != 'id_codigo1') 
                                      ? ReportUtils.isNumeric(value) 
                                      : false;
                                  return DataCell(
                                    Align(
                                      alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Text(
                                        formattedValue,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  );
                                }).toList();
                                assert(cells.length == keys.length);
                                return DataRow(cells: cells);
                              }
                              final formattedValue = ReportUtils.formatValue(item);
                              final isNumeric = ReportUtils.isNumeric(item);
                              return DataRow(
                                cells: List.generate(keys.length, (index) {
                                  return DataCell(
                                    Align(
                                      alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Text(
                                        index == 0 ? formattedValue : '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            }),
                            _buildTotalRow(keys, dataList, reportColor),
                          ],
                        ),
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

  // 헤더 행 빌드 (수평 스크롤 동기화용)
  static Widget _buildHeaderRow(
    List<String> keys,
    List<DataColumn> columns,
    Color reportColor,
    String? sortColumn,
    bool sortAscending,
    Function(int columnIndex, bool ascending)? onSort,
  ) {
    // DataTable의 헤더와 동일한 스타일로 헤더 행 생성
    // DataTable의 columnSpacing(8)을 고려하여 각 컬럼에 동일한 간격 적용
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: reportColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[400]!,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: columns.asMap().entries.map((entry) {
          final index = entry.key;
          final column = entry.value;
          final key = keys[index];
          final isSorted = sortColumn == key;
          
          // 컬럼별 고정 너비 설정 (DataTable과 일치)
          final columnWidths = <String, double>{
            'codigo1': 150,
            'desc1': 300,
            'tprendas': 120,
            'timporte': 150,
          };
          final columnWidth = columnWidths[key] ?? 150.0;
          
          // label에서 텍스트 추출
          String labelText = '';
          if (column.label is Row) {
            final row = column.label as Row;
            for (var child in row.children) {
              if (child is Text) {
                labelText = child.data ?? '';
                break;
              }
            }
          } else if (column.label is Text) {
            labelText = (column.label as Text).data ?? '';
          } else {
            labelText = key.toString();
          }
          
          // 고정 너비로 설정하여 DataTable과 정확히 일치 (columnSpacing 8px 고려)
          return SizedBox(
            width: columnWidth + (index < columns.length - 1 ? 8 : 0), // 마지막 컬럼 제외하고 8px 간격 추가
            child: InkWell(
              onTap: column.onSort != null
                  ? () {
                      if (isSorted) {
                        column.onSort!(index, !sortAscending);
                      } else {
                        column.onSort!(index, false); // 첫 클릭 시 내림차순
                      }
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        labelText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSorted && column.onSort != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: reportColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
        dataRowMinHeight: 5,
        dataRowMaxHeight: 5,
        headingRowColor: MaterialStateProperty.all(
          reportColor.withOpacity(0.1),
        ),
        columns: columns,
        rows: rows,
      ),
    );
  }
}

