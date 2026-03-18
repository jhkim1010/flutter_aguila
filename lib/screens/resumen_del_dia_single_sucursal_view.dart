import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../utils/platform_utils.dart';
import '../widgets/report_utils.dart';
import '../services/config_service.dart';
import 'report_screen.dart';

/// 단일 sucursal일 때 사용하는 Resumen del Dia 뷰
/// 
/// 이 파일은 sucursal이 1개일 때만 사용되며, 카드 형태로 데이터를 표시합니다.
/// 여러 sucursal일 때는 resumen_del_dia_multiple_sucursales_view.dart를 사용합니다.
class ResumenDelDiaSingleSucursalView extends StatelessWidget {
  final Map<String, dynamic> data;
  final DateTime? selectedDate;
  final String serverUrl;
  final Function() onRefresh;
  final Function() onSelectDate;
  final Function(ReportType) onReportTypeSelected;
  final String? errorMessage;
  
  const ResumenDelDiaSingleSucursalView({
    super.key,
    required this.data,
    required this.selectedDate,
    required this.serverUrl,
    required this.onRefresh,
    required this.onSelectDate,
    required this.onReportTypeSelected,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [단일 Sucursal 뷰] ResumenDelDiaSingleSucursalView.build 호출');
    debugPrint('   → data 키: ${data.keys.toList()}');
    debugPrint('   → selectedDate: $selectedDate');
    debugPrint('   → errorMessage: $errorMessage');
    debugPrint('═══════════════════════════════════════════════════════');
    
    final maxWidth = PlatformUtils.getMaxWidth(
      context,
      mobileMaxWidth: double.infinity,
      tabletMaxWidth: 1200,
      desktopMaxWidth: 1600,
    );
    final padding = PlatformUtils.getPadding(
      context,
      mobilePadding: const EdgeInsets.all(16),
      tabletPadding: const EdgeInsets.all(24),
      desktopPadding: const EdgeInsets.all(32),
    );
    
    // 각 섹션별 데이터 존재 여부 확인
    final sectionChecks = <String, bool>{
      'vcodes': data.containsKey('vcodes'),
      'gastos': data.containsKey('gastos'),
      'vdetalle': data.containsKey('vdetalle'),
      'vcodes_mpago': data.containsKey('vcodes_mpago'),
      'ingresos': data.containsKey('ingresos'),
      'fventas': data.containsKey('fventas'),
      'fventas_mes': data.containsKey('fventas_mes'),
      'stocks': data.containsKey('stocks'),
      'stock_resumen': data.containsKey('stock_resumen'),
    };
    
    debugPrint('   → 섹션별 데이터 존재 여부:');
    sectionChecks.forEach((key, exists) {
      debugPrint('      - $key: ${exists ? "✅ 있음" : "❌ 없음"}');
    });
    debugPrint('═══════════════════════════════════════════════════════');
    
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Builder(
            builder: (context) {
              debugPrint('🔍 [단일 Sucursal 뷰] Builder 내부 렌더링 시작');
              final isLarge = _isLargeScreen(context);
              debugPrint('   → 대형화면 여부: $isLarge');
              
              // 안전한 데이터 접근 (디버깅용)
              if (data.containsKey('vcodes')) {
                final vcodesData = data['vcodes'];
                debugPrint('   - vcodes 데이터 타입: ${vcodesData.runtimeType}');
                if (vcodesData is List) {
                  debugPrint('   - vcodes List 길이: ${vcodesData.length}');
                }
              }
              
              // 렌더링될 섹션 개수 추적
              int renderedSectionCount = 0;
              
              return SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 날짜 선택 버튼 (맨 윗줄)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: onSelectDate,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                selectedDate != null
                                    ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                                    : DateFormat('yyyy-MM-dd').format(DateTime.now()),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 에러가 있지만 데이터도 있는 경우 경고 배너 표시
                      if (errorMessage != null && data.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            border: Border.all(color: Colors.orange[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '데이터를 새로고침하는 중 오류가 발생했습니다. 이전 데이터를 표시합니다.',
                                  style: TextStyle(color: Colors.orange[900], fontSize: 12),
                                ),
                              ),
                              TextButton(
                                onPressed: onRefresh,
                                child: const Text('다시 시도', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      
                      // 판매 통계 (vcodes) - 여러 sucursal이 있으면 합산
                      if (data.containsKey('vcodes')) ...[
                        Builder(
                          builder: (context) {
                            debugPrint('   🔍 [단일 Sucursal] Vcodes 섹션 생성 시작');
                            try {
                              final aggregatedVcodes = _getAggregatedVcodes(data);
                              debugPrint('      → aggregatedVcodes: $aggregatedVcodes');
                              final vcodesWidgets = _buildVcodesSection(context, aggregatedVcodes, serverUrl, selectedDate, isLarge, onReportTypeSelected);
                              debugPrint('      → vcodesWidgets 개수: ${vcodesWidgets.length}');
                              
                              if (vcodesWidgets.isNotEmpty) {
                                renderedSectionCount++;
                                debugPrint('      ✅ Vcodes 섹션 렌더링됨 (총 섹션: $renderedSectionCount)');
                                return _buildSection(context, l10n.salesStatistics, vcodesWidgets, isLarge, onTap: () {
                                  onReportTypeSelected(ReportType.ventas);
                                });
                              } else {
                                debugPrint('      ⚠️ Vcodes 위젯이 비어있음');
                                return const SizedBox.shrink();
                              }
                            } catch (e) {
                              debugPrint('      ❌ Vcodes 섹션 생성 오류: $e');
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ],
                      
                      // 지출 통계 (gastos)와 할인 통계 (vdetalle) - 큰 화면에서는 1줄에 배치
                      Builder(
                        builder: (context) {
                          debugPrint('   🔍 [단일 Sucursal] Gastos/Vdetalle 섹션 생성 시작');
                          final isLarge = _isLargeScreen(context);
                          final hasGastos = data.containsKey('gastos');
                          final hasVdetalle = data.containsKey('vdetalle');
                          debugPrint('      → hasGastos: $hasGastos, hasVdetalle: $hasVdetalle');
                          
                          // vdetalle 데이터 상세 확인
                          if (hasVdetalle) {
                            final vdetalleRaw = data['vdetalle'];
                            debugPrint('      → vdetalle 원본 데이터 타입: ${vdetalleRaw.runtimeType}');
                            debugPrint('      → vdetalle 원본 데이터: $vdetalleRaw');
                            if (vdetalleRaw is Map) {
                              debugPrint('      → vdetalle Map 키: ${vdetalleRaw.keys.toList()}');
                            } else if (vdetalleRaw is List) {
                              debugPrint('      → vdetalle List 길이: ${vdetalleRaw.length}');
                              if (vdetalleRaw.isNotEmpty) {
                                debugPrint('      → vdetalle List 첫 번째 항목: ${vdetalleRaw[0]}');
                              }
                            }
                          } else {
                            debugPrint('      ⚠️ vdetalle 키가 data에 없음');
                            debugPrint('      → data의 모든 키: ${data.keys.toList()}');
                          }
                          
                          // 둘 다 없으면 빈 위젯 반환
                          if (!hasGastos && !hasVdetalle) {
                            debugPrint('      ⚠️ Gastos와 Vdetalle 모두 없음');
                            return const SizedBox.shrink();
                          }
                          
                          // 큰 화면: Row로 1줄에 배치
                          if (isLarge) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 지출 통계 (gastos)
                                if (hasGastos)
                                  Flexible(
                                    flex: 1,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(minWidth: 400),
                                      child: Builder(
                                        builder: (context) {
                                          debugPrint('      → Gastos 섹션 생성 중...');
                                          try {
                                            final aggregatedGastos = _getAggregatedGastos(data);
                                            debugPrint('         → aggregatedGastos: $aggregatedGastos');
                                            final gastosWidgets = _buildGastosSection(context, aggregatedGastos, serverUrl, selectedDate, isLarge, onReportTypeSelected);
                                            debugPrint('         → gastosWidgets 개수: ${gastosWidgets.length}');
                                            
                                            if (gastosWidgets.isNotEmpty) {
                                              renderedSectionCount++;
                                              debugPrint('         ✅ Gastos 섹션 렌더링됨 (총 섹션: $renderedSectionCount)');
                                              return _buildSection(context, l10n.expenseStatistics, gastosWidgets, isLarge);
                                            } else {
                                              debugPrint('         ⚠️ Gastos 위젯이 비어있음');
                                              return const SizedBox.shrink();
                                            }
                                          } catch (e) {
                                            debugPrint('         ❌ Gastos 섹션 생성 오류: $e');
                                            return const SizedBox.shrink();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                if (hasGastos && hasVdetalle)
                                  const SizedBox(width: 16),
                                // 할인 통계 (vdetalle)
                                if (hasVdetalle)
                                  Flexible(
                                    flex: 1,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(minWidth: 400),
                                      child: Builder(
                                        builder: (context) {
                                          debugPrint('═══════════════════════════════════════════════════════');
                                          debugPrint('      → Vdetalle 섹션 생성 중 (대형화면)...');
                                          debugPrint('      → data: ${data.keys.toList()}');
                                          try {
                                            final aggregatedVdetalle = _getAggregatedVdetalle(data);
                                            debugPrint('         → aggregatedVdetalle 반환값: $aggregatedVdetalle');
                                            debugPrint('         → aggregatedVdetalle.isEmpty: ${aggregatedVdetalle.isEmpty}');
                                            
                                            final vdetalleWidgets = _buildVdetalleSection(context, aggregatedVdetalle, isLarge, onReportTypeSelected);
                                            debugPrint('         → vdetalleWidgets 개수: ${vdetalleWidgets.length}');
                                            debugPrint('         → vdetalleWidgets.isEmpty: ${vdetalleWidgets.isEmpty}');
                                            
                                            if (vdetalleWidgets.isNotEmpty) {
                                              renderedSectionCount++;
                                              debugPrint('         ✅ Vdetalle 섹션 렌더링됨 (총 섹션: $renderedSectionCount)');
                                              final sectionWidget = _buildSection(context, l10n.discountStatistics, vdetalleWidgets, isLarge);
                                              debugPrint('         → sectionWidget 타입: ${sectionWidget.runtimeType}');
                                              debugPrint('═══════════════════════════════════════════════════════');
                                              return sectionWidget;
                                            } else {
                                              debugPrint('         ⚠️ Vdetalle 위젯이 비어있음 - SizedBox.shrink() 반환');
                                              debugPrint('═══════════════════════════════════════════════════════');
                                              return const SizedBox.shrink();
                                            }
                                          } catch (e, stackTrace) {
                                            debugPrint('         ❌ Vdetalle 섹션 생성 오류: $e');
                                            debugPrint('         → Stack trace: $stackTrace');
                                            debugPrint('═══════════════════════════════════════════════════════');
                                            return const SizedBox.shrink();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }
                          
                          // 작은 화면: 기존대로 세로로 배치
                          return Column(
                            children: [
                              // 지출 통계 (gastos)
                              if (hasGastos)
                                Builder(
                                  builder: (context) {
                                    debugPrint('      → Gastos 섹션 생성 중 (작은 화면)...');
                                    try {
                                      final aggregatedGastos = _getAggregatedGastos(data);
                                      debugPrint('         → aggregatedGastos: $aggregatedGastos');
                                      final gastosWidgets = _buildGastosSection(context, aggregatedGastos, serverUrl, selectedDate, isLarge, onReportTypeSelected);
                                      debugPrint('         → gastosWidgets 개수: ${gastosWidgets.length}');
                                      
                                      if (gastosWidgets.isNotEmpty) {
                                        renderedSectionCount++;
                                        debugPrint('         ✅ Gastos 섹션 렌더링됨 (총 섹션: $renderedSectionCount)');
                                        return _buildSection(context, l10n.expenseStatistics, gastosWidgets, isLarge);
                                      } else {
                                        debugPrint('         ⚠️ Gastos 위젯이 비어있음');
                                        return const SizedBox.shrink();
                                      }
                                    } catch (e) {
                                      debugPrint('         ❌ Gastos 섹션 생성 오류: $e');
                                      return const SizedBox.shrink();
                                    }
                                  },
                                ),
                              // 할인 통계 (vdetalle)
                              if (hasVdetalle)
                                Builder(
                                  builder: (context) {
                                    debugPrint('═══════════════════════════════════════════════════════');
                                    debugPrint('      → Vdetalle 섹션 생성 중 (작은 화면)...');
                                    debugPrint('      → data: ${data.keys.toList()}');
                                    try {
                                      final aggregatedVdetalle = _getAggregatedVdetalle(data);
                                      debugPrint('         → aggregatedVdetalle 반환값: $aggregatedVdetalle');
                                      debugPrint('         → aggregatedVdetalle.isEmpty: ${aggregatedVdetalle.isEmpty}');
                                      
                                      final vdetalleWidgets = _buildVdetalleSection(context, aggregatedVdetalle, isLarge, onReportTypeSelected);
                                      debugPrint('         → vdetalleWidgets 개수: ${vdetalleWidgets.length}');
                                      debugPrint('         → vdetalleWidgets.isEmpty: ${vdetalleWidgets.isEmpty}');
                                      
                                      if (vdetalleWidgets.isNotEmpty) {
                                        renderedSectionCount++;
                                        debugPrint('         ✅ Vdetalle 섹션 렌더링됨 (총 섹션: $renderedSectionCount)');
                                        final sectionWidget = _buildSection(context, l10n.discountStatistics, vdetalleWidgets, isLarge);
                                        debugPrint('         → sectionWidget 타입: ${sectionWidget.runtimeType}');
                                        debugPrint('═══════════════════════════════════════════════════════');
                                        return sectionWidget;
                                      } else {
                                        debugPrint('         ⚠️ Vdetalle 위젯이 비어있음 - SizedBox.shrink() 반환');
                                        debugPrint('═══════════════════════════════════════════════════════');
                                        return const SizedBox.shrink();
                                      }
                                    } catch (e, stackTrace) {
                                      debugPrint('         ❌ Vdetalle 섹션 생성 오류: $e');
                                      debugPrint('         → Stack trace: $stackTrace');
                                      debugPrint('═══════════════════════════════════════════════════════');
                                      return const SizedBox.shrink();
                                    }
                                  },
                                ),
                            ],
                          );
                        },
                      ),

                      // 결제 통계 (vcodes_mpago) - 여러 sucursal이 있으면 합산
                      if (data.containsKey('vcodes_mpago')) ...[
                        Builder(
                          builder: (context) {
                            debugPrint('   🔍 [단일 Sucursal] Mpago 섹션 생성 시작');
                            try {
                              final aggregatedMpago = _getAggregatedMpago(data);
                              debugPrint('      → aggregatedMpago: $aggregatedMpago');
                              final mpagoWidgets = _buildMpagoSection(context, aggregatedMpago, isLarge);
                              debugPrint('      → mpagoWidgets 개수: ${mpagoWidgets.length}');
                              
                              if (mpagoWidgets.isNotEmpty) {
                                renderedSectionCount++;
                                debugPrint('      ✅ Mpago 섹션 렌더링됨 (총 섹션: $renderedSectionCount)');
                                return _buildSection(context, l10n.mercadoPagoStatistics, mpagoWidgets, isLarge);
                              } else {
                                debugPrint('      ⚠️ Mpago 위젯이 비어있음');
                                return const SizedBox.shrink();
                              }
                            } catch (e) {
                              debugPrint('      ❌ Mpago 섹션 생성 오류: $e');
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ],

                      // Ingresos 통계 - 여러 sucursal이 있으면 합산
                      if (data.containsKey('ingresos')) ...[
                        Builder(
                          builder: (context) {
                            debugPrint('   🔍 [단일 Sucursal] Ingresos 섹션 생성 시작');
                            try {
                              final aggregatedIngresos = _getAggregatedIngresos(data);
                              debugPrint('      → aggregatedIngresos: $aggregatedIngresos');
                              final ingresosWidgets = _buildIngresosSection(context, aggregatedIngresos, serverUrl, selectedDate, isLarge, onReportTypeSelected);
                              debugPrint('      → ingresosWidgets 개수: ${ingresosWidgets.length}');
                              
                              if (ingresosWidgets.isNotEmpty) {
                                renderedSectionCount++;
                                debugPrint('      ✅ Ingresos 섹션 렌더링됨 (총 섹션: $renderedSectionCount)');
                                return _buildSection(context, 'Ingresos', ingresosWidgets, isLarge, onTap: () {
                                  onReportTypeSelected(ReportType.ingresos);
                                });
                              } else {
                                debugPrint('      ⚠️ Ingresos 위젯이 비어있음');
                                return const SizedBox.shrink();
                              }
                            } catch (e) {
                              debugPrint('      ❌ Ingresos 섹션 생성 오류: $e');
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ],

                      // FVentas 통계 - 여러 sucursal이 있으면 합산
                      if (data.containsKey('fventas')) ...[
                        Builder(
                          builder: (context) {
                            debugPrint('   🔍 [단일 Sucursal] FVentas 섹션 생성 시작');
                            try {
                              final aggregatedFventas = _getAggregatedFventas(data);
                              debugPrint('      → aggregatedFventas: $aggregatedFventas');
                              final fventasWidgets = _buildFventasSection(context, aggregatedFventas, serverUrl, selectedDate, isLarge, onReportTypeSelected);
                              debugPrint('      → fventasWidgets 개수: ${fventasWidgets.length}');
                              
                              if (fventasWidgets.isNotEmpty) {
                                renderedSectionCount++;
                                debugPrint('      ✅ FVentas 섹션 렌더링됨 (총 섹션: $renderedSectionCount)');
                                return _buildSection(context, 'FVentas del Día', fventasWidgets, isLarge);
                              } else {
                                debugPrint('      ⚠️ FVentas 위젯이 비어있음');
                                return const SizedBox.shrink();
                              }
                            } catch (e) {
                              debugPrint('      ❌ FVentas 섹션 생성 오류: $e');
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ],

                      // FVentas Mes 통계
                      if (data.containsKey('fventas_mes')) ...[
                        Builder(
                          builder: (context) {
                            debugPrint('   🔍 [단일 Sucursal] FVentas Mes 섹션 생성 시작');
                            try {
                              final aggregatedFventasMes = _getAggregatedFventasMes(data);
                              debugPrint('      → aggregatedFventasMes: $aggregatedFventasMes');
                              final fventasMesWidgets = _buildFventasMesSection(context, aggregatedFventasMes, isLarge);
                              debugPrint('      → fventasMesWidgets 개수: ${fventasMesWidgets.length}');
                              
                              if (fventasMesWidgets.isNotEmpty) {
                                renderedSectionCount++;
                                debugPrint('      ✅ FVentas Mes 섹션 렌더링됨 (총 섹션: $renderedSectionCount)');
                                return _buildSection(context, 'FVentas del Mes', fventasMesWidgets, isLarge);
                              } else {
                                debugPrint('      ⚠️ FVentas Mes 위젯이 비어있음');
                                return const SizedBox.shrink();
                              }
                            } catch (e) {
                              debugPrint('      ❌ FVentas Mes 섹션 생성 오류: $e');
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ],

                      // Stock Resumen (stock_resumen 또는 stocks 키 확인)
                      Builder(
                        builder: (context) {
                          debugPrint('   🔍 [단일 Sucursal] Stock Resumen 섹션 생성 시작');
                          try {
                            debugPrint('🔍 Stock 섹션 체크: stock_resumen=${data.containsKey('stock_resumen')}, stocks=${data.containsKey('stocks')}');
                            
                            // stock_resumen 또는 stocks 키 확인
                            final hasStockResumen = data.containsKey('stock_resumen') && data['stock_resumen'] != null;
                            final hasStocks = data.containsKey('stocks') && data['stocks'] != null;
                            
                            debugPrint('   - hasStockResumen: $hasStockResumen');
                            debugPrint('   - hasStocks: $hasStocks');
                            
                            if (!hasStockResumen && !hasStocks) {
                              debugPrint('   ⚠️ Stock 데이터 없음');
                              return const SizedBox.shrink();
                            }
                            
                            final stockData = hasStocks && data['stocks'] != null
                                  ? {'stocks': data['stocks']}
                                : (hasStockResumen && data['stock_resumen'] != null
                                    ? (data['stock_resumen'] is Map<String, dynamic>
                                        ? data['stock_resumen'] as Map<String, dynamic>
                                        : <String, dynamic>{})
                                      : <String, dynamic>{});
                            
                            debugPrint('   - stockData 키: ${stockData.keys.toList()}');
                              
                            final stockWidgets = _buildStockResumenSection(context, stockData, serverUrl, selectedDate, isLarge, onReportTypeSelected);
                            
                            debugPrint('   - stockWidgets 개수: ${stockWidgets.length}');
                              
                            if (stockWidgets.isNotEmpty) {
                              renderedSectionCount++;
                              debugPrint('   ✅ Stock Resumen 섹션 렌더링됨 (총 섹션: $renderedSectionCount)');
                              return _buildSection(context, 'Stock Resumen', stockWidgets, isLarge, useGrid: false, onTap: () {
                                onReportTypeSelected(ReportType.stocks);
                              });
                            } else {
                              debugPrint('   ⚠️ stockWidgets가 비어있음');
                              return const SizedBox.shrink();
                            }
                          } catch (e) {
                            debugPrint('   ❌ Stock Resumen 섹션 생성 오류: $e');
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
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

  Widget _buildSection(BuildContext context, String title, List<Widget> children, bool isLarge, {VoidCallback? onTap, bool useGrid = true}) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: (isLarge && useGrid)
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    const minCardWidth = 250.0;
                    final maxCrossAxisCount = (availableWidth / minCardWidth).floor();
                    final crossAxisCount = maxCrossAxisCount >= 4 ? 4 : (maxCrossAxisCount >= 3 ? 3 : 2);
                    
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.8,
                      children: children,
                    );
                  },
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
        ),
      ],
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: spacing),
                    Text(
                      _formatValue(value, isCurrency: isCurrency),
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: isCurrency ? Theme.of(context).colorScheme.primary : Colors.grey[800],
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  // ==================== 데이터 집계 함수들 ====================
  
  Map<String, dynamic> _getAggregatedVcodes(Map<String, dynamic> data) {
    if (!data.containsKey('vcodes')) {
      return <String, dynamic>{};
    }
    
    final vcodes = data['vcodes'];
    
    if (vcodes is! List || vcodes.isEmpty) {
      return vcodes is Map<String, dynamic> ? vcodes : <String, dynamic>{};
    }
    
    final aggregated = <String, dynamic>{
      'operation_count': 0,
      'total_venta_day': 0.0,
      'total_efectivo_day': 0.0,
      'total_credito_day': 0.0,
      'total_banco_day': 0.0,
      'total_favor_day': 0.0,
      'total_count_ropas': 0,
    };
    String? lastVentaHour;
    
    for (var item in vcodes) {
      if (item is Map<String, dynamic>) {
        aggregated['operation_count'] = (aggregated['operation_count'] as int) + 
            (item['operation_count'] as int? ?? 0);
        aggregated['total_venta_day'] = (aggregated['total_venta_day'] as double) + 
            ((item['total_venta_day'] as num?)?.toDouble() ?? 0.0);
        aggregated['total_efectivo_day'] = (aggregated['total_efectivo_day'] as double) + 
            ((item['total_efectivo_day'] as num?)?.toDouble() ?? 0.0);
        aggregated['total_credito_day'] = (aggregated['total_credito_day'] as double) + 
            ((item['total_credito_day'] as num?)?.toDouble() ?? 0.0);
        aggregated['total_banco_day'] = (aggregated['total_banco_day'] as double) + 
            ((item['total_banco_day'] as num?)?.toDouble() ?? 0.0);
        aggregated['total_favor_day'] = (aggregated['total_favor_day'] as double) + 
            ((item['total_favor_day'] as num?)?.toDouble() ?? 0.0);
        aggregated['total_count_ropas'] = (aggregated['total_count_ropas'] as int) + 
            (item['total_count_ropas'] as int? ?? 0);
        
        if (item['last_venta_hour'] != null) {
          final currentHour = item['last_venta_hour'].toString();
          if (lastVentaHour == null || currentHour.compareTo(lastVentaHour) > 0) {
            lastVentaHour = currentHour;
          }
        }
      }
    }
    
    if (lastVentaHour != null) {
      aggregated['last_venta_hour'] = lastVentaHour;
    }
    
    return aggregated;
  }
  
  Map<String, dynamic> _getAggregatedGastos(Map<String, dynamic> data) {
    if (!data.containsKey('gastos')) {
      debugPrint('🔍 _getAggregatedGastos: gastos 키가 없음');
      return <String, dynamic>{};
    }
    
    final gastos = data['gastos'];
    debugPrint('🔍 _getAggregatedGastos: gastos 타입=${gastos.runtimeType}, 값=$gastos');
    
    if (gastos is Map<String, dynamic>) {
      debugPrint('   → Map 형태로 반환');
      return gastos;
    }
    
    if (gastos is List) {
      if (gastos.isEmpty) {
        debugPrint('   → List가 비어있음');
        return <String, dynamic>{};
      }
      
      debugPrint('   → List 형태 (${gastos.length}개 항목), 합산 시작');
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
          
          debugPrint('     - 항목: gasto_count=$gastoCount, total_gasto_day=$totalGastoDay');
        }
      }
      
      debugPrint('   → 합산 결과: gasto_count=${aggregated['gasto_count']}, total_gasto_day=${aggregated['total_gasto_day']}');
      return aggregated;
    }
    
    debugPrint('   → 알 수 없는 형태, 빈 Map 반환');
    return <String, dynamic>{};
  }
  
  Map<String, dynamic> _getAggregatedVdetalle(Map<String, dynamic> data) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_getAggregatedVdetalle] 호출됨');
    debugPrint('   → data 키: ${data.keys.toList()}');
    debugPrint('   → data.containsKey(\'vdetalle\'): ${data.containsKey('vdetalle')}');
    
    if (!data.containsKey('vdetalle')) {
      debugPrint('   ⚠️ vdetalle 키가 없음 - 빈 Map 반환');
      debugPrint('═══════════════════════════════════════════════════════');
      return <String, dynamic>{};
    }
    
    final vdetalle = data['vdetalle'];
    debugPrint('   → vdetalle 타입: ${vdetalle.runtimeType}');
    debugPrint('   → vdetalle 값: $vdetalle');
    
    if (vdetalle is Map<String, dynamic>) {
      debugPrint('   → vdetalle이 Map이므로 그대로 반환');
      debugPrint('   → Map 키: ${vdetalle.keys.toList()}');
      debugPrint('   → Map 값: $vdetalle');
      debugPrint('═══════════════════════════════════════════════════════');
      return vdetalle;
    }
    
    if (vdetalle is! List || vdetalle.isEmpty) {
      debugPrint('   ⚠️ vdetalle이 List가 아니거나 비어있음 - 빈 Map 반환');
      debugPrint('═══════════════════════════════════════════════════════');
      return <String, dynamic>{};
    }
    
    final vdetalleList = vdetalle;
    debugPrint('   → vdetalle List 길이: ${vdetalleList.length}');
    
    final aggregated = <String, dynamic>{
      'count_discount_event': 0,
      'total_discount_day': 0.0,
    };
    
    int processedItems = 0;
    for (var item in vdetalleList) {
      debugPrint('      - vdetalle 항목 #$processedItems: ${item.runtimeType}');
      if (item is Map<String, dynamic>) {
        debugPrint('         → 항목 키: ${item.keys.toList()}');
        debugPrint('         → 항목 값: $item');
        
        final countDiscountEvent = item['count_discount_event'] as int? ?? 0;
        final totalDiscountDay = (item['total_discount_day'] as num?)?.toDouble() ?? 0.0;
        
        debugPrint('         → count_discount_event: $countDiscountEvent');
        debugPrint('         → total_discount_day: $totalDiscountDay');
        
        aggregated['count_discount_event'] = (aggregated['count_discount_event'] as int) + countDiscountEvent;
        aggregated['total_discount_day'] = (aggregated['total_discount_day'] as double) + totalDiscountDay;
        
        processedItems++;
      } else {
        debugPrint('         ⚠️ 항목이 Map이 아님 - 건너뜀');
      }
    }
    
    debugPrint('   ✅ 처리 완료: $processedItems개 항목 처리됨');
    debugPrint('   → 최종 aggregated: $aggregated');
    debugPrint('   → count_discount_event: ${aggregated['count_discount_event']}');
    debugPrint('   → total_discount_day: ${aggregated['total_discount_day']}');
    debugPrint('═══════════════════════════════════════════════════════');
    
    return aggregated;
  }
  
  Map<String, dynamic> _getAggregatedMpago(Map<String, dynamic> data) {
    if (!data.containsKey('vcodes_mpago')) {
      return <String, dynamic>{};
    }
    
    final mpago = data['vcodes_mpago'];
    if (mpago is! List || mpago.isEmpty) {
      return mpago is Map<String, dynamic> ? mpago : <String, dynamic>{};
    }
    
    final aggregated = <String, dynamic>{
      'count_mpago_total': 0,
      'total_mpago_day': 0.0,
    };
    
    for (var item in mpago) {
      if (item is Map<String, dynamic>) {
        aggregated['count_mpago_total'] = (aggregated['count_mpago_total'] as int) + 
            (item['count_mpago_total'] as int? ?? 0);
        aggregated['total_mpago_day'] = (aggregated['total_mpago_day'] as double) + 
            ((item['total_mpago_day'] as num?)?.toDouble() ?? 0.0);
      }
    }
    
    return aggregated;
  }
  
  Map<String, dynamic> _getAggregatedIngresos(Map<String, dynamic> data) {
    if (!data.containsKey('ingresos')) {
      return <String, dynamic>{};
    }
    
    final ingresos = data['ingresos'];
    if (ingresos is! List || ingresos.isEmpty) {
      return ingresos is Map<String, dynamic> ? ingresos : <String, dynamic>{};
    }
    
    final aggregated = <String, dynamic>{
      'ingreso_events': 0,
      'ingreso_total_ropas': 0,
    };
    
    for (var item in ingresos) {
      if (item is Map<String, dynamic>) {
        aggregated['ingreso_events'] = (aggregated['ingreso_events'] as int) + 
            (item['ingreso_events'] as int? ?? 0);
        aggregated['ingreso_total_ropas'] = (aggregated['ingreso_total_ropas'] as int) + 
            (item['ingreso_total_ropas'] as int? ?? 0);
      }
    }
    
    return aggregated;
  }

  Map<String, dynamic> _getAggregatedFventas(Map<String, dynamic> data) {
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
        
        int totalCount = 0;
        double totalSumMonto = 0.0;
        int notaCreditoCount = 0;
        double notaCreditoSumMonto = 0.0;
        
        const notaCreditoTypes = ['C', 'NCA', 'NCB', 'NCM'];
        
        for (var item in grouped.values) {
          final tipofactura = item['tipofactura']?.toString() ?? '';
          final count = item['count'] as int? ?? 0;
          final sumMonto = (item['sum_monto'] as num?)?.toDouble() ?? 0.0;
          
          if (notaCreditoTypes.contains(tipofactura)) {
            notaCreditoCount += count;
            notaCreditoSumMonto += sumMonto;
            debugPrint('   → Nota de Credito ($tipofactura) 발견: count=$count, sum_monto=$sumMonto');
          } else {
            totalCount += count;
            totalSumMonto += sumMonto;
          }
        }
        
        final finalCount = (totalCount - notaCreditoCount) < 0 ? 0 : (totalCount - notaCreditoCount);
        final finalSumMonto = (totalSumMonto - notaCreditoSumMonto) < 0.0 ? 0.0 : (totalSumMonto - notaCreditoSumMonto);
        
        debugPrint('   → FVentas 계산: totalCount=$totalCount, notaCreditoCount=$notaCreditoCount, 최종 count=$finalCount');
        debugPrint('   → FVentas 계산: totalSumMonto=$totalSumMonto, notaCreditoSumMonto=$notaCreditoSumMonto, 최종 sum_monto=$finalSumMonto');
        
        result['total_count'] = finalCount;
        result['total_sum_monto'] = finalSumMonto;
      }
    }
    
    return result;
  }

  Map<String, dynamic> _getAggregatedFventasMes(Map<String, dynamic> data) {
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

  // ==================== 섹션 빌드 함수들 ====================
  
  List<Widget> _buildVcodesSection(BuildContext context, Map<String, dynamic> vcodes, String serverUrl, DateTime? selectedDate, bool isLarge, Function(ReportType) onReportTypeSelected) {
    try {
      debugPrint('🔍 _buildVcodesSection 호출됨');
      debugPrint('   - vcodes 키: ${vcodes.keys.toList()}');
      final cards = <Widget>[];
      final configService = ConfigService();
      
      if (vcodes.isEmpty) {
        debugPrint('   ⚠️ vcodes가 비어있음');
        return cards;
      }
      
      if (vcodes.containsKey('operation_count')) {
        cards.add(_buildDataCard(
          context,
          'Evento de Venta',
          vcodes['operation_count'],
          Icons.shopping_cart,
          isLarge: isLarge,
          onTap: () => onReportTypeSelected(ReportType.ventas),
        ));
      }
      
      if (vcodes.containsKey('total_venta_day') && 
          configService.shouldShowResumenField('total_venta_day')) {
        cards.add(_buildDataCard(
          context,
          'Total de Ventas',
          vcodes['total_venta_day'],
          Icons.attach_money,
          isCurrency: true,
          isLarge: isLarge,
        ));
      }
      
      if (vcodes.containsKey('total_efectivo_day') && 
          configService.shouldShowResumenField('total_efectivo_day')) {
        cards.add(_buildDataCard(
          context,
          'Ventas en Efectivo',
          vcodes['total_efectivo_day'],
          Icons.money,
          isCurrency: true,
          isLarge: isLarge,
        ));
      }
      
      if (vcodes.containsKey('total_credito_day') && 
          configService.shouldShowResumenField('total_credito_day')) {
        cards.add(_buildDataCard(
          context,
          'Ventas a Crédito',
          vcodes['total_credito_day'],
          Icons.credit_card,
          isCurrency: true,
          isLarge: isLarge,
        ));
      }
      
      if (vcodes.containsKey('total_banco_day') && 
          configService.shouldShowResumenField('total_banco_day')) {
        cards.add(_buildDataCard(
          context,
          'Ventas Bancarias',
          vcodes['total_banco_day'],
          Icons.account_balance,
          isCurrency: true,
          isLarge: isLarge,
        ));
      }
      
      if (vcodes.containsKey('total_favor_day') && 
          configService.shouldShowResumenField('total_favor_day')) {
        cards.add(_buildDataCard(
          context,
          'Ventas Favor',
          vcodes['total_favor_day'],
          Icons.favorite,
          isCurrency: true,
          isLarge: isLarge,
        ));
      }
      
      if (vcodes.containsKey('total_count_ropas')) {
        cards.add(_buildDataCard(
          context,
          'Total de Ropas',
          vcodes['total_count_ropas'],
          Icons.checkroom,
          isLarge: isLarge,
        ));
      }
      
      if (vcodes.containsKey('last_venta_hour')) {
        final lastVentaHour = vcodes['last_venta_hour'];
        String formattedTime = '';
        if (lastVentaHour != null) {
          try {
            final valueStr = lastVentaHour.toString();
            if (valueStr.contains(':') && valueStr.split(':').length == 3 && !valueStr.contains('-')) {
              formattedTime = valueStr;
            } else {
              final dateTime = DateTime.parse(valueStr);
              formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
            }
          } catch (e) {
            formattedTime = lastVentaHour.toString();
          }
        }
        cards.add(_buildDataCard(
          context,
          'Última Venta',
          formattedTime,
          Icons.access_time,
          isLarge: isLarge,
        ));
      }

      debugPrint('   ✅ Vcodes 섹션 카드 생성 완료: ${cards.length}개');
      return cards;
    } catch (e) {
      debugPrint('❌ Error building Vcodes section: $e');
      return [];
    }
  }
  
  List<Widget> _buildGastosSection(BuildContext context, Map<String, dynamic> gastos, String serverUrl, DateTime? selectedDate, bool isLarge, Function(ReportType) onReportTypeSelected) {
    try {
      debugPrint('🔍 _buildGastosSection 호출: gastos=$gastos');
      final cards = <Widget>[];
      
      if (gastos.isEmpty) {
        debugPrint('   → gastos가 비어있음');
        return cards;
      }
      
      final gastoCount = gastos['gasto_count'] ?? gastos['count'];
      if (gastoCount != null && (gastoCount is int || gastoCount is num) && (gastoCount as num) > 0) {
        debugPrint('   → gasto_count 카드 추가: $gastoCount');
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
        debugPrint('   → total_gasto_day 카드 추가: $totalGastoDay');
        cards.add(_buildDataCard(
          context,
          'Total de Gastos',
          totalGastoDay,
          Icons.payments,
          isCurrency: true,
          isLarge: isLarge,
        ));
      }

      debugPrint('   → 총 ${cards.length}개 카드 생성');
      return cards;
    } catch (e) {
      debugPrint('❌ Error building Gastos section: $e');
      return [];
    }
  }
  
  List<Widget> _buildVdetalleSection(BuildContext context, Map<String, dynamic> vdetalle, bool isLarge, Function(ReportType) onReportTypeSelected) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_buildVdetalleSection] 호출됨');
    debugPrint('   → vdetalle: $vdetalle');
    debugPrint('   → vdetalle.isEmpty: ${vdetalle.isEmpty}');
    debugPrint('   → vdetalle.keys: ${vdetalle.keys.toList()}');
    debugPrint('   → isLarge: $isLarge');
    
    try {
      final cards = <Widget>[];
      
      if (vdetalle.isEmpty) {
        debugPrint('   ⚠️ vdetalle이 비어있음 - 빈 리스트 반환');
        debugPrint('═══════════════════════════════════════════════════════');
        return cards;
      }
      
      debugPrint('   → vdetalle.containsKey(\'count_discount_event\'): ${vdetalle.containsKey('count_discount_event')}');
      if (vdetalle.containsKey('count_discount_event')) {
        final countValue = vdetalle['count_discount_event'];
        debugPrint('      → count_discount_event 값: $countValue (타입: ${countValue.runtimeType})');
        
        // 값이 0이거나 null이 아닌 경우에만 카드 추가
        if (countValue != null && countValue != 0) {
          debugPrint('      ✅ count_discount_event 카드 추가');
          cards.add(_buildDataCard(
            context,
            'Eventos de Descuento',
            countValue,
            Icons.local_offer,
            isLarge: isLarge,
            onTap: () {
              debugPrint('🔍 [Descuento 카드 클릭] Eventos de Descuento 카드 클릭됨');
              debugPrint('   → onReportTypeSelected 호출: ReportType.ventas');
              onReportTypeSelected(ReportType.ventas);
            },
          ));
        } else {
          debugPrint('      ⚠️ count_discount_event가 null이거나 0임 - 카드 추가 안 함');
        }
      } else {
        debugPrint('      ⚠️ count_discount_event 키가 없음');
      }
      
      debugPrint('   → vdetalle.containsKey(\'total_discount_day\'): ${vdetalle.containsKey('total_discount_day')}');
      if (vdetalle.containsKey('total_discount_day')) {
        final totalValue = vdetalle['total_discount_day'];
        debugPrint('      → total_discount_day 값: $totalValue (타입: ${totalValue.runtimeType})');
        
        // 값이 0이거나 null이 아닌 경우에만 카드 추가
        if (totalValue != null && totalValue != 0.0 && totalValue != 0) {
          debugPrint('      ✅ total_discount_day 카드 추가');
          cards.add(_buildDataCard(
            context,
            'Total Descuento',
            totalValue,
            Icons.discount,
            isCurrency: true,
            isLarge: isLarge,
            onTap: () {
              debugPrint('🔍 [Descuento 카드 클릭] Total Descuento 카드 클릭됨');
              debugPrint('   → onReportTypeSelected 호출: ReportType.ventas');
              onReportTypeSelected(ReportType.ventas);
            },
          ));
        } else {
          debugPrint('      ⚠️ total_discount_day가 null이거나 0임 - 카드 추가 안 함');
        }
      } else {
        debugPrint('      ⚠️ total_discount_day 키가 없음');
      }

      debugPrint('   → 생성된 카드 개수: ${cards.length}');
      debugPrint('═══════════════════════════════════════════════════════');
      return cards;
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('❌ Error building Vdetalle section: $e');
      debugPrint('   → Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════');
      return [];
    }
  }
  
  List<Widget> _buildMpagoSection(BuildContext context, Map<String, dynamic> mpago, bool isLarge) {
    try {
      final cards = <Widget>[];
      
      if (mpago.isEmpty) {
        return cards;
      }
      
      if (mpago.containsKey('count_mpago_total')) {
        cards.add(_buildDataCard(
          context,
          'Evento de MPago',
          mpago['count_mpago_total'],
          Icons.payment,
          isLarge: isLarge,
        ));
      }
      
      if (mpago.containsKey('total_mpago_day')) {
        cards.add(_buildDataCard(
          context,
          'Total MPago',
          mpago['total_mpago_day'],
          Icons.account_balance_wallet,
          isCurrency: true,
          isLarge: isLarge,
        ));
      }

      return cards;
    } catch (e) {
      debugPrint('Error building Mpago section: $e');
      return [];
    }
  }
  
  List<Widget> _buildIngresosSection(BuildContext context, Map<String, dynamic> ingresos, String serverUrl, DateTime? selectedDate, bool isLarge, Function(ReportType) onReportTypeSelected) {
    try {
      final cards = <Widget>[];
      
      if (ingresos.isEmpty) {
        return cards;
      }
      
      if (ingresos.containsKey('ingreso_events')) {
        cards.add(_buildDataCard(
          context,
          'Eventos de Ingreso',
          ingresos['ingreso_events'],
          Icons.inventory,
          isLarge: isLarge,
          onTap: () => onReportTypeSelected(ReportType.ingresos),
        ));
      }
      
      if (ingresos.containsKey('ingreso_total_ropas')) {
        cards.add(_buildDataCard(
          context,
          'Total de Ropas Ingresadas',
          ingresos['ingreso_total_ropas'],
          Icons.checkroom,
          isLarge: isLarge,
        ));
      }

      return cards;
    } catch (e) {
      debugPrint('❌ Error building Ingresos section: $e');
      return [];
    }
  }
  
  List<Widget> _buildFventasSection(BuildContext context, Map<String, dynamic> fventas, String serverUrl, DateTime? selectedDate, bool isLarge, Function(ReportType) onReportTypeSelected) {
    try {
      final cards = <Widget>[];
      
      if (fventas.isEmpty) {
        return cards;
      }
      
      if (fventas.containsKey('items') && fventas['items'] is List) {
        final items = fventas['items'] as List;
        
        if (items.isNotEmpty) {
          // Factura A, B 합산
          int countAB = 0;
          double sumMontoAB = 0.0;
          
          // NCA, NCB 합산
          int countNC = 0;
          double sumMontoNC = 0.0;
          
          for (var item in items) {
            if (item is Map<String, dynamic>) {
              final tipofactura = item['tipofactura']?.toString() ?? 'Unknown';
              final count = item['count'] as int? ?? 0;
              final sumMonto = (item['sum_monto'] as num?)?.toDouble() ?? 0.0;
              
              if (tipofactura == 'A' || tipofactura == 'B') {
                countAB += count;
                sumMontoAB += sumMonto;
              } else if (tipofactura == 'NCA' || tipofactura == 'NCB') {
                countNC += count;
                sumMontoNC += sumMonto;
              }
            }
          }
          
          // Factura A, B 카드
          if (countAB > 0 || sumMontoAB > 0) {
            cards.add(
              InkWell(
                onTap: () => onReportTypeSelected(ReportType.fventas),
                child: Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.all(isLarge ? (12.0 * 2 * 2 / 3) : 12.0),
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
                                'Factura A, B',
                                style: TextStyle(
                                  fontSize: isLarge ? 18.0 : 15.0,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isLarge ? 12.0 : 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${_formatValue(countAB)} / ${_formatValue(sumMontoAB, isCurrency: true)}',
                              style: TextStyle(
                                fontSize: isLarge ? 15.0 : 13.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ),
                  ),
                ),
              ),
            );
          }
          
          // NCA, NCB 카드
          if (countNC > 0 || sumMontoNC > 0) {
            cards.add(
              InkWell(
                onTap: () => onReportTypeSelected(ReportType.fventas),
                child: Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.all(isLarge ? (12.0 * 2 * 2 / 3) : 12.0),
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long, 
                              color: Colors.orange, 
                              size: isLarge ? 24.0 : 20.0,
                            ),
                            SizedBox(width: isLarge ? 10.0 : 8.0),
                            Flexible(
                              child: Text(
                                'Nota de Crédito (NCA, NCB)',
                                style: TextStyle(
                                  fontSize: isLarge ? 18.0 : 15.0,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isLarge ? 12.0 : 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${_formatValue(countNC)} / ${_formatValue(sumMontoNC, isCurrency: true)}',
                              style: TextStyle(
                                fontSize: isLarge ? 15.0 : 13.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ),
                  ),
                ),
              ),
            );
          }
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
  
  List<Widget> _buildFventasMesSection(BuildContext context, Map<String, dynamic> fventasMes, bool isLarge) {
    try {
      final cards = <Widget>[];
      
      if (fventasMes.isEmpty) {
        return cards;
      }
      
      const double ivaRate = 0.173553719;
      
      if (fventasMes.containsKey('items') && fventasMes['items'] is List) {
        final items = fventasMes['items'] as List;
        
        double totalFacturaAB = 0.0;
        double totalNotaCredito = 0.0;
        
        for (var item in items) {
          if (item is Map<String, dynamic>) {
            final tipofactura = item['tipofactura']?.toString() ?? 'Unknown';
            final totalVentasMes = (item['total_ventas_mes'] as num?)?.toDouble() ?? 0.0;
            
            if (tipofactura == 'A' || tipofactura == 'B') {
              totalFacturaAB += totalVentasMes;
            } else if (tipofactura == 'C') {
              totalNotaCredito = totalVentasMes;
            }
            
            if (totalVentasMes > 0) {
              final ivaAmount = totalVentasMes * ivaRate;
              
              cards.add(
                InkWell(
                  onTap: () {
                    // 콜백을 통해 처리
                  },
                  child: Card(
                    color: Colors.blue.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'FVentas del Mes - Tipo $tipofactura',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _formatValue(totalVentasMes, isCurrency: true),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'IVA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                _formatValue(ivaAmount, isCurrency: true),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          }
        }
        
        final totalFacturaMes = totalFacturaAB - totalNotaCredito;
        if (totalFacturaMes > 0 || totalFacturaAB > 0) {
          final totalIvaAmount = totalFacturaMes * ivaRate;
          
          cards.add(
            InkWell(
              onTap: () {
                // 콜백을 통해 처리
              },
              child: Card(
                color: Colors.green.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Total Facturas del Mes',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _formatValue(totalFacturaMes, isCurrency: true),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'IVA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _formatValue(totalIvaAmount, isCurrency: true),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }

      return cards;
    } catch (e) {
      debugPrint('❌ Error building FventasMes section: $e');
      return [];
    }
  }
  
  List<Widget> _buildStockResumenSection(BuildContext context, Map<String, dynamic> stockData, String serverUrl, DateTime? selectedDate, bool isLarge, Function(ReportType) onReportTypeSelected) {
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
                      DataCell(Text(_formatValue(stock['tVentas'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['tIngresos'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['tOffset'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['hVentas'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['hIngresos'], isCurrency: true))),
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
}
