import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../utils/platform_utils.dart';
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
      // TODO: 원본 파일에서 복사 필요
      
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
          
          // 왼쪽/오른쪽 분할 레이아웃
          debugPrint('   → Row 분할 레이아웃 추가 (Expanded 사용)');
          debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
          debugPrint('   → constraints.hasBoundedHeight: ${constraints.hasBoundedHeight}');
          
          columnChildren.add(
            Expanded(
              child: Builder(
                builder: (context) {
                  debugPrint('═══════════════════════════════════════════════════════');
                  debugPrint('🔍 [대형화면 레이아웃] Expanded 내부 Row 렌더링 시작');
                  debugPrint('   → 왼쪽:오른쪽 비율 = 1:2 (왼쪽이 오른쪽의 절반)');
                  debugPrint('   → flex 비율: 왼쪽=1, 오른쪽=2');
                  
                  return LayoutBuilder(
                    builder: (rowContext, rowConstraints) {
                      debugPrint('   → Row constraints: maxWidth=${rowConstraints.maxWidth}, maxHeight=${rowConstraints.maxHeight}');
                      final leftWidth = rowConstraints.maxWidth / 3; // 왼쪽이 전체의 1/3 (오른쪽의 절반)
                      final rightWidth = rowConstraints.maxWidth * 2 / 3; // 오른쪽이 전체의 2/3
                      debugPrint('   → 계산된 너비: 왼쪽=$leftWidth, 오른쪽=$rightWidth');
                      
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 왼쪽: 비교 테이블 (오른쪽의 절반 너비)
                          Expanded(
                            flex: 1,
                            child: Builder(
                              builder: (context) {
                                debugPrint('   → 왼쪽 테이블 영역 렌더링 시작');
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final renderObject = context.findRenderObject();
                                  if (renderObject != null && renderObject is RenderBox) {
                                    debugPrint('   → 왼쪽 테이블 영역 실제 크기: width=${renderObject.size.width}, height=${renderObject.size.height}');
                                  }
                                });
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: _buildComparisonTable(context, sucursalesData, l10n),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // 오른쪽: 카드 섹션 (왼쪽의 2배 너비)
                          Expanded(
                            flex: 2,
                            child: Builder(
                              builder: (context) {
                                debugPrint('═══════════════════════════════════════════════════════');
                                debugPrint('🔍 [오른쪽 카드 영역] 렌더링 시작');
                                
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final renderObject = context.findRenderObject();
                                  if (renderObject != null && renderObject is RenderBox) {
                                    debugPrint('   → 오른쪽 카드 영역 실제 크기: width=${renderObject.size.width}, height=${renderObject.size.height}');
                                    debugPrint('   → 카드 그리드 레이아웃: 한 줄에 2-3개 배치');
                                  }
                                });
                                
                                return LayoutBuilder(
                                  builder: (cardContext, cardConstraints) {
                                    debugPrint('═══════════════════════════════════════════════════════');
                                    debugPrint('🔍 [카드 영역 레이아웃] LayoutBuilder 시작');
                                    debugPrint('   → 카드 영역 constraints: maxWidth=${cardConstraints.maxWidth}, maxHeight=${cardConstraints.maxHeight}');
                                    
                                    // 카드와 Stock Resumen 테이블 분리
                                    final cardWidgets = _buildRightSideCards(context, l10n);
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
                                    
                                    debugPrint('   → 카드 위젯 개수: ${cardWidgets.length}');
                                    debugPrint('   → Stock Resumen 위젯 개수: ${stockWidgets.length}');
                                    debugPrint('   → Stock 데이터 존재 여부: $hasStockData');
                                    
                                    // 카드 너비 계산 (한 줄에 2-3개)
                                    // 패딩과 간격을 고려하여 카드 너비 계산
                                    const padding = 16.0;
                                    const spacing = 12.0;
                                    final availableWidth = cardConstraints.maxWidth - (padding * 2);
                                    final cardWidth2 = (availableWidth - spacing) / 2; // 한 줄에 2개
                                    final cardWidth3 = (availableWidth - spacing * 2) / 3; // 한 줄에 3개
                                    
                                    // 화면 크기에 따라 2개 또는 3개 선택
                                    final crossAxisCount = availableWidth > 600 ? 3 : 2;
                                    final cardWidth = crossAxisCount == 3 ? cardWidth3 : cardWidth2;
                                    
                                    debugPrint('   → 카드 레이아웃 계산:');
                                    debugPrint('      - availableWidth: $availableWidth');
                                    debugPrint('      - crossAxisCount: $crossAxisCount (한 줄 카드 개수)');
                                    debugPrint('      - cardWidth: $cardWidth');
                                    debugPrint('      - padding: $padding, spacing: $spacing');
                                    debugPrint('═══════════════════════════════════════════════════════');
                                    
                                    return SingleChildScrollView(
                                      padding: const EdgeInsets.all(padding),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // 카드 그리드
                                          if (cardWidgets.isNotEmpty)
                                            GridView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: crossAxisCount,
                                                crossAxisSpacing: spacing,
                                                mainAxisSpacing: spacing,
                                                childAspectRatio: cardWidth > 0 ? cardWidth / 120 : 1.5, // 카드 높이를 120으로 고정
                                              ),
                                              itemCount: cardWidgets.length,
                                              itemBuilder: (context, index) {
                                                debugPrint('      - 카드 #$index 렌더링 (총 ${cardWidgets.length}개 중)');
                                                return cardWidgets[index];
                                              },
                                            ),
                                          
                                          // Stock Resumen 테이블 (별도 섹션)
                                          if (hasStockData) ...[
                                            const SizedBox(height: 24),
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
                                          ],
                                        ],
                                      ),
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
          
          // 카드 섹션 (작은 화면에서는 테이블 아래에 표시)
          ..._buildRightSideCards(context, l10n),
        ],
      ),
    );
  }

  // ==================== 공통 헬퍼 함수들 ====================
  
  bool _isLargeScreen(BuildContext context) {
    if (PlatformUtils.isDesktop()) {
      return true;
    }
    if (PlatformUtils.isIPad(context)) {
      return true;
    }
    return false;
  }

  Widget _buildDateHeader(BuildContext context, String fecha) {
    return GestureDetector(
      onTap: onSelectDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Fecha: $fecha',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(dynamic value, {bool isCurrency = false}) {
    if (value == null) return 'N/A';
    
    final configService = ConfigService();
    final ventasConfig = configService.getVentasConfig();
    final shouldHideAmount = ventasConfig?['showTpago'] == false;
    
    if (shouldHideAmount && isCurrency) {
      return '****';
    }
    
    if (value is num) {
      return NumberFormat('#,###').format(value);
    }
    if (value is String) {
      String cleanedValue = value.replaceAll('\$', '').trim();
      final numValue = num.tryParse(cleanedValue.replaceAll(',', '').replaceAll('.', ''));
      if (numValue != null) {
        if (shouldHideAmount && isCurrency) {
          return '****';
        }
        return NumberFormat('#,###').format(numValue);
      }
      return cleanedValue;
    }
    return value.toString().replaceAll('\$', '').trim();
  }

  // ==================== 비교 테이블 및 카드 빌드 함수들 ====================
  
  Widget _buildDataCard(BuildContext context, String title, dynamic value, IconData icon, {bool isCurrency = false, VoidCallback? onTap, bool isLarge = false}) {
    final titleFontSize = isLarge ? (10.0 * 2 * 2 / 3) : 10.0;
    final valueFontSize = isLarge ? (16.0 * 2 * 2 / 3) : 16.0;
    final iconSize = isLarge ? (20.0 * 2 * 2 / 3) : 20.0;
    final padding = isLarge ? (12.0 * 2 * 2 / 3) : 12.0;
    final iconPadding = isLarge ? (10.0 * 2 * 2 / 3) : 10.0;
    final spacing = isLarge ? (2.0 * 2 * 2 / 3) : 2.0;
    
    Widget cardContent = Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: iconSize,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    SizedBox(height: spacing),
                    Text(
                      _formatValue(value, isCurrency: isCurrency),
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: isCurrency ? Theme.of(context).colorScheme.primary : Colors.black87,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: cardContent,
      );
    }
    
    return cardContent;
  }

  Map<String, dynamic> _getAggregatedFventas() {
    final result = <String, dynamic>{};
    
    if (data.containsKey('fventas')) {
      final fventas = data['fventas'];
      if (fventas is List && fventas.isNotEmpty) {
        final Map<String, Map<String, dynamic>> grouped = {};
        
        for (var item in fventas) {
          if (item is Map<String, dynamic>) {
            final tipofactura = item['tipofactura']?.toString() ?? 'Unknown';
            
            if (!grouped.containsKey(tipofactura)) {
              grouped[tipofactura] = {
                'tipofactura': tipofactura,
                'count': 0,
                'sum_monto': 0.0,
              };
            }
            
            grouped[tipofactura]!['count'] = (grouped[tipofactura]!['count'] as int) + 
                (item['count'] as int? ?? 0);
            grouped[tipofactura]!['sum_monto'] = (grouped[tipofactura]!['sum_monto'] as double) + 
                ((item['sum_monto'] as num?)?.toDouble() ?? 0.0);
          }
        }
        
        result['items'] = grouped.values.toList();
        
        const notaCreditoTypes = ['C', 'NCA', 'NCB', 'NCM'];
        int totalCount = 0;
        double totalSumMonto = 0.0;
        int notaCreditoCount = 0;
        double notaCreditoSumMonto = 0.0;
        
        for (var item in grouped.values) {
          final tipofactura = item['tipofactura']?.toString() ?? '';
          final count = item['count'] as int? ?? 0;
          final sumMonto = (item['sum_monto'] as num?)?.toDouble() ?? 0.0;
          
          if (notaCreditoTypes.contains(tipofactura)) {
            notaCreditoCount += count;
            notaCreditoSumMonto += sumMonto;
          } else {
            totalCount += count;
            totalSumMonto += sumMonto;
          }
        }
        
        final finalCount = (totalCount - notaCreditoCount) < 0 ? 0 : (totalCount - notaCreditoCount);
        final finalSumMonto = (totalSumMonto - notaCreditoSumMonto) < 0.0 ? 0.0 : (totalSumMonto - notaCreditoSumMonto);
        
        result['total_count'] = finalCount;
        result['total_sum_monto'] = finalSumMonto;
      }
    }
    
    return result;
  }

  Map<String, dynamic> _getAggregatedGastos() {
    if (!data.containsKey('gastos')) {
      return <String, dynamic>{};
    }
    
    final gastos = data['gastos'];
    if (gastos is Map<String, dynamic>) {
      return gastos;
    }
    
    if (gastos is List) {
      if (gastos.isEmpty) {
        return <String, dynamic>{};
      }
      
      final aggregated = <String, dynamic>{
        'gasto_count': 0,
        'total_gasto_day': 0.0,
      };
      
      for (var item in gastos) {
        if (item is Map<String, dynamic>) {
          final gastoCount = item['gasto_count'] as int? ?? item['count'] as int? ?? 0;
          final totalGastoDay = (item['total_gasto_day'] as num?)?.toDouble() ?? 
                               (item['total'] as num?)?.toDouble() ?? 0.0;
          
          aggregated['gasto_count'] = (aggregated['gasto_count'] as int) + gastoCount;
          aggregated['total_gasto_day'] = (aggregated['total_gasto_day'] as double) + totalGastoDay;
        }
      }
      
      return aggregated;
    }
    
    return <String, dynamic>{};
  }

  List<Widget> _buildFventasSection(BuildContext context, Map<String, dynamic> fventas, bool isLarge) {
    try {
      final cards = <Widget>[];
      
      if (fventas.isEmpty) {
        return cards;
      }
      
      if (fventas.containsKey('items') && fventas['items'] is List) {
        final items = fventas['items'] as List;
        
        if (items.isNotEmpty) {
          cards.add(
            InkWell(
              onTap: () => onReportTypeSelected(ReportType.fventas),
              child: Card(
                child: Container(
                  constraints: isLarge 
                      ? const BoxConstraints(minHeight: 140.0)
                      : const BoxConstraints(minHeight: 100.0),
                  padding: EdgeInsets.all(isLarge ? 18.0 : 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt, 
                            color: Colors.deepPurple, 
                            size: isLarge ? 24.0 : 20.0,
                          ),
                          SizedBox(width: isLarge ? 10.0 : 8.0),
                          Flexible(
                            child: Text(
                              'FVentas del Día',
                              style: TextStyle(
                                fontSize: isLarge ? 18.0 : 15.0,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isLarge ? 18.0 : 12.0),
                      ...items.map<Widget>((item) {
                        if (item is Map<String, dynamic>) {
                          final tipofactura = item['tipofactura']?.toString() ?? 'Unknown';
                          final sumMonto = (item['sum_monto'] as num?)?.toDouble() ?? 0.0;
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: isLarge ? 12.0 : 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Factura Tipo $tipofactura',
                                  style: TextStyle(
                                    fontSize: isLarge ? 15.0 : 13.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatValue(sumMonto, isCurrency: true),
                                  style: TextStyle(
                                    fontSize: isLarge ? 16.0 : 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
      
      if (fventas.containsKey('total_count')) {
        final totalCount = fventas['total_count'] as int? ?? 0;
        if (totalCount > 0) {
          cards.add(_buildDataCard(
            context,
            'Total Facturas',
            totalCount,
            Icons.receipt_long,
            isLarge: isLarge,
          ));
        }
      }
      
      if (fventas.containsKey('total_sum_monto')) {
        final totalSumMonto = (fventas['total_sum_monto'] as num?)?.toDouble() ?? 0.0;
        if (totalSumMonto > 0) {
          cards.add(_buildDataCard(
            context,
            'Total Monto',
            totalSumMonto,
            Icons.attach_money,
            isCurrency: true,
            isLarge: isLarge,
          ));
        }
      }

      return cards;
    } catch (e) {
      debugPrint('Error building FVentas section: $e');
      return [];
    }
  }

  List<Widget> _buildGastosSection(BuildContext context, Map<String, dynamic> gastos, bool isLarge) {
    try {
      final cards = <Widget>[];
      
      if (gastos.isEmpty) {
        return cards;
      }
      
      final gastoCount = gastos['gasto_count'] ?? gastos['count'];
      if (gastoCount != null && (gastoCount is int || gastoCount is num) && (gastoCount as num) > 0) {
        cards.add(_buildDataCard(
          context,
          'Evento de Gastos',
          gastoCount,
          Icons.receipt_long,
          isLarge: isLarge,
          onTap: () => onReportTypeSelected(ReportType.gastos),
        ));
      }
      
      final totalGastoDay = gastos['total_gasto_day'] ?? gastos['total'];
      if (totalGastoDay != null && totalGastoDay is num && totalGastoDay > 0) {
        cards.add(_buildDataCard(
          context,
          'Total de Gastos',
          totalGastoDay,
          Icons.payments,
          isCurrency: true,
          isLarge: isLarge,
        ));
      }

      return cards;
    } catch (e) {
      debugPrint('Error building Gastos section: $e');
      return [];
    }
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
            
            final sucursalNum = sucursalValue is num 
                ? sucursalValue 
                : (sucursalValue is String ? int.tryParse(sucursalValue) : null);
            
            if (sucursalNum == null || sucursalNum < 1) {
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
                headingRowColor: MaterialStateProperty.all(
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
                      DataCell(Text(_formatValue(stock['tVentas'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['tIngresos'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['tOffset'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['hVentas'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['hIngresos'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['finalStock']))),
                    ],
                  )),
                  DataRow(
                    color: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ),
                    cells: [
                      const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(totalItemCount.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalTVentas, isCurrency: true), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalTIngresos, isCurrency: true), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalTOffset, isCurrency: true), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalHVentas, isCurrency: true), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalHIngresos, isCurrency: true), style: const TextStyle(fontWeight: FontWeight.bold))),
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
    final value = _getValue(map, keys);
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  List<Widget> _buildRightSideCards(BuildContext context, AppLocalizations l10n) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_buildRightSideCards] 호출됨');
    debugPrint('   → 대형화면에서 GridView로 카드 배치 (한 줄에 2-3개)');
    final cards = <Widget>[];
    final isLarge = _isLargeScreen(context);
    
    // FVentas 섹션
    try {
      debugPrint('   → FVentas 섹션 생성 시작');
      final aggregatedFventas = _getAggregatedFventas();
      debugPrint('   → aggregatedFventas: $aggregatedFventas');
      final fventasWidgets = _buildFventasSection(context, aggregatedFventas, isLarge);
      debugPrint('   → fventasWidgets 개수: ${fventasWidgets.length}');
      
      if (fventasWidgets.isNotEmpty) {
        cards.addAll(fventasWidgets);
        debugPrint('   ✅ FVentas 카드 ${fventasWidgets.length}개 추가 완료');
      } else {
        debugPrint('   ⚠️ FVentas 위젯이 비어있음');
      }
    } catch (e) {
      debugPrint('   ❌ FVentas 섹션 생성 오류: $e');
    }
    
    // Gastos 섹션
    try {
      debugPrint('   → Gastos 섹션 생성 시작');
      final aggregatedGastos = _getAggregatedGastos();
      debugPrint('   → aggregatedGastos: $aggregatedGastos');
      final gastosWidgets = _buildGastosSection(context, aggregatedGastos, isLarge);
      debugPrint('   → gastosWidgets 개수: ${gastosWidgets.length}');
      
      if (gastosWidgets.isNotEmpty) {
        cards.addAll(gastosWidgets);
        debugPrint('   ✅ Gastos 카드 ${gastosWidgets.length}개 추가 완료');
      } else {
        debugPrint('   ⚠️ Gastos 위젯이 비어있음');
      }
    } catch (e) {
      debugPrint('   ❌ Gastos 섹션 생성 오류: $e');
    }
    
    // Stock Resumen 섹션
    try {
      debugPrint('   → Stock Resumen 섹션 생성 시작');
      final stockData = <String, dynamic>{};
      
      if (data.containsKey('stock_resumen') && data['stock_resumen'] is Map) {
        stockData.addAll(data['stock_resumen'] as Map<String, dynamic>);
        debugPrint('   → stock_resumen 키 발견');
      }
      
      if (data.containsKey('stocks')) {
        stockData['stocks'] = data['stocks'];
        debugPrint('   → stocks 키 발견');
      }
      
      debugPrint('   → stockData 키: ${stockData.keys.toList()}');
      final stockWidgets = _buildStockResumenSection(context, stockData, isLarge);
      debugPrint('   → stockWidgets 개수: ${stockWidgets.length}');
      
      if (stockWidgets.isNotEmpty) {
        // Stock Resumen은 테이블이므로 GridView에 포함하지 않고 별도 처리
        // cards.addAll(stockWidgets);
        debugPrint('   ✅ Stock Resumen 위젯 ${stockWidgets.length}개 생성 완료 (테이블은 별도 처리)');
      } else {
        debugPrint('   ⚠️ Stock Resumen 위젯이 비어있음');
      }
    } catch (e) {
      debugPrint('   ❌ Stock Resumen 섹션 생성 오류: $e');
    }
    
    debugPrint('   → 최종 카드 개수: ${cards.length}');
    debugPrint('   → GridView에 배치될 카드: ${cards.length}개');
    debugPrint('═══════════════════════════════════════════════════════');
    
    if (cards.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '추가 정보가 없습니다.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }
    
    return cards;
  }

  Widget _buildComparisonTable(BuildContext context, List<Map<String, dynamic>> sucursalesData, AppLocalizations l10n) {
    // 모든 통계 항목 수집
    final allMetrics = <String>[];
    
    for (var sucursalData in sucursalesData) {
      // vcodes 항목
      if (sucursalData.containsKey('vcodes') && sucursalData['vcodes'] is Map) {
        final vcodes = sucursalData['vcodes'] as Map<String, dynamic>;
        vcodes.keys.forEach((key) {
          if (!allMetrics.contains('vcodes_$key')) {
            allMetrics.add('vcodes_$key');
          }
        });
      }
      
      // gastos 항목
      if (sucursalData.containsKey('gastos') && sucursalData['gastos'] is Map) {
        final gastos = sucursalData['gastos'] as Map<String, dynamic>;
        gastos.keys.forEach((key) {
          if (!allMetrics.contains('gastos_$key')) {
            allMetrics.add('gastos_$key');
          }
        });
      }
      
      // vdetalle 항목
      if (sucursalData.containsKey('vdetalle') && sucursalData['vdetalle'] is Map) {
        final vdetalle = sucursalData['vdetalle'] as Map<String, dynamic>;
        vdetalle.keys.forEach((key) {
          if (!allMetrics.contains('vdetalle_$key')) {
            allMetrics.add('vdetalle_$key');
          }
        });
      }
      
      // vcodes_mpago 항목
      if (sucursalData.containsKey('vcodes_mpago') && sucursalData['vcodes_mpago'] is Map) {
        final mpago = sucursalData['vcodes_mpago'] as Map<String, dynamic>;
        mpago.keys.forEach((key) {
          if (!allMetrics.contains('mpago_$key')) {
            allMetrics.add('mpago_$key');
          }
        });
      }
      
      // ingresos 항목
      if (sucursalData.containsKey('ingresos') && sucursalData['ingresos'] is Map) {
        final ingresos = sucursalData['ingresos'] as Map<String, dynamic>;
        ingresos.keys.forEach((key) {
          if (!allMetrics.contains('ingresos_$key')) {
            allMetrics.add('ingresos_$key');
          }
        });
      }
      
      // stocks 항목
      if (sucursalData.containsKey('stocks') && sucursalData['stocks'] is Map) {
        final stocks = sucursalData['stocks'] as Map<String, dynamic>;
        stocks.keys.forEach((key) {
          if (!allMetrics.contains('stocks_$key')) {
            allMetrics.add('stocks_$key');
          }
        });
      }
    }

    debugPrint('📊 수집된 메트릭: ${allMetrics.length}개 - $allMetrics');

    // 메트릭이 없으면 빈 테이블 메시지 표시
    if (allMetrics.isEmpty) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              '표시할 데이터가 없습니다.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    // 테이블 컬럼 생성
    final columns = [
      DataColumn(
        label: Text(
          l10n.item,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      ...sucursalesData.map((data) {
        final sucursal = data['sucursal']?.toString() ?? 
                        data['sucursal_id']?.toString() ?? 
                        'N/A';
        return DataColumn(
          label: Text(
            sucursal,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }),
    ];

    // 테이블 행 생성 (sucursal 필터링)
    final filteredMetrics = allMetrics.where((metric) => !metric.contains('sucursal')).toList();
    debugPrint('📋 필터링된 메트릭: ${filteredMetrics.length}개');
    
    final rows = filteredMetrics.map((metric) {
      final parts = metric.split('_');
      final category = parts[0];
      final key = parts.sublist(1).join('_');
      
      debugPrint('  - 처리 중: $metric -> category: $category, key: $key');
      
      // 항목 이름 매핑 (스페인어)
      final metricNames = {
        'vcodes_operation_count': 'Evento de Venta',
        'vcodes_total_venta_day': 'Total de Ventas',
        'vcodes_total_efectivo_day': 'Ventas en Efectivo',
        'vcodes_total_credito_day': 'Ventas a Crédito',
        'vcodes_total_banco_day': 'Ventas Bancarias',
        'vcodes_total_favor_day': 'Ventas Favor',
        'vcodes_total_count_ropas': 'Total de Ropas',
        'vcodes_last_venta_hour': 'Última Venta',
        'gastos_gasto_count': 'Evento de Gastos',
        'gastos_total_gasto_day': 'Total de Gastos',
        'vdetalle_count_discount_event': 'Eventos de Descuento',
        'vdetalle_total_discount_day': 'Evento de Descuento',
        'mpago_count_mpago_total': 'Evento de MPago',
        'mpago_total_mpago_day': 'Total MPago',
        'ingresos_ingreso_events': 'Eventos de Ingreso',
        'ingresos_ingreso_total_ropas': 'Total de Ropas Ingresadas',
        'stocks_item_count': 'Item Count',
        'stocks_tVentas': 'Total Ventas',
        'stocks_tIngresos': 'Total Ingresos',
        'stocks_tOffset': 'Total Offset',
        'stocks_hVentas': 'Hoy Ventas',
        'stocks_hIngresos': 'Hoy Ingresos',
        'stocks_finalStock': 'Final Stock',
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
                         metric.contains('tVentas') ||
                         metric.contains('tIngresos') ||
                         metric.contains('tOffset') ||
                         metric.contains('hVentas') ||
                         metric.contains('hIngresos')) &&
                        !metric.contains('count') &&
                        !metric.contains('_count_') &&
                        !metric.contains('item_count') &&
                        !metric.contains('finalStock');
      
      return DataRow(
        cells: [
          DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(metricName),
            ),
          ),
          ...sucursalesData.map((data) {
            dynamic value;
            
            if (category == 'vcodes' && data.containsKey('vcodes')) {
              final vcodesData = data['vcodes'];
              if (vcodesData is Map<String, dynamic>) {
                value = vcodesData[key];
                // last_venta_hour 필드는 날짜/시간 형식으로 포맷팅
                if (key == 'last_venta_hour' && value != null) {
                  try {
                    final dateTime = DateTime.parse(value.toString());
                    value = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
                  } catch (e) {
                    // 파싱 실패 시 원본 값 유지
                  }
                }
              }
            } else if (category == 'gastos' && data.containsKey('gastos')) {
              final gastosData = data['gastos'];
              if (gastosData is Map<String, dynamic>) {
                value = gastosData[key];
              }
            } else if (category == 'vdetalle' && data.containsKey('vdetalle')) {
              final vdetalleData = data['vdetalle'];
              if (vdetalleData is Map<String, dynamic>) {
                value = vdetalleData[key];
              }
            } else if (category == 'mpago' && data.containsKey('vcodes_mpago')) {
              final mpagoData = data['vcodes_mpago'];
              if (mpagoData is Map<String, dynamic>) {
                value = mpagoData[key];
              }
            } else if (category == 'ingresos' && data.containsKey('ingresos')) {
              final ingresosData = data['ingresos'];
              if (ingresosData is Map<String, dynamic>) {
                value = ingresosData[key];
              }
            } else if (category == 'stocks' && data.containsKey('stocks')) {
              final stocksData = data['stocks'];
              if (stocksData is Map<String, dynamic>) {
                value = stocksData[key];
              }
            }
            
            final formattedValue = _formatValue(value, isCurrency: isCurrency);
            final isNumeric = value is num || (value is String && (num.tryParse(value.toString().replaceAll(',', '').replaceAll('.', '')) != null));
            
            return DataCell(
              Align(
                alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  formattedValue,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: isCurrency ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
              ),
            );
          }),
        ],
      );
    }).toList();

    debugPrint('✅ 테이블 생성 완료: ${columns.length}개 컬럼, ${rows.length}개 행');
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}
