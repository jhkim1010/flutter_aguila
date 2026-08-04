import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/sucursal_data_filter.dart';
import 'report_screen.dart';
import 'resumen_del_dia_single_sucursal_view.dart';
import 'resumen_del_dia_multiple_sucursales_view.dart';

/// 보기 형식: 카드(지점별/합계) 또는 비교 테이블
enum ResumenViewMode { cards, table }

/// sucursal이 2개 이상일 때 Resumen del Dia의 진입 위젯.
///
/// 기본은 카드 뷰이고 선택은 Total(전 지점 합계)이다. 우측 상단 콤보로 개별
/// 지점을, 토글로 기존 비교 테이블을 고를 수 있다.
///
/// 지점 선택 상태를 여기서 따로 들고 있는 이유: 부모 화면의 _selectedSucursal은
/// getResumenDelDia()의 요청 파라미터로 서버에 전송된다. 카드 필터용으로 겸용하면
/// 지점을 고른 뒤 새로고침할 때 서버 쿼리까지 그 지점으로 좁혀진다.
class ResumenDelDiaMultiSucursalView extends StatefulWidget {
  final Map<String, dynamic> data;
  final DateTime? selectedDate;
  final String serverUrl;
  final Function() onRefresh;
  final Function() onSelectDate;
  final Function(ReportType) onReportTypeSelected;
  final String? errorMessage;

  const ResumenDelDiaMultiSucursalView({
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
  State<ResumenDelDiaMultiSucursalView> createState() =>
      _ResumenDelDiaMultiSucursalViewState();
}

class _ResumenDelDiaMultiSucursalViewState
    extends State<ResumenDelDiaMultiSucursalView> {
  static const String _prefsKey = 'resumen_del_dia_multi_view_mode';

  ResumenViewMode _mode = ResumenViewMode.cards;

  /// null = Total(전 지점 합계). 화면을 다시 열면 항상 Total로 시작한다.
  String? _selectedSucursal;

  @override
  void initState() {
    super.initState();
    _loadSavedMode();
  }

  /// 마지막에 고른 보기 형식을 복원한다. 실패해도 기본값(카드)으로 동작한다.
  Future<void> _loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == ResumenViewMode.table.name && mounted) {
        setState(() => _mode = ResumenViewMode.table);
      }
    } catch (e) {
      debugPrint('⚠️ [MultiSucursal] 보기 형식 복원 실패: $e');
    }
  }

  /// 보기 형식을 바꾸고 저장한다. 저장에 실패해도 전환 자체는 유지한다.
  Future<void> _setMode(ResumenViewMode mode) async {
    setState(() => _mode = mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (e) {
      debugPrint('⚠️ [MultiSucursal] 보기 형식 저장 실패: $e');
    }
  }

  /// 날짜 버튼 우측에 들어갈 컨트롤: 지점 콤보(카드 모드 전용) + 보기 형식 토글
  Widget _buildHeaderControls() {
    final sucursales = SucursalDataFilter.availableSucursales(widget.data);
    final showSelector =
        _mode == ResumenViewMode.cards && sucursales.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 비교 테이블은 전 지점 비교가 목적이므로 테이블 모드에서는 콤보를 숨긴다
        if (showSelector) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButton<String?>(
              value: _selectedSucursal,
              underline: const SizedBox(),
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              style: TextStyle(fontSize: 13, color: Colors.grey[900]),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Total', style: TextStyle(fontSize: 13)),
                ),
                ...sucursales.map(
                  (s) => DropdownMenuItem<String?>(
                    value: s,
                    child: Text('Sucursal $s',
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedSucursal = value);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
        _buildModeToggle(),
      ],
    );
  }

  Widget _buildModeToggle() {
    return ToggleButtons(
      isSelected: [
        _mode == ResumenViewMode.cards,
        _mode == ResumenViewMode.table,
      ],
      onPressed: (index) {
        _setMode(index == 0 ? ResumenViewMode.cards : ResumenViewMode.table);
      },
      borderRadius: BorderRadius.circular(6),
      constraints: const BoxConstraints(minHeight: 34, minWidth: 44),
      selectedColor: Colors.white,
      fillColor: Colors.blue[700],
      color: Colors.grey[700],
      borderColor: Colors.grey[400],
      selectedBorderColor: Colors.blue[700],
      children: const [
        Tooltip(message: 'Tarjetas', child: Icon(Icons.grid_view, size: 18)),
        Tooltip(message: 'Tabla', child: Icon(Icons.table_chart, size: 18)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == ResumenViewMode.table) {
      // 비교 테이블은 전 지점을 함께 보여줘야 하므로 원본 데이터를 그대로 넘긴다
      return ResumenDelDiaMultipleSucursalesView(
        data: widget.data,
        selectedDate: widget.selectedDate,
        serverUrl: widget.serverUrl,
        onRefresh: widget.onRefresh,
        onSelectDate: widget.onSelectDate,
        onReportTypeSelected: widget.onReportTypeSelected,
        headerTrailing: _buildHeaderControls(),
      );
    }

    // Total이면 원본과 동일한 맵이 돌아온다.
    // 단일 지점 뷰의 집계 함수들이 이미 여러 지점 행을 합산하므로 그대로 넘기면 된다.
    final filtered = SucursalDataFilter.filterBySucursal(
      widget.data,
      _selectedSucursal,
    );

    return ResumenDelDiaSingleSucursalView(
      data: filtered,
      selectedDate: widget.selectedDate,
      serverUrl: widget.serverUrl,
      onRefresh: widget.onRefresh,
      onSelectDate: widget.onSelectDate,
      onReportTypeSelected: widget.onReportTypeSelected,
      errorMessage: widget.errorMessage,
      headerTrailing: _buildHeaderControls(),
    );
  }
}
