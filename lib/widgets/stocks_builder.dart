import 'package:flutter/material.dart';
import 'report_utils.dart';
import '../utils/mobile_layout_helper.dart';

/// Stocks 보고서 UI 빌더
class StocksBuilder {
  /// Stocks 콘텐츠 빌드
  static Widget buildContent({
    required Map<String, dynamic> data,
    required BuildContext context,
    required ScrollController scrollController,
    required bool isLoadingMore,
    required Color reportColor,
    required Widget headerWidget, // 헤더 위젯 추가
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
    
    // 실제 컨텐츠 너비 계산 (각 칼럼 너비 + 간격)
    // 칼럼 너비 합계: 120+250+90+100+110+100+120+100+100+100+100+100+90+90+90+90+90+90+100 = 1940
    // 칼럼 사이 간격 (8px * 18개): 144
    // Row의 좌우 padding은 Container에 있으므로 Row 자체 너비는 1940 + 144 = 2084
    // Container의 좌우 padding (16px * 2): 32
    // 총 너비: 2084 + 32 = 2116
    // 오른쪽 끝 패턴 문제 방지를 위해 약간의 여유 공간 추가
    final rowContentWidth = 1940.0 + 144.0; // Row 자체 너비 (padding 제외)
    final containerPadding = 32.0; // 좌우 padding
    final extraPadding = 20.0; // 오른쪽 끝 패턴 방지를 위한 추가 공간
    final totalWidth = rowContentWidth + containerPadding + extraPadding; // 실제 컨텐츠 너비
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final needsHorizontalScroll = totalWidth > screenWidth;
    
    // ============================================================
    // 📱 Stocks 화면 깨짐 현상 디버깅
    // ============================================================
    // 핸드폰에서 화면 깨짐 현상 원인 파악을 위한 디버깅
    final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
    final isMobilePhone = layoutInfo.isMobilePhone;
    final isMobilePhonePortrait = layoutInfo.isMobilePhonePortrait;
    final isMobilePhoneLandscape = layoutInfo.isMobilePhoneLandscape;
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📱 [Stocks Builder] buildContent 시작');
    debugPrint('   → isMobilePhone: $isMobilePhone');
    debugPrint('   → isMobilePhonePortrait: $isMobilePhonePortrait');
    debugPrint('   → isMobilePhoneLandscape: $isMobilePhoneLandscape');
    debugPrint('   → screenWidth: $screenWidth');
    debugPrint('   → screenHeight: $screenHeight');
    debugPrint('   → totalWidth: $totalWidth');
    debugPrint('   → needsHorizontalScroll: $needsHorizontalScroll');
    debugPrint('   → dataList.length: ${dataList.length}');
    debugPrint('   → filteredDataList.length: ${filteredDataList.length}');
    debugPrint('═══════════════════════════════════════════════════════');

    return Builder(
      builder: (context) {
        // 렌더링 후 실제 크기 측정
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('📱 [Stocks Builder] Column 실제 렌더링 크기');
            debugPrint('   → Column width: ${renderBox.size.width}');
            debugPrint('   → Column height: ${renderBox.size.height}');
            debugPrint('   → 예상 width: $screenWidth');
            debugPrint('   → 차이: ${renderBox.size.width - screenWidth}');
            debugPrint('═══════════════════════════════════════════════════════');
          }
        });
        
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
          child: needsHorizontalScroll
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    // 헤더 높이를 측정하기 위한 GlobalKey 사용
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: totalWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 칼럼 헤더 (수평 스크롤과 함께 이동)
                            SizedBox(
                              width: totalWidth, // Container padding 포함한 전체 너비
                              child: headerWidget,
                            ),
                            // 데이터 리스트
                            SizedBox(
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
                                    child: _buildStockRow(stock, reportColor),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : Column(
                  children: [
                    // 칼럼 헤더
                    SizedBox(
                      width: screenWidth,
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
                            child: _buildStockRow(stock, reportColor),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
      },
    );
  }

  static Widget _buildStockRow(Map<String, dynamic> stock, Color reportColor) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Codigo
        SizedBox(
          width: 120,
          child: Text(
            stock['codigo']?.toString() ?? 
            stock['tcode']?.toString() ?? 
            'N/A',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Descripción
        SizedBox(
          width: 250,
          child: Text(
            stock['descripcion']?.toString() ?? 
            stock['tdesc']?.toString() ?? 
            'N/A',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Totaling
        SizedBox(
          width: 90,
          child: Text(
            stock['totaling']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        // Total Venta
        SizedBox(
          width: 100,
          child: Text(
            stock['totalventa']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        // Today Ingreso
        SizedBox(
          width: 110,
          child: Text(
            stock['todayingreso']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        // Today Venta
        SizedBox(
          width: 100,
          child: Text(
            stock['todayventa']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        // Total Reservado
        SizedBox(
          width: 120,
          child: Text(
            stock['totalreservado']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        // Cnt Offset
        SizedBox(
          width: 100,
          child: Text(
            stock['cntoffset']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        // Stock Real
        SizedBox(
          width: 100,
          child: Text(
            stock['stockreal']?.toString() ?? 
            stock['stockreal3']?.toString() ?? 
            'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        // Porcentaje
        SizedBox(
          width: 100,
          child: Text(
            stock['porcentaje']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        // First Date
        SizedBox(
          width: 100,
          child: Text(
            stock['first_date']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Last Date
        SizedBox(
          width: 100,
          child: Text(
            stock['last_date']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Precio 1-5
        SizedBox(
          width: 90,
          child: Text(
            stock['pre1']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            stock['pre2']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            stock['pre3']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            stock['pre4']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            stock['pre5']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        // Sucursal
        SizedBox(
          width: 90,
          child: Text(
            stock['sucursal']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        // ID Codigo1
        SizedBox(
          width: 100,
          child: Text(
            stock['id_codigo1']?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// Stocks 칼럼 헤더 빌드
  static Widget buildHeader({
    required ReportType reportType,
    required String? sortColumn,
    required bool sortAscending,
    required Function(String, bool) onSort,
    required Color reportColor,
  }) {
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
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
            _buildSortableHeader('codigo', 'Codigo', 120, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('descripcion', 'Descripción', 250, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('totaling', 'Totaling', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('totalventa', 'Total Venta', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('todayingreso', 'Today Ingreso', 110, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('todayventa', 'Today Venta', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('totalreservado', 'Total Reservado', 120, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('cntoffset', 'Cnt Offset', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('stockreal', 'Stock Real', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('porcentaje', 'Porcentaje', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('first_date', 'First Date', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('last_date', 'Last Date', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('pre1', 'Precio 1', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('pre2', 'Precio 2', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('pre3', 'Precio 3', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('pre4', 'Precio 4', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('pre5', 'Precio 5', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('sucursal', 'Sucursal', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('id_codigo1', 'ID Codigo1', 100, sortColumn, sortAscending, onSort, reportColor),
          ],
        ),
    );
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
          children: [
            Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSorted ? reportColor : Colors.black87,
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
      
      for (var item in dataList) {
        if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
          final sucursal = item['sucursal']?.toString();
          if (sucursal != null && sucursal.isNotEmpty) {
            sucursalSet.add(sucursal);
          }
        }
      }
      
      sucursales = sucursalSet.toList()..sort((a, b) {
        final aNum = int.tryParse(a) ?? 0;
        final bNum = int.tryParse(b) ?? 0;
        return aNum.compareTo(bNum);
      });
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
              Container(
                constraints: const BoxConstraints(minWidth: 100),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<String?>(
                  value: selectedSucursal,
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
                    }).toList(),
                  ],
                  onChanged: onSucursalChanged,
                ),
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

