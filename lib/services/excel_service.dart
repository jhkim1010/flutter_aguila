import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/report_utils.dart';
import '../utils/web_compat/web_file_saver.dart';

class ExcelService {
  /// 필드 이름이 code 관련인지 확인 (code로 끝나거나 code를 포함)
  static bool _isCodeField(String fieldName) {
    final lowerName = fieldName.toLowerCase();
    return lowerName.contains('code') || lowerName.endsWith('code');
  }
  
  /// 셀 값 설정 (code 필드는 항상 문자열로 처리)
  static void _setCellValue(dynamic cell, String fieldName, dynamic value) {
    // code 필드는 항상 문자열로 처리
    if (_isCodeField(fieldName)) {
      cell.value = TextCellValue(value?.toString() ?? '');
      return;
    }
    
    // 일반 필드는 숫자 형식 처리
    if (value != null) {
      if (value is num) {
        cell.value = DoubleCellValue(value.toDouble());
      } else if (value is String) {
        // 숫자 문자열인지 확인
        final numValue = num.tryParse(value);
        if (numValue != null) {
          cell.value = DoubleCellValue(numValue.toDouble());
        } else {
          cell.value = TextCellValue(value);
        }
      } else {
        cell.value = TextCellValue(value.toString());
      }
    } else {
      cell.value = TextCellValue('');
    }
  }
  
  /// 보고서 데이터를 Excel로 변환하여 파일로 저장
  static Future<File> generateReportExcel({
    required ReportType reportType,
    required Map<String, dynamic>? data,
    DateTime? startDate,
    DateTime? endDate,
    String? filteringWord,
    List<String>? displayedColumns, // 화면에 표시되는 컬럼 목록
  }) async {
    final excel = Excel.createExcel();
    final reportTitle = ReportUtils.getReportTitle(reportType);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final now = DateTime.now();
    
    // 기본 Sheet1 삭제 (시트가 존재하는 경우에만)
    // Excel.createExcel()은 기본적으로 'Sheet1'을 생성하므로 먼저 삭제
    try {
      if (excel.sheets.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
        print('✅ Sheet1 삭제 완료');
      }
    } catch (e) {
      print('⚠️ Sheet1 삭제 중 오류 (무시): $e');
    }
    
    // 보고서 제목으로 새 시트 생성
    final sheet = excel[reportTitle];
    print('✅ 시트 생성 완료: $reportTitle, 전체 시트: ${excel.sheets.keys.toList()}');
    
    int currentRow = 0;
    
    // 헤더 행: 보고서 제목과 날짜
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .value = TextCellValue(reportTitle);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
    );
    currentRow++;
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .value = TextCellValue('Generado: ${dateFormat.format(now)}');
    currentRow++;
    currentRow++; // 빈 줄
    
    // 필터 정보
    if (startDate != null || endDate != null || filteringWord != null) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = TextCellValue('Filtros aplicados:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .cellStyle = CellStyle(bold: true);
      currentRow++;
      
      if (startDate != null || endDate != null) {
        final dateRange = 'Fecha: ${startDate != null ? DateFormat('yyyy-MM-dd').format(startDate) : ''} - ${endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : ''}';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .value = TextCellValue(dateRange);
        currentRow++;
      }
      
      if (filteringWord != null && filteringWord.isNotEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .value = TextCellValue('Búsqueda: $filteringWord');
        currentRow++;
      }
      currentRow++; // 빈 줄
    }
    
    // ITEMS, INGRESOS, GASTOS 보고서의 경우 특별 처리
    if (reportType == ReportType.items || reportType == ReportType.ingresos || reportType == ReportType.gastos) {
      // 1. 먼저 모든 resumen 정보 기록
      
      // 1-1. 전체 Summary
      if (data != null && data.containsKey('summary') && data['summary'] is Map) {
        final summary = data['summary'] as Map<String, dynamic>;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .value = TextCellValue('Resumen General:');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .cellStyle = CellStyle(bold: true, fontSize: 14);
        currentRow++;
        
        int summaryCol = 0;
        for (var entry in summary.entries) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: summaryCol, rowIndex: currentRow))
              .value = TextCellValue(entry.key);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: summaryCol, rowIndex: currentRow))
              .cellStyle = CellStyle(bold: true);
          summaryCol++;
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: summaryCol, rowIndex: currentRow))
              .value = TextCellValue(entry.value?.toString() ?? '');
          summaryCol++;
          if (summaryCol >= 2) {
            summaryCol = 0;
            currentRow++;
          }
        }
        if (summaryCol > 0) currentRow++;
        currentRow++; // 빈 줄
      }
      
      // 1-2. INGRESOS/ITEMS: summary_by_company
      if ((reportType == ReportType.ingresos || reportType == ReportType.items) &&
          data != null && 
          data.containsKey('data') && 
          data['data'] is Map &&
          (data['data'] as Map).containsKey('summary_by_company') &&
          (data['data'] as Map)['summary_by_company'] is List) {
        final summaryByCompany = (data['data'] as Map)['summary_by_company'] as List;
        if (summaryByCompany.isNotEmpty) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .value = TextCellValue('Resumen por Empresa:');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .cellStyle = CellStyle(bold: true, fontSize: 14);
          currentRow++;
          
          // 헤더 행
          final firstItem = summaryByCompany.first as Map<String, dynamic>;
          final keys = firstItem.keys.toList();
          for (int col = 0; col < keys.length; col++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
            cell.value = TextCellValue(keys[col]);
            cell.cellStyle = CellStyle(bold: true);
          }
          currentRow++;
          
          // 데이터 행들
          for (var item in summaryByCompany) {
            if (item is Map<String, dynamic>) {
              for (int col = 0; col < keys.length; col++) {
                final key = keys[col];
                final value = item[key];
                final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
                _setCellValue(cell, key, value);
              }
              currentRow++;
            }
          }
          currentRow++; // 빈 줄
        }
      }
      
      // 1-3. INGRESOS/ITEMS: summary_by_category
      if ((reportType == ReportType.ingresos || reportType == ReportType.items) &&
          data != null && 
          data.containsKey('data') && 
          data['data'] is Map &&
          (data['data'] as Map).containsKey('summary_by_category') &&
          (data['data'] as Map)['summary_by_category'] is List) {
        final summaryByCategory = (data['data'] as Map)['summary_by_category'] as List;
        if (summaryByCategory.isNotEmpty) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .value = TextCellValue('Resumen por Categoría:');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .cellStyle = CellStyle(bold: true, fontSize: 14);
          currentRow++;
          
          // 헤더 행
          final firstItem = summaryByCategory.first as Map<String, dynamic>;
          final keys = firstItem.keys.toList();
          for (int col = 0; col < keys.length; col++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
            cell.value = TextCellValue(keys[col]);
            cell.cellStyle = CellStyle(bold: true);
          }
          currentRow++;
          
          // 데이터 행들
          for (var item in summaryByCategory) {
            if (item is Map<String, dynamic>) {
              for (int col = 0; col < keys.length; col++) {
                final key = keys[col];
                final value = item[key];
                final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
                _setCellValue(cell, key, value);
              }
              currentRow++;
            }
          }
          currentRow++; // 빈 줄
        }
      }
      
      // 1-4. GASTOS: summary_by_rubro
      if (reportType == ReportType.gastos &&
          data != null && 
          data.containsKey('summary_by_rubro') &&
          data['summary_by_rubro'] is List) {
        final summaryByRubro = data['summary_by_rubro'] as List;
        if (summaryByRubro.isNotEmpty) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .value = TextCellValue('Resumen por Rubro:');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .cellStyle = CellStyle(bold: true, fontSize: 14);
          currentRow++;
          
          // 헤더 행
          final firstItem = summaryByRubro.first as Map<String, dynamic>;
          final keys = firstItem.keys.toList();
          for (int col = 0; col < keys.length; col++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
            cell.value = TextCellValue(keys[col]);
            cell.cellStyle = CellStyle(bold: true);
          }
          currentRow++;
          
          // 데이터 행들
          for (var item in summaryByRubro) {
            if (item is Map<String, dynamic>) {
              for (int col = 0; col < keys.length; col++) {
                final key = keys[col];
                final value = item[key];
                final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
                _setCellValue(cell, key, value);
              }
              currentRow++;
            }
          }
          currentRow++; // 빈 줄
        }
      }
      
      // 2. 그 아래에 세부 사항 기록
      currentRow++; // resumen과 detail 사이 빈 줄
      
      // 2-1. INGRESOS/ITEMS: products
      if ((reportType == ReportType.ingresos || reportType == ReportType.items) &&
          data != null && 
          data.containsKey('data') && 
          data['data'] is Map &&
          (data['data'] as Map).containsKey('products') &&
          (data['data'] as Map)['products'] is List) {
        final productsList = (data['data'] as Map)['products'] as List;
        if (productsList.isNotEmpty) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .value = TextCellValue('Detalle de Productos:');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .cellStyle = CellStyle(bold: true, fontSize: 14);
          currentRow++;
          
          final firstItem = productsList.first as Map<String, dynamic>;
          final keys = displayedColumns != null && displayedColumns.isNotEmpty
              ? displayedColumns.where((key) => firstItem.containsKey(key)).toList()
              : firstItem.keys.toList();
          
          print('📋 Excel 생성 - 사용할 컬럼: $keys (총 ${keys.length}개)');
          
          // 헤더 행
          for (int col = 0; col < keys.length; col++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
            cell.value = TextCellValue(keys[col]);
            cell.cellStyle = CellStyle(bold: true);
          }
          currentRow++;
          
          // 데이터 행들
          for (var item in productsList) {
            if (item is Map<String, dynamic>) {
              for (int col = 0; col < keys.length; col++) {
                final key = keys[col];
                final value = item[key];
                final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
                _setCellValue(cell, key, value);
              }
              currentRow++;
            }
          }
        }
      }
      
      // 2-2. GASTOS: detail
      if (reportType == ReportType.gastos &&
          data != null && 
          data.containsKey('data') && 
          data['data'] is Map &&
          (data['data'] as Map).containsKey('detail') &&
          (data['data'] as Map)['detail'] is List) {
        final detailList = (data['data'] as Map)['detail'] as List;
        if (detailList.isNotEmpty) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .value = TextCellValue('Detalle de Gastos:');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .cellStyle = CellStyle(bold: true, fontSize: 14);
          currentRow++;
          
          final firstItem = detailList.first as Map<String, dynamic>;
          final keys = displayedColumns != null && displayedColumns.isNotEmpty
              ? displayedColumns.where((key) => firstItem.containsKey(key)).toList()
              : firstItem.keys.toList();
          
          print('📋 Excel 생성 - 사용할 컬럼: $keys (총 ${keys.length}개)');
          
          // 헤더 행
          for (int col = 0; col < keys.length; col++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
            cell.value = TextCellValue(keys[col]);
            cell.cellStyle = CellStyle(bold: true);
          }
          currentRow++;
          
          // 데이터 행들
          for (var item in detailList) {
            if (item is Map<String, dynamic>) {
              for (int col = 0; col < keys.length; col++) {
                final key = keys[col];
                final value = item[key];
                final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
                _setCellValue(cell, key, value);
              }
              currentRow++;
            }
          }
        }
      }
    } else {
      // 다른 보고서들은 기존 로직 사용
      
      // clientes 보고서의 경우 top_localidades와 top_provincias 처리
      Map<String, dynamic>? filteredData = data;
      bool hasTopLocalidades = false;
      bool hasTopProvincias = false;
      List<dynamic>? topLocalidadesData;
      List<dynamic>? topProvinciasData;
      
      if (reportType == ReportType.clientes && data != null) {
        filteredData = Map<String, dynamic>.from(data);
        
        // top_localidades가 존재하고 비어있지 않으면 저장 후 제거
        if (filteredData.containsKey('top_localidades') && 
            filteredData['top_localidades'] != null &&
            filteredData['top_localidades'] is List) {
          final localidades = filteredData['top_localidades'] as List;
          if (localidades.isNotEmpty) {
            hasTopLocalidades = true;
            topLocalidadesData = localidades;
            print('📋 clientes 보고서 Excel 생성 - top_localidades 포함됨 (${localidades.length}개)');
          }
        }
        
        // top_provincias가 존재하고 비어있지 않으면 저장 후 제거
        if (filteredData.containsKey('top_provincias') && 
            filteredData['top_provincias'] != null &&
            filteredData['top_provincias'] is List) {
          final provincias = filteredData['top_provincias'] as List;
          if (provincias.isNotEmpty) {
            hasTopProvincias = true;
            topProvinciasData = provincias;
            print('📋 clientes 보고서 Excel 생성 - top_provincias 포함됨 (${provincias.length}개)');
          }
        }
        
        // filteredData에서 제거 (나중에 별도 섹션으로 추가)
        filteredData.remove('top_localidades');
        filteredData.remove('top_provincias');
      }
      
      // Summary 정보가 있으면 표시
      if (filteredData != null && filteredData.containsKey('summary') && filteredData['summary'] is Map) {
        final summary = filteredData['summary'] as Map<String, dynamic>;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .value = TextCellValue('Resumen:');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .cellStyle = CellStyle(bold: true);
        currentRow++;
        
        int summaryCol = 0;
        for (var entry in summary.entries) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: summaryCol, rowIndex: currentRow))
              .value = TextCellValue(entry.key);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: summaryCol, rowIndex: currentRow))
              .cellStyle = CellStyle(bold: true);
          summaryCol++;
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: summaryCol, rowIndex: currentRow))
              .value = TextCellValue(entry.value?.toString() ?? '');
          summaryCol++;
          if (summaryCol >= 2) {
            summaryCol = 0;
            currentRow++;
          }
        }
        if (summaryCol > 0) currentRow++;
        currentRow++; // 빈 줄
      }
      
      // 데이터 리스트가 있으면 테이블로 표시
      if (filteredData != null && filteredData.containsKey('data') && filteredData['data'] is List) {
        final dataList = filteredData['data'] as List;
        
        if (dataList.isEmpty) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .value = TextCellValue('No hay datos disponibles');
          currentRow++;
        } else if (dataList.isNotEmpty && dataList.first is Map) {
          final firstItem = dataList.first as Map<String, dynamic>;
          
          // 화면에 표시되는 컬럼만 사용 (없으면 모든 컬럼 사용)
          final keys = displayedColumns != null && displayedColumns.isNotEmpty
              ? displayedColumns.where((key) => firstItem.containsKey(key)).toList()
              : firstItem.keys.toList();
          
          print('📋 Excel 생성 - 사용할 컬럼: $keys (총 ${keys.length}개)');
          
          // 헤더 행
          for (int col = 0; col < keys.length; col++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
            cell.value = TextCellValue(keys[col]);
            cell.cellStyle = CellStyle(
              bold: true,
            );
          }
          currentRow++;
          
          // 데이터 행들
          for (var item in dataList) {
            if (item is Map<String, dynamic>) {
              for (int col = 0; col < keys.length; col++) {
                final key = keys[col];
                final value = item[key];
                final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
                _setCellValue(cell, key, value);
              }
              currentRow++;
            }
          }
        }
      }
      
      // clientes 보고서의 경우 top_localidades와 top_provincias 추가
      if (reportType == ReportType.clientes) {
        // top_localidades 추가
        if (hasTopLocalidades && topLocalidadesData != null && topLocalidadesData.isNotEmpty) {
          currentRow++; // 빈 줄
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .value = TextCellValue('Top Localidades:');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .cellStyle = CellStyle(bold: true, fontSize: 14);
          currentRow++;
          
          // 헤더 행
          if (topLocalidadesData.first is Map) {
            final firstItem = topLocalidadesData.first as Map<String, dynamic>;
            final keys = firstItem.keys.toList();
            for (int col = 0; col < keys.length; col++) {
              final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
              cell.value = TextCellValue(keys[col]);
              cell.cellStyle = CellStyle(bold: true);
            }
            currentRow++;
            
            // 데이터 행들
            for (var item in topLocalidadesData) {
              if (item is Map<String, dynamic>) {
                for (int col = 0; col < keys.length; col++) {
                  final key = keys[col];
                  final value = item[key];
                  final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
                  _setCellValue(cell, key, value);
                }
                currentRow++;
              }
            }
          }
        }
        
        // top_provincias 추가
        if (hasTopProvincias && topProvinciasData != null && topProvinciasData.isNotEmpty) {
          currentRow++; // 빈 줄
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .value = TextCellValue('Top Provincias:');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .cellStyle = CellStyle(bold: true, fontSize: 14);
          currentRow++;
          
          // 헤더 행
          if (topProvinciasData.first is Map) {
            final firstItem = topProvinciasData.first as Map<String, dynamic>;
            final keys = firstItem.keys.toList();
            for (int col = 0; col < keys.length; col++) {
              final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
              cell.value = TextCellValue(keys[col]);
              cell.cellStyle = CellStyle(bold: true);
            }
            currentRow++;
            
            // 데이터 행들
            for (var item in topProvinciasData) {
              if (item is Map<String, dynamic>) {
                for (int col = 0; col < keys.length; col++) {
                  final key = keys[col];
                  final value = item[key];
                  final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
                  _setCellValue(cell, key, value);
                }
                currentRow++;
              }
            }
          }
        }
      }
    }
    
    final fileName = '${reportTitle}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';

    // Excel 저장 전에 Sheet1이 남아있는지 다시 확인하고 삭제
    try {
      if (excel.sheets.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
        print('✅ 저장 전 Sheet1 삭제 완료');
      }
      print('📊 최종 시트 목록: ${excel.sheets.keys.toList()}');
    } catch (e) {
      print('⚠️ 저장 전 Sheet1 삭제 중 오류 (무시): $e');
    }

    // 웹: 파일 시스템이 없으므로 브라우저 다운로드로 처리
    if (kIsWeb) {
      final excelBytes = excel.save();
      if (excelBytes == null) {
        throw Exception('Excel 파일 생성 실패: excelBytes가 null입니다');
      }
      await saveFileOnWeb(
        Uint8List.fromList(excelBytes),
        fileName,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      // 웹에서는 실제 파일이 아니므로 반환값을 사용하면 안 됨 (호출부에서 kIsWeb 분기 필수)
      return File(fileName);
    }

    // 임시 디렉토리에 파일 저장
    final directory = await getTemporaryDirectory();

    // 디렉토리가 존재하는지 확인하고 없으면 생성
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('📁 디렉토리 생성: ${directory.path}');
    }

    final file = File('${directory.path}/$fileName');

    // Excel 저장
    try {
      final excelBytes = excel.save();
      if (excelBytes == null) {
        throw Exception('Excel 파일 생성 실패: excelBytes가 null입니다');
      }

      await file.writeAsBytes(excelBytes);
      print('✅ Excel 파일 저장 완료: ${file.path}');
      print('📄 파일 크기: ${excelBytes.length} bytes');
      
      // 파일이 실제로 생성되었는지 확인
      if (!await file.exists()) {
        throw Exception('Excel 파일이 생성되지 않았습니다: ${file.path}');
      }
      
      return file;
    } catch (e) {
      print('❌ Excel 파일 저장 실패: $e');
      print('   디렉토리 경로: ${directory.path}');
      print('   디렉토리 존재: ${await directory.exists()}');
      rethrow;
    }
  }

  /// Cliente 상세 정보를 Excel로 변환하여 파일로 저장
  static Future<File> generateClienteDetailExcel({
    required Map<String, dynamic> clienteDetailData,
    required String clienteNombre,
  }) async {
    final excel = Excel.createExcel();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final now = DateTime.now();
    
    // 기본 Sheet1 삭제 (시트가 존재하는 경우에만)
    // Excel.createExcel()은 기본적으로 'Sheet1'을 생성하므로 먼저 삭제
    try {
      if (excel.sheets.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
        print('✅ Sheet1 삭제 완료');
      }
    } catch (e) {
      print('⚠️ Sheet1 삭제 중 오류 (무시): $e');
    }
    
    // Cliente 상세 정보 시트 생성
    final sheet = excel['Detalle del Cliente'];
    print('✅ 시트 생성 완료: Detalle del Cliente, 전체 시트: ${excel.sheets.keys.toList()}');
    
    int currentRow = 0;
    
    // 헤더 행
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .value = TextCellValue('Detalle del Cliente');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .cellStyle = CellStyle(bold: true, fontSize: 16);
    currentRow++;
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .value = TextCellValue('Generado: ${dateFormat.format(now)}');
    currentRow++;
    currentRow++; // 빈 줄
    
    // Cliente 기본 정보
    if (clienteDetailData.containsKey('cliente') && clienteDetailData['cliente'] is Map) {
      final cliente = clienteDetailData['cliente'] as Map<String, dynamic>;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = TextCellValue('Información del Cliente');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .cellStyle = CellStyle(bold: true, fontSize: 14);
      currentRow++;
      
      final clienteInfo = [
        ['DNI', cliente['dni']?.toString() ?? 'N/A'],
        ['Nombre', cliente['nombre']?.toString() ?? 'N/A'],
        ['Dirección', cliente['direccion']?.toString() ?? 'N/A'],
        ['Localidad', cliente['localidad']?.toString() ?? 'N/A'],
        ['Provincia', cliente['provincia']?.toString() ?? 'N/A'],
        ['Vendedor', cliente['vendedor']?.toString() ?? 'N/A'],
        ['Teléfono', cliente['telefono']?.toString() ?? 'N/A'],
        ['Email', cliente['email']?.toString() ?? 'N/A'],
        ['Transporte', cliente['transporte']?.toString() ?? 'N/A'],
        ['Deuda', cliente['deuda']?.toString() ?? 'N/A'],
        ['Tipo', cliente['tipo']?.toString() ?? 'N/A'],
        ['Memo', cliente['memo']?.toString() ?? 'N/A'],
      ];
      
      for (var info in clienteInfo) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .value = TextCellValue(info[0]);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .cellStyle = CellStyle(bold: true);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
            .value = TextCellValue(info[1]);
        currentRow++;
      }
      currentRow++; // 빈 줄
    }
    
    // 구매 이력 요약
    if (clienteDetailData.containsKey('compra_historial')) {
      final compraHistorial = clienteDetailData['compra_historial'] as Map<String, dynamic>;
      
      // Summary 정보
      if (compraHistorial.containsKey('summary') && compraHistorial['summary'] is Map) {
        final summary = compraHistorial['summary'] as Map<String, dynamic>;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .value = TextCellValue('Resumen de Compras');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .cellStyle = CellStyle(bold: true, fontSize: 14);
        currentRow++;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .value = TextCellValue('Total de Items');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .cellStyle = CellStyle(bold: true);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
            .value = TextCellValue(summary['total_items']?.toString() ?? 'N/A');
        currentRow++;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .value = TextCellValue('Unidad');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .cellStyle = CellStyle(bold: true);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
            .value = TextCellValue(summary['unit']?.toString() ?? 'N/A');
        currentRow++;
        
        currentRow++; // 빈 줄
      }
      
      // 구매 이력 데이터 테이블
      if (compraHistorial.containsKey('data') && compraHistorial['data'] is List) {
        final compraData = compraHistorial['data'] as List;
        if (compraData.isNotEmpty) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .value = TextCellValue('Historial de Compras (${compraData.length} registros)');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .cellStyle = CellStyle(bold: true, fontSize: 14);
          currentRow++;
          currentRow++; // 빈 줄
          
          final columns = ['vcode', 'fecha', 'tpago', 'cntropas', 'tefectivo', 'tcredito', 'tbanco', 'treservado', 'sucursal', 'vendedor'];
          final labels = {
            'vcode': 'Código',
            'fecha': 'Fecha',
            'tpago': 'Total Pago',
            'cntropas': 'Cant. Ropas',
            'tefectivo': 'Efectivo',
            'tcredito': 'Crédito',
            'tbanco': 'Banco',
            'treservado': 'Reservado',
            'sucursal': 'Sucursal',
            'vendedor': 'Vendedor',
          };
          
          // 헤더 행
          int col = 0;
          for (var key in columns) {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow))
                .value = TextCellValue(labels[key] ?? key);
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow))
                .cellStyle = CellStyle(bold: true);
            col++;
          }
          currentRow++;
          
          // 데이터 행들
          for (var item in compraData) {
            if (item is Map<String, dynamic>) {
              col = 0;
              for (var key in columns) {
                final value = item[key];
                final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
                _setCellValue(cell, key, value);
                col++;
              }
              currentRow++;
            }
          }
        }
      }
    }
    
    final fileName = 'Detalle_Cliente_${clienteNombre.replaceAll(RegExp(r'[^\w\s-]'), '_')}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';

    // Excel 저장 전에 Sheet1이 남아있는지 다시 확인하고 삭제
    try {
      if (excel.sheets.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
        print('✅ 저장 전 Sheet1 삭제 완료');
      }
      print('📊 최종 시트 목록: ${excel.sheets.keys.toList()}');
    } catch (e) {
      print('⚠️ 저장 전 Sheet1 삭제 중 오류 (무시): $e');
    }

    // 웹: 브라우저 다운로드로 처리
    if (kIsWeb) {
      final excelBytes = excel.save();
      if (excelBytes == null) {
        throw Exception('Excel 파일 생성 실패: excelBytes가 null입니다');
      }
      await saveFileOnWeb(
        Uint8List.fromList(excelBytes),
        fileName,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      // 웹에서는 실제 파일이 아니므로 반환값을 사용하면 안 됨
      return File(fileName);
    }

    // 파일 저장
    final directory = await getTemporaryDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File('${directory.path}/$fileName');

    final excelBytes = excel.save();
    if (excelBytes != null) {
      await file.writeAsBytes(excelBytes);
    }

    return file;
  }
}

