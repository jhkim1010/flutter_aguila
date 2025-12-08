import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'report_utils.dart';

/// Codigos 보고서 UI 빌더
class CodigosBuilder {
  /// Codigos 콘텐츠 빌드
  static Widget buildContent({
    required Map<String, dynamic> data,
    required BuildContext context,
    required ScrollController scrollController,
    required Map<String, dynamic>? selectedCodigo,
    required Function(Map<String, dynamic>) onCodigoSelected,
    required bool isLoadingMore,
    required Color reportColor,
    required List<String> columnKeys,
    required Map<String, double> columnWidths,
    required Widget headerWidget,
  }) {
    final dataList = data['data'] as List;
    if (dataList.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final filteredDataList = dataList;
    final totalWidth = columnWidths.values.fold(0.0, (sum, width) => sum + width) + (columnKeys.length * 12);
    final screenWidth = MediaQuery.of(context).size.width;
    final needsHorizontalScroll = totalWidth > screenWidth;

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
          child: Row(
            children: [
              // 왼쪽: Codigos 리스트
              Expanded(
                flex: selectedCodigo != null ? 1 : 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: selectedCodigo != null 
                          ? BorderSide(color: Colors.grey[300]!, width: 1)
                          : BorderSide.none,
                    ),
                  ),
                  child: needsHorizontalScroll
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: totalWidth,
                            child: Column(
                              children: [
                                // 칼럼 헤더 (수평 스크롤과 함께 이동)
                                SizedBox(
                                  width: totalWidth,
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
                                      final isSelected = selectedCodigo != null && 
                                          selectedCodigo!['codigo'] == codigo['codigo'];
                                      
                                      return InkWell(
                                        onTap: () => onCodigoSelected(codigo),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey[300]!,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: columnKeys.map((key) {
                                              final value = codigo[key];
                                              final width = columnWidths[key] ?? 100.0;
                                              // codigo, tcodigo 같은 코드 필드는 숫자로 처리하지 않음
                                              final isCodeColumn = key == 'codigo' || key == 'tcodigo';
                                              final isNumeric = !isCodeColumn && ReportUtils.isNumeric(value);
                                              
                                              // codigo 칼럼은 원본 문자열 그대로 표시 (포맷팅 없이)
                                              final displayValue = isCodeColumn 
                                                  ? (value?.toString() ?? 'N/A')
                                                  : ReportUtils.formatValue(value);
                                              
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 12),
                                                child: SizedBox(
                                                  width: width,
                                                  child: Text(
                                                    displayValue,
                                                    style: TextStyle(
                                                      fontWeight: key == 'codigo' ? FontWeight.bold : FontWeight.normal,
                                                      fontSize: key == 'codigo' ? 14 : 12,
                                                      color: isSelected && key == 'codigo' 
                                                          ? Colors.teal[700] 
                                                          : (key == 'codigo' ? Colors.black87 : Colors.grey[700]),
                                                    ),
                                                    textAlign: isNumeric ? TextAlign.right : TextAlign.left,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(
                          width: screenWidth,
                          child: Column(
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
                                    final isSelected = selectedCodigo != null && 
                                        selectedCodigo!['codigo'] == codigo['codigo'];
                                    
                                    return InkWell(
                                      onTap: () => onCodigoSelected(codigo),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: columnKeys.map((key) {
                                            final value = codigo[key];
                                            final width = columnWidths[key] ?? 100.0;
                                            // codigo, tcodigo 같은 코드 필드는 숫자로 처리하지 않음
                                            final isCodeColumn = key == 'codigo' || key == 'tcodigo';
                                            final isNumeric = !isCodeColumn && ReportUtils.isNumeric(value);
                                            
                                            // codigo 칼럼은 원본 문자열 그대로 표시 (포맷팅 없이)
                                            final displayValue = isCodeColumn 
                                                ? (value?.toString() ?? 'N/A')
                                                : ReportUtils.formatValue(value);
                                            
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 12),
                                              child: SizedBox(
                                                width: width,
                                                child: Text(
                                                  displayValue,
                                                  style: TextStyle(
                                                    fontWeight: key == 'codigo' ? FontWeight.bold : FontWeight.normal,
                                                    fontSize: key == 'codigo' ? 14 : 12,
                                                    color: isSelected && key == 'codigo' 
                                                        ? Colors.teal[700] 
                                                        : (key == 'codigo' ? Colors.black87 : Colors.grey[700]),
                                                  ),
                                                  textAlign: isNumeric ? TextAlign.right : TextAlign.left,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  },
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
      ],
    );
  }
                      child: Column(
                        children: [
                          // 칼럼 헤더 (수평 스크롤과 함께 이동)
                          SizedBox(
                            width: totalWidth,
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
                                final isSelected = selectedCodigo != null && 
                                    selectedCodigo!['codigo'] == codigo['codigo'];
                                
                                return InkWell(
                                  onTap: () => onCodigoSelected(codigo),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: columnKeys.map((key) {
                                        final value = codigo[key];
                                        final width = columnWidths[key] ?? 100.0;
                                        // codigo, tcodigo 같은 코드 필드는 숫자로 처리하지 않음
                                        final isCodeColumn = key == 'codigo' || key == 'tcodigo';
                                        final isNumeric = !isCodeColumn && ReportUtils.isNumeric(value);
                                        
                                        // codigo 칼럼은 원본 문자열 그대로 표시 (포맷팅 없이)
                                        final displayValue = isCodeColumn 
                                            ? (value?.toString() ?? 'N/A')
                                            : ReportUtils.formatValue(value);
                                        
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 12),
                                          child: SizedBox(
                                            width: width,
                                            child: Text(
                                              displayValue,
                                              style: TextStyle(
                                                fontWeight: key == 'codigo' ? FontWeight.bold : FontWeight.normal,
                                                fontSize: key == 'codigo' ? 14 : 12,
                                                color: isSelected && key == 'codigo' 
                                                    ? Colors.teal[700] 
                                                    : (key == 'codigo' ? Colors.black87 : Colors.grey[700]),
                                              ),
                                              textAlign: isNumeric ? TextAlign.right : TextAlign.left,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Codigos 칼럼 헤더 빌드
  static Widget buildHeader({
    required ReportType reportType,
    required String? sortColumn,
    required bool sortAscending,
    required Function(String, bool) onSort,
    required Color reportColor,
    required List<String> columnKeys,
    required Map<String, double> columnWidths,
    required Map<String, String> columnDisplayNames,
  }) {
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
        children: columnKeys.map((key) {
          final width = columnWidths[key] ?? 100.0;
          final displayName = columnDisplayNames[key] ?? key;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildSortableHeader(
              key, 
              displayName, 
              width, 
              reportType, 
              sortColumn, 
              sortAscending, 
              onSort, 
              reportColor
            ),
          );
        }).toList(),
      ),
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

  /// Codigo 편집 패널 빌드
  static Widget buildEditPanel({
    required Map<String, dynamic> selectedCodigo,
    required Map<String, TextEditingController> editControllers,
    required bool isLoading,
    required Function() onClose,
    required Function() onSave,
    required Color reportColor,
    required Function(String, String) buildEditField,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // id_codigo 표시
                      if (selectedCodigo['id_codigo'] != null)
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
                      if (selectedCodigo['id_codigo'] != null) const SizedBox(height: 16),
                      // 모든 필드를 동적으로 표시 (id_codigo 제외)
                      ...selectedCodigo.keys.where((key) => key != 'id_codigo').map((key) {
                        // 필드 표시 이름 매핑
                        final displayNames = {
                          'codigo': 'Codigo',
                          'descripcion': 'Descripción',
                          'pre1': 'Precio 1',
                          'pre2': 'Precio 2',
                          'pre3': 'Precio 3',
                          'pre4': 'Precio 4',
                          'pre5': 'Precio 5',
                          'preorg': 'Precio Org',
                          'tcodigo': 'T Codigo',
                          'borrado': 'Borrado',
                          'b_sincronizar_x_web': 'Sincronizar Web',
                          'id_woocommerce': 'ID WooCommerce',
                          'id_woocommerce_producto': 'ID WooCommerce Producto',
                        };
                        
                        final displayName = displayNames[key] ?? key;
                        final fieldKey = key;
                        
                        return Column(
                          children: [
                            buildEditField(fieldKey, displayName),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
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
                    ],
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
    required Function(String) onChanged,
  }) {
    // 숫자 필드 확인 (pre로 시작하거나, borrado, id_로 시작하거나, tcodigo인 경우)
    final isNumericField = fieldKey.startsWith('pre') || 
                           fieldKey == 'borrado' || 
                           fieldKey.startsWith('id_') ||
                           fieldKey == 'tcodigo';
    
    // boolean 필드 확인
    final isBooleanField = fieldKey == 'b_sincronizar_x_web' || fieldKey == 'borrado';
    
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        enabled: true,
      ),
      keyboardType: isNumericField ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
    );
  }

  /// Codigo 변경사항 저장 (로깅 포함)
  static Future<Map<String, dynamic>> saveCodigoChanges({
    required DatabaseService databaseService,
    required Map<String, dynamic> selectedCodigo,
    required Map<String, TextEditingController> editControllers,
  }) async {
    // 편집된 값들 수집
    final updatedData = <String, dynamic>{};
    for (var entry in editControllers.entries) {
      final key = entry.key;
      
      // tcodigo는 전송하지 않음
      if (key == 'tcodigo') {
        continue;
      }
      
      final value = entry.value.text.trim();
      
      // 숫자 필드는 숫자로 변환 시도
      if (key.startsWith('pre') || key == 'borrado' || key.startsWith('id_')) {
        final numValue = num.tryParse(value);
        if (numValue != null) {
          updatedData[key] = numValue;
        } else if (value.isEmpty) {
          updatedData[key] = null;
        } else {
          updatedData[key] = value;
        }
      } else {
        updatedData[key] = value.isEmpty ? null : value;
      }
    }

    // 서버에 업데이트 요청
    final idCodigo = selectedCodigo['id_codigo']?.toString();
    final codigo = selectedCodigo['codigo']?.toString() ?? '';
    
    // id_codigo는 URL에 포함되므로 바디에는 포함하지 않음
    
    print('📤 CODIGO 업데이트 요청');
    print('   - id_codigo: ${idCodigo ?? "없음"}');
    print('   - codigo: ${codigo.isNotEmpty ? codigo : "없음"}');
    print('   - 변경된 필드: ${updatedData.length}개');
    
    final response = await databaseService.updateCodigo(
      idCodigo: idCodigo,
      codigo: codigo.isNotEmpty ? codigo : null,
      updatedData: updatedData,
    );
    
    print('✅ 업데이트 완료');

    return response;
  }
}

