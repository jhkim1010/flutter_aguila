import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

    // 헤더와 Row의 크기를 추적하기 위한 GlobalKey
    final headerKey = GlobalKey();
    final firstRowKey = GlobalKey();
    
    return Builder(
      builder: (context) {
        // 렌더링 후 실제 크기 측정
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
              debugPrint('   → 예상 header width: ${needsHorizontalScroll ? totalWidth : screenWidth}');
            }
            if (rowBox != null) {
              debugPrint('   → First Row size: ${rowBox.size}');
              debugPrint('   → First Row width: ${rowBox.size.width}');
              debugPrint('   → 예상 row width: ${needsHorizontalScroll ? totalWidth : screenWidth}');
              debugPrint('   → Row width 차이: ${rowBox.size.width - (needsHorizontalScroll ? totalWidth : screenWidth)}');
            }
            debugPrint('═══════════════════════════════════════════════════════');
          } catch (e) {
            debugPrint('❌ [Stocks Builder] 렌더링 크기 측정 중 에러: $e');
          }
        });
        
        return LayoutBuilder(
          builder: (context, columnConstraints) {
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('📱 [Stocks Builder] 최상위 Column 빌드');
            debugPrint('   → Column constraints: ${columnConstraints.maxWidth} x ${columnConstraints.maxHeight}');
            debugPrint('   → isLoadingMore: $isLoadingMore');
            debugPrint('   → needsHorizontalScroll: $needsHorizontalScroll');
            debugPrint('═══════════════════════════════════════════════════════');
            
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
                      debugPrint('📱 [Stocks Builder] Expanded 빌드');
                      debugPrint('   → Expanded constraints: ${expandedConstraints.maxWidth} x ${expandedConstraints.maxHeight}');
                      
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
                                  key: headerKey,
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
                                    key: index == 0 ? firstRowKey : null,
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
                                    child: _buildStockRow(stock, reportColor, index == 0),
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
                                debugPrint('📱 [Stocks Builder] 일반 모드 (수평 스크롤 없음)');
                                debugPrint('   → LayoutBuilder constraints: ${constraints.maxWidth} x ${constraints.maxHeight}');
                                debugPrint('   → screenWidth: $screenWidth');
                                
                                return Column(
                      children: [
                        // 칼럼 헤더
                        SizedBox(
                          key: headerKey,
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
                                key: index == 0 ? firstRowKey : null,
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
                                child: _buildStockRow(stock, reportColor, index == 0),
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

  static Widget _buildStockRow(Map<String, dynamic> stock, Color reportColor, [bool isFirstRow = false]) {
    // 첫 번째 Row에만 디버깅 정보 출력
    final rowKey = isFirstRow ? GlobalKey() : null;
    
    if (isFirstRow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (rowKey?.currentContext != null) {
            final RenderBox? renderBox = rowKey!.currentContext!.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              debugPrint('═══════════════════════════════════════════════════════');
              debugPrint('📱 [Stocks Builder] 첫 번째 Row 렌더링 후 실제 크기');
              debugPrint('   → Row 실제 size: ${renderBox.size}');
              debugPrint('   → Row constraints: ${renderBox.constraints}');
              debugPrint('   → Row hasSize: ${renderBox.hasSize}');
              debugPrint('   → Row 타입: ${renderBox.runtimeType}');
              
              // Row의 실제 너비와 constraint 비교
              debugPrint('   → Row 실제 너비: ${renderBox.size.width}');
              debugPrint('   → Row constraint.maxWidth: ${renderBox.constraints.maxWidth}');
              
              if (renderBox.size.width > renderBox.constraints.maxWidth) {
                debugPrint('   ⚠️ 경고: Row가 constraint를 초과함!');
                debugPrint('   ⚠️ constraint.maxWidth: ${renderBox.constraints.maxWidth}');
                debugPrint('   ⚠️ 실제 width: ${renderBox.size.width}');
                debugPrint('   ⚠️ 초과량: ${renderBox.size.width - renderBox.constraints.maxWidth}px');
              } else {
                debugPrint('   ✅ Row가 constraint 내에 있음');
                debugPrint('   → 여유 공간: ${renderBox.constraints.maxWidth - renderBox.size.width}px');
              }
              debugPrint('═══════════════════════════════════════════════════════');
            }
          }
        } catch (e, stackTrace) {
          debugPrint('❌ [Stocks Builder] Row 크기 측정 중 에러: $e');
          debugPrint('   → StackTrace: $stackTrace');
        }
      });
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isFirstRow) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('📱 [Stocks Builder] 첫 번째 Row 빌드 시작');
          debugPrint('   → Row constraints: ${constraints.maxWidth} x ${constraints.maxHeight}');
          debugPrint('   → constraints.isTight: ${constraints.isTight}');
          debugPrint('   → constraints.isNormalized: ${constraints.isNormalized}');
          
          // 실제 칼럼 너비 계산
          final columnWidths = [120, 250, 90, 100, 110, 100, 120, 100, 100, 100, 100, 100, 90, 90, 90, 90, 90, 90, 100];
          final totalColumnWidth = columnWidths.fold(0.0, (sum, width) => sum + width);
          final spacingCount = columnWidths.length - 1; // 18개
          final totalSpacing = spacingCount * 8.0;
          final expectedRowWidth = totalColumnWidth + totalSpacing;
          
          debugPrint('   → 칼럼 개수: ${columnWidths.length}');
          debugPrint('   → 칼럼 너비 합계: $totalColumnWidth');
          debugPrint('   → 간격 개수: $spacingCount');
          debugPrint('   → 간격 합계: $totalSpacing');
          debugPrint('   → 예상 Row 너비 (padding 제외): $expectedRowWidth');
          debugPrint('   → Container padding: 32 (좌우 각 16)');
          debugPrint('   → 예상 총 너비 (padding 포함): ${expectedRowWidth + 32}');
          debugPrint('   → 실제 사용 가능 너비: ${constraints.maxWidth}');
          
          // Row의 실제 너비 계산
          final availableWidth = constraints.maxWidth; // Container padding은 이미 제외됨
          final widthDifference = expectedRowWidth - availableWidth;
          
          debugPrint('   → 예상 Row 너비: $expectedRowWidth');
          debugPrint('   → 사용 가능 너비: $availableWidth');
          debugPrint('   → 너비 차이: $widthDifference');
          
          if (widthDifference > 0) {
            debugPrint('   ⚠️ 경고: Row가 사용 가능한 너비보다 ${widthDifference}px 더 큼!');
            debugPrint('   ⚠️ 이로 인해 overflow가 발생할 수 있습니다.');
            debugPrint('   ⚠️ 해결 방법: Row를 SingleChildScrollView로 감싸거나 너비 조정 필요');
          } else if (widthDifference < -10) {
            debugPrint('   ℹ️ 정보: Row가 사용 가능한 너비보다 ${widthDifference.abs()}px 작음 (정상)');
          }
          debugPrint('═══════════════════════════════════════════════════════');
        }
        
        // Row가 constraint를 초과하지 않도록 처리
        // 수평 스크롤 모드에서는 이미 전체가 SingleChildScrollView 안에 있으므로
        // Row는 min size로 설정하고, 필요시 Flexible로 감싸서 overflow 방지
        return Row(
          key: rowKey,
          mainAxisSize: MainAxisSize.min, // min으로 설정하여 overflow 방지
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
        // Porcentaje (소수점 1자리)
        SizedBox(
          width: 100,
          child: Text(
            _formatPorcentaje(stock['porcentaje']),
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
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        debugPrint('📱 [Stocks Builder] Header 빌드');
        debugPrint('   → Header constraints: ${constraints.maxWidth} x ${constraints.maxHeight}');
        debugPrint('   → 예상 Header 너비: ${1940.0 + 144.0 + 32.0} (칼럼 너비 + 간격 + padding)');
        debugPrint('   → 실제 사용 가능 너비: ${constraints.maxWidth}');
        
        final expectedHeaderWidth = 1940.0 + 144.0 + 32.0; // 2116
        final availableWidth = constraints.maxWidth;
        final widthDifference = expectedHeaderWidth - availableWidth;
        
        // 실제 칼럼 너비 계산 (19개 칼럼)
        final actualColumnWidth = 120 + 250 + 90 + 100 + 110 + 100 + 120 + 100 + 100 + 100 + 100 + 100 + 90 + 90 + 90 + 90 + 90 + 90 + 100;
        final actualSpacing = 8 * 18; // 18개 간격
        final actualRowWidth = actualColumnWidth + actualSpacing; // 2084
        final actualTotalWidth = actualRowWidth + 32; // Container padding 포함
        
        debugPrint('   → 예상 Header 너비: $expectedHeaderWidth');
        debugPrint('   → 실제 칼럼 너비 합계: $actualColumnWidth');
        debugPrint('   → 실제 간격 합계: $actualSpacing');
        debugPrint('   → 실제 Row 너비 (padding 제외): $actualRowWidth');
        debugPrint('   → 실제 총 너비 (padding 포함): $actualTotalWidth');
        debugPrint('   → 사용 가능 너비: $availableWidth');
        debugPrint('   → 너비 차이: $widthDifference');
        
        if (widthDifference > 0) {
          debugPrint('   ⚠️ 경고: Header가 사용 가능한 너비보다 ${widthDifference}px 더 큼!');
          debugPrint('   ✅ 해결: Header Row를 SingleChildScrollView로 감싸서 overflow 방지');
        }
        
        // Header Container의 실제 크기 측정을 위한 GlobalKey
        final containerKey = GlobalKey();
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            if (containerKey.currentContext != null) {
              final RenderBox? renderBox = containerKey.currentContext!.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                debugPrint('═══════════════════════════════════════════════════════');
                debugPrint('📱 [Stocks Builder] Header Container 렌더링 후 실제 크기');
                debugPrint('   → Container 실제 size: ${renderBox.size}');
                debugPrint('   → Container constraints: ${renderBox.constraints}');
                debugPrint('   → Container padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)');
                
                // Padding을 제외한 내부 크기 계산
                final innerWidth = renderBox.size.width - 32; // 좌우 padding 16*2
                final innerHeight = renderBox.size.height - 24; // 상하 padding 12*2
                
                debugPrint('   → Container 내부 너비 (padding 제외): $innerWidth');
                debugPrint('   → Container 내부 높이 (padding 제외): $innerHeight');
                
                // Row의 예상 너비와 비교
                final expectedRowWidth = 1940.0 + 144.0; // 2084
                final rowWidthDifference = expectedRowWidth - innerWidth;
                
                debugPrint('   → 예상 Row 너비: $expectedRowWidth');
                debugPrint('   → Row 너비 차이: $rowWidthDifference');
                
                if (rowWidthDifference > 0) {
                  debugPrint('   ⚠️ 경고: Row가 Container 내부 너비보다 ${rowWidthDifference}px 더 큼!');
                }
                debugPrint('═══════════════════════════════════════════════════════');
              }
            }
          } catch (e, stackTrace) {
            debugPrint('❌ [Stocks Builder] Header Container 크기 측정 중 에러: $e');
            debugPrint('   → StackTrace: $stackTrace');
          }
        });
        
        return Container(
          key: containerKey,
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
          child: LayoutBuilder(
            builder: (context, innerConstraints) {
              // 대형 화면 여부 확인 (800px 이상)
              final isLargeScreen = innerConstraints.maxWidth > 800;
              final screenWidth = MediaQuery.of(context).size.width;
              final needsScroll = screenWidth < 800; // 작은 화면에서만 스크롤 필요
              
              debugPrint('📱 [Stocks Builder] Header 빌드 (내부)');
              debugPrint('   → innerConstraints: ${innerConstraints.maxWidth} x ${innerConstraints.maxHeight}');
              debugPrint('   → screenWidth: $screenWidth');
              debugPrint('   → isLargeScreen: $isLargeScreen');
              debugPrint('   → needsScroll: $needsScroll');
              
              // Row의 예상 너비와 비교
              final expectedRowWidth = 1940.0 + 144.0;
              final widthDifference = expectedRowWidth - innerConstraints.maxWidth;
              
              debugPrint('   → 예상 Row 너비: $expectedRowWidth');
              debugPrint('   → 사용 가능 너비: ${innerConstraints.maxWidth}');
              debugPrint('   → 너비 차이: $widthDifference');
              
              // 작은 화면에서만 SingleChildScrollView 사용
              if (needsScroll) {
                if (widthDifference > 0) {
                  debugPrint('   ✅ 작은 화면: Row가 SingleChildScrollView로 감싸져 있어 overflow 방지됨');
                }
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.hardEdge,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
              } else {
                // 대형 화면에서는 SingleChildScrollView 없이 일반 Row 사용
                debugPrint('   ✅ 대형 화면: 일반 Row 사용 (변경 없음)');
                return Row(
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
                );
              }
            },
          ),
        );
      },
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
          debugPrint('   ⚠️ 경고: selectedSucursal "$selectedSucursal"이 items에 ${foundCount}개 있음!');
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
                  for (var item in sucursales!) {
                    if (sucursales!.where((s) => s == item).length > 1) {
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
                        ...sucursales!.map((sucursal) {
                          return DropdownMenuItem<String?>(
                            value: sucursal,
                            child: Text(sucursal, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
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

