part of '../report_screen_legacy.dart';

mixin ReportShareMixin on _ReportScreenStateBase {

  /// 보고서 공유 (macOS/Windows: Excel, 기타: PDF)
  Future<void> _shareReport() async {
    if (_data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos para compartir'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // macOS 또는 Windows인 경우 Excel로 공유
    if (Platform.isMacOS || Platform.isWindows) {
      _shareAsExcel();
    } else {
      // 모바일/태블릿: 기존대로 PDF만 공유
      _shareAsPdf();
    }
  }

  /// PDF로 변환하여 공유
  Future<void> _shareAsPdf() async {
    if (_data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos para compartir'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      // 날짜 범위 가져오기
      DateTime? startDate;
      DateTime? endDate;
      
      if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas) {
        startDate = _itemsStartDate;
        endDate = _itemsEndDate;
      } else if (widget.reportType == ReportType.ventas) {
        startDate = _ventasStartDate;
        endDate = _ventasEndDate;
      }

      // 필터링 단어 가져오기
      final filteringWord = _filteringWordController.text.trim();
      final filterWord = filteringWord.isEmpty ? null : filteringWord;

      // 화면에 표시되는 모든 데이터 수집 (필터링/정렬 적용)
      final displayedData = _getDisplayedData();
      
      // 화면에 표시되는 컬럼 목록 가져오기
      List<String>? displayedColumns;
      if (displayedData.containsKey('data') && displayedData['data'] is List) {
        final dataList = displayedData['data'] as List;
        if (dataList.isNotEmpty) {
          displayedColumns = ReportTableBuilder.getDisplayedColumns(
            dataList,
            widget.reportType,
            unit: widget.reportType == ReportType.ventas ? _ventasUnit : null,
          );
          print('📋 PDF용 표시 컬럼: $displayedColumns');
        }
      }

      // PDF 생성
      final pdfFile = await PdfService.generateReportPdf(
        reportType: widget.reportType,
        data: displayedData,
        startDate: startDate,
        endDate: endDate,
        filteringWord: filterWord,
        displayedColumns: displayedColumns,
      );

      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 파일 존재 확인
      if (!await pdfFile.exists()) {
        throw Exception('PDF 파일이 생성되지 않았습니다: ${pdfFile.path}');
      }

      print('📄 PDF 파일 생성 완료: ${pdfFile.path}');
      print('📄 파일 크기: ${await pdfFile.length()} bytes');

      // PDF 미리보기 및 공유 다이얼로그 표시
      if (mounted) {
        await _showPdfPreviewDialog(pdfFile);
      }
    } catch (e, stackTrace) {
      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 상세한 에러 로깅
      print('❌ PDF 생성/공유 오류: $e');
      print('❌ Stack trace: $stackTrace');

      // 에러 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar/compartir PDF: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// PDF 미리보기 및 공유 다이얼로그 표시
  Future<void> _showPdfPreviewDialog(File pdfFile) async {
    final reportTitle = ReportUtils.getReportTitle(widget.reportType);
    final fileName = pdfFile.path.split('/').last;
    final fileSize = await pdfFile.length();
    final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'PDF 생성 완료',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '보고서: $reportTitle',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              '파일명: $fileName',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '파일 크기: $fileSizeMB MB',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'PDF를 먼저 확인한 후 공유할 수 있습니다.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _openPdfFile(pdfFile);
            },
            icon: const Icon(Icons.preview, size: 20),
            label: const Text('PDF 보기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _sharePdfFile(pdfFile);
            },
            icon: const Icon(Icons.share, size: 20),
            label: const Text('공유'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// PDF 파일을 시스템 기본 뷰어로 열기
  Future<void> _openPdfFile(File pdfFile) async {
    try {
      if (Platform.isMacOS) {
        // macOS: Preview 앱으로 열기
        final result = await Process.run(
          'open',
          [pdfFile.path],
        );
        if (result.exitCode == 0) {
          print('✅ PDF 파일 열기 성공: ${pdfFile.path}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF가 열렸습니다'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('PDF 열기 실패: ${result.stderr}');
        }
      } else if (Platform.isWindows) {
        // Windows: 기본 PDF 뷰어로 열기
        await Process.run('start', [pdfFile.path], runInShell: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF가 열렸습니다'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (Platform.isLinux) {
        // Linux: xdg-open 사용
        await Process.run('xdg-open', [pdfFile.path]);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF가 열렸습니다'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ PDF 파일 열기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 열기 실패: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// PDF 파일 공유
  Future<void> _sharePdfFile(File pdfFile) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Reporte ${ReportUtils.getReportTitle(widget.reportType)}',
      );
      print('✅ PDF 공유 성공');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF 공유 완료'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (shareError) {
      print('❌ PDF 공유 실패: $shareError');
      
      // macOS에서 공유가 실패하면 데스크톱에 복사하고 Finder에서 열기
      if (Platform.isMacOS && mounted) {
        try {
          final homeDir = Platform.environment['HOME'] ?? '';
          final desktopPath = '$homeDir/Desktop';
          final desktopDir = Directory(desktopPath);
          
          if (await desktopDir.exists()) {
            final fileName = pdfFile.path.split('/').last;
            final desktopFile = File('$desktopPath/$fileName');
            
            await pdfFile.copy(desktopFile.path);
            print('✅ PDF 파일을 데스크톱에 복사: ${desktopFile.path}');
            
            final result = await Process.run(
              'open',
              ['-R', desktopFile.path],
            );
            
            if (result.exitCode == 0) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PDF가 데스크톱에 저장되었습니다: $fileName'),
                    duration: const Duration(seconds: 4),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              return;
            }
          }
        } catch (copyError) {
          print('❌ 데스크톱 복사 실패: $copyError');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 공유 실패: $shareError'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Excel로 변환하여 공유
  Future<void> _shareAsExcel() async {
    if (_data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos para compartir'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando Excel...'),
                ],
              ),
            ),
          ),
        ),
      );

      // 날짜 범위 가져오기
      DateTime? startDate;
      DateTime? endDate;
      
      if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas) {
        startDate = _itemsStartDate;
        endDate = _itemsEndDate;
      } else if (widget.reportType == ReportType.ventas) {
        startDate = _ventasStartDate;
        endDate = _ventasEndDate;
      }

      // 필터링 단어 가져오기
      final filteringWord = _filteringWordController.text.trim();
      final filterWord = filteringWord.isEmpty ? null : filteringWord;

      // 화면에 표시되는 모든 데이터 수집 (필터링/정렬 적용)
      final displayedData = _getDisplayedData();
      
      // 화면에 표시되는 컬럼 목록 가져오기
      List<String>? displayedColumns;
      if (displayedData.containsKey('data') && displayedData['data'] is List) {
        final dataList = displayedData['data'] as List;
        if (dataList.isNotEmpty) {
          displayedColumns = ReportTableBuilder.getDisplayedColumns(
            dataList,
            widget.reportType,
            unit: widget.reportType == ReportType.ventas ? _ventasUnit : null,
          );
          print('📋 Excel용 표시 컬럼: $displayedColumns');
        }
      }

      // Excel 생성
      final excelFile = await ExcelService.generateReportExcel(
        reportType: widget.reportType,
        data: displayedData,
        startDate: startDate,
        endDate: endDate,
        filteringWord: filterWord,
        displayedColumns: displayedColumns,
      );

      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 파일 존재 확인
      if (!await excelFile.exists()) {
        throw Exception('Excel 파일이 생성되지 않았습니다: ${excelFile.path}');
      }

      print('📄 Excel 파일 생성 완료: ${excelFile.path}');
      print('📄 파일 크기: ${await excelFile.length()} bytes');

      // Excel 미리보기 및 공유 다이얼로그 표시
      if (mounted) {
        await _showExcelPreviewDialog(excelFile);
      }
    } catch (e, stackTrace) {
      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 상세한 에러 로깅
      print('❌ Excel 생성/공유 오류: $e');
      print('❌ Stack trace: $stackTrace');

      // 에러 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar/compartir Excel: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Excel 미리보기 및 공유 다이얼로그 표시
  Future<void> _showExcelPreviewDialog(File excelFile) async {
    final reportTitle = ReportUtils.getReportTitle(widget.reportType);
    final fileName = excelFile.path.split('/').last;
    final fileSize = await excelFile.length();
    final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.table_chart, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Excel 생성 완료',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '보고서: $reportTitle',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              '파일명: $fileName',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '파일 크기: $fileSizeMB MB',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Excel 파일을 열거나 공유할 수 있습니다.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _openExcelFile(excelFile);
            },
            icon: const Icon(Icons.open_in_new, size: 20),
            label: const Text('열기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _shareExcelFile(excelFile);
            },
            icon: const Icon(Icons.share, size: 20),
            label: const Text('공유'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Excel 파일을 시스템 기본 앱으로 열기
  Future<void> _openExcelFile(File excelFile) async {
    try {
      if (Platform.isMacOS) {
        // macOS: Excel 또는 기본 앱으로 열기
        final result = await Process.run(
          'open',
          [excelFile.path],
        );
        if (result.exitCode == 0) {
          print('✅ Excel 파일 열기 성공: ${excelFile.path}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Excel 파일이 열렸습니다'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Excel 파일 열기 실패: ${result.stderr}');
        }
      } else if (Platform.isWindows) {
        // Windows: 기본 앱으로 열기
        final result = await Process.run(
          'start',
          ['', excelFile.path],
          runInShell: true,
        );
        if (result.exitCode == 0) {
          print('✅ Excel 파일 열기 성공: ${excelFile.path}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Excel 파일이 열렸습니다'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Excel 파일 열기 실패: ${result.stderr}');
        }
      }
    } catch (e) {
      print('❌ Excel 파일 열기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel 파일 열기 실패: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Excel 파일 공유
  Future<void> _shareExcelFile(File excelFile) async {
    try {
      await Share.shareXFiles(
        [XFile(excelFile.path)],
        text: 'Reporte ${ReportUtils.getReportTitle(widget.reportType)}',
      );
      print('✅ Excel 공유 성공');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel 공유 완료'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (shareError) {
      print('❌ Excel 공유 실패: $shareError');
      
      // macOS에서 공유가 실패하면 데스크톱에 복사하고 Finder에서 열기
      if (Platform.isMacOS && mounted) {
        try {
          final homeDir = Platform.environment['HOME'] ?? '';
          final desktopPath = '$homeDir/Desktop';
          final desktopDir = Directory(desktopPath);
          
          if (await desktopDir.exists()) {
            final fileName = excelFile.path.split('/').last;
            final desktopFile = File('$desktopPath/$fileName');
            
            await excelFile.copy(desktopFile.path);
            print('✅ Excel 파일을 데스크톱에 복사: ${desktopFile.path}');
            
            final result = await Process.run(
              'open',
              ['-R', desktopFile.path],
            );
            
            if (result.exitCode == 0) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Excel이 데스크톱에 저장되었습니다: $fileName'),
                    duration: const Duration(seconds: 4),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              return;
            }
          }
        } catch (copyError) {
          print('❌ Excel 파일 복사 실패: $copyError');
        }
      }
      
      // Windows에서 공유가 실패하면 데스크톱에 복사
      if (Platform.isWindows && mounted) {
        try {
          final homeDir = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
          final desktopPath = '$homeDir\\Desktop';
          final desktopDir = Directory(desktopPath);
          
          if (await desktopDir.exists()) {
            final fileName = excelFile.path.split('\\').last;
            final desktopFile = File('$desktopPath\\$fileName');
            
            await excelFile.copy(desktopFile.path);
            print('✅ Excel 파일을 데스크톱에 복사: ${desktopFile.path}');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Excel이 데스크톱에 저장되었습니다: $fileName'),
                  duration: const Duration(seconds: 4),
                  backgroundColor: Colors.green,
                ),
              );
            }
            return;
          }
        } catch (copyError) {
          print('❌ Excel 파일 복사 실패: $copyError');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel 공유 실패: $shareError'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
