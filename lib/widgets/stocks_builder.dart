import 'package:flutter/material.dart';
import 'report_utils.dart';
import '../utils/mobile_layout_helper.dart';
import 'resizable_data_table.dart';

/// Stocks 보고서 UI 빌더
class StocksBuilder {
  /// 칼럼 키 순서 (헤더·행과 동일)
  static const List<String> stockColumnKeys = [
    'codigo', 'descripcion', 'totaling', 'totalventa', 'todayingreso', 'todayventa',
    'totalreservado', 'cntoffset', 'stockreal', 'porcentaje', 'first_date', 'last_date',
    'pre1', 'pre2', 'pre3', 'pre4', 'pre5', 'sucursal', 'id_codigo1',
  ];

  /// 기본 칼럼 너비
  static Map<String, double> get defaultStockColumnWidths => {
    'codigo': 120, 'descripcion': 250, 'totaling': 90, 'totalventa': 100,
    'todayingreso': 110, 'todayventa': 100, 'totalreservado': 120, 'cntoffset': 100,
    'stockreal': 100, 'porcentaje': 100, 'first_date': 100, 'last_date': 100,
    'pre1': 90, 'pre2': 90, 'pre3': 90, 'pre4': 90, 'pre5': 90,
    'sucursal': 90, 'id_codigo1': 100,
  };

  /// 칼럼 표시 이름
  static Map<String, String> get stockColumnDisplayNames => {
    'codigo': 'Codigo', 'descripcion': 'Descripción', 'totaling': 'Totaling',
    'totalventa': 'Total Venta', 'todayingreso': 'Today Ingreso', 'todayventa': 'Today Venta',
    'totalreservado': 'Total Reservado', 'cntoffset': 'Cnt Offset', 'stockreal': 'Stock Real',
    'porcentaje': 'Porcentaje', 'first_date': 'First Date', 'last_date': 'Last Date',
    'pre1': 'Precio 1', 'pre2': 'Precio 2', 'pre3': 'Precio 3', 'pre4': 'Precio 4', 'pre5': 'Precio 5',
    'sucursal': 'Sucursal', 'id_codigo1': 'ID Codigo1',
  };

  /// ResizableDataTable에 전달할 칼럼 정의 리스트.
  static List<TableColumnDef> buildColumnDefs() => [
    const TableColumnDef(key: 'codigo',         label: 'Codigo',          defaultWidth: 120, sortable: true),
    const TableColumnDef(key: 'descripcion',    label: 'Descripción',     defaultWidth: 250, sortable: true),
    const TableColumnDef(key: 'totaling',       label: 'Totaling',        defaultWidth: 90,  textAlign: TextAlign.right),
    const TableColumnDef(key: 'totalventa',     label: 'Total Venta',     defaultWidth: 100, textAlign: TextAlign.right),
    const TableColumnDef(key: 'todayingreso',   label: 'Today Ingreso',   defaultWidth: 110, textAlign: TextAlign.right),
    const TableColumnDef(key: 'todayventa',     label: 'Today Venta',     defaultWidth: 100, textAlign: TextAlign.right),
    const TableColumnDef(key: 'totalreservado', label: 'Total Reservado', defaultWidth: 120, textAlign: TextAlign.right),
    const TableColumnDef(key: 'cntoffset',      label: 'Cnt Offset',      defaultWidth: 100, textAlign: TextAlign.right),
    const TableColumnDef(key: 'stockreal',      label: 'Stock Real',      defaultWidth: 100, textAlign: TextAlign.right),
    const TableColumnDef(key: 'porcentaje',     label: 'Porcentaje',      defaultWidth: 100, textAlign: TextAlign.right),
    const TableColumnDef(key: 'first_date',     label: 'First Date',      defaultWidth: 100),
    const TableColumnDef(key: 'last_date',      label: 'Last Date',       defaultWidth: 100),
    const TableColumnDef(key: 'pre1',           label: 'Precio 1',        defaultWidth: 90,  textAlign: TextAlign.right),
    const TableColumnDef(key: 'pre2',           label: 'Precio 2',        defaultWidth: 90,  textAlign: TextAlign.right),
    const TableColumnDef(key: 'pre3',           label: 'Precio 3',        defaultWidth: 90,  textAlign: TextAlign.right),
    const TableColumnDef(key: 'pre4',           label: 'Precio 4',        defaultWidth: 90,  textAlign: TextAlign.right),
    const TableColumnDef(key: 'pre5',           label: 'Precio 5',        defaultWidth: 90,  textAlign: TextAlign.right),
    const TableColumnDef(key: 'sucursal',       label: 'Sucursal',        defaultWidth: 90,  textAlign: TextAlign.center),
    const TableColumnDef(key: 'id_codigo1',     label: 'ID Codigo1',      defaultWidth: 100, textAlign: TextAlign.right),
  ];

  /// 데이터 리스트를 셀 위젯 리스트로 변환.
  /// 셀 크기(SizedBox 래핑)는 ResizableDataTable 내부에서 columnWidths 기준으로 적용된다.
  static List<List<Widget>> buildRows(List<dynamic> data) {
    return data.map((item) => _buildRowCells(item as Map<String, dynamic>)).toList();
  }

  static List<Widget> _buildRowCells(Map<String, dynamic> stock) {
    String val(String key) => stock[key]?.toString() ?? 'N/A';
    return [
      Text(stock['codigo']?.toString() ?? stock['tcode']?.toString() ?? 'N/A',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(stock['descripcion']?.toString() ?? stock['tdesc']?.toString() ?? 'N/A',
          style: TextStyle(fontSize: 10, color: Colors.grey[700]),
          maxLines: 5, overflow: TextOverflow.ellipsis),
      Text(val('totaling'),       style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(val('totalventa'),     style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(val('todayingreso'),   style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(val('todayventa'),     style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(val('totalreservado'), style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(val('cntoffset'),      style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(stock['stockreal']?.toString() ?? stock['stockreal3']?.toString() ?? 'N/A',
          style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(_formatPorcentaje(stock['porcentaje']),
          style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(val('first_date'),  style: TextStyle(fontSize: 10, color: Colors.grey[700])),
      Text(val('last_date'),   style: TextStyle(fontSize: 10, color: Colors.grey[700])),
      Text(val('pre1'),  style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(val('pre2'),  style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(val('pre3'),  style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(val('pre4'),  style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(val('pre5'),  style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(val('sucursal'),   style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.center),
      Text(val('id_codigo1'), style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
    ];
  }

  /// Stocks 콘텐츠 빌드
  static Widget buildContent({
    required Map<String, dynamic> data,
    required BuildContext context,
    required ScrollController scrollController,
    required bool isLoadingMore,
    required Color reportColor,
    required Widget headerWidget, // 헤더 위젯 추가
    required Map<String, double> columnWidths,
  }) {
    // 새로운 응답 형식 지원: data 배열이 최상위에 있음
    final dataList = data['data'] as List? ?? [];
    
    print('📊 Stocks 데이터: ${dataList.length}개 항목');
    
    if (dataList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No hay datos disponibles',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    
    final filteredDataList = dataList;
    
    // 실제 컨텐츠 너비 계산 (columnWidths 합 + 간격)
    final columnsTotalWidth = stockColumnKeys.fold(0.0, (sum, k) => sum + (columnWidths[k] ?? 100));
    const double columnGap = 8.0;
    final rowContentWidth = columnsTotalWidth + (stockColumnKeys.length - 1) * columnGap;
    const containerPadding = 32.0; // 좌우 padding
    const extraPadding = 20.0; // 오른쪽 끝 패턴 방지를 위한 추가 공간
    final totalWidth = rowContentWidth + containerPadding + extraPadding;
    final kMinWidthForNoScroll = rowContentWidth + 32.0;
    final screenWidth = MediaQuery.of(context).size.width;
    // 주의: needsHorizontalScroll은 LayoutBuilder 내부에서 실제 제약(expandedConstraints.maxWidth)으로 계산함.
    // MediaQuery.size만 쓰면 패널/사이드바 등으로 실제 가용 너비가 더 좁을 때 오버플로우 발생.
    
    final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
    final isMobilePhone = layoutInfo.isMobilePhone;
    final isMobilePhonePortrait = layoutInfo.isMobilePhonePortrait;
    final isMobilePhoneLandscape = layoutInfo.isMobilePhoneLandscape;
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📱 [Stocks Builder] buildContent 시작');
    debugPrint('   → isMobilePhone: $isMobilePhone');
    debugPrint('   → screenWidth (MediaQuery): $screenWidth');
    debugPrint('   → totalWidth (필요): $totalWidth');
    debugPrint('   → kMinWidthForNoScroll: $kMinWidthForNoScroll');
    debugPrint('   → needsHorizontalScroll: LayoutBuilder 내부에서 실제 제약으로 결정');
    debugPrint('   → dataList.length: ${dataList.length}');
    debugPrint('═══════════════════════════════════════════════════════');

    // 헤더와 Row의 크기를 추적하기 위한 GlobalKey (디버그 측정 전용 - 위젯 key로 사용 금지)
    final headerKey = GlobalKey();
    final firstRowKey = GlobalKey();
    // 주의: 위 GlobalKey들은 addPostFrameCallback에서 크기 측정용으로만 사용.
    // SizedBox key로 사용하면 매 빌드마다 헤더가 재생성되어 ResizeHandle 상태가 리셋됨.
    
    return Builder(
      builder: (context) {
        // 렌더링 후 실제 크기 측정 (오버플로우 분석용)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            final RenderBox? columnBox = context.findRenderObject() as RenderBox?;
            final RenderBox? headerBox = headerKey.currentContext?.findRenderObject() as RenderBox?;
            final RenderBox? rowBox = firstRowKey.currentContext?.findRenderObject() as RenderBox?;
            
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('📱 [Stocks Builder] 렌더링 후 크기 측정');
            if (columnBox != null) {
              debugPrint('   → Column size: ${columnBox.size}');
              debugPrint('   → Column constraints: ${columnBox.constraints}');
            }
            if (headerBox != null) {
              debugPrint('   → Header size: ${headerBox.size}');
              debugPrint('   → Header width: ${headerBox.size.width}');
            }
            if (rowBox != null) {
              debugPrint('   → First Row size: ${rowBox.size}');
              debugPrint('   → First Row width: ${rowBox.size.width}');
              debugPrint('   → Row constraints.maxWidth: ${rowBox.constraints.maxWidth}');
              final overflow = rowBox.size.width - rowBox.constraints.maxWidth;
              if (overflow > 0) {
                debugPrint('   ⚠️ [오버플로우] Row가 제약 초과: ${overflow.toStringAsFixed(0)}px');
              }
            }
            debugPrint('═══════════════════════════════════════════════════════');
          } catch (e) {
            debugPrint('❌ [Stocks Builder] 렌더링 크기 측정 중 에러: $e');
          }
        });
        
        return LayoutBuilder(
          builder: (context, columnConstraints) {
            debugPrint('📱 [Stocks Builder] Column constraints: ${columnConstraints.maxWidth} x ${columnConstraints.maxHeight}');
            
            return Column(
              children: [
                // 백그라운드 로딩 인디케이터
                if (isLoadingMore)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.blue.withOpacity(0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: reportColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '추가 데이터 로딩 중...',
                          style: TextStyle(
                            fontSize: 12,
                            color: reportColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, expandedConstraints) {
                      // 실제 가용 너비로 수평 스크롤 여부 결정 (오버플로우 방지)
                      final availableWidth = expandedConstraints.maxWidth;
                      final needsHorizontalScroll = totalWidth > availableWidth;
                      debugPrint('═══════════════════════════════════════════════════════');
                      debugPrint('📱 [Stocks Builder] Expanded 레이아웃 결정');
                      debugPrint('   → availableWidth (실제 제약): $availableWidth');
                      debugPrint('   → totalWidth (필요): $totalWidth');
                      debugPrint('   → needsHorizontalScroll: $needsHorizontalScroll ${needsHorizontalScroll ? "(수평 스크롤 사용)" : "(일반 모드)"}');
                      if (!needsHorizontalScroll && availableWidth < kMinWidthForNoScroll) {
                        debugPrint('   ⚠️ [오버플로우 위험] availableWidth < kMinWidthForNoScroll → Row가 넘칠 수 있음');
                      }
                      debugPrint('═══════════════════════════════════════════════════════');
                      
                      return needsHorizontalScroll
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                    debugPrint('📱 [Stocks Builder] 수평 스크롤 모드');
                    debugPrint('   → LayoutBuilder constraints: ${constraints.maxWidth} x ${constraints.maxHeight}');
                    debugPrint('   → totalWidth: $totalWidth');
                    debugPrint('   → 헤더 예상 높이: 60px');
                    debugPrint('   → ListView 예상 높이: ${constraints.maxHeight - 60}');
                    
                    // 헤더 높이를 측정하기 위한 GlobalKey 사용
                    final horizontalScrollController = ScrollController();
                    
                    // SingleChildScrollView의 스크롤 위치 추적
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (horizontalScrollController.hasClients) {
                        debugPrint('📱 [Stocks Builder] SingleChildScrollView 스크롤 위치');
                        debugPrint('   → 스크롤 위치: ${horizontalScrollController.offset}');
                        debugPrint('   → 최대 스크롤: ${horizontalScrollController.position.maxScrollExtent}');
                      }
                    });
                    
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification) {
                          debugPrint('📱 [Stocks Builder] 수평 스크롤 업데이트');
                          debugPrint('   → 스크롤 위치: ${notification.metrics.pixels}');
                          debugPrint('   → 최대 스크롤: ${notification.metrics.maxScrollExtent}');
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        controller: horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        physics: const ClampingScrollPhysics(),
                        child: Builder(
                          builder: (context) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              try {
                                final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                                if (renderBox != null) {
                                  debugPrint('📱 [Stocks Builder] SingleChildScrollView child SizedBox');
                                  debugPrint('   → SizedBox size: ${renderBox.size}');
                                  debugPrint('   → SizedBox constraints: ${renderBox.constraints}');
                                  debugPrint('   → 설정된 width: $totalWidth');
                                  debugPrint('   → 실제 width: ${renderBox.size.width}');
                                }
                              } catch (e) {
                                debugPrint('❌ SingleChildScrollView child SizedBox 크기 측정 에러: $e');
                              }
                            });
                            
                            return SizedBox(
                              width: totalWidth,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                            // 칼럼 헤더 (수평 스크롤과 함께 이동)
                            Builder(
                              builder: (context) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  try {
                                    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                                    if (renderBox != null) {
                                      debugPrint('📱 [Stocks Builder] Header SizedBox 렌더링 후');
                                      debugPrint('   → SizedBox size: ${renderBox.size}');
                                      debugPrint('   → SizedBox constraints: ${renderBox.constraints}');
                                      debugPrint('   → 설정된 width: $totalWidth');
                                      debugPrint('   → 실제 width: ${renderBox.size.width}');
                                      debugPrint('   → 차이: ${renderBox.size.width - totalWidth}');
                                    }
                                  } catch (e) {
                                    debugPrint('❌ Header SizedBox 크기 측정 에러: $e');
                                  }
                                });
                                
                                return SizedBox(
                                  width: totalWidth, // Container padding 포함한 전체 너비
                                  child: headerWidget,
                                );
                              },
                            ),
                            // 데이터 리스트
                            Builder(
                              builder: (context) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  try {
                                    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                                    if (renderBox != null) {
                                      debugPrint('📱 [Stocks Builder] 데이터 ListView SizedBox 렌더링 후');
                                      debugPrint('   → SizedBox size: ${renderBox.size}');
                                      debugPrint('   → SizedBox constraints: ${renderBox.constraints}');
                                      debugPrint('   → 설정된 height: ${constraints.maxHeight - 60}');
                                      debugPrint('   → 설정된 width: $totalWidth');
                                      debugPrint('   → 실제 size: ${renderBox.size}');
                                    }
                                  } catch (e) {
                                    debugPrint('❌ 데이터 ListView SizedBox 크기 측정 에러: $e');
                                  }
                                });
                                
                                return SizedBox(
                                  height: constraints.maxHeight - 60, // 헤더 높이 대략 60px
                                  width: totalWidth,
                                  child: ListView.builder(
                                controller: scrollController,
                                scrollDirection: Axis.vertical,
                                shrinkWrap: false,
                                physics: const AlwaysScrollableScrollPhysics(),
                                cacheExtent: 500,
                                itemCount: filteredDataList.length,
                                itemBuilder: (context, index) {
                                  final stock = filteredDataList[index] as Map<String, dynamic>;
                                  
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: _buildStockRow(stock, reportColor, columnWidths, index == 0),
                                  );
                                },
                              ),
                            );
                              },
                            ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                              },
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                // 일반 모드: 실제 가용 너비 사용 (screenWidth 사용 시 패널/사이드바에서 오버플로우)
                                final contentWidth = constraints.maxWidth;
                                debugPrint('📱 [Stocks Builder] 일반 모드 (수평 스크롤 없음) contentWidth: $contentWidth');
                                
                                return Column(
                      children: [
                        // 칼럼 헤더
                        SizedBox(
                          width: contentWidth,
                          child: headerWidget,
                        ),
                        // 데이터 리스트
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            scrollDirection: Axis.vertical,
                            shrinkWrap: false,
                            physics: const AlwaysScrollableScrollPhysics(),
                            cacheExtent: 500,
                            itemCount: filteredDataList.length,
                            itemBuilder: (context, index) {
                              final stock = filteredDataList[index] as Map<String, dynamic>;
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: _buildStockRow(stock, reportColor, columnWidths, index == 0),
                              );
                            },
                          ),
                        ),
                                ],
                              );
                              },
                            );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildStockRow(Map<String, dynamic> stock, Color reportColor, Map<String, double> columnWidths, [bool isFirstRow = false]) {
    final rowKey = isFirstRow ? GlobalKey() : null;
    final expectedRowWidth = stockColumnKeys.fold(0.0, (sum, k) => sum + (columnWidths[k] ?? 100)) + (stockColumnKeys.length - 1) * 8.0;

    if (isFirstRow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (rowKey?.currentContext != null) {
            final RenderBox? renderBox = rowKey!.currentContext!.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              debugPrint('📱 [Stocks Builder] 첫 번째 Row 렌더링 후 실제 크기');
              debugPrint('   → Row 실제 width: ${renderBox.size.width}, expected: $expectedRowWidth');
            }
          }
        } catch (e) {
          debugPrint('❌ [Stocks Builder] Row 크기 측정 중 에러: $e');
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final rowFits = constraints.maxWidth >= expectedRowWidth;
        final rowContent = Row(
          key: rowKey,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < stockColumnKeys.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _buildStockCell(stock, stockColumnKeys[i], columnWidths[stockColumnKeys[i]] ?? 100, reportColor),
            ],
          ],
        );
        if (rowFits) {
          return rowContent;
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: rowContent,
        );
      },
    );
  }

  static const Set<String> _rightAlignKeys = {
    'totaling', 'totalventa', 'todayingreso', 'todayventa', 'totalreservado',
    'cntoffset', 'stockreal', 'porcentaje', 'pre1', 'pre2', 'pre3', 'pre4', 'pre5', 'id_codigo1',
  };

  static Widget _buildStockCell(Map<String, dynamic> stock, String key, double width, Color reportColor) {
    final isCode = key == 'codigo';
    final isDesc = key == 'descripcion';
    String displayValue;
    if (key == 'codigo') {
      displayValue = stock['codigo']?.toString() ?? stock['tcode']?.toString() ?? 'N/A';
    } else if (key == 'descripcion') {
      displayValue = stock['descripcion']?.toString() ?? stock['tdesc']?.toString() ?? 'N/A';
    } else if (key == 'stockreal') {
      displayValue = stock['stockreal']?.toString() ?? stock['stockreal3']?.toString() ?? 'N/A';
    } else if (key == 'porcentaje') {
      displayValue = _formatPorcentaje(stock['porcentaje']);
    } else {
      displayValue = stock[key]?.toString() ?? 'N/A';
    }
    final textAlign = key == 'sucursal' ? TextAlign.center : (_rightAlignKeys.contains(key) ? TextAlign.right : TextAlign.left);
    return SizedBox(
      width: width,
      child: Text(
        displayValue,
        style: TextStyle(
          fontWeight: isCode ? FontWeight.bold : FontWeight.normal,
          fontSize: isCode ? 12 : 10,
          color: isCode ? Colors.black87 : Colors.grey[700],
        ),
        maxLines: isDesc ? 5 : 1,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
      ),
    );
  }

  /// Stocks 칼럼 헤더 빌드. [columnWidths]와 [onColumnResize]가 있으면 칼럼 리사이즈 가능.
  static Widget buildHeader({
    required ReportType reportType,
    required String? sortColumn,
    required bool sortAscending,
    required Function(String, bool) onSort,
    required Color reportColor,
    required Map<String, double> columnWidths,
    void Function(String columnKey, double newWidth)? onColumnResize,
  }) {
    const double resizeHandleWidth = 14.0;
    const double minColumnWidth = 50.0;
    const double maxColumnWidth = 2000.0;

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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.hardEdge,
        physics: const ClampingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < stockColumnKeys.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _buildSortableHeader(
                stockColumnKeys[i],
                stockColumnDisplayNames[stockColumnKeys[i]] ?? stockColumnKeys[i],
                columnWidths[stockColumnKeys[i]] ?? 100,
                sortColumn,
                sortAscending,
                onSort,
                reportColor,
              ),
              if (onColumnResize != null)
                _buildStocksResizeHandle(
                  stockColumnKeys[i],
                  columnWidths[stockColumnKeys[i]] ?? 100,
                  resizeHandleWidth,
                  (double newWidth) {
                    final clamped = newWidth.clamp(minColumnWidth, maxColumnWidth);
                    onColumnResize(stockColumnKeys[i], clamped);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _buildStocksResizeHandle(
    String columnKey,
    double currentWidth,
    double handleWidth,
    void Function(double newWidth) onResize,
  ) {
    return _StocksColumnResizeHandle(
      key: ValueKey('stocks_resize_$columnKey'),
      currentWidth: currentWidth,
      handleWidth: handleWidth,
      onResize: onResize,
    );
  }

  /// porcentaje 칼럼 값 소수점 1자리 포맷
  static String _formatPorcentaje(dynamic value) {
    if (value == null) return 'N/A';
    final d = value is num ? value.toDouble() : double.tryParse(value.toString());
    return d != null ? d.toStringAsFixed(1) : value.toString();
  }

  static Widget _buildSortableHeader(
    String columnKey,
    String displayName,
    double width,
    String? sortColumn,
    bool sortAscending,
    Function(String, bool) onSort,
    Color reportColor,
  ) {
    final isSorted = sortColumn == columnKey;
    
    return InkWell(
      onTap: () {
        if (isSorted) {
          onSort(columnKey, !sortAscending);
        } else {
          onSort(columnKey, false); // 첫 클릭 시 내림차순
        }
      },
      child: SizedBox(
        width: width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSorted ? reportColor : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (isSorted)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: reportColor,
              ),
          ],
        ),
      ),
    );
  }

  /// Stocks Vista 타입 표시
  static Widget buildViewType({
    required Map<String, dynamic>? data,
    required String? selectedSucursal,
    required Function(String?) onSucursalChanged,
    required Color reportColor,
  }) {
    if (data == null) {
      return const SizedBox.shrink();
    }
    
    // 새로운 응답 형식: filters 객체가 최상위에 있음
    // 기존 형식 지원: data['filters'] 또는 최상위 bcolorview
    Map<String, dynamic>? filters;
    if (data.containsKey('filters') && data['filters'] is Map) {
      filters = data['filters'] as Map<String, dynamic>;
    }
    
    // bcolorview 확인 (filters 객체 안 또는 최상위)
    dynamic bcolorview;
    if (filters != null && filters.containsKey('bcolorview')) {
      bcolorview = filters['bcolorview'];
    } else if (data.containsKey('bcolorview')) {
      bcolorview = data['bcolorview'];
    } else {
      return const SizedBox.shrink();
    }
    final isBcolorviewEnabled = ReportUtils.isBcolorviewEnabled(bcolorview);
    final viewType = isBcolorviewEnabled ? 'Vista Resumida' : 'VistaD';
    
    // Vista Detallada일 때만 sucursal 필터 표시
    final bool showSucursalFilter = !isBcolorviewEnabled;
    List<String>? sucursales;
    
    if (showSucursalFilter && data.containsKey('data') && data['data'] is List) {
      final dataList = data['data'] as List;
      final sucursalSet = <String>{};
      
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📱 [Stocks Builder] buildViewType - Sucursal 필터 처리');
      debugPrint('   → dataList.length: ${dataList.length}');
      debugPrint('   → selectedSucursal: $selectedSucursal');
      
      for (var item in dataList) {
        if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
          final sucursal = item['sucursal']?.toString();
          if (sucursal != null && sucursal.isNotEmpty) {
            sucursalSet.add(sucursal);
          } else {
            debugPrint('   ⚠️ sucursal이 null이거나 비어있음: $item');
          }
        } else {
          debugPrint('   ⚠️ item이 Map이 아니거나 sucursal 키가 없음: ${item.runtimeType}');
        }
      }
      
      debugPrint('   → 추출된 sucursal 개수: ${sucursalSet.length}');
      debugPrint('   → 추출된 sucursal 목록: ${sucursalSet.toList()}');
      
      sucursales = sucursalSet.toList()..sort((a, b) {
        final aNum = int.tryParse(a) ?? 0;
        final bNum = int.tryParse(b) ?? 0;
        return aNum.compareTo(bNum);
      });
      
      debugPrint('   → 정렬된 sucursales: $sucursales');
      
      // selectedSucursal이 items에 있는지 확인
      if (selectedSucursal != null) {
        final foundCount = sucursales.where((s) => s == selectedSucursal).length;
        debugPrint('   → selectedSucursal "$selectedSucursal" 찾은 개수: $foundCount');
        
        if (foundCount == 0) {
          debugPrint('   ⚠️ 경고: selectedSucursal "$selectedSucursal"이 items에 없음!');
          debugPrint('   ⚠️ 이로 인해 DropdownButton 에러가 발생할 수 있습니다.');
        } else if (foundCount > 1) {
          debugPrint('   ⚠️ 경고: selectedSucursal "$selectedSucursal"이 items에 $foundCount개 있음!');
          debugPrint('   ⚠️ 이로 인해 DropdownButton 에러가 발생할 수 있습니다.');
        }
      }
      debugPrint('═══════════════════════════════════════════════════════');
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: reportColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBcolorviewEnabled ? Icons.view_compact : Icons.view_list,
            color: reportColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            viewType,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: reportColor,
            ),
          ),
          // Sucursal이 2개 이상일 때만 콤보박스 표시
          if (showSucursalFilter && sucursales != null && sucursales.length > 1)
            ...[
              const SizedBox(width: 16),
              Builder(
                builder: (context) {
                  // DropdownButton의 items 확인
                  final allItems = [
                    null,
                    ...sucursales!,
                  ];
                  
                  debugPrint('═══════════════════════════════════════════════════════');
                  debugPrint('📱 [Stocks Builder] DropdownButton 빌드');
                  debugPrint('   → selectedSucursal: $selectedSucursal');
                  debugPrint('   → sucursales: $sucursales');
                  debugPrint('   → allItems (null 포함): $allItems');
                  
                  // selectedSucursal이 items에 있는지 확인
                  if (selectedSucursal != null) {
                    final foundInItems = allItems.contains(selectedSucursal);
                    debugPrint('   → selectedSucursal "$selectedSucursal"이 items에 있음: $foundInItems');
                    
                    if (!foundInItems) {
                      debugPrint('   ⚠️ 경고: selectedSucursal "$selectedSucursal"이 items에 없음!');
                      debugPrint('   ⚠️ DropdownButton value를 null로 설정해야 합니다.');
                    }
                  }
                  
                  // items에 중복이 있는지 확인
                  final duplicates = <String>[];
                  for (var item in sucursales) {
                    if (sucursales.where((s) => s == item).length > 1) {
                      if (!duplicates.contains(item)) {
                        duplicates.add(item);
                      }
                    }
                  }
                  if (duplicates.isNotEmpty) {
                    debugPrint('   ⚠️ 경고: items에 중복된 값이 있음: $duplicates');
                  }
                  
                  debugPrint('═══════════════════════════════════════════════════════');
                  
                  // selectedSucursal이 items에 없으면 null로 설정
                  final safeSelectedValue = (selectedSucursal != null && allItems.contains(selectedSucursal))
                      ? selectedSucursal
                      : null;
                  
                  if (safeSelectedValue != selectedSucursal) {
                    debugPrint('   ✅ selectedSucursal을 null로 변경 (items에 없음)');
                  }
                  
                  return Container(
                    constraints: const BoxConstraints(minWidth: 100),
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButton<String?>(
                      value: safeSelectedValue,
                      hint: const Text('Todos', style: TextStyle(fontSize: 12)),
                      underline: const SizedBox(),
                      isDense: true,
                      icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 20),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos', style: TextStyle(fontSize: 12)),
                        ),
                        ...sucursales.map((sucursal) {
                          return DropdownMenuItem<String?>(
                            value: sucursal,
                            child: Text(sucursal, style: const TextStyle(fontSize: 12)),
                          );
                        }),
                      ],
                      onChanged: onSucursalChanged,
                    ),
                  );
                },
              ),
            ],
          // summary 정보 표시 (새로운 응답 형식: summary 객체 또는 최상위 total_items)
          if (data.containsKey('summary') || data.containsKey('total_items'))
            const Spacer(),
          if (data.containsKey('summary') && data['summary'] is Map)
            Text(
              'Total: ${(data['summary'] as Map)['total_items'] ?? 0}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          else if (data.containsKey('total_items'))
            Text(
              'Total: ${data['total_items'] ?? 0}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
}

/// Stocks 칼럼 너비 리사이즈 핸들 (드래그 시 누적 델타 반영)
class _StocksColumnResizeHandle extends StatefulWidget {
  final double currentWidth;
  final double handleWidth;
  final void Function(double newWidth) onResize;

  const _StocksColumnResizeHandle({
    super.key,
    required this.currentWidth,
    required this.handleWidth,
    required this.onResize,
  });

  @override
  State<_StocksColumnResizeHandle> createState() => _StocksColumnResizeHandleState();
}

class _StocksColumnResizeHandleState extends State<_StocksColumnResizeHandle> {
  double _initialWidth = 0;
  double _initialPointerX = 0;
  bool _isDragging = false;

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
          onPointerUp: (_) {
            _isDragging = false;
          },
          onPointerCancel: (_) {
            _isDragging = false;
          },
          child: SizedBox(
            width: widget.handleWidth,
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
                child: Icon(
                  Icons.drag_indicator,
                  size: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
