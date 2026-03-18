import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/report_utils.dart';

// ReportUtils의 formatValue 함수를 사용하기 위한 헬퍼
String _formatValue(dynamic value) {
  if (value == null) return 'N/A';
  if (value is num) {
    return NumberFormat('#,##0.00').format(value);
  }
  return value.toString();
}

class PdfService {
  /// 보고서 데이터를 PDF로 변환하여 파일로 저장
  static Future<File> generateReportPdf({
    required ReportType reportType,
    required Map<String, dynamic>? data,
    DateTime? startDate,
    DateTime? endDate,
    String? filteringWord,
    List<String>? displayedColumns, // 화면에 표시되는 컬럼 목록
  }) async {
    final pdf = pw.Document();
    final reportTitle = ReportUtils.getReportTitle(reportType);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final now = DateTime.now();
    
    // Unicode 지원을 위한 폰트 설정 (기본 폰트 사용, 경고는 무시)
    // macOS에서는 기본 폰트가 대부분의 문자를 지원하므로 경고는 무시해도 됨

    // PDF 제목 및 메타데이터
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // 헤더
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    reportTitle,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    dateFormat.format(now),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 필터 정보
            if (startDate != null || endDate != null || filteringWord != null)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Filtros aplicados:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    if (startDate != null || endDate != null)
                      pw.Text(
                        'Fecha: ${startDate != null ? DateFormat('yyyy-MM-dd').format(startDate) : ''} - ${endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : ''}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (filteringWord != null && filteringWord.isNotEmpty)
                      pw.Text(
                        'Búsqueda: $filteringWord',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ),
            pw.SizedBox(height: 20),

            // 데이터 내용
            if (data == null)
              pw.Center(
                child: pw.Text(
                  'No hay datos disponibles',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                ),
              )
            else
              ..._buildReportContent(pdf, data, reportType, displayedColumns: displayedColumns),
          ];
        },
      ),
    );

    // 임시 디렉토리에 파일 저장
    final directory = await getTemporaryDirectory();
    
    // 디렉토리가 존재하는지 확인하고 없으면 생성
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('📁 디렉토리 생성: ${directory.path}');
    }
    
    final fileName = '${reportTitle}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
    final file = File('${directory.path}/$fileName');
    
    // PDF 저장
    try {
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      print('✅ PDF 파일 저장 완료: ${file.path}');
      print('📄 파일 크기: ${pdfBytes.length} bytes');
      
      // 파일이 실제로 생성되었는지 확인
      if (!await file.exists()) {
        throw Exception('PDF 파일이 생성되지 않았습니다: ${file.path}');
      }
      
      return file;
    } catch (e) {
      print('❌ PDF 파일 저장 실패: $e');
      print('   디렉토리 경로: ${directory.path}');
      print('   디렉토리 존재: ${await directory.exists()}');
      rethrow;
    }
  }

  /// 보고서 타입에 따라 적절한 내용 생성
  static List<pw.Widget> _buildReportContent(
    pw.Document pdf,
    Map<String, dynamic> data,
    ReportType reportType, {
    List<String>? displayedColumns,
  }) {
    final widgets = <pw.Widget>[];
    
    // Summary 정보가 있으면 표시
    if (data.containsKey('summary') && data['summary'] is Map) {
      final summary = data['summary'] as Map<String, dynamic>;
      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Resumen:',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: summary.entries.map((entry) {
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        entry.key,
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        entry.value?.toString() ?? '',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],
        ),
      );
    }

    // 데이터 리스트가 있으면 테이블로 표시
    if (data.containsKey('data') && data['data'] is List) {
      final dataList = data['data'] as List;
      
      if (dataList.isEmpty) {
        widgets.add(
          pw.Center(
            child: pw.Text(
              'No hay datos disponibles',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
          ),
        );
      } else if (dataList.isNotEmpty && dataList.first is Map) {
        final firstItem = dataList.first as Map<String, dynamic>;
        
        // 화면에 표시되는 컬럼만 사용 (없으면 모든 컬럼 사용)
        final keys = displayedColumns != null && displayedColumns.isNotEmpty
            ? displayedColumns.where((key) => firstItem.containsKey(key)).toList()
            : firstItem.keys.toList();
        
        print('📋 PDF 생성 - 사용할 컬럼: $keys (총 ${keys.length}개)');
        
        // 제목 추가
        widgets.add(
          pw.Text(
            'Datos (Total: ${dataList.length} registros):',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        );
        widgets.add(pw.SizedBox(height: 10));
        
        // 모든 데이터를 페이지별로 나누어 표시 (화면에 표시되는 컬럼만)
        widgets.addAll(_buildDataTables(dataList, keys));
      }
    }

    if (widgets.isEmpty) {
      widgets.add(
        pw.Text(
          'Formato de datos no reconocido',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.red),
        ),
      );
    }

    return widgets;
  }

  /// 데이터 테이블들을 생성 (모든 데이터 포함, 여러 페이지로 분할)
  static List<pw.Widget> _buildDataTables(List<dynamic> dataList, List<String> keys) {
    final widgets = <pw.Widget>[];
    // 페이지당 데이터 행 수 (헤더 제외, 약 25-30행)
    const int rowsPerPage = 28;
    
    // 헤더를 포함한 총 행 수
    final totalPages = (dataList.length / rowsPerPage).ceil();
    
    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startIndex = pageIndex * rowsPerPage;
      final endIndex = (startIndex + rowsPerPage < dataList.length) 
          ? startIndex + rowsPerPage 
          : dataList.length;
      final pageData = dataList.sublist(startIndex, endIndex);
      
      // 페이지 번호 표시 (첫 페이지가 아닌 경우)
      if (pageIndex > 0) {
        widgets.add(pw.SizedBox(height: 20));
        widgets.add(
          pw.Text(
            'Continuación... (Página ${pageIndex + 1} de $totalPages)',
            style: pw.TextStyle(
              fontSize: 10,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey600,
            ),
          ),
        );
        widgets.add(pw.SizedBox(height: 10));
      }
      
      // 테이블 생성
      widgets.add(
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            for (int i = 0; i < keys.length; i++)
              i: const pw.FlexColumnWidth(1),
          },
          children: [
            // 헤더 행 (각 페이지마다 표시)
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: keys.map((key) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    key,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    maxLines: 2,
                  ),
                );
              }).toList(),
            ),
            // 데이터 행들
            ...pageData.map((item) {
              if (item is Map<String, dynamic>) {
                return pw.TableRow(
                  children: keys.map((key) {
                    final value = item[key];
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(
                        value?.toString() ?? '',
                        style: const pw.TextStyle(fontSize: 8),
                        maxLines: 2,
                      ),
                    );
                  }).toList(),
                );
              }
              return const pw.TableRow(children: []);
            }),
          ],
        ),
      );
    }
    
    return widgets;
  }

  /// Cliente 상세 정보를 PDF로 변환하여 파일로 저장
  static Future<File> generateClienteDetailPdf({
    required Map<String, dynamic> clienteDetailData,
    required String clienteNombre,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final now = DateTime.now();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[];
          
          // 헤더
          widgets.add(
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Detalle del Cliente',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    dateFormat.format(now),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 20));
          
          // Cliente 기본 정보
          if (clienteDetailData.containsKey('cliente') && clienteDetailData['cliente'] is Map) {
            final cliente = clienteDetailData['cliente'] as Map<String, dynamic>;
            widgets.add(
              pw.Text(
                'Información del Cliente',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
            
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
              ['Deuda', _formatValue(cliente['deuda'])],
              ['Tipo', cliente['tipo']?.toString() ?? 'N/A'],
              ['Memo', cliente['memo']?.toString() ?? 'N/A'],
            ];
            
            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: clienteInfo.map((row) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          row[0],
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(row[1] ?? 'N/A'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
            widgets.add(pw.SizedBox(height: 20));
          }
          
          // 구매 이력 요약
          if (clienteDetailData.containsKey('compra_historial')) {
            final compraHistorial = clienteDetailData['compra_historial'] as Map<String, dynamic>;
            
            // Summary 정보
            if (compraHistorial.containsKey('summary') && compraHistorial['summary'] is Map) {
              final summary = compraHistorial['summary'] as Map<String, dynamic>;
              widgets.add(
                pw.Text(
                  'Resumen de Compras',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              );
              widgets.add(pw.SizedBox(height: 10));
              
              final summaryInfo = [
                ['Total de Items', summary['total_items']?.toString() ?? 'N/A'],
                ['Unidad', summary['unit']?.toString() ?? 'N/A'],
                ['Función Usada', summary['function_used']?.toString() ?? 'N/A'],
              ];
              
              widgets.add(
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: summaryInfo.map((row) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            row[0],
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(row[1] ?? 'N/A'),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
              widgets.add(pw.SizedBox(height: 20));
            }
            
            // 구매 이력 데이터 테이블
            if (compraHistorial.containsKey('data') && compraHistorial['data'] is List) {
              final compraData = compraHistorial['data'] as List;
              if (compraData.isNotEmpty) {
                widgets.add(
                  pw.Text(
                    'Historial de Compras (${compraData.length} registros)',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                );
                widgets.add(pw.SizedBox(height: 10));
                
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
                widgets.add(
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      for (int i = 0; i < columns.length; i++)
                        i: const pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: columns.map((key) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              labels[key] ?? key,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      // 데이터 행들 (최대 50개만 표시)
                      ...compraData.take(50).map((item) {
                        if (item is Map<String, dynamic>) {
                          return pw.TableRow(
                            children: columns.map((key) {
                              final value = item[key];
                              return pw.Padding(
                                padding: const pw.EdgeInsets.all(3),
                                child: pw.Text(
                                  _formatValue(value),
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                              );
                            }).toList(),
                          );
                        }
                        return const pw.TableRow(children: []);
                      }),
                    ],
                  ),
                );
                
                if (compraData.length > 50) {
                  widgets.add(pw.SizedBox(height: 10));
                  widgets.add(
                    pw.Text(
                      '... y ${compraData.length - 50} registros más',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                    ),
                  );
                }
              }
            }
          }
          
          return widgets;
        },
      ),
    );

    // 임시 디렉토리에 파일 저장
    final directory = await getTemporaryDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    final fileName = 'Detalle_Cliente_${clienteNombre.replaceAll(RegExp(r'[^\w\s-]'), '_')}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
    final file = File('${directory.path}/$fileName');
    
    final pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);
    
    return file;
  }
}
