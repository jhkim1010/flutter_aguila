import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/device_info_helper.dart';
import '../utils/mobile_layout_helper.dart';
import 'report_utils.dart';
import 'resizable_data_table.dart';

/// Codigos 보고서 UI 빌더
class CodigosBuilder {
  /// Codigos 보고서의 칼럼 정의 (ResizableDataTable 용).
  /// todocodigos 여부에 따라 다른 칼럼 셋을 반환한다.
  static List<TableColumnDef> buildColumnDefs({bool isTodocodigos = false}) {
    if (isTodocodigos) {
      return const [
        TableColumnDef(key: 'id_todocodigo', label: 'ID Todo Codigo', defaultWidth: 120, textAlign: TextAlign.right),
        TableColumnDef(key: 'tcodigo',        label: 'T Codigo',       defaultWidth: 120, sortable: true),
        TableColumnDef(key: 'tdesc',          label: 'T Desc',         defaultWidth: 300, sortable: true),
        TableColumnDef(key: 'tpre1',          label: 'T Precio 1',     defaultWidth: 100, textAlign: TextAlign.right),
        TableColumnDef(key: 'tpre2',          label: 'T Precio 2',     defaultWidth: 100, textAlign: TextAlign.right),
        TableColumnDef(key: 'tpre3',          label: 'T Precio 3',     defaultWidth: 100, textAlign: TextAlign.right),
        TableColumnDef(key: 'tpre4',          label: 'T Precio 4',     defaultWidth: 100, textAlign: TextAlign.right),
        TableColumnDef(key: 'tpre5',          label: 'T Precio 5',     defaultWidth: 100, textAlign: TextAlign.right),
        TableColumnDef(key: 'utime',          label: 'Utime',          defaultWidth: 150),
        TableColumnDef(key: 'borrado',        label: 'Borrado',        defaultWidth: 80,  textAlign: TextAlign.center),
        TableColumnDef(key: 'ip',             label: 'IP',             defaultWidth: 120),
        TableColumnDef(key: 'mac',            label: 'MAC',            defaultWidth: 150),
      ];
    }
    return const [
      TableColumnDef(key: 'codigo',                  label: 'Codigo',                 defaultWidth: 150, sortable: true),
      TableColumnDef(key: 'descripcion',             label: 'Descripción',            defaultWidth: 300, sortable: true),
      TableColumnDef(key: 'pre1',                    label: 'Precio 1',               defaultWidth: 100, textAlign: TextAlign.right),
      TableColumnDef(key: 'pre2',                    label: 'Precio 2',               defaultWidth: 100, textAlign: TextAlign.right),
      TableColumnDef(key: 'pre3',                    label: 'Precio 3',               defaultWidth: 100, textAlign: TextAlign.right),
      TableColumnDef(key: 'pre4',                    label: 'Precio 4',               defaultWidth: 100, textAlign: TextAlign.right),
      TableColumnDef(key: 'pre5',                    label: 'Precio 5',               defaultWidth: 100, textAlign: TextAlign.right),
      TableColumnDef(key: 'preorg',                  label: 'Precio Org',             defaultWidth: 100, textAlign: TextAlign.right),
      TableColumnDef(key: 'utime',                   label: 'Utime',                  defaultWidth: 150),
      TableColumnDef(key: 'borrado',                 label: 'Borrado',                defaultWidth: 80,  textAlign: TextAlign.center),
      TableColumnDef(key: 'ip',                      label: 'IP',                     defaultWidth: 120),
      TableColumnDef(key: 'mac',                     label: 'MAC',                    defaultWidth: 150),
      TableColumnDef(key: 'b_sincronizar_x_web',     label: 'Sincronizar Web',        defaultWidth: 120, textAlign: TextAlign.center),
      TableColumnDef(key: 'id_codigo',               label: 'ID Codigo',              defaultWidth: 100, textAlign: TextAlign.right),
    ];
  }

  /// 데이터 리스트를 ResizableDataTable 행 셀 위젯 리스트로 변환.
  /// [isTodocodigos] が true の場合は todocodigos 列を使用する。
  /// [selectedCodigo] と [editedCodigoIdentifier] は行の強調表示に使用する。
  static List<List<Widget>> buildRows(
    List<dynamic> data, {
    bool isTodocodigos = false,
    Map<String, dynamic>? selectedCodigo,
    String? editedCodigoIdentifier,
    Color reportColor = Colors.teal,
  }) {
    return data.map((item) => _buildRowCells(
      item as Map<String, dynamic>,
      isTodocodigos: isTodocodigos,
      selectedCodigo: selectedCodigo,
      editedCodigoIdentifier: editedCodigoIdentifier,
      reportColor: reportColor,
    )).toList();
  }

  static List<Widget> _buildRowCells(
    Map<String, dynamic> codigo, {
    bool isTodocodigos = false,
    Map<String, dynamic>? selectedCodigo,
    String? editedCodigoIdentifier,
    Color reportColor = Colors.teal,
  }) {
    final columnDefs = buildColumnDefs(isTodocodigos: isTodocodigos);
    final currentId = isTodocodigos
        ? codigo['tcodigo']?.toString()
        : codigo['codigo']?.toString();
    final isSelected = selectedCodigo != null && (isTodocodigos
        ? selectedCodigo['tcodigo'] == codigo['tcodigo']
        : selectedCodigo['codigo'] == codigo['codigo']);
    final isEdited = editedCodigoIdentifier != null && currentId == editedCodigoIdentifier;

    return columnDefs.map((col) {
      final key = col.key;
      final value = codigo[key];
      final isCodeColumn = key == 'codigo' || key == 'tcodigo';
      final isDescColumn = key == 'descripcion' || key == 'tdesc';
      final isNumeric = !isCodeColumn && ReportUtils.isNumeric(value);

      final displayValue = (isCodeColumn || isDescColumn)
          ? (value?.toString() ?? 'N/A')
          : ReportUtils.formatValue(value);

      final maxLines = isDescColumn ? null : 1;
      final overflow = isDescColumn ? TextOverflow.visible : TextOverflow.ellipsis;

      Color textColor;
      if (isEdited) {
        textColor = Colors.green[700]!;
      } else if (isSelected && isCodeColumn) {
        textColor = Colors.teal[700]!;
      } else if (isCodeColumn) {
        textColor = Colors.black87;
      } else {
        textColor = Colors.grey[700]!;
      }

      return Text(
        displayValue,
        style: TextStyle(
          fontWeight: isCodeColumn ? FontWeight.bold : FontWeight.normal,
          fontSize: isCodeColumn ? 14 : 12,
          color: textColor,
        ),
        textAlign: isNumeric ? TextAlign.right : col.textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }).toList();
  }

  /// Codigos 콘텐츠 빌드
  static Widget buildContent({
    required Map<String, dynamic> data,
    required BuildContext context,
    required ScrollController scrollController,
    required Map<String, dynamic>? selectedCodigo,
    required Function(Map<String, dynamic>) onCodigoSelected,
    Function(Map<String, dynamic>)? onCodigoDoubleTap,
    required bool isLoadingMore,
    required Color reportColor,
    required List<String> columnKeys,
    required Map<String, double> columnWidths,
    required Widget headerWidget,
    String? editedCodigoIdentifier, // 편집된 codigo 식별자
    ReportType? reportType, // 보고서 타입 추가
  }) {
    final dataList = data['data'] as List;
    if (dataList.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final filteredDataList = dataList;
    // 실제 컨텐츠 너비 계산: 칼럼 너비 합 + 칼럼 사이 padding(12px) + 좌우 padding(16px * 2)
    final columnsTotalWidth = columnWidths.values.fold(0.0, (sum, width) => sum + width);
    final columnsSpacing = columnKeys.length > 0 ? (columnKeys.length - 1) * 12.0 : 0.0;
    final horizontalPadding = 32.0; // 좌우 padding
    final totalWidth = columnsTotalWidth + columnsSpacing + horizontalPadding;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final needsHorizontalScroll = totalWidth > screenWidth;
    
    // ============================================================
    // 📱 Codigos/Todocodigos 화면 깨짐 현상 디버깅
    // ============================================================
    // 핸드폰에서 화면 깨짐 현상 원인 파악을 위한 디버깅
    final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
    final isMobilePhone = layoutInfo.isMobilePhone;
    final isMobilePhonePortrait = layoutInfo.isMobilePhonePortrait;
    final isMobilePhoneLandscape = layoutInfo.isMobilePhoneLandscape;
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📱 [Codigos Builder] buildContent 시작');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → isMobilePhone: $isMobilePhone');
    debugPrint('   → isMobilePhonePortrait: $isMobilePhonePortrait');
    debugPrint('   → isMobilePhoneLandscape: $isMobilePhoneLandscape');
    debugPrint('   → screenWidth: $screenWidth');
    debugPrint('   → screenHeight: $screenHeight');
    debugPrint('   → totalWidth: $totalWidth');
    debugPrint('   → needsHorizontalScroll: $needsHorizontalScroll');
    debugPrint('   → dataList.length: ${dataList.length}');
    debugPrint('   → filteredDataList.length: ${filteredDataList.length}');
    debugPrint('   → selectedCodigo != null: ${selectedCodigo != null}');
    debugPrint('   → columnKeys.length: ${columnKeys.length}');
    debugPrint('═══════════════════════════════════════════════════════');

    return Builder(
      builder: (context) {
        // 렌더링 후 실제 크기 측정
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('📱 [Codigos Builder] Column 실제 렌더링 크기');
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
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '추가 데이터 로딩 중...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal[700],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Builder(
            builder: (rowContext) {
              // ============================================================
              // 📱 Codigos/Todocodigos Row 레이아웃 디버깅
              // ============================================================
              // Row 렌더링 후 실제 크기 측정
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final RenderBox? renderBox = rowContext.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  debugPrint('═══════════════════════════════════════════════════════');
                  debugPrint('📱 [Codigos Builder] Row 실제 렌더링 크기');
                  debugPrint('   → Row width: ${renderBox.size.width}');
                  debugPrint('   → Row height: ${renderBox.size.height}');
                  debugPrint('   → 예상 width: $screenWidth');
                  debugPrint('   → 차이: ${renderBox.size.width - screenWidth}');
                  debugPrint('   → selectedCodigo != null: ${selectedCodigo != null}');
                  
                  // Row의 자식들 확인
                  int childIndex = 0;
                  renderBox.visitChildren((child) {
                    if (child is RenderBox) {
                      debugPrint('   → [Row 자식 #$childIndex]');
                      debugPrint('      → width: ${child.size.width}');
                      debugPrint('      → height: ${child.size.height}');
                      debugPrint('      → 타입: ${child.runtimeType}');
                      childIndex++;
                    }
                  });
                  debugPrint('═══════════════════════════════════════════════════════');
                }
              });
              
              return Row(
                children: [
                  // 왼쪽: Codigos 리스트
                  Expanded(
                    flex: selectedCodigo != null ? 1 : 1,
                    child: Builder(
                      builder: (leftExpandedContext) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final RenderBox? renderBox = leftExpandedContext.findRenderObject() as RenderBox?;
                          if (renderBox != null) {
                            debugPrint('📱 [Codigos Builder] 왼쪽 Expanded 실제 크기');
                            debugPrint('   → width: ${renderBox.size.width}');
                            debugPrint('   → height: ${renderBox.size.height}');
                          }
                        });
                        
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: selectedCodigo != null 
                                  ? BorderSide(color: Colors.grey[300]!, width: 1)
                                  : BorderSide.none,
                            ),
                          ),
                          child: needsHorizontalScroll
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.hardEdge,
                              child: SizedBox(
                                width: totalWidth,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 칼럼 헤더 (수평 스크롤과 함께 이동)
                                    SizedBox(
                                      width: totalWidth,
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
                                        itemCount: filteredDataList.length,
                                        itemBuilder: (context, index) {
                                          final codigo = filteredDataList[index] as Map<String, dynamic>;
                                          final codigoId = reportType == ReportType.todocodigos
                                              ? codigo['tcodigo']?.toString()
                                              : codigo['codigo']?.toString();
                                          final isSelected = selectedCodigo != null && 
                                              (reportType == ReportType.todocodigos
                                                  ? selectedCodigo!['tcodigo'] == codigo['tcodigo']
                                                  : selectedCodigo!['codigo'] == codigo['codigo']);
                                          final isEdited = editedCodigoIdentifier != null && 
                                              editedCodigoIdentifier == codigoId;
                                          
                                          return InkWell(
                                            onTap: () => onCodigoSelected(codigo),
                                            onDoubleTap: onCodigoDoubleTap != null ? () => onCodigoDoubleTap!(codigo) : null,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: isEdited 
                                                    ? Colors.green.withOpacity(0.2) // 편집된 항목: 연한 녹색
                                                    : (isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent),
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey[300]!,
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              child: _buildCodigoRow(
                                                codigo: codigo,
                                                columnKeys: columnKeys,
                                                columnWidths: columnWidths,
                                                isSelected: isSelected,
                                                reportColor: reportColor,
                                                editedCodigoIdentifier: editedCodigoIdentifier,
                                                reportType: reportType,
                                              ),
                                            ),
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
                                itemCount: filteredDataList.length,
                                itemBuilder: (context, index) {
                                  final codigo = filteredDataList[index] as Map<String, dynamic>;
                                  final codigoId = codigo['codigo']?.toString() ?? codigo['tcodigo']?.toString();
                                  final isSelected = selectedCodigo != null && 
                                      (selectedCodigo!['codigo'] == codigo['codigo'] || 
                                       selectedCodigo!['tcodigo'] == codigo['tcodigo']);
                                  final isEdited = editedCodigoIdentifier != null && 
                                      editedCodigoIdentifier == codigoId;
                                  
                                  return InkWell(
                                    onTap: () => onCodigoSelected(codigo),
                                    onDoubleTap: onCodigoDoubleTap != null ? () => onCodigoDoubleTap!(codigo) : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isEdited 
                                            ? Colors.green.withOpacity(0.2) // 편집된 항목: 연한 녹색
                                            : (isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent),
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                              child: _buildCodigoRow(
                                                codigo: codigo,
                                                columnKeys: columnKeys,
                                                columnWidths: columnWidths,
                                                isSelected: isSelected,
                                                reportColor: reportColor,
                                                editedCodigoIdentifier: editedCodigoIdentifier,
                                                reportType: reportType,
                                              ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                    );
                  },
                ),
              ),
            ],
          );
            },
          ),
        ),
      ],
    );
      },
    );
  }

  /// Codigos 칼럼 헤더 빌드
  /// [onColumnResize]가 있으면 각 칼럼 오른쪽에 리사이즈 핸들을 표시합니다.
  static Widget buildHeader({
    required ReportType reportType,
    required String? sortColumn,
    required bool sortAscending,
    required Function(String, bool) onSort,
    required Color reportColor,
    required List<String> columnKeys,
    required Map<String, double> columnWidths,
    required Map<String, String> columnDisplayNames,
    void Function(String columnKey, double newWidth)? onColumnResize,
  }) {
    const double resizeHandleWidth = 14.0; // 넓게 해서 잡기 쉽고, 스크롤 제스처와 구분
    const double minColumnWidth = 50.0;
    const double maxColumnWidth = 2000.0; // descripcion 등 긴 텍스트도 넓게 확장 가능

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[400]!,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < columnKeys.length; i++) ...[
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildSortableHeader(
                columnKeys[i],
                columnDisplayNames[columnKeys[i]] ?? columnKeys[i],
                columnWidths[columnKeys[i]] ?? 100.0,
                reportType,
                sortColumn,
                sortAscending,
                onSort,
                reportColor,
              ),
            ),
            if (onColumnResize != null)
              _buildColumnResizeHandle(
                columnKeys[i],
                columnWidths[columnKeys[i]] ?? 100.0,
                resizeHandleWidth,
                (double newWidth) {
                  final clamped = newWidth.clamp(minColumnWidth, maxColumnWidth);
                  onColumnResize(columnKeys[i], clamped);
                },
              ),
          ],
        ],
      ),
    );
  }

  static Widget _buildColumnResizeHandle(
    String columnKey,
    double currentWidth,
    double handleWidth,
    void Function(double newWidth) onResize,
  ) {
    return _ColumnResizeHandle(
      key: ValueKey('resize_$columnKey'),
      currentWidth: currentWidth,
      handleWidth: handleWidth,
      onResize: onResize,
    );
  }

  static Widget _buildSortableHeader(
    String columnKey,
    String displayName,
    double width,
    ReportType reportType,
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
                color: isSorted ? Colors.teal[700] : Colors.black87,
              ),
            ),
            if (isSorted)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: Colors.teal[700],
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildCodigoRow({
    required Map<String, dynamic> codigo,
    required List<String> columnKeys,
    required Map<String, double> columnWidths,
    required bool isSelected,
    required Color reportColor,
    String? editedCodigoIdentifier, // 편집된 codigo 식별자
    ReportType? reportType, // 보고서 타입
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: columnKeys.map((key) {
        final value = codigo[key];
        final width = columnWidths[key] ?? 100.0;
        // codigo, tcodigo 같은 코드 필드는 숫자로 처리하지 않음
        final isCodeColumn = key == 'codigo' || key == 'tcodigo';
        final isNumeric = !isCodeColumn && ReportUtils.isNumeric(value);
        
        // descripcion/tdesc 는 formatValue의 50자 잘림 적용하지 않고 원문 전체 표시
        final isDescColumn = key == 'descripcion' || key == 'tdesc';
        // codigo 칼럼·descripcion/tdesc 는 원본 문자열 그대로, 나머지는 formatValue
        final displayValue = (isCodeColumn || isDescColumn)
            ? (value?.toString() ?? 'N/A')
            : ReportUtils.formatValue(value);
        
        final currentCodigoIdentifier = reportType == ReportType.todocodigos
            ? codigo['tcodigo']?.toString()
            : codigo['codigo']?.toString();
        final isEdited = editedCodigoIdentifier != null && currentCodigoIdentifier == editedCodigoIdentifier;
        final isCodeKey = key == 'codigo' || key == 'tcodigo';
        // descripcion / tdesc 는 생략 없이 전체 표시 (줄 수 제한 없음)
        final maxLines = isDescColumn ? null : 1;
        final overflow = isDescColumn ? TextOverflow.visible : TextOverflow.ellipsis;
        
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: SizedBox(
            width: width,
            child: Text(
              displayValue,
              style: TextStyle(
                fontWeight: isCodeKey ? FontWeight.bold : FontWeight.normal,
                fontSize: isCodeKey ? 14 : 12,
                color: isEdited
                    ? Colors.green[700] // 편집된 항목은 녹색
                    : (isSelected && isCodeKey
                        ? Colors.teal[700]
                        : (isCodeKey ? Colors.black87 : Colors.grey[700])),
              ),
              textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              maxLines: maxLines,
              overflow: overflow,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Codigo 편집 패널 빌드
  static Widget buildEditPanel({
    required Map<String, dynamic> selectedCodigo,
    required Map<String, TextEditingController> editControllers,
    required bool isLoading,
    required Function() onClose,
    required Function() onSave,
    required Color reportColor,
    required Function(String, String, int) buildEditField,
    ReportType? reportType,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Editar Codigo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: reportColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: FocusTraversalGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      // id_codigo 또는 id_todocodigo 표시
                      if (reportType == ReportType.todocodigos && selectedCodigo['id_todocodigo'] != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID Todo Codigo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      selectedCodigo['id_todocodigo']?.toString() ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue[900],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (reportType != ReportType.todocodigos && selectedCodigo['id_codigo'] != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID Codigo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      selectedCodigo['id_codigo']?.toString() ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue[900],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if ((reportType == ReportType.todocodigos && selectedCodigo['id_todocodigo'] != null) ||
                          (reportType != ReportType.todocodigos && selectedCodigo['id_codigo'] != null))
                        const SizedBox(height: 16),
                      // 편집 가능한 필드만 표시
                      if (reportType == ReportType.todocodigos)
                        // Todocodigos: tcodigo, tdesc, tpre1, tpre2, tpre3, tpre4, tpre5, borrado
                        ...(['tcodigo', 'tdesc', 'tpre1', 'tpre2', 'tpre3', 'tpre4', 'tpre5', 'borrado'] as List<String>).where((key) => selectedCodigo.containsKey(key)).toList().asMap().entries.map((entry) {
                          final index = entry.key;
                          final key = entry.value;
                          final displayNames = {
                            'tcodigo': 'T Codigo',
                            'tdesc': 'T Desc',
                            'tpre1': 'T Precio 1',
                            'tpre2': 'T Precio 2',
                            'tpre3': 'T Precio 3',
                            'tpre4': 'T Precio 4',
                            'tpre5': 'T Precio 5',
                            'borrado': 'Borrado',
                          };
                          
                          final displayName = displayNames[key] ?? key;
                          final fieldKey = key;
                          
                          return Column(
                            children: [
                              buildEditField(fieldKey, displayName, index),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList()
                      else
                        // Codigos: codigo, descripcion, pre1, pre2, pre3, pre4, pre5, b_mostrar_vcontrol, borrado
                        ...(['codigo', 'descripcion', 'pre1', 'pre2', 'pre3', 'pre4', 'pre5', 'b_mostrar_vcontrol', 'borrado'] as List<String>).asMap().entries.map((entry) {
                          final index = entry.key;
                          final key = entry.value;
                          // 필드가 없어도 편집 가능한 필드는 표시 (기본값 사용)
                          final displayNames = {
                            'codigo': 'Codigo',
                            'descripcion': 'Descripción',
                            'pre1': 'Precio 1',
                            'pre2': 'Precio 2',
                            'pre3': 'Precio 3',
                            'pre4': 'Precio 4',
                            'pre5': 'Precio 5',
                            'b_mostrar_vcontrol': 'Mostrar VControl',
                            'borrado': 'Borrado',
                          };
                          
                          final displayName = displayNames[key] ?? key;
                          final fieldKey = key;
                          
                          return Column(
                            children: [
                              buildEditField(fieldKey, displayName, index),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      const SizedBox(height: 8),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(999), // 마지막 순서
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : onSave,
                        icon: isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(isLoading ? 'Guardando...' : 'Guardar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: reportColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Codigo 편집 필드 빌드
  static Widget buildEditField({
    required String fieldKey,
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required int order,
    required Function(String) onChanged,
  }) {
    // 숫자 필드 확인 (pre 또는 tpre로 시작하는 경우)
    final isNumericField = fieldKey.startsWith('pre') || fieldKey.startsWith('tpre');
    
    // boolean 필드 확인
    final isBooleanField = fieldKey == 'b_mostrar_vcontrol' || fieldKey == 'borrado';
    
    Widget fieldWidget;
    
    if (isBooleanField) {
      // boolean 필드는 체크박스로 표시
      final boolValue = controller.text.toLowerCase() == 'true' || controller.text == '1';
      fieldWidget = CheckboxListTile(
        title: Text(label),
        value: boolValue,
        onChanged: (value) {
          controller.text = value == true ? '1' : '0';
          onChanged(controller.text);
        },
        controlAffinity: ListTileControlAffinity.leading,
      );
    } else {
      fieldWidget = TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabled: true,
        ),
        keyboardType: isNumericField ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        textInputAction: TextInputAction.next,
        onChanged: onChanged,
        onSubmitted: (_) {
          // Enter 키로 다음 필드로 이동
          if (focusNode.context != null) {
            FocusScope.of(focusNode.context!).nextFocus();
          }
        },
      );
    }
    
    // Tab 순서 지정
    return FocusTraversalOrder(
      order: NumericFocusOrder(order.toDouble()),
      child: fieldWidget,
    );
  }

  /// Todocodigo 수정 데이터를 codigo hijo bulk payload로 변환 (tpre* -> pre*, borrado 등)
  static Map<String, dynamic> _mapTodocodigoDataToCodigoPayload(Map<String, dynamic> todocodigoData) {
    final payload = <String, dynamic>{};
    for (var i = 1; i <= 5; i++) {
      final key = 'tpre$i';
      if (todocodigoData.containsKey(key)) {
        payload['pre$i'] = todocodigoData[key];
      }
    }
    if (todocodigoData.containsKey('borrado')) {
      payload['borrado'] = todocodigoData['borrado'];
    }
    if (todocodigoData.containsKey('liquidacion')) {
      payload['liquidacion'] = todocodigoData['liquidacion'];
    }
    if (todocodigoData.containsKey('promocion')) {
      payload['promocion'] = todocodigoData['promocion'];
    }
    return payload;
  }

  /// Codigo 변경사항 저장 (로깅 포함)
  static Future<Map<String, dynamic>> saveCodigoChanges({
    required DatabaseService databaseService,
    required Map<String, dynamic> selectedCodigo,
    required Map<String, TextEditingController> editControllers,
    ReportType? reportType,
  }) async {
    // 편집된 값들 수집 (편집 가능한 필드만)
    final editableFields = reportType == ReportType.todocodigos
        ? ['tcodigo', 'tdesc', 'tpre1', 'tpre2', 'tpre3', 'tpre4', 'tpre5', 'borrado']
        : ['codigo', 'descripcion', 'pre1', 'pre2', 'pre3', 'pre4', 'pre5', 'b_mostrar_vcontrol', 'borrado'];
    
    final updatedData = <String, dynamic>{};
    for (var entry in editControllers.entries) {
      final key = entry.key;
      
      // 편집 가능한 필드만 포함
      if (!editableFields.contains(key)) {
        continue;
      }
      
      final value = entry.value.text.trim();
      
      // 숫자 필드는 숫자로 변환 시도
      if (key.startsWith('pre') || key.startsWith('tpre')) {
        final numValue = num.tryParse(value);
        if (numValue != null) {
          updatedData[key] = numValue;
        } else if (value.isEmpty) {
          updatedData[key] = null;
        } else {
          updatedData[key] = value;
        }
      } else if (key == 'b_mostrar_vcontrol' || key == 'borrado') {
        // boolean 필드는 1 또는 0으로 변환
        updatedData[key] = (value == '1' || value.toLowerCase() == 'true') ? 1 : 0;
      } else {
        updatedData[key] = value.isEmpty ? null : value;
      }
    }

    if (reportType == ReportType.todocodigos) {
      // Todocodigo 업데이트 요청
      final idTodocodigo = selectedCodigo['id_todocodigo']?.toString();
      
      // id_todocodigo가 없으면 편집 불가
      if (idTodocodigo == null || idTodocodigo.isEmpty) {
        throw Exception('id_todocodigo가 없어서 편집할 수 없습니다.');
      }
      
      final tcodigo = selectedCodigo['tcodigo']?.toString() ?? '';
      
      // MAC 주소 가져오기
      final macAddress = await DeviceInfoHelper.getMacAddress();
      if (macAddress != null && macAddress.isNotEmpty) {
        updatedData['mac'] = macAddress;
        print('📱 MAC 주소: $macAddress');
      } else {
        print('⚠️ MAC 주소를 가져올 수 없습니다.');
      }
      
      // 플랫폼 정보 추가
      final platform = await DeviceInfoHelper.getPlatform();
      updatedData['platform'] = platform;
      print('💻 플랫폼: $platform');
      
      print('📤 TODOCODIGO 업데이트 요청');
      print('   - id_todocodigo: $idTodocodigo');
      print('   - tcodigo: ${tcodigo.isNotEmpty ? tcodigo : "없음"}');
      print('   - 변경된 필드: ${updatedData.length}개');
      print('   - MAC 주소: ${macAddress ?? "없음"}');
      print('   - 플랫폼: $platform');
      
      final response = await databaseService.updateTodocodigo(
        idTodocodigo: idTodocodigo,
        tcodigo: null, // id_todocodigo가 있으면 tcodigo는 사용하지 않음
        updatedData: updatedData,
      );
      
      print('✅ Todocodigo 업데이트 완료');
      // Codigo madre 수정 시 해당하는 모든 codigo hijo 가격·상태 일괄 반영 (codigos 라우터 bulk)
      final payloadForHijos = _mapTodocodigoDataToCodigoPayload(updatedData);
      if (payloadForHijos.isNotEmpty) {
        try {
          await databaseService.updateCodigosByTodocodigo(
            idTodocodigo: idTodocodigo,
            updatedData: payloadForHijos,
          );
          print('✅ Codigos hijos 일괄 업데이트 완료');
        } catch (e, st) {
          print('⚠️ Codigos hijos 일괄 업데이트 실패 (madre는 이미 저장됨): $e');
          print('   $st');
        }
      }
      return response;
    } else {
      // Codigo 업데이트 요청
      final idCodigo = selectedCodigo['id_codigo']?.toString();
      final codigo = selectedCodigo['codigo']?.toString() ?? '';
      
      // MAC 주소 가져오기
      final macAddress = await DeviceInfoHelper.getMacAddress();
      if (macAddress != null && macAddress.isNotEmpty) {
        updatedData['mac'] = macAddress;
        print('📱 MAC 주소: $macAddress');
      } else {
        print('⚠️ MAC 주소를 가져올 수 없습니다.');
      }
      
      // 플랫폼 정보 추가
      final platform = await DeviceInfoHelper.getPlatform();
      updatedData['platform'] = platform;
      print('💻 플랫폼: $platform');
      
      print('📤 CODIGO 업데이트 요청');
      print('   - id_codigo: ${idCodigo ?? "없음"}');
      print('   - codigo: ${codigo.isNotEmpty ? codigo : "없음"}');
      print('   - 변경된 필드: ${updatedData.length}개');
      print('   - MAC 주소: ${macAddress ?? "없음"}');
      print('   - 플랫폼: $platform');
      
      final response = await databaseService.updateCodigo(
        idCodigo: idCodigo,
        codigo: codigo.isNotEmpty ? codigo : null,
        updatedData: updatedData,
      );
      
      print('✅ 업데이트 완료');
      return response;
    }
  }
}

/// 칼럼 너비 리사이즈 핸들 (드래그 시 누적 델타 반영)
class _ColumnResizeHandle extends StatefulWidget {
  final double currentWidth;
  final double handleWidth;
  final void Function(double newWidth) onResize;

  const _ColumnResizeHandle({
    super.key,
    required this.currentWidth,
    required this.handleWidth,
    required this.onResize,
  });

  @override
  State<_ColumnResizeHandle> createState() => _ColumnResizeHandleState();
}

class _ColumnResizeHandleState extends State<_ColumnResizeHandle> {
  double _initialWidth = 0;
  double _initialPointerX = 0;
  bool _isDragging = false;

  @override
  void didUpdateWidget(covariant _ColumnResizeHandle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentWidth != widget.currentWidth && !_isDragging) {
      // 외부에서 너비가 바뀌었을 때만 동기화
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Arrastrar para ajustar ancho',
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          _initialWidth = widget.currentWidth;
          _initialPointerX = e.position.dx;
          _isDragging = true;
        },
        onPointerMove: (e) {
          if (!_isDragging) return;
          final totalDelta = e.position.dx - _initialPointerX;
          widget.onResize(_initialWidth + totalDelta);
        },
        onPointerUp: (_) {
          _isDragging = false;
        },
        onPointerCancel: (_) {
          _isDragging = false;
        },
        child: SizedBox(
          width: widget.handleWidth,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.25),
                borderRadius: BorderRadius.circular(4),
                border: Border(
                  left: BorderSide(color: Colors.grey[500]!, width: 1),
                  right: BorderSide(color: Colors.grey[500]!, width: 1),
                ),
              ),
              child: Icon(
                Icons.drag_indicator,
                size: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

