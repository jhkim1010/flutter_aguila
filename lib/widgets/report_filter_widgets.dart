import 'package:flutter/material.dart';
import 'report_utils.dart';

/// 보고서 필터 UI 위젯 빌더들
/// 상태 변경은 콜백을 통해 처리
class ReportFilterWidgets {
  /// 필터링 단어 입력 필드 (AppBar용)
  static Widget buildFilteringWordField({
    required TextEditingController controller,
    required VoidCallback onChanged,
    Color? textColor,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: textColor ?? Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Buscar...',
        hintStyle: TextStyle(
          color: (textColor ?? Colors.white).withOpacity(0.7),
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: (textColor ?? Colors.white).withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: (textColor ?? Colors.white).withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: textColor ?? Colors.white,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
        filled: true,
        fillColor: (textColor ?? Colors.white).withOpacity(0.1),
      ),
      onChanged: (_) => onChanged(),
    );
  }

  /// Tipo 선택 드롭다운
  static Widget buildTipoSelector({
    required List<Map<String, dynamic>> tiposList,
    required int? selectedTipoId,
    required Function(int?) onChanged,
    required Color reportColor,
  }) {
    // 현재 선택된 값이 items 리스트에 있는지 확인
    final availableIds = tiposList.map((tipo) {
      final id = tipo['id_tipo'] is int 
          ? tipo['id_tipo'] 
          : (tipo['id_tipo'] != null ? int.tryParse(tipo['id_tipo'].toString()) : null) ??
            (tipo['id'] is int ? tipo['id'] : (tipo['id'] != null ? int.tryParse(tipo['id'].toString()) : null));
      return id;
    }).where((id) => id != null).cast<int>().toList();
    
    final validValue = selectedTipoId != null && availableIds.contains(selectedTipoId)
        ? selectedTipoId
        : null;
    
    // items 생성
    final items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(
        value: null,
        child: Text('Todos', style: TextStyle(fontSize: 12)),
      ),
      ...tiposList.map((tipo) {
        // id_tipo 또는 id 필드 확인
        final id = tipo['id_tipo'] is int 
            ? tipo['id_tipo'] 
            : (tipo['id_tipo'] != null ? int.tryParse(tipo['id_tipo'].toString()) : null) ??
              (tipo['id'] is int ? tipo['id'] : (tipo['id'] != null ? int.tryParse(tipo['id'].toString()) : null));
        // tpdesc, tipodesc, tipo_desc, descripcion, nombre, tipo, tipo_nombre 필드 확인
        final nombre = tipo['tpdesc']?.toString() ?? 
                      tipo['tipodesc']?.toString() ?? 
                      tipo['tipo_desc']?.toString() ?? 
                      tipo['descripcion']?.toString() ?? 
                      tipo['nombre']?.toString() ?? 
                      tipo['tipo']?.toString() ?? 
                      tipo['tipo_nombre']?.toString() ??
                      'N/A';
        if (id == null) return null;
        return DropdownMenuItem<int?>(
          value: id,
          child: Text(nombre, style: const TextStyle(fontSize: 12)),
        );
      }).where((item) => item != null).cast<DropdownMenuItem<int?>>(),
    ];
    
    return Tooltip(
      message: 'Filtrar por Tipo',
      child: SizedBox(
        width: 140,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<int?>(
            value: validValue,
            hint: const Text('Tipo', style: TextStyle(fontSize: 12, color: Colors.grey)),
            underline: const SizedBox(),
            isDense: true,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 20),
            selectedItemBuilder: (BuildContext context) {
              return items.map((item) {
                if (item.value == null) {
                  return const Text('Todos', style: TextStyle(fontSize: 12));
                }
                final tipo = tiposList.firstWhere(
                  (t) {
                    final id = t['id_tipo'] is int 
                        ? t['id_tipo'] 
                        : (t['id_tipo'] != null ? int.tryParse(t['id_tipo'].toString()) : null) ??
                          (t['id'] is int ? t['id'] : (t['id'] != null ? int.tryParse(t['id'].toString()) : null));
                    return id == item.value;
                  },
                  orElse: () => <String, dynamic>{},
                );
                
                // tpdesc 필드 확인 (실제 서버 응답 필드명)
                final nombre = tipo['tpdesc']?.toString() ?? 
                               tipo['tipodesc']?.toString() ?? 
                               tipo['tipo_desc']?.toString() ?? 
                               tipo['descripcion']?.toString() ?? 
                               tipo['nombre']?.toString() ?? 
                               tipo['tipo']?.toString() ?? 
                               tipo['tipo_nombre']?.toString() ??
                               'N/A';
                return Text(nombre, style: const TextStyle(fontSize: 12));
              }).toList();
            },
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  /// Temporada 선택 드롭다운
  static Widget buildTemporadaSelector({
    required List<Map<String, dynamic>> temporadasList,
    required int? selectedTemporadaId,
    required Function(int?) onChanged,
    required Color reportColor,
  }) {
    // 현재 선택된 값이 items 리스트에 있는지 확인
    final availableIds = temporadasList.map((temporada) {
      final id = temporada['id_temporada'] is int 
          ? temporada['id_temporada'] 
          : (temporada['id_temporada'] != null ? int.tryParse(temporada['id_temporada'].toString()) : null) ??
            (temporada['id'] is int ? temporada['id'] : (temporada['id'] != null ? int.tryParse(temporada['id'].toString()) : null));
      return id;
    }).where((id) => id != null).cast<int>().toList();
    
    final validValue = selectedTemporadaId != null && availableIds.contains(selectedTemporadaId)
        ? selectedTemporadaId
        : null;
    
    // items 생성
    final items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(
        value: null,
        child: Text('Todos', style: TextStyle(fontSize: 12)),
      ),
      ...temporadasList.map((temporada) {
        // id_temporada 또는 id 필드 확인
        final id = temporada['id_temporada'] is int 
            ? temporada['id_temporada'] 
            : (temporada['id_temporada'] != null ? int.tryParse(temporada['id_temporada'].toString()) : null) ??
              (temporada['id'] is int ? temporada['id'] : (temporada['id'] != null ? int.tryParse(temporada['id'].toString()) : null));
        // temporada_nombre, nombre, temporada 필드 확인
        final nombre = temporada['temporada_nombre']?.toString() ?? 
                      temporada['nombre']?.toString() ?? 
                      temporada['temporada']?.toString() ??
                      'N/A';
        if (id == null) return null;
        return DropdownMenuItem<int?>(
          value: id,
          child: Text(nombre, style: const TextStyle(fontSize: 12)),
        );
      }).where((item) => item != null).cast<DropdownMenuItem<int?>>(),
    ];
    
    return Tooltip(
      message: 'Filtrar por Temporada',
      child: SizedBox(
        width: 140,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<int?>(
            value: validValue,
            hint: const Text('Temporada', style: TextStyle(fontSize: 12, color: Colors.grey)),
            underline: const SizedBox(),
            isDense: true,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 20),
            selectedItemBuilder: (BuildContext context) {
              return items.map((item) {
                if (item.value == null) {
                  return const Text('Todos', style: TextStyle(fontSize: 12));
                }
                final temporada = temporadasList.firstWhere(
                  (t) {
                    final id = t['id_temporada'] is int 
                        ? t['id_temporada'] 
                        : (t['id_temporada'] != null ? int.tryParse(t['id_temporada'].toString()) : null) ??
                          (t['id'] is int ? t['id'] : (t['id'] != null ? int.tryParse(t['id'].toString()) : null));
                    return id == item.value;
                  },
                  orElse: () => <String, dynamic>{},
                );
                final nombre = temporada['temporada_nombre']?.toString() ?? 
                               temporada['nombre']?.toString() ?? 
                               temporada['temporada']?.toString() ??
                               'N/A';
                return Text(nombre, style: const TextStyle(fontSize: 12));
              }).toList();
            },
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  /// Clientes 보고서용 Responsable Ins 선택 드롭다운
  static Widget buildClientesResponsableInsSelector({
    required String? selectedValue,
    required Function(String?) onChanged,
    required Color reportColor,
  }) {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Todos', style: TextStyle(fontSize: 12, color: Colors.white)),
      ),
      const DropdownMenuItem<String?>(
        value: 'Responsable Ins',
        child: Text('Responsable Ins', style: TextStyle(fontSize: 12, color: Colors.white)),
      ),
      const DropdownMenuItem<String?>(
        value: 'Monotributista',
        child: Text('Monotributista', style: TextStyle(fontSize: 12, color: Colors.white)),
      ),
      const DropdownMenuItem<String?>(
        value: 'Sin Rubro',
        child: Text('Sin Rubro', style: TextStyle(fontSize: 12, color: Colors.white)),
      ),
    ];
    
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: DropdownButton<String?>(
          value: selectedValue,
          hint: const Text('Responsable', style: TextStyle(fontSize: 12, color: Colors.white70)),
          underline: const SizedBox(),
          isDense: true,
          isExpanded: true,
          dropdownColor: reportColor,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
          style: const TextStyle(fontSize: 12, color: Colors.white),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Clientes 보고서용 Provincias 선택 드롭다운
  static Widget buildClientesProvinciaSelector({
    required String? selectedValue,
    required Function(String?) onChanged,
    required Color reportColor,
  }) {
    // 아르헨티나 23개 주 + CABA + Otro Países
    final provincias = [
      'Buenos Aires',
      'Catamarca',
      'Chaco',
      'Chubut',
      'Córdoba',
      'Corrientes',
      'Entre Ríos',
      'Formosa',
      'Jujuy',
      'La Pampa',
      'La Rioja',
      'Mendoza',
      'Misiones',
      'Neuquén',
      'Río Negro',
      'Salta',
      'San Juan',
      'San Luis',
      'Santa Cruz',
      'Santa Fe',
      'Santiago del Estero',
      'Tierra del Fuego',
      'Tucumán',
      'CABA',
      'Otro Países',
    ];
    
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Todas', style: TextStyle(fontSize: 12, color: Colors.white)),
      ),
      ...provincias.map((provincia) {
        return DropdownMenuItem<String?>(
          value: provincia,
          child: Text(provincia, style: const TextStyle(fontSize: 12, color: Colors.white)),
        );
      }),
    ];
    
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: DropdownButton<String?>(
          value: selectedValue,
          hint: const Text('Provincia', style: TextStyle(fontSize: 12, color: Colors.white70)),
          underline: const SizedBox(),
          isDense: true,
          isExpanded: true,
          dropdownColor: reportColor,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
          style: const TextStyle(fontSize: 12, color: Colors.white),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Clientes 보고서용 Deudores 체크박스
  static Widget buildClientesDeudoresCheckbox({
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (bool? newValue) => onChanged(newValue ?? false),
          checkColor: Colors.white,
          fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white.withOpacity(0.3);
            }
            return Colors.transparent;
          }),
        ),
        const Text(
          'Deudores',
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
      ],
    );
  }

  /// Clientes 보고서용 Reservadores 체크박스
  static Widget buildClientesReservadoresCheckbox({
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (bool? newValue) => onChanged(newValue ?? false),
          checkColor: Colors.white,
          fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white.withOpacity(0.3);
            }
            return Colors.transparent;
          }),
        ),
        const Text(
          'Reservadores',
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
      ],
    );
  }

  /// 지점 선택 드롭다운 (AppBar용)
  static Widget buildSucursalSelector({
    required String? selectedSucursal,
    required List<String>? availableSucursales,
    required Function(String?) onChanged,
    required Color reportColor,
  }) {
    debugPrint('🔍 [ReportFilterWidgets.buildSucursalSelector] 호출됨');
    debugPrint('   → selectedSucursal: $selectedSucursal');
    debugPrint('   → availableSucursales: $availableSucursales');
    debugPrint('   → reportColor: $reportColor');
    
    return SizedBox(
      width: 140,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButton<String?>(
          value: selectedSucursal,
          hint: const Text('Todos', style: TextStyle(fontSize: 12, color: Colors.black87)),
          underline: const SizedBox(),
          isDense: true,
          isExpanded: false,
          icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 20),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          dropdownColor: Colors.white,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todos', style: TextStyle(fontSize: 12, color: Colors.black87)),
            ),
            if (availableSucursales != null)
              ...availableSucursales.map((sucursal) {
                debugPrint('   → DropdownMenuItem 생성: Sucursal $sucursal');
                return DropdownMenuItem<String?>(
                  value: sucursal,
                  child: Text('Sucursal $sucursal', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                );
              }),
          ],
          onChanged: (String? value) {
            debugPrint('   → 콤보박스 값 변경: $value');
            onChanged(value);
          },
        ),
      ),
    );
  }
}

