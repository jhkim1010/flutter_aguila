import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/report_utils.dart';

class ExcelService {
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
    
    // 첫 번째 시트 선택
    excel.delete('Sheet1'); // 기본 시트 삭제
    final sheet = excel[reportTitle];
    
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
    
    // Summary 정보가 있으면 표시
    if (data != null && data.containsKey('summary') && data['summary'] is Map) {
      final summary = data['summary'] as Map<String, dynamic>;
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
    if (data != null && data.containsKey('data') && data['data'] is List) {
      final dataList = data['data'] as List;
      
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
              
              // 숫자 형식 처리
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
            currentRow++;
          }
        }
      }
    }
    
    // 임시 디렉토리에 파일 저장
    final directory = await getTemporaryDirectory();
    
    // 디렉토리가 존재하는지 확인하고 없으면 생성
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('📁 디렉토리 생성: ${directory.path}');
    }
    
    final fileName = '${reportTitle}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';
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
}

