import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/config_service.dart';
import 'report_screen.dart';

/// 여러 sucursal일 때 사용하는 Resumen del Dia 뷰
/// 
/// 이 파일은 sucursal이 2개 이상일 때만 사용되며, 비교 테이블 형태로 데이터를 표시합니다.
/// 단일 sucursal일 때는 resumen_del_dia_single_sucursal_view.dart를 사용합니다.
class ResumenDelDiaMultipleSucursalesView extends StatelessWidget {
  final Map<String, dynamic> data;
  final DateTime? selectedDate;
  final String serverUrl;
  final Function() onRefresh;
  final Function() onSelectDate;
  final Function(ReportType) onReportTypeSelected;
  
  const ResumenDelDiaMultipleSucursalesView({
    super.key,
    required this.data,
    required this.selectedDate,
    required this.serverUrl,
    required this.onRefresh,
    required this.onSelectDate,
    required this.onReportTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [여러 Sucursal 뷰] ResumenDelDiaMultipleSucursalesView.build 호출');
    debugPrint('   → data 키: ${data.keys.toList()}');
    debugPrint('   → selectedDate: $selectedDate');
    debugPrint('═══════════════════════════════════════════════════════');
    
    final isLarge = _isLargeScreen(context);
    debugPrint('   → 대형화면 여부: $isLarge');
    
    // 대형화면: Expanded를 사용할 수 있도록 SingleChildScrollView 제거
    if (isLarge) {
      debugPrint('   → 대형화면: Expanded 사용 가능하도록 직접 반환');
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: _buildComparisonView(context, l10n),
      );
    }
    
    // 작은 화면: SingleChildScrollView로 감싸서 스크롤 가능하게
    debugPrint('   → 작은 화면: SingleChildScrollView로 감싸서 반환');
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: _buildComparisonView(context, l10n),
      ),
    );
  }

  // ==================== 비교 뷰 빌드 ====================
  
  Widget _buildComparisonView(BuildContext context, AppLocalizations l10n) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_buildComparisonView] 호출됨');
    debugPrint('   → data 키: ${data.keys.toList()}');
    List<Map<String, dynamic>> sucursalesData = [];
    
    // vcodes가 배열인 경우 (서버 응답 구조)
    if (data.containsKey('vcodes') && data['vcodes'] is List) {
      debugPrint('   → vcodes 배열 처리 시작');
      final vcodesList = data['vcodes'] as List;
      debugPrint('   → vcodesList 길이: ${vcodesList.length}');
      
      // 각 sucursal별로 데이터를 합침
      final sucursalMap = <int, Map<String, dynamic>>{};
      
      // vcodes 데이터 추가
      debugPrint('   → vcodes 항목 처리 시작...');
      for (int i = 0; i < vcodesList.length; i++) {
        final item = vcodesList[i];
        debugPrint('      - vcodes 항목 #$i: ${item.runtimeType}');
        if (item is Map && item.containsKey('sucursal')) {
          final sucursalValue = item['sucursal'];
          final sucursal = sucursalValue is int 
              ? sucursalValue 
              : int.tryParse(sucursalValue.toString()) ?? 0;
          debugPrint('         → sucursal: $sucursal (원본: $sucursalValue)');
          
          if (!sucursalMap.containsKey(sucursal)) {
            debugPrint('         → 새 sucursal 추가: $sucursal');
            sucursalMap[sucursal] = {'sucursal': sucursal};
          } else {
            debugPrint('         → 기존 sucursal 업데이트: $sucursal');
          }
          sucursalMap[sucursal]!['vcodes'] = item;
        } else {
          debugPrint('         → Map이 아니거나 sucursal 키 없음');
        }
      }
      debugPrint('   → vcodes 처리 완료. sucursalMap 크기: ${sucursalMap.length}');
      
      // 다른 데이터들도 추가 (vdetalle, vcodes_mpago, gastos, ingresos, stocks)
      // vdetalle 처리
      if (data.containsKey('vdetalle') && data['vdetalle'] is List) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('   → vdetalle 배열 처리 시작');
        final vdetalleList = data['vdetalle'] as List;
        debugPrint('   → vdetalleList 길이: ${vdetalleList.length}');
        debugPrint('   → vdetalleList 전체 데이터: $vdetalleList');
        
        int processedCount = 0;
        for (var item in vdetalleList) {
          debugPrint('      - vdetalle 항목 #$processedCount: ${item.runtimeType}');
          if (item is Map && item.containsKey('sucursal')) {
            final sucursalValue = item['sucursal'];
            final sucursal = sucursalValue is int 
                ? sucursalValue 
                : int.tryParse(sucursalValue.toString()) ?? 0;
            debugPrint('         → sucursal: $sucursal (원본: $sucursalValue)');
            debugPrint('         → 항목 전체 데이터: $item');
            debugPrint('         → 항목 키: ${item.keys.toList()}');
            
            if (sucursalMap.containsKey(sucursal)) {
              debugPrint('         ✅ sucursalMap에 추가: sucursal=$sucursal');
              sucursalMap[sucursal]!['vdetalle'] = item;
              debugPrint('         → 추가 후 sucursalMap[$sucursal]: ${sucursalMap[sucursal]}');
            } else {
              debugPrint('         ⚠️ sucursalMap에 sucursal=$sucursal이 없음 (건너뜀)');
              debugPrint('         → 현재 sucursalMap 키: ${sucursalMap.keys.toList()}');
            }
            processedCount++;
          } else {
            debugPrint('         ⚠️ Map이 아니거나 sucursal 키 없음');
          }
        }
        debugPrint('   → vdetalle 처리 완료: $processedCount개 항목 처리됨');
        debugPrint('═══════════════════════════════════════════════════════');
      } else {
        debugPrint('   ⚠️ vdetalle 키가 없거나 List가 아님');
        debugPrint('      → data.containsKey(\'vdetalle\'): ${data.containsKey('vdetalle')}');
        if (data.containsKey('vdetalle')) {
          debugPrint('      → data[\'vdetalle\'] 타입: ${data['vdetalle'].runtimeType}');
        }
      }
      
      // vcodes_mpago 처리
      if (data.containsKey('vcodes_mpago') && data['vcodes_mpago'] is List) {
        debugPrint('   → vcodes_mpago 배열 처리 시작');
        final mpagoList = data['vcodes_mpago'] as List;
        for (var item in mpagoList) {
          if (item is Map && item.containsKey('sucursal')) {
            final sucursalValue = item['sucursal'];
            final sucursal = sucursalValue is int 
                ? sucursalValue 
                : int.tryParse(sucursalValue.toString()) ?? 0;
            if (sucursalMap.containsKey(sucursal)) {
              sucursalMap[sucursal]!['vcodes_mpago'] = item;
            }
          }
        }
      }
      
      // gastos 처리
      if (data.containsKey('gastos') && data['gastos'] is List) {
        debugPrint('   → gastos 배열 처리 시작');
        final gastosList = data['gastos'] as List;
        for (var item in gastosList) {
          if (item is Map && item.containsKey('sucursal')) {
            final sucursalValue = item['sucursal'];
            final sucursal = sucursalValue is int 
                ? sucursalValue 
                : int.tryParse(sucursalValue.toString()) ?? 0;
            if (sucursalMap.containsKey(sucursal)) {
              sucursalMap[sucursal]!['gastos'] = item;
            }
          }
        }
      }
      
      // ingresos 처리
      if (data.containsKey('ingresos') && data['ingresos'] is List) {
        debugPrint('   → ingresos 배열 처리 시작');
        final ingresosList = data['ingresos'] as List;
        for (var item in ingresosList) {
          if (item is Map && item.containsKey('sucursal')) {
            final sucursalValue = item['sucursal'];
            final sucursal = sucursalValue is int 
                ? sucursalValue 
                : int.tryParse(sucursalValue.toString()) ?? 0;
            if (sucursalMap.containsKey(sucursal)) {
              sucursalMap[sucursal]!['ingresos'] = item;
            }
          }
        }
      }
      
      // fventas 처리 (sucursal별로 그룹화)
      if (data.containsKey('fventas') && data['fventas'] is List) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('   → fventas 배열 처리 시작 (sucursal별 그룹화)');
        final fventasList = data['fventas'] as List;
        debugPrint('   → fventasList 길이: ${fventasList.length}');
        
        // 각 sucursal별로 fventas 데이터를 그룹화
        final Map<int, Map<String, Map<String, dynamic>>> fventasBySucursal = {};
        
        for (var item in fventasList) {
          if (item is Map<String, dynamic>) {
            final sucursalValue = item['sucursal'];
            final sucursal = sucursalValue is int 
                ? sucursalValue 
                : (sucursalValue is String ? int.tryParse(sucursalValue) : null);
            
            if (sucursal != null) {
              // sucursalMap에 없으면 추가 (fventas 데이터에만 있는 sucursal일 수 있음)
              if (!sucursalMap.containsKey(sucursal)) {
                debugPrint('      → fventas에서 발견된 새 sucursal: $sucursal (sucursalMap에 추가)');
                sucursalMap[sucursal] = {'sucursal': sucursal};
              }
              
              final tipofactura = item['tipofactura']?.toString() ?? 'Unknown';
              
              debugPrint('      → fventas 항목: sucursal=$sucursal, tipofactura=$tipofactura');
              
              if (!fventasBySucursal.containsKey(sucursal)) {
                fventasBySucursal[sucursal] = {};
              }
              
              // tipofactura별로 그룹화 (같은 tipofactura가 여러 개 있을 수 있으므로 합산)
              if (!fventasBySucursal[sucursal]!.containsKey(tipofactura)) {
                fventasBySucursal[sucursal]![tipofactura] = {
                  'tipofactura': tipofactura,
                  'count': 0,
                  'sum_monto': 0.0,
                };
              }
              
              final count = (item['count'] as num?)?.toInt() ?? 0;
              final sumMonto = (item['sum_monto'] as num?)?.toDouble() ?? 0.0;
              
              fventasBySucursal[sucursal]![tipofactura]!['count'] = 
                  (fventasBySucursal[sucursal]![tipofactura]!['count'] as int) + count;
              fventasBySucursal[sucursal]![tipofactura]!['sum_monto'] = 
                  (fventasBySucursal[sucursal]![tipofactura]!['sum_monto'] as double) + sumMonto;
              
              debugPrint('         → 합산: count=${fventasBySucursal[sucursal]![tipofactura]!['count']}, sum_monto=${fventasBySucursal[sucursal]![tipofactura]!['sum_monto']}');
            } else {
              debugPrint('      ⚠️ fventas 항목: sucursal을 파싱할 수 없음 (건너뜀)');
            }
          }
        }
        
        // 각 sucursal별로 fventas 데이터를 sucursalMap에 저장
        fventasBySucursal.forEach((sucursal, tipofacturaMap) {
          if (sucursalMap.containsKey(sucursal)) {
            // tipofactura별로 그룹화된 데이터를 리스트로 변환
            final fventasItems = tipofacturaMap.values.toList();
            sucursalMap[sucursal]!['fventas'] = {
              'items': fventasItems,
            };
            debugPrint('   ✅ sucursal $sucursal에 fventas 데이터 저장: ${fventasItems.length}개 tipofactura');
          }
        });
        
        debugPrint('   → fventas 처리 완료: ${fventasBySucursal.length}개 sucursal에 데이터 저장');
        debugPrint('═══════════════════════════════════════════════════════');
      } else {
        debugPrint('   ⚠️ fventas 키가 없거나 List가 아님');
        debugPrint('      → data.containsKey(\'fventas\'): ${data.containsKey('fventas')}');
        if (data.containsKey('fventas')) {
          debugPrint('      → data[\'fventas\'] 타입: ${data['fventas'].runtimeType}');
        }
      }
      
      // sucursalMap에서 sucursalesData 생성
      debugPrint('   → sucursalMap에서 sucursalesData 생성 시작...');
      final sortedKeys = sucursalMap.keys.toList()..sort();
      debugPrint('   → sucursalMap 키: $sortedKeys');
      debugPrint('   → 정렬 전 sucursalesData 길이: ${sucursalMap.length}');
      
      for (final key in sortedKeys) {
        final data = sucursalMap[key]!;
        sucursalesData.add({
          'sucursal': key,
          ...data,
        });
      }
    }

    if (sucursalesData.isEmpty) {
      debugPrint('   ⚠️ sucursalesData가 비어있음');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '비교할 데이터가 없습니다',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '데이터 키: ${data.keys.toList()}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    debugPrint('   ✅ 비교 뷰 렌더링 시작: ${sucursalesData.length}개 sucursal');
    final isLarge = _isLargeScreen(context);
    debugPrint('   → 대형화면 여부: $isLarge');
    debugPrint('   → context: ${context.runtimeType}');
    
    // 대형화면: 왼쪽 테이블, 오른쪽 카드
    if (isLarge) {
      debugPrint('   → 대형화면 레이아웃: Row로 분할 (왼쪽: 테이블, 오른쪽: 카드)');
      debugPrint('   → LayoutBuilder로 constraints 확인 시작');
      
      return LayoutBuilder(
        builder: (context, constraints) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [LayoutBuilder] constraints 확인');
          debugPrint('   → width: ${constraints.minWidth} ~ ${constraints.maxWidth}');
          debugPrint('   → height: ${constraints.minHeight} ~ ${constraints.maxHeight}');
          debugPrint('   → constraints.isTight: ${constraints.isTight}');
          debugPrint('   → constraints.hasBoundedHeight: ${constraints.hasBoundedHeight}');
          debugPrint('   → constraints.hasBoundedWidth: ${constraints.hasBoundedWidth}');
          debugPrint('   → constraints.isNormalized: ${constraints.isNormalized}');
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final renderObject = context.findRenderObject();
            if (renderObject != null && renderObject is RenderBox) {
              debugPrint('   → LayoutBuilder 실제 렌더링 크기: width=${renderObject.size.width}, height=${renderObject.size.height}');
            }
          });
          debugPrint('═══════════════════════════════════════════════════════');
          
          debugPrint('   → Column 생성: mainAxisSize=max, children 개수 계산 중...');
          final columnChildren = <Widget>[];

          // 날짜 선택 버튼 (맨 윗줄)
          debugPrint('   → 날짜 선택 버튼 추가');
          columnChildren.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildDateSelectorButton(),
            ),
          );

          // 날짜 표시
          if (data.containsKey('fecha')) {
            debugPrint('   → 날짜 헤더 추가');
            columnChildren.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _buildDateHeader(context, data['fecha']),
              ),
            );
          }
          
          // 비교 테이블 제목
          debugPrint('   → 비교 테이블 제목 추가');
          columnChildren.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l10n.branchComparison,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
          );
          
          // 왼쪽/오른쪽 분할 레이아웃 (Resizable Splitter 사용)
          debugPrint('   → Resizable Splitter 레이아웃 추가');
          debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
          debugPrint('   → constraints.hasBoundedHeight: ${constraints.hasBoundedHeight}');
          
          columnChildren.add(
            Expanded(
              child: _ResizableSplitView(
                leftChild: Builder(
                  builder: (context) {
                    debugPrint('   → 왼쪽 테이블 영역 렌더링 시작');
                    return Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: _buildComparisonTable(context, sucursalesData, l10n),
                        ),
                      ),
                    );
                  },
                ),
                rightChild: Builder(
                  builder: (context) {
                    debugPrint('═══════════════════════════════════════════════════════');
                    debugPrint('🔍 [오른쪽 Stock 영역] 렌더링 시작');
                    
                    // 오른쪽에는 Stock Resumen 테이블만 표시
                    final stockData = <String, dynamic>{};
                    
                    if (data.containsKey('stock_resumen') && data['stock_resumen'] is Map) {
                      stockData.addAll(data['stock_resumen'] as Map<String, dynamic>);
                      debugPrint('   → stock_resumen 키 발견');
                    }
                    if (data.containsKey('stocks')) {
                      stockData['stocks'] = data['stocks'];
                      debugPrint('   → stocks 키 발견');
                    }
                    
                    final stockWidgets = _buildStockResumenSection(context, stockData, isLarge);
                    final hasStockData = stockWidgets.isNotEmpty;
                    
                    debugPrint('   → Stock Resumen 위젯 개수: ${stockWidgets.length}');
                    debugPrint('   → Stock 데이터 존재 여부: $hasStockData');
                    debugPrint('   → 오른쪽에는 Stock Resumen 테이블만 표시');
                    
                    const padding = 16.0;
                    
                    debugPrint('═══════════════════════════════════════════════════════');
                    
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(padding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Stock Resumen 테이블만 표시
                            if (hasStockData) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'Stock Resumen',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              ...stockWidgets,
                            ] else ...[
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text(
                                    'Stock 데이터가 없습니다.',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                sucursalesCount: sucursalesData.length,
              ),
            ),
          );
          
          debugPrint('   → Column children 개수: ${columnChildren.length}');
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columnChildren,
          );
        },
      );
    }
    
    // 작은 화면: 기존 레이아웃 (세로로 배치)
    debugPrint('   → 작은 화면 레이아웃: Column으로 세로 배치');
    debugPrint('   → SingleChildScrollView로 감싸서 스크롤 가능하게');
    
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 날짜 선택 버튼 (맨 윗줄)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildDateSelectorButton(),
          ),

          // 날짜 표시
          if (data.containsKey('fecha'))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildDateHeader(context, data['fecha']),
            ),
          
          // 비교 테이블 제목
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              l10n.branchComparison,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          
          // 비교 테이블 (전체 너비로 표시, 수평 스크롤 가능)
          _buildComparisonTable(context, sucursalesData, l10n),
          
          // Stock Resumen 테이블 (작은 화면에서는 테이블 아래에 표시)
          Builder(
            builder: (context) {
              final stockData = <String, dynamic>{};
              
              if (data.containsKey('stock_resumen') && data['stock_resumen'] is Map) {
                stockData.addAll(data['stock_resumen'] as Map<String, dynamic>);
              }
              if (data.containsKey('stocks')) {
                stockData['stocks'] = data['stocks'];
              }
              
              final stockWidgets = _buildStockResumenSection(context, stockData, isLarge);
              final hasStockData = stockWidgets.isNotEmpty;
              
              if (hasStockData) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'Stock Resumen',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    ...stockWidgets,
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // ==================== 비교 테이블 빌드 ====================
  
  Widget _buildComparisonTable(BuildContext context, List<Map<String, dynamic>> sucursalesData, AppLocalizations l10n) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_buildComparisonTable] 호출됨');
    debugPrint('   → sucursalesData 개수: ${sucursalesData.length}');
    
    // 모든 메트릭 수집
    final allMetrics = <String>[];
    
    for (var sucursalData in sucursalesData) {
      // vcodes 항목 (sucursal 제외)
      if (sucursalData.containsKey('vcodes') && sucursalData['vcodes'] is Map) {
        final vcodes = sucursalData['vcodes'] as Map<String, dynamic>;
        for (var key in vcodes.keys) {
          // sucursal 키는 제외 (이미 컬럼 헤더에 표시됨)
          if (key != 'sucursal' && !allMetrics.contains('vcodes_$key')) {
            allMetrics.add('vcodes_$key');
          }
        }
      }
      
      // gastos 항목 (갯수와 총 금액, sucursal 제외)
      if (sucursalData.containsKey('gastos') && sucursalData['gastos'] is Map) {
        final gastos = sucursalData['gastos'] as Map<String, dynamic>;
        for (var key in gastos.keys) {
          // sucursal 키는 제외 (이미 컬럼 헤더에 표시됨)
          if (key != 'sucursal' && !allMetrics.contains('gastos_$key')) {
            allMetrics.add('gastos_$key');
          }
        }
      }
      
      // vdetalle 항목 (Descuento 포함, sucursal 제외)
      debugPrint('      → vdetalle 체크: sucursalData.containsKey(\'vdetalle\'): ${sucursalData.containsKey('vdetalle')}');
      if (sucursalData.containsKey('vdetalle')) {
        debugPrint('         → vdetalle 타입: ${sucursalData['vdetalle'].runtimeType}');
        debugPrint('         → vdetalle 값: ${sucursalData['vdetalle']}');
      }
      
      if (sucursalData.containsKey('vdetalle') && sucursalData['vdetalle'] is Map) {
        final vdetalle = sucursalData['vdetalle'] as Map<String, dynamic>;
        debugPrint('         ✅ vdetalle이 Map임 - 키 수집 시작');
        debugPrint('         → vdetalle 키: ${vdetalle.keys.toList()}');
        for (var key in vdetalle.keys) {
          // sucursal 키는 제외 (이미 컬럼 헤더에 표시됨)
          if (key != 'sucursal' && !allMetrics.contains('vdetalle_$key')) {
            allMetrics.add('vdetalle_$key');
            debugPrint('            → 메트릭 추가: vdetalle_$key');
          } else if (key == 'sucursal') {
            debugPrint('            → sucursal 키는 제외됨');
          } else {
            debugPrint('            → 이미 존재하는 메트릭: vdetalle_$key');
          }
        }
        debugPrint('         → vdetalle 메트릭 수집 완료');
      } else {
        debugPrint('         ⚠️ vdetalle이 없거나 Map이 아님');
      }
      
      // vcodes_mpago 항목 (갯수와 총 금액, sucursal 제외) - MPago 포함
      if (sucursalData.containsKey('vcodes_mpago') && sucursalData['vcodes_mpago'] is Map) {
        final mpago = sucursalData['vcodes_mpago'] as Map<String, dynamic>;
        for (var key in mpago.keys) {
          // sucursal 키는 제외 (이미 컬럼 헤더에 표시됨)
          if (key != 'sucursal' && !allMetrics.contains('mpago_$key')) {
            allMetrics.add('mpago_$key');
          }
        }
      }
      
      // ingresos 항목 (sucursal 제외)
      if (sucursalData.containsKey('ingresos') && sucursalData['ingresos'] is Map) {
        final ingresos = sucursalData['ingresos'] as Map<String, dynamic>;
        for (var key in ingresos.keys) {
          // sucursal 키는 제외 (이미 컬럼 헤더에 표시됨)
          if (key != 'sucursal' && !allMetrics.contains('ingresos_$key')) {
            allMetrics.add('ingresos_$key');
          }
        }
      }
    }
    
    // FVentas 항목 추가 (전체 데이터에서 가져옴 - Factura A, B, NCA, NCB)
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('   → FVentas 데이터 추가 시작');
    debugPrint('   → data.containsKey(\'fventas\'): ${data.containsKey('fventas')}');
    
    // 먼저 원본 fventas 데이터 구조 확인
    if (data.containsKey('fventas')) {
      final fventasRaw = data['fventas'];
      debugPrint('   → fventas 원본 타입: ${fventasRaw.runtimeType}');
      if (fventasRaw is List) {
        debugPrint('   → fventas 원본 List 길이: ${fventasRaw.length}');
        debugPrint('   → fventas 원본 데이터 (날짜별):');
        for (int i = 0; i < fventasRaw.length; i++) {
          final item = fventasRaw[i];
          if (item is Map<String, dynamic>) {
            debugPrint('      - 항목 #$i:');
            debugPrint('         → 전체 데이터: $item');
            debugPrint('         → 키: ${item.keys.toList()}');
            debugPrint('         → tipofactura: ${item['tipofactura']}');
            debugPrint('         → sucursal 존재 여부: ${item.containsKey('sucursal')}');
            if (item.containsKey('sucursal')) {
              debugPrint('         → sucursal 값: ${item['sucursal']} (타입: ${item['sucursal'].runtimeType})');
            }
            debugPrint('         → count: ${item['count']}');
            debugPrint('         → sum_monto: ${item['sum_monto']}');
            if (item.containsKey('fecha')) {
              debugPrint('         → fecha: ${item['fecha']}');
            }
          }
        }
      }
    }
    
    final aggregatedFventas = _getAggregatedFventas();
    debugPrint('   → aggregatedFventas 결과:');
    debugPrint('      → 키: ${aggregatedFventas.keys.toList()}');
    if (aggregatedFventas.containsKey('items') && aggregatedFventas['items'] is List) {
      final fventasItems = aggregatedFventas['items'] as List;
      debugPrint('      → items 개수: ${fventasItems.length}');
      for (var item in fventasItems) {
        if (item is Map<String, dynamic>) {
          final tipofactura = item['tipofactura']?.toString() ?? 'Unknown';
          debugPrint('         - tipofactura: $tipofactura, count: ${item['count']}, sum_monto: ${item['sum_monto']}');
          if (['A', 'B', 'NCA', 'NCB'].contains(tipofactura)) {
            if (!allMetrics.contains('fventas_${tipofactura}_count')) {
              allMetrics.add('fventas_${tipofactura}_count');
              debugPrint('            → 메트릭 추가: fventas_${tipofactura}_count');
            }
            if (!allMetrics.contains('fventas_${tipofactura}_sum_monto')) {
              allMetrics.add('fventas_${tipofactura}_sum_monto');
              debugPrint('            → 메트릭 추가: fventas_${tipofactura}_sum_monto');
            }
          }
        }
      }
      debugPrint('   → FVentas 메트릭 추가 완료');
    } else {
      debugPrint('   ⚠️ aggregatedFventas에 items가 없거나 List가 아님');
    }
    debugPrint('═══════════════════════════════════════════════════════');
    
    // FVentas Mes 항목 추가 (sucursal별로 구분)
    debugPrint('   → FVentas Mes 데이터 추가 시작 (sucursal별 구분)');
    if (data.containsKey('fventas_mes') && data['fventas_mes'] is List) {
      final fventasMesList = data['fventas_mes'] as List;
      final tipofacturaSet = <String>{};
      
      // 모든 tipofactura 수집
      for (var item in fventasMesList) {
        if (item is Map<String, dynamic>) {
          final tipofactura = item['tipofactura']?.toString() ?? 'Unknown';
          tipofacturaSet.add(tipofactura);
        }
      }
      
      // 각 tipofactura에 대해 메트릭 추가
      for (var tipofactura in tipofacturaSet) {
        if (!allMetrics.contains('fventas_mes_$tipofactura')) {
          allMetrics.add('fventas_mes_$tipofactura');
          debugPrint('      - FVentas Mes 메트릭 추가: $tipofactura');
        }
      }
      debugPrint('   → FVentas Mes 메트릭 추가 완료 (${tipofacturaSet.length}개 타입)');
    }

    debugPrint('📊 수집된 메트릭: ${allMetrics.length}개 - $allMetrics');

    // Encargado 모드: 금액 숨김, 오직 판매 수·마지막 venta·gastos 수만 표시
    final configService = ConfigService();
    final isEncargado = configService.isResumenDelDiaEncargadoMode();
    final List<String> displayMetrics = isEncargado
        ? allMetrics.where((m) => _isEncargadoAllowedMetric(m)).toList()
        : allMetrics;
    if (isEncargado) {
      debugPrint('   → Encargado 모드: 메트릭 필터 적용 (${displayMetrics.length}개) - $displayMetrics');
    }

    // 메트릭이 없으면 빈 테이블 메시지 표시
    if (displayMetrics.isEmpty) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              '비교할 데이터가 없습니다',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
        ),
      );
    }

    // 테이블 생성
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowHeight: 42, // 56 * 0.75 = 42
          dataRowMinHeight: 36, // 48 * 0.75 = 36
          dataRowMaxHeight: 54, // 72 * 0.75 = 54
          columns: [
            const DataColumn(
              label: Text(
                'Métrica',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...sucursalesData.map((sucursalData) {
              final sucursal = sucursalData['sucursal']?.toString() ?? 'Unknown';
              return DataColumn(
                label: Text(
                  'Sucursal $sucursal',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
            const DataColumn(
              label: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: displayMetrics.map((metric) {
            // 메트릭 이름과 카테고리 파싱
            final parts = metric.split('_');
            final category = parts[0]; // vcodes, gastos, vdetalle, mpago, ingresos, fventas, fventas_mes
            final key = parts.sublist(1).join('_'); // 나머지 부분
            
            debugPrint('   → 메트릭 처리: $metric (category=$category, key=$key)');
            
            // 각 sucursal의 값 수집
            final sucursalValues = <dynamic>[];
            
            for (var sucursalData in sucursalesData) {
              dynamic value;
              
              if (category == 'vcodes' && sucursalData.containsKey('vcodes')) {
                final vcodesData = sucursalData['vcodes'];
                if (vcodesData is Map<String, dynamic>) {
                  value = vcodesData[key];
                }
              } else if (category == 'gastos' && sucursalData.containsKey('gastos')) {
                final gastosData = sucursalData['gastos'];
                if (gastosData is Map<String, dynamic>) {
                  value = gastosData[key];
                }
              } else if (category == 'vdetalle') {
                debugPrint('═══════════════════════════════════════════════════════');
                debugPrint('      → Vdetalle 처리 시작');
                debugPrint('         → 현재 처리 중인 sucursalData: ${sucursalData['sucursal']}');
                debugPrint('         → key: $key');
                debugPrint('         → sucursalData.containsKey(\'vdetalle\'): ${sucursalData.containsKey('vdetalle')}');
                
                if (sucursalData.containsKey('vdetalle')) {
                  final vdetalleData = sucursalData['vdetalle'];
                  debugPrint('         → vdetalleData 타입: ${vdetalleData.runtimeType}');
                  debugPrint('         → vdetalleData 값: $vdetalleData');
                  
                  if (vdetalleData is Map<String, dynamic>) {
                    debugPrint('         → vdetalleData 키: ${vdetalleData.keys.toList()}');
                    debugPrint('         → vdetalleData.containsKey(\'$key\'): ${vdetalleData.containsKey(key)}');
                    value = vdetalleData[key];
                    debugPrint('         → 최종 value: $value');
                  } else {
                    debugPrint('         ⚠️ vdetalleData가 Map<String, dynamic>이 아님');
                  }
                } else {
                  debugPrint('         ⚠️ sucursalData에 vdetalle 키가 없음');
                  debugPrint('         → sucursalData 키: ${sucursalData.keys.toList()}');
                }
                debugPrint('═══════════════════════════════════════════════════════');
              } else if (category == 'mpago' && sucursalData.containsKey('vcodes_mpago')) {
                final mpagoData = sucursalData['vcodes_mpago'];
                if (mpagoData is Map<String, dynamic>) {
                  value = mpagoData[key];
                }
              } else if (category == 'ingresos' && sucursalData.containsKey('ingresos')) {
                final ingresosData = sucursalData['ingresos'];
                if (ingresosData is Map<String, dynamic>) {
                  value = ingresosData[key];
                }
              } else if (category == 'fventas') {
                // FVentas 처리 - sucursalData에서 직접 가져오기
                // key 형식: A_count, B_sum_monto 등
                debugPrint('═══════════════════════════════════════════════════════');
                debugPrint('      → FVentas 처리 시작');
                debugPrint('         → 현재 처리 중인 sucursalData: ${sucursalData['sucursal']}');
                debugPrint('         → key: $key');
                debugPrint('         → sucursalData.containsKey(\'fventas\'): ${sucursalData.containsKey('fventas')}');
                
                final keyParts = key.split('_');
                if (keyParts.length >= 2) {
                  final tipofactura = keyParts[0]; // A, B, NCA, NCB
                  final fieldType = keyParts.sublist(1).join('_'); // count 또는 sum_monto
                  
                  debugPrint('         → 파싱된 tipofactura: $tipofactura');
                  debugPrint('         → 파싱된 fieldType: $fieldType');
                  
                  // sucursalData에서 fventas 데이터 가져오기
                  if (sucursalData.containsKey('fventas') && sucursalData['fventas'] is Map) {
                    final fventasData = sucursalData['fventas'] as Map<String, dynamic>;
                    debugPrint('         → fventasData: $fventasData');
                    
                    if (fventasData.containsKey('items') && fventasData['items'] is List) {
                      final fventasItems = fventasData['items'] as List;
                      debugPrint('         → fventasItems 길이: ${fventasItems.length}');
                      
                      // 해당 tipofactura 찾기
                      for (var item in fventasItems) {
                        if (item is Map<String, dynamic>) {
                          final itemTipofactura = item['tipofactura']?.toString() ?? 'Unknown';
                          debugPrint('            → 항목 체크: tipofactura=$itemTipofactura');
                          
                          if (itemTipofactura == tipofactura) {
                            debugPrint('            ✅ 해당 tipofactura 찾음!');
                            if (fieldType == 'count') {
                              value = item['count'] as int? ?? 0;
                              debugPrint('               → count 값: $value');
                            } else if (fieldType == 'sum_monto') {
                              value = (item['sum_monto'] as num?)?.toDouble() ?? 0.0;
                              debugPrint('               → sum_monto 값: $value');
                            }
                            break;
                          }
                        }
                      }
                      
                      if (value == null) {
                        debugPrint('         ⚠️ 해당 tipofactura를 찾지 못함 - 0으로 설정');
                        value = fieldType == 'count' ? 0 : 0.0;
                      }
                    } else {
                      debugPrint('         ⚠️ fventasData에 items가 없거나 List가 아님');
                      value = fieldType == 'count' ? 0 : 0.0;
                    }
                  } else {
                    debugPrint('         ⚠️ sucursalData에 fventas 키가 없거나 Map이 아님');
                    debugPrint('         → sucursalData 키: ${sucursalData.keys.toList()}');
                    value = fieldType == 'count' ? 0 : 0.0;
                  }
                } else {
                  debugPrint('         ⚠️ key 형식이 올바르지 않음: $key');
                  value = 0;
                }
                debugPrint('═══════════════════════════════════════════════════════');
              } else if (category == 'fventas_mes') {
                // FVentas Mes는 sucursal별로 구분하여 가져옴
                // key는 tipofactura (A, B, C, NCA, NCB, NCM)
                // sucursalData에서 sucursal 번호 추출
                final sucursalNum = sucursalData['sucursal'] is int
                    ? sucursalData['sucursal'] as int
                    : int.tryParse(sucursalData['sucursal']?.toString() ?? '0') ?? 0;
                
                debugPrint('      → FVentas Mes 처리: sucursal=$sucursalNum, tipofactura=$key');
                
                if (data.containsKey('fventas_mes') && data['fventas_mes'] is List) {
                  final fventasMesList = data['fventas_mes'] as List;
                  final tipofactura = key; // key가 tipofactura임
                  
                  // 해당 sucursal과 tipofactura에 맞는 항목 찾기
                  for (var item in fventasMesList) {
                    if (item is Map<String, dynamic>) {
                      final itemSucursal = item['sucursal'] is int
                          ? item['sucursal'] as int
                          : int.tryParse(item['sucursal']?.toString() ?? '0') ?? 0;
                      final itemTipofactura = item['tipofactura']?.toString() ?? 'Unknown';
                      
                      if (itemSucursal == sucursalNum && itemTipofactura == tipofactura) {
                        value = (item['total_ventas_mes'] as num?)?.toDouble() ?? 0.0;
                        debugPrint('         → 찾음: total_ventas_mes=$value');
                        break;
                      }
                    }
                  }
                  
                  if (value == null) {
                    value = 0.0;
                    debugPrint('         → 해당 데이터 없음, 0으로 설정');
                  }
                }
              }
              
              // FVentas 메트릭인 경우 상세 로그 기록
              if (category == 'fventas') {
                debugPrint('         → [FVentas 테이블 값] sucursal=${sucursalData['sucursal']}, metric=$metric, 최종 value=$value');
              }
              
              sucursalValues.add(value);
            }
            
            // FVentas 메트릭인 경우 모든 sucursal 값 요약 로그
            if (category == 'fventas') {
              debugPrint('═══════════════════════════════════════════════════════');
              debugPrint('   📊 [FVentas 테이블 값 요약] 메트릭: $metric');
              debugPrint('      → 각 sucursal별 값:');
              for (int i = 0; i < sucursalesData.length; i++) {
                final sucursal = sucursalesData[i]['sucursal']?.toString() ?? 'Unknown';
                final val = i < sucursalValues.length ? sucursalValues[i] : null;
                debugPrint('         - Sucursal $sucursal: $val');
              }
              debugPrint('═══════════════════════════════════════════════════════');
            }
            
            // Total 계산
            // FVentas는 전체 데이터이므로 각 sucursal에 동일한 값이 표시됨 (첫 번째 값 사용)
            // FVentas Mes는 이제 sucursal별로 구분되므로 모든 sucursal 값의 합산
            // 그 외의 경우는 모든 sucursal 값의 합산
            dynamic totalValue;
            
            if (category == 'fventas') {
              // FVentas는 이제 sucursal별로 구분되므로 모든 sucursal 값의 합산
              if (sucursalValues.isNotEmpty) {
                totalValue = sucursalValues.fold<dynamic>(
                  null,
                  (sum, val) {
                    if (val == null) return sum;
                    if (sum == null) {
                      if (val is num) return val;
                      return null;
                    }
                    if (val is num && sum is num) {
                      return sum + val;
                    }
                    return sum;
                  },
                );
                debugPrint('      → Total (FVentas): $totalValue (sucursal별 합산)');
              } else {
                totalValue = null;
              }
            } else {
              // 나머지는 각 sucursal 값의 합산
              totalValue = sucursalValues.fold<dynamic>(
                null,
                (sum, val) {
                  if (val == null) return sum;
                  if (sum == null) {
                    if (val is num) return val;
                    return null;
                  }
                  if (val is num && sum is num) {
                    return sum + val;
                  }
                  return sum;
                },
              );
              debugPrint('      → Total 계산: $totalValue (합산)');
            }
            
            // 메트릭 이름 매핑
            final metricNames = {
              'vcodes_total_venta_day': 'Total Ventas',
              'vcodes_total_efectivo_day': 'Total Efectivo',
              'vcodes_total_credito_day': 'Total Crédito',
              'vcodes_total_banco_day': 'Ventas Bancarias',
              'vcodes_total_favor_day': 'Ventas Favor',
              'vcodes_total_count_ropas': 'Total de Ropas',
              'vcodes_last_venta_hour': 'Última Venta',
              'gastos_gasto_count': 'Evento de Gastos',
              'gastos_total_gasto_day': 'Total de Gastos',
              'vdetalle_count_discount_event': 'Eventos de Descuento',
              'vdetalle_total_discount_day': 'Total Descuento',
              'mpago_count_mpago_total': 'Evento de MPago',
              'mpago_total_mpago_day': 'Total MPago',
              'ingresos_ingreso_events': 'Eventos de Ingreso',
              'ingresos_ingreso_total_ropas': 'Total de Ropas Ingresadas',
              // FVentas 항목
              'fventas_A_count': 'FVentas A - Cantidad',
              'fventas_A_sum_monto': 'FVentas A - Monto',
              'fventas_B_count': 'FVentas B - Cantidad',
              'fventas_B_sum_monto': 'FVentas B - Monto',
              'fventas_NCA_count': 'FVentas NCA - Cantidad',
              'fventas_NCA_sum_monto': 'FVentas NCA - Monto',
              'fventas_NCB_count': 'FVentas NCB - Cantidad',
              'fventas_NCB_sum_monto': 'FVentas NCB - Monto',
              // FVentas Mes 항목
              'fventas_mes_A': 'FVentas del Mes - Tipo A',
              'fventas_mes_B': 'FVentas del Mes - Tipo B',
              'fventas_mes_C': 'FVentas del Mes - Tipo C',
              'fventas_mes_NCA': 'FVentas del Mes - Tipo NCA',
              'fventas_mes_NCB': 'FVentas del Mes - Tipo NCB',
              'fventas_mes_NCM': 'FVentas del Mes - Tipo NCM',
            };
            
            final metricName = metricNames[metric] ?? key;
            // 통화 표시가 필요한 항목만 true로 설정 (건수는 제외)
            final isCurrency = (metric.contains('total_venta') || 
                               metric.contains('total_efectivo') || 
                               metric.contains('total_credito') || 
                               metric.contains('total_banco') || 
                               metric.contains('total_favor') ||
                               metric.contains('total_gasto') ||
                               metric.contains('total_discount') ||
                               metric.contains('total_mpago') ||
                               metric.contains('sum_monto') ||
                               metric.contains('fventas_mes_') ||
                               metric.contains('tVentas') ||
                               metric.contains('tIngresos') ||
                               metric.contains('tOffset') ||
                               metric.contains('hVentas') ||
                               metric.contains('hIngresos')) &&
                              !metric.contains('count') &&
                              !metric.contains('_count') &&
                              !metric.contains('_count_') &&
                              !metric.contains('events');
            
            // Encargado 모드에서 금액 칸은 **** 로 표시 (필터 후에도 방어적으로 적용)
            final maskAmount = isEncargado && isCurrency;
            return DataRow(
              cells: [
                DataCell(Text(metricName)),
                ...sucursalValues.map((value) {
                  if (value == null) {
                    return const DataCell(Text('-'));
                  }
                  if (maskAmount) {
                    return const DataCell(Text('****'));
                  }
                  if (isCurrency && value is num) {
                    return DataCell(Text(NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(value)));
                  }
                  return DataCell(Text(value.toString()));
                }),
                DataCell(
                  totalValue == null
                      ? const Text('-')
                      : maskAmount
                          ? const Text('****')
                          : isCurrency && totalValue is num
                              ? Text(NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(totalValue))
                              : Text(totalValue.toString()),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==================== 헬퍼 함수들 ====================

  /// Encargado 모드일 때 허용하는 메트릭만 표시: 판매 수, 마지막 venta 시각, gastos 수
  static bool _isEncargadoAllowedMetric(String metric) {
    const allowed = {
      'vcodes_total_count_ropas',   // Total de Ropas (몇 개 판매)
      'vcodes_last_venta_hour',     // Última Venta (마지막 venta 시각)
      'gastos_gasto_count',         // Evento de Gastos (gastos 몇 개)
      'vcodes_operation_count',     // 이벤트 수 (서버에서 오는 경우)
    };
    if (allowed.contains(metric)) return true;
    if (metric.startsWith('vcodes_') && (metric.contains('operation_count') || metric.contains('event_count'))) return true;
    return false;
  }

  bool _isLargeScreen(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 1200;
  }

  /// 날짜 선택 버튼 (단일 sucursal 뷰와 동일한 형태)
  ///
  /// 여러 sucursal 뷰에는 이 버튼이 없어서 다른 날짜를 조회할 방법이 없었다.
  /// _buildDateHeader 는 서버가 응답한 fecha 를 보여주는 표시 전용이라 탭해도 반응하지 않는다.
  Widget _buildDateSelectorButton() {
    final labelDate = selectedDate ?? DateTime.now();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: onSelectDate,
          icon: const Icon(Icons.calendar_today),
          label: Text(
            DateFormat('yyyy-MM-dd').format(labelDate),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader(BuildContext context, dynamic fecha) {
    String fechaStr = '';
    if (fecha is String) {
      fechaStr = fecha;
    } else if (fecha is DateTime) {
      fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
    } else {
      fechaStr = fecha.toString();
    }
    
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          fechaStr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getAggregatedFventas() {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_getAggregatedFventas] 호출됨');
    debugPrint('   → data.containsKey(\'fventas\'): ${data.containsKey('fventas')}');
    
    final result = <String, dynamic>{};
    
    if (data.containsKey('fventas')) {
      final fventas = data['fventas'];
      debugPrint('   → fventas 타입: ${fventas.runtimeType}');
      
      if (fventas is List && fventas.isNotEmpty) {
        debugPrint('   → fventas List 길이: ${fventas.length}');
        debugPrint('   → fventas 원본 데이터:');
        for (int i = 0; i < fventas.length; i++) {
          final item = fventas[i];
          if (item is Map<String, dynamic>) {
            debugPrint('      - 항목 #$i: $item');
            debugPrint('         → 키: ${item.keys.toList()}');
            debugPrint('         → tipofactura: ${item['tipofactura']}');
            debugPrint('         → sucursal 존재 여부: ${item.containsKey('sucursal')}');
            if (item.containsKey('sucursal')) {
              debugPrint('         → sucursal 값: ${item['sucursal']} (타입: ${item['sucursal'].runtimeType})');
            }
            debugPrint('         → count: ${item['count']}');
            debugPrint('         → sum_monto: ${item['sum_monto']}');
          }
        }
        
        final Map<String, Map<String, dynamic>> groupedFventas = {};
        
        for (var item in fventas) {
          if (item is Map<String, dynamic>) {
            final tipofactura = item['tipofactura']?.toString() ?? 'Unknown';
            final sucursal = item.containsKey('sucursal') 
                ? (item['sucursal'] is int 
                    ? item['sucursal'] as int 
                    : int.tryParse(item['sucursal']?.toString() ?? '0') ?? 0)
                : null;
            
            debugPrint('      → 처리 중: tipofactura=$tipofactura, sucursal=$sucursal');
            
            if (!groupedFventas.containsKey(tipofactura)) {
              groupedFventas[tipofactura] = {
                'tipofactura': tipofactura,
                'count': 0,
                'sum_monto': 0.0,
              };
            }
            
            final oldCount = groupedFventas[tipofactura]!['count'] as int;
            final oldSumMonto = groupedFventas[tipofactura]!['sum_monto'] as double;
            final newCount = (item['count'] as num?)?.toInt() ?? 0;
            final newSumMonto = (item['sum_monto'] as num?)?.toDouble() ?? 0.0;
            
            groupedFventas[tipofactura]!['count'] = oldCount + newCount;
            groupedFventas[tipofactura]!['sum_monto'] = oldSumMonto + newSumMonto;
            
            debugPrint('         → 합산: count=$oldCount + $newCount = ${oldCount + newCount}');
            debugPrint('         → 합산: sum_monto=$oldSumMonto + $newSumMonto = ${oldSumMonto + newSumMonto}');
          }
        }
        
        debugPrint('   → 최종 groupedFventas:');
        groupedFventas.forEach((key, value) {
          debugPrint('      - $key: $value');
        });
        
        result['items'] = groupedFventas.values.toList();
        debugPrint('   → result[\'items\']: ${result['items']}');
      } else {
        debugPrint('   ⚠️ fventas가 List가 아니거나 비어있음');
      }
    } else {
      debugPrint('   ⚠️ data에 fventas 키가 없음');
    }
    
    debugPrint('═══════════════════════════════════════════════════════');
    return result;
  }

  Map<String, dynamic> _getAggregatedFventasMes() {
    final result = <String, dynamic>{};
    
    if (data.containsKey('fventas_mes')) {
      final fventasMes = data['fventas_mes'];
      if (fventasMes is List && fventasMes.isNotEmpty) {
        final Map<String, Map<String, dynamic>> groupedMes = {};
        
        for (var item in fventasMes) {
          if (item is Map<String, dynamic>) {
            final tipofactura = item['tipofactura']?.toString() ?? 'Unknown';
            
            if (!groupedMes.containsKey(tipofactura)) {
              groupedMes[tipofactura] = {
                'tipofactura': tipofactura,
                'total_ventas_mes': 0.0,
              };
            }
            
            groupedMes[tipofactura]!['total_ventas_mes'] = 
                (groupedMes[tipofactura]!['total_ventas_mes'] as double) + 
                ((item['total_ventas_mes'] as num?)?.toDouble() ?? 0.0);
          }
        }
        
        result['items'] = groupedMes.values.toList();
        result['total_ventas_mes'] = groupedMes.values.fold<double>(
          0.0, 
          (sum, item) => sum + ((item['total_ventas_mes'] as num?)?.toDouble() ?? 0.0)
        );
      }
    }
    
    return result;
  }

  List<Widget> _buildStockResumenSection(BuildContext context, Map<String, dynamic> stockData, bool isLarge) {
    try {
      if (stockData.isEmpty) {
        return [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Stock resumen 데이터가 없습니다.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ];
      }
      
      if (stockData.containsKey('stocks') && stockData['stocks'] is List) {
        final stocksList = stockData['stocks'] as List;
        
        if (stocksList.isEmpty) {
          return [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Stock resumen 데이터가 없습니다.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ];
        }
        
        final List<Map<String, dynamic>> parsedStocks = [];
        double totalItemCount = 0;
        double totalTVentas = 0;
        double totalTIngresos = 0;
        double totalTOffset = 0;
        double totalHVentas = 0;
        double totalHIngresos = 0;
        double totalFinalStock = 0;
        
        for (var stock in stocksList) {
          if (stock is Map<String, dynamic>) {
            final sucursalValue = stock['sucursal'];
            final sucursal = sucursalValue?.toString() ?? 'N/A';
            
            if (sucursal == 'N/A') {
              continue;
            }
            
            final itemCount = _getValue(stock, ['item_count', 'itemCount', 'itemcount']) ?? 0;
            final tVentas = _getDoubleValue(stock, ['tventas', 'tVentas', 't_ventas', 'total_ventas', 'totalVentas']) ?? 0.0;
            final tIngresos = _getDoubleValue(stock, ['tingresos', 'tIngresos', 't_ingresos', 'total_ingresos', 'totalIngresos']) ?? 0.0;
            final tOffset = _getDoubleValue(stock, ['toffset', 'tOffset', 't_offset', 'total_offset', 'totalOffset']) ?? 0.0;
            final hVentas = _getDoubleValue(stock, ['hventas', 'hVentas', 'h_ventas', 'hoy_ventas', 'hoyVentas']) ?? 0.0;
            final hIngresos = _getDoubleValue(stock, ['hingresos', 'hIngresos', 'h_ingresos', 'hoy_ingresos', 'hoyIngresos']) ?? 0.0;
            final finalStock = _getDoubleValue(stock, ['finalstock', 'finalStock', 'final_stock']) ?? 0.0;
            
            parsedStocks.add({
              'sucursal': sucursal,
              'itemCount': itemCount,
              'tVentas': tVentas,
              'tIngresos': tIngresos,
              'tOffset': tOffset,
              'hVentas': hVentas,
              'hIngresos': hIngresos,
              'finalStock': finalStock,
            });
            
            totalItemCount += (itemCount is num ? itemCount.toDouble() : (itemCount is String ? double.tryParse(itemCount) ?? 0.0 : 0.0));
            totalTVentas += tVentas;
            totalTIngresos += tIngresos;
            totalTOffset += tOffset;
            totalHVentas += hVentas;
            totalHIngresos += hIngresos;
            totalFinalStock += finalStock;
          }
        }
        
        if (parsedStocks.isEmpty) {
          return [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Stock resumen 데이터가 없습니다.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ];
        }
        
        return [
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                columns: const [
                  DataColumn(label: Text('Sucursal', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Item Count', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Total Ventas', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Total Ingresos', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Total Offset', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Hoy Ventas', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Hoy Ingresos', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Final Stock', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: [
                  ...parsedStocks.map((stock) => DataRow(
                    cells: [
                      DataCell(Text(stock['sucursal'].toString())),
                      DataCell(Text(stock['itemCount'].toString())),
                      // tVentas 만 금액. 나머지는 수량이므로 통화 기호를 붙이지 않는다.
                      DataCell(Text(_formatValue(stock['tVentas'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['tIngresos']))),
                      DataCell(Text(_formatValue(stock['tOffset']))),
                      DataCell(Text(_formatValue(stock['hVentas']))),
                      DataCell(Text(_formatValue(stock['hIngresos']))),
                      DataCell(Text(_formatValue(stock['finalStock']))),
                    ],
                  )),
                  DataRow(
                    color: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ),
                    cells: [
                      const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(totalItemCount.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold))),
                      // tVentas 만 금액. 나머지는 수량이므로 통화 기호를 붙이지 않는다.
                      DataCell(Text(_formatValue(totalTVentas, isCurrency: true), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalTIngresos), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalTOffset), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalHVentas), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalHIngresos), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalFinalStock), style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ];
      }
      
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Stock resumen 데이터가 없습니다.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    } catch (e) {
      debugPrint('Error building Stock Resumen section: $e');
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Stock resumen 데이터를 표시하는 중 오류가 발생했습니다: $e',
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }
  }

  dynamic _getValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) {
        return map[key];
      }
    }
    return null;
  }

  double? _getDoubleValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) {
        final value = map[key];
        if (value is num) {
          return value.toDouble();
        } else if (value is String) {
          return double.tryParse(value);
        }
      }
    }
    return null;
  }

  String _formatValue(dynamic value, {bool isCurrency = false}) {
    if (value == null) return '-';
    if (isCurrency && value is num) {
      return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(value);
    }
    if (value is num) {
      return NumberFormat('#,##0.##').format(value);
    }
    return value.toString();
  }
}

// ==================== Resizable Split View ====================

class _ResizableSplitView extends StatefulWidget {
  final Widget leftChild;
  final Widget rightChild;
  final int sucursalesCount;
  
  const _ResizableSplitView({
    required this.leftChild,
    required this.rightChild,
    required this.sucursalesCount,
  });

  @override
  State<_ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<_ResizableSplitView> {
  static const String _prefsKey = 'resumen_del_dia_left_panel_width';
  static const double _dividerWidth = 4.0;
  
  late double _leftWidth;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // sucursal 개수에 따라 기본 너비 조정 (4-5개일 때 더 넓게)
    if (widget.sucursalesCount >= 4) {
      _leftWidth = 600.0; // 4개 이상일 때 더 넓게
    } else if (widget.sucursalesCount == 3) {
      _leftWidth = 500.0;
    } else {
      _leftWidth = 400.0; // 2개일 때 기본값
    }
    _loadSavedWidth();
  }

  Future<void> _loadSavedWidth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedWidth = prefs.getDouble(_prefsKey);
      if (savedWidth != null && savedWidth >= 200.0 && savedWidth <= 1200.0) {
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
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    final newWidth = _leftWidth + details.delta.dx;
    final clampedWidth = newWidth.clamp(200.0, maxWidth * 0.8); // 최소 200, 최대 화면의 80%
    
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
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [_ResizableSplitView] 렌더링');
        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
        debugPrint('   → 현재 _leftWidth: $_leftWidth');
        debugPrint('   → sucursalesCount: ${widget.sucursalesCount}');
        
        // 화면 크기에 맞게 조정
        final maxLeftWidth = constraints.maxWidth * 0.8;
        const minLeftWidth = 200.0;
        final adjustedLeftWidth = _leftWidth.clamp(minLeftWidth, maxLeftWidth);
        
        if (adjustedLeftWidth != _leftWidth) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _leftWidth = adjustedLeftWidth;
            });
          });
        }
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽 패널
            SizedBox(
              width: adjustedLeftWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: widget.leftChild,
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
