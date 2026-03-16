// Header row and total row builders extracted from ReportTableBuilder.
import 'package:flutter/material.dart';
import 'report_utils.dart';
import 'report_table_column_widths.dart';
import 'report_table_measured_columns.dart';
import 'report_table_builder.dart';

class ReportTableHeaderFooter {
  static Widget buildFixedTotalRow(List<String> keys, List<dynamic> displayedList, Color reportColor, {Map<String, double>? columnWidths, List<dynamic>? dataList, ReportType? reportType, double? explicitWidth, String? unit}) {
    // 디버깅: 함수 진입 확인 (가장 먼저 실행)
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_buildFixedTotalRow] 함수 진입');
    debugPrint('   → keys: $keys');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columnWidths 전달됨: ${columnWidths != null}');
    debugPrint('   → displayedList.length: ${displayedList.length}');
    debugPrint('   → dataList.length: ${dataList?.length ?? 0}');
    debugPrint('   → reportType: $reportType');
    
    // items/ingresos 보고서의 경우 전체 데이터(dataList)를 사용하여 합계 계산
    // 다른 보고서는 displayedList 사용 (페이지네이션된 경우)
    final listForTotal = ((reportType == ReportType.items || reportType == ReportType.ingresos) && dataList != null && dataList.isNotEmpty) 
        ? dataList 
        : displayedList;
    
    debugPrint('   → 합계 계산에 사용할 리스트 길이: ${listForTotal.length}');
    
    // fventas 보고서의 경우 factura A와 B 각각의 개수와 monto 합계만 계산
    Map<String, dynamic>? fventasSummary;
    if (reportType == ReportType.fventas) {
      int countA = 0;
      int countB = 0;
      double montoA = 0.0;
      double montoB = 0.0;
      
      for (var item in listForTotal) {
        if (item is Map<String, dynamic>) {
          final tipofactura = item['tipofactura']?.toString() ?? '';
          final monto = (item['monto'] as num?)?.toDouble() ?? 0.0;
          
          if (tipofactura == 'A') {
            countA++;
            montoA += monto;
          } else if (tipofactura == 'B') {
            countB++;
            montoB += monto;
          }
        }
      }
      
      fventasSummary = {
        'countA': countA,
        'countB': countB,
        'montoA': montoA,
        'montoB': montoB,
      };
      
      debugPrint('   → [FVentas] Factura A: $countA개, Monto: $montoA');
      debugPrint('   → [FVentas] Factura B: $countB개, Monto: $montoB');
    }
    
    // 각 칼럼별 합계 계산 (fventas가 아닌 경우에만)
    final totals = <String, num>{};
    
    if (reportType != ReportType.fventas) {
      for (var key in keys) {
        // 합계를 계산하지 않아야 하는 컬럼들
        final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode' || key == 'id';
        final isDateColumn = key == 'fecha' || key == 'month' || key == 'year' || key == 'hora';
        final isTextColumn = key == 'dni' || key == 'DNI' || key == 'clientenombre' || key == 'vendedor' || 
                            key == 'tipo' || key == 'nencargado' || key == 'casoesp' || key == 'resiva' || 
                            key == 'cretmp' || key == 'sucursal' || key == 'ntiqrepetir' || key == 'b_mercadopago' ||
                            key == 'd_num_caja' || key == 'd_num_terminal' || key == 'ProductName' || key == 'desc1' || 
                            key == 'descripcion' || key == 'CategoryCode' || key == 'CompanyCode'; // CategoryCode, CompanyCode 추가
        if (isCodigoColumn || isDateColumn || isTextColumn) continue; // 합계 계산 제외
        
        num sum = 0;
        for (var item in listForTotal) {
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
    }
    
    // 컬럼별 고정 너비 설정 (헤더와 일치) - 파라미터로 받은 columnWidths 사용, 없으면 기본값 사용
    // 넓은 화면에서 모든 칼럼이 보이도록 크기 조정
    final defaultColumnWidths = <String, double>{
      // Items 보고서 (codigo/codigo1, CategoryCode, CompanyCode 50% 더 넓게)
      'codigo1': 300,  // 200 * 1.5
      'desc1': 200,
      'ProductName': 400,  // ProductName 칼럼 너비 증가 (250 -> 400)
      'totalCantidad': 156,  // 120 * 1.3 (30% 넓게)
      'CategoryCode': 150,  // 100 * 1.5
      'CompanyCode': 150,  // 100 * 1.5
      'tprendas': 100,
      'timporte': 120,
      // Ingresos 보고서 (codigo 50% 더 넓게)
      'codigo': 180,  // 120 * 1.5
      'descripcion': 200,
      'tevent': 100,
      'tcant': 120,
      'tIngreso': 120,
      'tingreso': 120,
      'cntEvent': 100,
      'cntevent': 100,
    };
    
    var finalColumnWidths = columnWidths ?? defaultColumnWidths;
    
    // month 유닛인 경우 tefectivo, tcredito, tbanco 칼럼 너비를 30% 증가
    final isMonthUnitForFooter = unit == 'month';
    if (isMonthUnitForFooter && finalColumnWidths.containsKey('tefectivo')) {
      final baseTefectivo = finalColumnWidths['tefectivo'] ?? 306;
      final baseTcredito = finalColumnWidths['tcredito'] ?? 306;
      final baseTbanco = finalColumnWidths['tbanco'] ?? 306;
      
      // 30% 증가: 1.3배
      finalColumnWidths = Map<String, double>.from(finalColumnWidths);
      finalColumnWidths['tefectivo'] = (baseTefectivo * 1.3).roundToDouble();
      finalColumnWidths['tcredito'] = (baseTcredito * 1.3).roundToDouble();
      finalColumnWidths['tbanco'] = (baseTbanco * 1.3).roundToDouble();
      
      debugPrint('📊 [푸터] month 유닛: tefectivo, tcredito, tbanco 칼럼 너비 30% 증가');
      debugPrint('   → tefectivo: $baseTefectivo -> ${finalColumnWidths['tefectivo']}');
      debugPrint('   → tcredito: $baseTcredito -> ${finalColumnWidths['tcredito']}');
      debugPrint('   → tbanco: $baseTbanco -> ${finalColumnWidths['tbanco']}');
    }
    
    // 디버깅: 푸터 칼럼 너비 정보 출력 (항상 출력)
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📊 [푸터] _buildFixedTotalRow 칼럼 너비 정보');
    debugPrint('   → keys: $keys');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columnWidths 전달됨: ${columnWidths != null}');
    debugPrint('   → finalColumnWidths: $finalColumnWidths');
    final isAlertas = reportType == ReportType.alertas;
    final footerPadding = isAlertas ? 1 : 16; // alertas는 1, 다른 보고서는 16
    final footerColumnSpacing = isAlertas ? 1 : 8; // alertas는 1, 다른 보고서는 8
    
    // ventas day/month/year 유닛인지 확인 (푸터도 헤더/데이터 행과 동일한 칼럼 폭 계산)
    final isVentasDayMonthYear = reportType == ReportType.ventas && 
                                 unit != null && 
                                 unit != 'vcode';
    
    double footerCumulativeX = 0.0;
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final baseColumnWidth = finalColumnWidths[key] ?? 150.0;
      
      // 헤더와 동일한 칼럼 폭 계산 로직 적용
      final footerColumnWidth = isVentasDayMonthYear
          ? baseColumnWidth + 32.0  // DataCell padding (16px * 2) 추가
          : baseColumnWidth;
      
      debugPrint('   → [푸터] 칼럼 #$i: key="$key", baseWidth=$baseColumnWidth, footerWidth=$footerColumnWidth, x=$footerCumulativeX, padding=$footerPadding (alertas: $isAlertas, ventasDayMonthYear: $isVentasDayMonthYear)');
      footerCumulativeX += footerColumnWidth;
      if (i < keys.length - 1) {
        footerCumulativeX += footerColumnSpacing;
        debugPrint('      → columnSpacing($footerColumnSpacing) 추가 후 x=$footerCumulativeX');
      }
    }
    debugPrint('   → [푸터] 총 너비: $footerCumulativeX');
    
    // fventas의 경우 명시적 너비 사용, 다른 보고서는 double.infinity 사용
    final containerWidth = explicitWidth ?? double.infinity;
    
    return Container(
      width: containerWidth, // 명시적 너비가 있으면 사용, 없으면 전체 폭 차지
      decoration: BoxDecoration(
        color: reportColor.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: reportColor.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Builder(
        builder: (context) {
          // 푸터 렌더링 후 실제 크기 측정
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              debugPrint('═══════════════════════════════════════════════════════');
              debugPrint('🔍 [오버랩 디버깅] buildFixedTotalRow 실제 렌더링 크기');
              debugPrint('   → reportType: $reportType');
              debugPrint('   → 푸터 실제 width: ${renderBox.size.width}');
              debugPrint('   → 푸터 실제 height: ${renderBox.size.height}');
              debugPrint('   → 계산된 총 너비: $footerCumulativeX');
              
              // fventas의 경우 추가 디버깅
              if (reportType == ReportType.fventas) {
                debugPrint('   → [FVentas 푸터] 높이 확인: ${renderBox.size.height}');
                debugPrint('   → [FVentas 푸터] 예상 높이: 56.0 (1줄)');
                if (renderBox.size.height > 60) {
                  debugPrint('   ⚠️ [FVentas 푸터] 높이가 60px 이상입니다! 2줄로 표시되고 있을 가능성');
                }
                
                // RenderObject 트리 확인
                debugPrint('   → [FVentas 푸터] RenderBox 타입: ${renderBox.runtimeType}');
                debugPrint('   → [FVentas 푸터] RenderBox constraints: ${renderBox.constraints}');
              }
              
              final parentBox = renderBox.parent as RenderBox?;
              if (parentBox != null) {
                debugPrint('   → 부모 실제 width: ${parentBox.size.width}');
                final footerOverflow = renderBox.size.width - parentBox.size.width;
                if (footerOverflow > 0) {
                  debugPrint('   ⚠️ 푸터 오버랩: ${footerOverflow.toStringAsFixed(1)}px');
                } else {
                  debugPrint('   ✅ 푸터 오버랩 없음. 여유: ${(-footerOverflow).toStringAsFixed(1)}px');
                }
              }
              debugPrint('═══════════════════════════════════════════════════════');
            }
          });
          
          // Footer는 수평 스크롤 컨트롤러를 사용하지 않음 (전체가 하나의 스크롤로 동기화됨)
          
          // fventas 보고서의 경우 factura A와 B 각각의 개수와 monto 합계를 1줄로 표시
          if (reportType == ReportType.fventas && fventasSummary != null) {
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('🔍 [FVentas 푸터] 1줄 표시 시작');
            debugPrint('   → fventasSummary: $fventasSummary');
            debugPrint('   → keys: $keys');
            debugPrint('   → keys.length: ${keys.length}');
            
            // tipofactura와 monto 컬럼의 위치 찾기
            int tipofacturaIndex = keys.indexOf('tipofactura');
            int montoIndex = keys.indexOf('monto');
            
            debugPrint('   → tipofacturaIndex: $tipofacturaIndex');
            debugPrint('   → montoIndex: $montoIndex');
            
            if (tipofacturaIndex == -1) tipofacturaIndex = 0;
            if (montoIndex == -1) montoIndex = keys.length - 1;
            
            debugPrint('   → 조정 후 tipofacturaIndex: $tipofacturaIndex');
            debugPrint('   → 조정 후 montoIndex: $montoIndex');
            
            // Factura A와 B를 1줄로 표시
            final rowWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: keys.asMap().entries.map((entry) {
                  final index = entry.key;
                  final key = entry.value;
                  final columnWidth = finalColumnWidths[key] ?? 150.0;
                  
                debugPrint('   → [푸터 셀] index=$index, key=$key, width=$columnWidth');
                
                // tipofactura 컬럼에 Factura A와 B 정보를 모두 표시
                  if (index == tipofacturaIndex) {
                  final text = 'Factura A: ${fventasSummary!['countA']} | Factura B: ${fventasSummary!['countB']}';
                  debugPrint('   → [푸터 셀] tipofactura 컬럼 텍스트: "$text"');
                  debugPrint('   → [푸터 셀] tipofactura 컬럼 너비: $columnWidth');
                  
                    return SizedBox(
                      width: columnWidth,
                      child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        height: 56.0,
                        child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                // monto 컬럼에 Factura A와 B의 monto 합계를 모두 표시 (showTpago false면 ****)
                  else if (index == montoIndex) {
                  final montoAText = ReportUtils.formatValueForTotalRow(fventasSummary!['montoA'] as double, 'monto');
                  final montoBText = ReportUtils.formatValueForTotalRow(fventasSummary!['montoB'] as double, 'monto');
                  final text = '$montoAText | $montoBText';
                  debugPrint('   → [푸터 셀] monto 컬럼 텍스트: "$text"');
                  debugPrint('   → [푸터 셀] monto 컬럼 너비: $columnWidth');
                  
                    return SizedBox(
                      width: columnWidth,
                      child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        height: 56.0,
                        child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  // 다른 컬럼은 빈 칸
                  else {
                    return SizedBox(
                      width: columnWidth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        height: 56.0,
                        child: const SizedBox.shrink(),
                      ),
                    );
                  }
                }).toList(),
              );
            
            debugPrint('   → [FVentas 푸터] Row 위젯 생성 완료');
            debugPrint('   → [FVentas 푸터] Row children 개수: ${rowWidget.children.length}');
            debugPrint('═══════════════════════════════════════════════════════');
            
            return rowWidget;
          }
          
          // Alertas 보고서의 경우 총 로그 개수만 표시
          if (reportType == ReportType.alertas) {
            final totalLogCount = listForTotal.length;
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('🔍 [Alertas 푸터] 총 로그 개수 계산');
            debugPrint('   → listForTotal.length: ${listForTotal.length}');
            debugPrint('   → totalLogCount: $totalLogCount');
            debugPrint('   → keys: $keys');
            debugPrint('   → keys[0]: ${keys.isNotEmpty ? keys[0] : "없음"}');
            debugPrint('   → finalColumnWidths[keys[0]]: ${keys.isNotEmpty ? finalColumnWidths[keys[0]] : "없음"}');
            debugPrint('   → 표시할 텍스트: "Total: $totalLogCount"');
            debugPrint('═══════════════════════════════════════════════════════');
            
            // 첫 번째 칼럼 너비는 최소 150으로 설정하여 "Total: XX" 텍스트가 잘리지 않도록 함
            final actualFirstColumnWidth = keys.isNotEmpty 
                ? (finalColumnWidths[keys[0]] ?? 150.0)
                : 150.0;
            final firstColumnWidth = actualFirstColumnWidth < 150.0 ? 150.0 : actualFirstColumnWidth;
            debugPrint('🔍 [Alertas 푸터] 첫 번째 칼럼 너비: $firstColumnWidth (실제: $actualFirstColumnWidth)');
            
            final totalText = 'Total: $totalLogCount';
            debugPrint('🔍 [Alertas 푸터] 생성할 텍스트: "$totalText"');
            
            // 총 너비 계산 (오버플로우 방지)
            double totalFooterWidth = firstColumnWidth;
            for (int i = 1; i < keys.length; i++) {
              final columnWidth = finalColumnWidths[keys[i]] ?? 150.0;
              totalFooterWidth += columnWidth + 1; // columnSpacing (1) 고려
            }
            debugPrint('🔍 [Alertas 푸터] 계산된 총 너비: $totalFooterWidth, explicitWidth: $explicitWidth');
            
            return Container(
              width: explicitWidth ?? double.infinity,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                    // 첫 번째 칼럼에 총 로그 개수 표시 (최소 150 너비로 텍스트가 잘리지 않도록)
                    SizedBox(
                      width: firstColumnWidth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8), // padding을 1로 설정
                        height: 56.0,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            totalText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: reportColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible, // 텍스트가 잘리지 않도록 visible 사용
                          ),
                        ),
                      ),
                    ),
                    // 나머지 칼럼은 빈 칸
                    ...keys.skip(1).map((key) {
                      final columnWidth = finalColumnWidths[key] ?? 150.0;
                      debugPrint('🔍 [Alertas 푸터] 빈 칸 칼럼: $key, width: $columnWidth');
                      return SizedBox(
                        width: columnWidth + 1, // columnSpacing 고려
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8), // padding을 1로 설정
                          height: 56.0,
                          child: const SizedBox.shrink(),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }
          
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: keys.asMap().entries.expand((entry) {
            final index = entry.key;
            final key = entry.value;
            // 합계를 계산하지 않아야 하는 컬럼들
            final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode' || key == 'id';
            final isDateColumn = key == 'fecha' || key == 'month' || key == 'year' || key == 'hora';
            final isTextColumn = key == 'dni' || key == 'DNI' || key == 'clientenombre' || key == 'vendedor' || 
                                key == 'tipo' || key == 'nencargado' || key == 'casoesp' || key == 'resiva' || 
                                key == 'cretmp' || key == 'sucursal' || key == 'ntiqrepetir' || key == 'b_mercadopago' ||
                                key == 'd_num_caja' || key == 'd_num_terminal' || key == 'ProductName' || key == 'desc1' || 
                                key == 'descripcion' || key == 'CategoryCode' || key == 'CompanyCode'; // CategoryCode, CompanyCode 추가
            final baseColumnWidth = finalColumnWidths[key] ?? 150.0;
            
            // ventas day/month/year 유닛인지 확인 (푸터도 헤더/데이터 행과 동일한 칼럼 폭 계산)
            final isVentasDayMonthYear = reportType == ReportType.ventas && 
                                        unit != null && 
                                        unit != 'vcode';
            
            // 헤더와 동일한 칼럼 폭 계산 로직 적용
            // ventas day/month/year 유닛은 padding(32px)을 고려하여 푸터 너비 계산
            final footerColumnWidth = isVentasDayMonthYear
                ? baseColumnWidth + 32.0  // DataCell padding (16px * 2) 추가
                : baseColumnWidth;
            
            // 합계를 계산하지 않는 컬럼은 빈 칸으로 표시
            final isExcludedColumn = isCodigoColumn || isDateColumn || isTextColumn;
            final total = isExcludedColumn ? null : (totals.containsKey(key) ? totals[key] ?? 0 : null);
            
            // 첫 칼럼(codigo1 또는 codigo)에 총 개수 표시 (items/ingresos 보고서만)
            final isFirstColumn = index == 0;
            final shouldShowTotalCount = (reportType == ReportType.items || reportType == ReportType.ingresos) && 
                                        isFirstColumn && isCodigoColumn;
            final totalCount = shouldShowTotalCount ? listForTotal.length : null;
            
            // DataTable의 DataCell과 동일한 구조로 만들기
            // 헤더와 동일한 구조 사용: Container + padding
            // DataTable은 각 DataCell에 horizontal: 16 padding을 추가함
            // items/ingresos 보고서의 경우 행 높이가 32-37이므로 푸터도 동일한 높이로 맞춤
            final isNumericColumn = (key == 'tevent' || key == 'tcant' || key == 'tprendas' || key == 'timporte' || 
                                    key == 'tIngreso' || key == 'tingreso' || key == 'cntEvent' || key == 'cntevent' ||
                                    key == 'sucursal' || key == 'totalCantidad');
            
            final footerHeight = (reportType == ReportType.items || reportType == ReportType.ingresos) ? 37.0 : 56.0;
            final isVentas = reportType == ReportType.ventas;
            
            return [
              SizedBox(
                width: footerColumnWidth,  // 헤더와 동일한 칼럼 폭 사용
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 테이블 행 높이에 맞춰 vertical: 8로 조정 (32-37 높이)
                  height: footerHeight, // items/ingresos는 37, 다른 보고서는 56
                  child: shouldShowTotalCount && totalCount != null
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Total: $totalCount',
                            style: TextStyle(
                              fontSize: 14, // ventas 보고서도 14px로 통일
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : total != null
                          ? Align(
                              alignment: isNumericColumn ? Alignment.centerRight : Alignment.centerLeft, // 숫자 칼럼은 오른쪽 정렬 (showTpago false면 금액 칸 ****)
                              child: Text(
                                ReportUtils.formatValueForTotalRow(total, key),
                                style: TextStyle(
                                  fontSize: 14, // ventas 보고서도 14px로 통일
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ),
              // 마지막 칼럼이 아니면 columnSpacing 추가
              // ventas day/month/year 유닛의 경우 간격을 줄여서 더 많은 공간 확보
              if (index < keys.length - 1) ...[
                Builder(
                  builder: (context) {
                    final isVentasDayMonthYearForSpacing = reportType == ReportType.ventas && 
                                                           unit != null && 
                                                           unit != 'vcode';
                    final spacing = isVentasDayMonthYearForSpacing ? 4.0 : 8.0;
                    return SizedBox(width: spacing);
                  },
                ),
              ],
            ];
          }).toList(),
          );
        },
      ),
    );
  }

  // 헤더 행 빌드 (수평 스크롤 동기화용). onColumnResize가 있으면 items/ingresos에서 칼럼 사이에 리사이즈 핸들 표시
  static Widget buildHeaderRow(
    List<String> keys,
    List<DataColumn> columns,
    Color reportColor,
    String? sortColumn,
    bool sortAscending,
    Function(int columnIndex, bool ascending)? onSort, {
    Map<String, double>? columnWidths,
    ReportType? reportType,
    double? explicitWidth,
    String? unit,
    bool useMeasuredWidths = false,
    bool isLargeScreen = false,
    void Function(String columnKey, double newWidth)? onColumnResize,
  }) {
    // 디버깅: 함수 진입 확인 (가장 먼저 실행)
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [report_table_builder.dart:3941] buildHeaderRow 함수 진입');
    debugPrint('   → 라인: 3941');
    debugPrint('   → keys: $keys');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columns.length: ${columns.length}');
    debugPrint('   → columnWidths 전달됨: ${columnWidths != null}');
    if (columnWidths != null) {
      debugPrint('   → columnWidths 내용: $columnWidths');
      debugPrint('   → columnWidths 개수: ${columnWidths.length}');
      debugPrint('   → 각 키별 columnWidths 값:');
      for (final key in keys) {
        final width = columnWidths[key] ?? 
                     columnWidths[key.toLowerCase()] ??
                     (key.toLowerCase() == 'eventcount' ? columnWidths['eventCount'] : null) ??
                     (key.toLowerCase() == 'tvents' ? columnWidths['tVents'] : null) ??
                     (key.toLowerCase() == 'tventas' ? columnWidths['tVentas'] : null) ??
                     (key.toLowerCase() == 'tcntropas' ? columnWidths['tCntRopas'] : null);
        debugPrint('     → $key: $width');
      }
      debugPrint('   → ⚠️ [중요] 이 columnWidths가 데이터 행의 columnWidths와 동일한지 확인 필요');
    } else {
      debugPrint('   → ⚠️ [경고] columnWidths가 null! 기본값 사용됨');
    }
    debugPrint('   → reportType: $reportType');
    debugPrint('   → unit: $unit');
    debugPrint('   → sortColumn: $sortColumn');
    debugPrint('   → sortAscending: $sortAscending');
    debugPrint('   → onSort != null: ${onSort != null}');
    debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
    debugPrint('   → isLargeScreen: $isLargeScreen');
    
    // Items/Ingresos 보고서인지 확인
    final isItems = reportType == ReportType.items;
    final isIngresos = reportType == ReportType.ingresos;
    final isItemsOrIngresos = isItems || isIngresos;
    
    if (isItemsOrIngresos) {
      debugPrint('   → [Items/Ingresos 헤더] 별도 헤더 행 생성 중');
      debugPrint('   → [중복 확인] DataTable의 headingRowHeight가 0이어야 함');
      debugPrint('   → [정렬 확인] 각 칼럼의 onSort 콜백 상태:');
      
      for (int i = 0; i < columns.length; i++) {
        final column = columns[i];
        final key = i < keys.length ? keys[i] : 'unknown';
        final hasOnSort = column.onSort != null;
        final isSorted = sortColumn == key;
        debugPrint('      칼럼 #$i ($key):');
        debugPrint('         → onSort=${hasOnSort ? "있음 ✅" : "없음 ❌"}');
        debugPrint('         → isSorted=$isSorted');
        if (hasOnSort) {
          debugPrint('         → 정렬 아이콘 표시: ${isSorted ? "예 ✅" : "아니오"}');
        } else {
          debugPrint('         → ⚠️ 정렬 불가: column.onSort가 null');
        }
      }
    }
    
    // 컬럼별 고정 너비 설정 (DataTable과 일치) — single source of truth via kReportDefaultColumnWidths
    // month 유닛인 경우 tefectivo, tcredito, tbanco 칼럼 너비를 30% 증가
    final isMonthUnitForHeader = unit == 'month';
    final Map<String, double> defaultColumnWidths = isMonthUnitForHeader
        ? (Map.of(kReportDefaultColumnWidths)
          ..['tefectivo'] = (306 * 1.3).roundToDouble() // 306 * 1.3 = 398
          ..['tcredito'] = (306 * 1.3).roundToDouble()
          ..['tbanco'] = (306 * 1.3).roundToDouble())
        : kReportDefaultColumnWidths;
    if (isMonthUnitForHeader) {
      debugPrint('📊 [헤더] month 유닛: tefectivo, tcredito, tbanco 칼럼 너비 30% 증가 (306 -> 398)');
    }

    final finalColumnWidths = columnWidths ?? defaultColumnWidths;
    
    // 디버깅: 헤더 칼럼 너비 정보 출력 (항상 출력)
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📊 [헤더] _buildHeaderRow 칼럼 너비 정보');
    debugPrint('   → keys: $keys');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columns.length: ${columns.length}');
    debugPrint('   → columnWidths 전달됨: ${columnWidths != null}');
    debugPrint('   → finalColumnWidths: $finalColumnWidths');
    final isAlertas = reportType == ReportType.alertas;
    // ventas day/month/year 유닛의 경우 대형 화면에서 칼럼 간격을 줄여서 더 많은 공간 확보
    final isVentasDayMonthYearForSpacing = reportType == ReportType.ventas && 
                                          unit != null && 
                                          unit != 'vcode';
    // 대형 화면에서 헤더 칼럼 간격을 줄여서 더 많은 공간 활용
    final headerColumnSpacing = isAlertas 
        ? 1 
        : (isVentasDayMonthYearForSpacing ? (isLargeScreen ? 2 : 4) : 8); // alertas는 1, ventas day/month/year는 대형 화면에서 2px, 그 외는 4px 또는 8px
    final headerPadding = isAlertas ? 1 : 16; // alertas는 1, 다른 보고서는 16
    
    // ventas 보고서의 day/month/year 유닛인지 확인
    final isVentasDayMonthYear = reportType == ReportType.ventas && 
                                 unit != null && 
                                 unit != 'vcode';
    
    final isVentas = reportType == ReportType.ventas;
    double headerCumulativeX = 0.0;
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final baseColumnWidth = resolveColumnWidth(key, finalColumnWidths);

          final finalColumnWidth = headerCellWidth(
              baseColumnWidth,
              isAlertas: isAlertas,
              isVentas: isVentas,
              useMeasuredWidths: useMeasuredWidths,
          );
      
      debugPrint('   → [헤더] 칼럼 #$i: key="$key", baseWidth=$baseColumnWidth, finalWidth=$finalColumnWidth, x=$headerCumulativeX, padding=$headerPadding (alertas: $isAlertas, ventasDayMonthYear: $isVentasDayMonthYear)');
      headerCumulativeX += finalColumnWidth;
      if (i < keys.length - 1) {
        headerCumulativeX += headerColumnSpacing;
        debugPrint('      → columnSpacing($headerColumnSpacing) 추가 후 x=$headerCumulativeX');
      }
    }
    debugPrint('   → [헤더] 총 너비: $headerCumulativeX');
    
    // DataTable의 헤더와 동일한 스타일로 헤더 행 생성
    // DataTable의 columnSpacing(8)을 고려하여 각 컬럼에 동일한 간격 적용
    return Container(
      width: explicitWidth, // 명시적 너비가 있으면 사용, 없으면 null (자동 크기)
      padding: EdgeInsets.zero, // padding 제거하여 DataTable과 정확히 일치
      decoration: BoxDecoration(
        color: reportColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[400]!,
            width: 2,
          ),
        ),
      ),
      child: Builder(
        builder: (context) {
          // 헤더 렌더링 후 실제 크기 측정
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              debugPrint('═══════════════════════════════════════════════════════');
              debugPrint('🔍 [오버랩 디버깅] buildHeaderRow 실제 렌더링 크기');
              debugPrint('   → 헤더 실제 width: ${renderBox.size.width}');
              debugPrint('   → 헤더 실제 height: ${renderBox.size.height}');
              debugPrint('   → 계산된 총 너비: $headerCumulativeX');
              final parentBox = renderBox.parent as RenderBox?;
              if (parentBox != null) {
                debugPrint('   → 부모 실제 width: ${parentBox.size.width}');
                final headerOverflow = renderBox.size.width - parentBox.size.width;
                if (headerOverflow > 0) {
                  debugPrint('   ⚠️ 헤더 오버랩: ${headerOverflow.toStringAsFixed(1)}px');
                } else {
                  debugPrint('   ✅ 헤더 오버랩 없음. 여유: ${(-headerOverflow).toStringAsFixed(1)}px');
                }
              }
              debugPrint('═══════════════════════════════════════════════════════');
            }
          });
          
          // 헤더는 수평 스크롤 컨트롤러를 사용하지 않음 (전체가 하나의 스크롤로 동기화됨)
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: columns.asMap().entries.expand((entry) {
          final index = entry.key;
          final column = entry.value;
          final key = keys[index];
          final isSorted = sortColumn == key;
          
          // columnWidths에서 칼럼 너비 가져오기 (단일 헬퍼로 대소문자 구분 없이)
          final keyLower = key.toLowerCase();
          final baseColumnWidth = resolveColumnWidth(key, finalColumnWidths);

          // 헤더 SizedBox 너비: 공유 헬퍼로 계산
          final headerSizedBoxWidth = headerCellWidth(
            baseColumnWidth,
            isAlertas: isAlertas,
            isVentas: isVentas,
            useMeasuredWidths: useMeasuredWidths,
          );
          
          // 디버깅: 헤더 칼럼 너비 최종 계산 (숨김)
          // debugPrint('🔍 [report_table_builder.dart:4569] 헤더 칼럼 너비 최종 계산');
          // debugPrint('   → 라인: 4569');
          // debugPrint('   → key: $key');
          // debugPrint('   → baseColumnWidth: $baseColumnWidth');
          // debugPrint('   → finalColumnWidth: $finalColumnWidth');
          // debugPrint('   → headerSizedBoxWidth: $headerSizedBoxWidth');
          // debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
          // debugPrint('   → isVentas: $isVentas');
          // debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
          // if (isVentas) {
          //   debugPrint('   → ⚠️ [매칭 확인] 데이터 행의 SizedBox 너비는 $baseColumnWidth이어야 함 (DataCell padding 32px 자동 추가)');
          //   debugPrint('   → ⚠️ [매칭 확인] 헤더의 headerSizedBoxWidth ($headerSizedBoxWidth) = 데이터 행의 실제 칼럼 너비 ($baseColumnWidth + 32 = ${baseColumnWidth + 32.0})');
          // }
          // print('🔍 [report_table_builder.dart:4569] 헤더 칼럼 너비 최종 계산');
          // print('   → 라인: 4569');
          // print('   → key: $key');
          // print('   → baseColumnWidth: $baseColumnWidth');
          // print('   → headerSizedBoxWidth: $headerSizedBoxWidth');
          // print('   → useMeasuredWidths: $useMeasuredWidths');
          // print('   → ⚠️ 데이터 행의 SizedBox 너비는 $baseColumnWidth이어야 함');
          
          // debugPrint('   → [헤더] headerSizedBoxWidth 계산: useMeasuredWidths=$useMeasuredWidths, baseColumnWidth=$baseColumnWidth, headerSizedBoxWidth=$headerSizedBoxWidth');
          
          // debugPrint('   → [헤더] 칼럼 #$index ($key): baseColumnWidth=$baseColumnWidth, finalColumnWidth=$finalColumnWidth, headerSizedBoxWidth=$headerSizedBoxWidth');
          
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [buildHeaderRow:4214] 헤더 칼럼 너비 설정');
          debugPrint('   → 라인: 4214');
          debugPrint('   → reportType: $reportType');
          debugPrint('   → unit: $unit');
          debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
          debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
          debugPrint('   → key: $key');
          debugPrint('   → keyLower: $keyLower');
          debugPrint('   → baseColumnWidth: $baseColumnWidth (columnWidths에서 가져온 값)');
          debugPrint('   → headerSizedBoxWidth: $headerSizedBoxWidth (useMeasuredWidths에 따라 계산된 값, 헤더 SizedBox 너비)');
          debugPrint('   → headerColumnSpacing: $headerColumnSpacing');
          debugPrint('   → finalColumnWidths[$key]: ${finalColumnWidths[key]}');
          debugPrint('   → finalColumnWidths[$keyLower]: ${finalColumnWidths[keyLower]}');
          debugPrint('   → ⚠️ [중요] useMeasuredWidths=$useMeasuredWidths이므로 ${useMeasuredWidths ? "전체 너비 그대로 사용 (baseColumnWidth=$baseColumnWidth)" : "padding 추가 (baseColumnWidth + 32.0 = ${baseColumnWidth + 32.0})"}');
          debugPrint('   → ⚠️ [매칭 확인] 데이터 행의 finalCellWidth와 일치해야 함');
          debugPrint('   → ⚠️ [매칭 확인] 데이터 행의 실제 칼럼 너비 (finalCellWidth + 32.0) = headerSizedBoxWidth와 일치해야 함');
          debugPrint('═══════════════════════════════════════════════════════');
          print('🔍 [buildHeaderRow:4214] 헤더 칼럼 너비 설정');
          print('   → 라인: 4214');
          print('   → key: $key');
          print('   → baseColumnWidth: $baseColumnWidth');
          print('   → headerSizedBoxWidth: $headerSizedBoxWidth');
          print('   → useMeasuredWidths: $useMeasuredWidths');
          
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
          
          // 고정 너비로 설정하여 DataTable과 정확히 일치
          // DataTable의 columnSpacing(8)을 각 칼럼 사이에 추가
          final isNumericHeader = (key == 'tevent' || key == 'tcant' || key == 'tprendas' || key == 'timporte' || 
                                   key == 'tIngreso' || key == 'tingreso' || key == 'cntEvent' || key == 'cntevent' ||
                                   key == 'sucursal' ||
                                   keyLower == 'eventcount' || keyLower == 'tvents' || keyLower == 'tventas' ||
                                   keyLower == 'tcntropas' || keyLower == 'tefectivo' || keyLower == 'tcredito' ||
                                   keyLower == 'tbanco' || keyLower == 'treservado' || keyLower == 'tfavor' ||
                                   keyLower == 'nencargado');
          
          // column.onSort가 있으면 사용하고, 없으면 onSort 파라미터를 사용 (fallback)
          final effectiveOnSort = column.onSort ?? onSort;
          final canSort = effectiveOnSort != null;
          
          // 헤더 칼럼 위치 계산 (디버깅용)
          double headerColumnX = 0.0;
          for (int j = 0; j < index; j++) {
            final prevKey = keys[j];
            final prevBaseColumnWidth = resolveColumnWidth(prevKey, finalColumnWidths);
            final prevFinalColumnWidth = headerCellWidth(
              prevBaseColumnWidth,
              isAlertas: isAlertas,
              isVentas: isVentas,
              useMeasuredWidths: useMeasuredWidths,
            );
            headerColumnX += prevFinalColumnWidth;
            if (j < index - 1) {
              headerColumnX += headerColumnSpacing;
            }
          }
          
          // 디버깅: 헤더 칼럼 위치와 너비 측정 (라인 번호 포함)
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [report_table_builder.dart:4545] 헤더 칼럼 위치 및 너비 측정');
          debugPrint('   → 라인: 4545');
          debugPrint('   → 칼럼 #$index ($key)');
          debugPrint('   → headerColumnX (계산된 x 위치): $headerColumnX');
          debugPrint('   → headerSizedBoxWidth: $headerSizedBoxWidth');
          debugPrint('   → baseColumnWidth: $baseColumnWidth');
          debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
          debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
          print('🔍 [report_table_builder.dart:4545] 헤더 칼럼 위치 및 너비 측정');
          print('   → 라인: 4545');
          print('   → 칼럼 #$index ($key)');
          print('   → headerColumnX: $headerColumnX');
          print('   → headerSizedBoxWidth: $headerSizedBoxWidth');
          
          // useMeasuredWidths가 true인 경우, 측정된 칼럼 너비는 DataTable의 실제 칼럼 너비(전체 너비)입니다.
          // 헤더의 SizedBox 너비는 측정값 전체를 사용해야 합니다.
          return [
            Builder(
              builder: (context) {
                // items/ingresos 칼럼 정렬 디버깅: 헤더 셀 실제 렌더 위치·너비 (최대 5칼럼, 테이블당 1회)
                if (isItemsOrIngresos && index < 5) {
                  final idx = index;
                  final k = key;
                  final expectedX = headerColumnX;
                  final expectedW = headerSizedBoxWidth;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (ReportTableBuilder.alignmentHeaderLoggedCount >= 5) return;
                    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox != null && context.mounted) {
                      final actualX = renderBox.localToGlobal(Offset.zero).dx;
                      final actualW = renderBox.size.width;
                      final contentLeft = actualX + 16.0;
                      final contentWidth = actualW - 32.0;
                      ReportTableBuilder.alignmentHeaderDebugList.add({
                        'key': k,
                        'cellLeft': actualX,
                        'cellWidth': actualW,
                        'contentLeft': contentLeft,
                        'contentWidth': contentWidth,
                      });
                      debugPrint('📐 [정렬디버그:헤더] report_table_builder.dart 칼럼#$idx ($k) expectedX=$expectedX expectedW=$expectedW actualX=${actualX.toStringAsFixed(1)} actualW=${actualW.toStringAsFixed(1)} diffX=${(actualX - expectedX).toStringAsFixed(1)} diffW=${(actualW - expectedW).toStringAsFixed(1)}');
                      print('📐 [정렬디버그:헤더] $k expectedX=$expectedX expectedW=$expectedW actualX=$actualX actualW=$actualW contentLeft=$contentLeft contentWidth=$contentWidth');
                      ReportTableBuilder.alignmentHeaderLoggedCount++;
                    }
                  });
                }
                
                // 디버깅: 헤더 칼럼에 수직선 추가 (라인 번호 포함)
                // 수직선은 칼럼 너비에 포함되지 않도록 별도로 추가
                debugPrint('🔍 [report_table_builder.dart:4710] 헤더 칼럼 수직선 추가');
                debugPrint('   → 라인: 4710');
                debugPrint('   → 칼럼 #$index ($key)');
                debugPrint('   → headerSizedBoxWidth: $headerSizedBoxWidth');
                debugPrint('   → headerColumnSpacing: $headerColumnSpacing');
                print('🔍 [report_table_builder.dart:4710] 헤더 칼럼 수직선 추가');
                print('   → 라인: 4710');
                print('   → 칼럼 #$index ($key)');
                print('   → headerSizedBoxWidth: $headerSizedBoxWidth');
                
                return Stack(
                  children: [
                    SizedBox(
                      width: headerSizedBoxWidth,
                      child: InkWell(
                    onTap: canSort
                    ? () {
                        debugPrint('═══════════════════════════════════════════════════════');
                        debugPrint('🔍 [buildHeaderRow] 헤더 칼럼 클릭 이벤트');
                        debugPrint('   → 칼럼 #$index ($key)');
                        debugPrint('   → column.onSort != null: ${column.onSort != null}');
                        debugPrint('   → onSort 파라미터 != null: ${onSort != null}');
                        debugPrint('   → effectiveOnSort != null: $canSort');
                        debugPrint('   → 현재 isSorted: $isSorted');
                        debugPrint('   → 현재 sortAscending: $sortAscending');
                        
                        if (canSort) {
                          final newAscending = isSorted ? !sortAscending : false;
                          debugPrint('   → 새 정렬 방향: $newAscending (${isSorted ? "토글" : "첫 클릭"})');
                          debugPrint('   → effectiveOnSort($index, $newAscending) 호출');
                          effectiveOnSort!(index, newAscending);
                          debugPrint('   ✅ onSort 호출 완료');
                        } else {
                          debugPrint('   ⚠️ effectiveOnSort가 null이므로 정렬 불가');
                        }
                        debugPrint('═══════════════════════════════════════════════════════');
                      }
                    : () {
                        debugPrint('═══════════════════════════════════════════════════════');
                        debugPrint('⚠️ [buildHeaderRow] 헤더 칼럼 클릭 - 정렬 불가');
                        debugPrint('   → 칼럼 #$index ($key)');
                        debugPrint('   → column.onSort == null: ${column.onSort == null}');
                        debugPrint('   → onSort 파라미터 == null: ${onSort == null}');
                        debugPrint('   → effectiveOnSort == null: 정렬 기능 없음');
                        debugPrint('═══════════════════════════════════════════════════════');
                      },
                    child: Container(
                      // DataCell과 동일한 구조: Container는 padding 없음, 내부 Padding이 16px 양쪽
                      padding: EdgeInsets.zero,
                      height: (reportType == ReportType.items || reportType == ReportType.ingresos) ? 37 : 56, // items/ingresos는 37, 다른 보고서는 56
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isAlertas ? 1 : 16, vertical: 8), // alertas는 1, 다른 보고서는 16 (DataCell과 동일)
                        child: Align(
                          alignment: isNumericHeader ? Alignment.centerRight : Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: isNumericHeader ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  labelText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14, // ventas 보고서도 14px로 통일
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: isNumericHeader ? TextAlign.right : TextAlign.left,
                                ),
                              ),
                              if (isSorted && canSort)
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
                      ),
                    ),
                    ),
                    // ventas/fventas 보고서가 아닐 때만 수직선 표시 (ventas·fventas는 수직선 숨김)
                    if (reportType != ReportType.ventas && reportType != ReportType.fventas && index < columns.length - 1)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 1.0,
                          color: Colors.red.withOpacity(0.5),  // 디버깅용 빨간색 수직선
                        ),
                      ),
                  ],
                );
              },
            ),
            // Items/Ingresos에서 칼럼 리사이즈 사용 시: 칼럼 사이에 리사이즈 핸들 표시
            if (onColumnResize != null && isItemsOrIngresos && index < columns.length - 1)
              ReportTableResizeHandle(
                key: ValueKey('rt_resize_$key'),
                columnKey: key,
                currentWidth: baseColumnWidth,
                onResize: (double w) => onColumnResize!(key, w.clamp(50.0, 2000.0)),
              ),
            if (index < columns.length - 1) SizedBox(width: headerColumnSpacing.toDouble()),
          ];
        }).toList(),
          );
        },
      ),
    );
  }

  // 합계 행 빌드
  static DataRow buildTotalRow(List<String> keys, List<dynamic> dataList, Color reportColor, {ReportType? reportType}) {
    // 각 칼럼별 합계 계산
    final totals = <String, num>{};
    
    for (var key in keys) {
      // 합계를 계산하지 않아야 하는 컬럼들
      final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode' || key == 'id';
      final isDateColumn = key == 'fecha' || key == 'month' || key == 'year' || key == 'hora';
      final isTextColumn = key == 'dni' || key == 'DNI' || key == 'clientenombre' || key == 'vendedor' || 
                          key == 'tipo' || key == 'nencargado' || key == 'casoesp' || key == 'resiva' || 
                          key == 'cretmp' || key == 'sucursal' || key == 'ntiqrepetir' || key == 'b_mercadopago' ||
                          key == 'd_num_caja' || key == 'd_num_terminal' || key == 'ProductName' || key == 'desc1' || 
                          key == 'descripcion';
      if (isCodigoColumn || isDateColumn || isTextColumn) continue; // 합계 계산 제외
      
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
    
    final isVentas = reportType == ReportType.ventas;
    
    return DataRow(
      color: MaterialStateProperty.all(reportColor.withOpacity(0.1)),
      cells: keys.map((key) {
        // 합계를 계산하지 않아야 하는 컬럼들
        final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode' || key == 'id';
        final isDateColumn = key == 'fecha' || key == 'month' || key == 'year' || key == 'hora';
        final isTextColumn = key == 'dni' || key == 'DNI' || key == 'clientenombre' || key == 'vendedor' || 
                            key == 'tipo' || key == 'nencargado' || key == 'casoesp' || key == 'resiva' || 
                            key == 'cretmp' || key == 'sucursal' || key == 'ntiqrepetir' || key == 'b_mercadopago' ||
                            key == 'd_num_caja' || key == 'd_num_terminal';
        
        // 합계를 계산하지 않는 컬럼은 빈 칸으로 표시
        if (isCodigoColumn || isDateColumn || isTextColumn) {
          return const DataCell(Text(''));
        }
        
        // 합계가 계산된 컬럼만 합계 값 표시 (showTpago false면 금액 칸 ****)
        if (totals.containsKey(key)) {
          final total = totals[key] ?? 0;
          return DataCell(
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                ReportUtils.formatValueForTotalRow(total, key),
                style: TextStyle(
                  fontSize: 14, // ventas 보고서도 14px로 통일
                  fontWeight: FontWeight.bold,
                  height: isVentas ? 1.0 : 1.2,
                ),
              ),
            ),
          );
        }
        
        // 합계가 계산되지 않은 컬럼도 빈 칸으로 표시
        return const DataCell(Text(''));
      }).toList(),
    );
  }

  // Map 형태 테이블용 합계 행 빌드
  static DataRow buildTotalRowForMapTable(Map<String, dynamic> data, Color reportColor) {
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
            ReportUtils.formatValueForTotalRow(total, key),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
}
