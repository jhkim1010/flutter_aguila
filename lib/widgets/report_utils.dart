import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/config_service.dart';

enum ReportType {
  stocks,
  items,
  clientes,
  gastos,
  ventas,
  fventas,
  alertas,
  codigos,
  todocodigos,
  ingresos,
}

class ReportUtils {
  static String getReportTitle(ReportType reportType) {
    switch (reportType) {
      case ReportType.stocks:
        return 'Stocks';
      case ReportType.items:
        return 'Items';
      case ReportType.clientes:
        return 'Clientes';
      case ReportType.gastos:
        return 'Gastos';
      case ReportType.ventas:
        return 'Ventas';
      case ReportType.fventas:
        return 'FVentas';
      case ReportType.alertas:
        return 'Alertas';
      case ReportType.codigos:
        return 'Codigos';
      case ReportType.todocodigos:
        return 'Todo Codigos';
      case ReportType.ingresos:
        return 'Ingresos';
    }
  }

  static IconData getReportIcon(ReportType reportType) {
    switch (reportType) {
      case ReportType.stocks:
        return Icons.warehouse;
      case ReportType.items:
        return Icons.inventory_2;
      case ReportType.clientes:
        return Icons.people;
      case ReportType.gastos:
        return Icons.receipt_long;
      case ReportType.ventas:
        return Icons.shopping_cart;
      case ReportType.fventas:
        return Icons.receipt;
      case ReportType.alertas:
        return Icons.notifications;
      case ReportType.codigos:
        return Icons.qr_code;
      case ReportType.todocodigos:
        return Icons.qr_code_scanner;
      case ReportType.ingresos:
        return Icons.trending_up;
    }
  }

  static Color getReportColor(ReportType reportType) {
    switch (reportType) {
      case ReportType.stocks:
        return Colors.orange;
      case ReportType.items:
        return Colors.green;
      case ReportType.clientes:
        return Colors.purple;
      case ReportType.gastos:
        return Colors.red;
      case ReportType.ventas:
        return Colors.blue;
      case ReportType.fventas:
        return Colors.deepPurple;
      case ReportType.alertas:
        return Colors.amber;
      case ReportType.codigos:
        return Colors.teal;
      case ReportType.todocodigos:
        return Colors.cyan;
      case ReportType.ingresos:
        return Colors.indigo;
    }
  }

  static bool isNumeric(dynamic value) {
    if (value == null) return false;
    if (value is num) return true;
    if (value is String) {
      return double.tryParse(value) != null || int.tryParse(value) != null;
    }
    return false;
  }

  static String formatValue(dynamic value, {String? fieldName, bool isCurrency = false, ReportType? reportType}) {
    if (value == null) return 'N/A';
    
    // showTpago가 false이고 ventas 보고서인 경우 금액을 ****로 표시
    if (reportType == ReportType.ventas) {
      final configService = ConfigService();
      final ventasConfig = configService.getVentasConfig();
      final shouldHideAmount = ventasConfig?['showTpago'] == false;
      
      if (shouldHideAmount) {
        // 금액 필드인 경우에만 숨김 (갯수 필드는 제외)
        if (isCurrency || (fieldName != null && isAmountField(fieldName))) {
          return '****';
        }
      }
    }
    
    if (value is num) {
      return NumberFormat('#,###').format(value);
    }
    if (value is DateTime) {
      return DateFormat('yyyy-MM-dd HH:mm').format(value);
    }
    if (value is String) {
      String cleanedValue = value.replaceAll('\$', '').trim();
      
      final numValue = num.tryParse(cleanedValue.replaceAll(',', ''));
      if (numValue != null) {
        // 숫자 문자열인 경우에도 금액 숨김 처리 (ventas 보고서만)
        if (reportType == ReportType.ventas) {
          final configService = ConfigService();
          final ventasConfig = configService.getVentasConfig();
          final shouldHideAmount = ventasConfig?['showTpago'] == false;
          
          if (shouldHideAmount && (isCurrency || (fieldName != null && isAmountField(fieldName)))) {
            return '****';
          }
        }
        return NumberFormat('#,###').format(numValue);
      }
      
      if (cleanedValue.length > 50) {
        return '${cleanedValue.substring(0, 50)}...';
      }
      
      return cleanedValue;
    }
    String strValue = value.toString();
    return strValue.replaceAll('\$', '').trim();
  }

  /// 합계 행(맨 마지막 줄)용 포맷: showTpago == false 이면 금액 칸은 **** 표시 (ventas 포함 모든 테이블)
  static String formatValueForTotalRow(dynamic value, String? fieldName) {
    final configService = ConfigService();
    final ventasConfig = configService.getVentasConfig();
    if (ventasConfig?['showTpago'] == false && fieldName != null && isAmountField(fieldName)) {
      return '****';
    }
    return formatValue(
      value,
      fieldName: fieldName,
      isCurrency: fieldName != null && isAmountField(fieldName),
    );
  }
  
  /// 필드명이 금액 필드인지 확인 (갯수 필드는 제외)
  static bool isAmountField(String? fieldName) {
    if (fieldName == null) return false;
    final keyLower = fieldName.toLowerCase();
    
    // 금액 관련 키워드 (갯수 관련 키워드 제외)
    final amountKeywords = ['costo', 'importe', 'ingreso', 'precio', 'pre', 'venta', 'total', 'pago', 'efectivo', 'credito', 'banco', 'favor', 'reservado', 'offset'];
    final countKeywords = ['cantidad', 'count', 'prendas', 'ropas', 'items', 'event'];
    
    // 갯수 관련 키워드가 포함되어 있으면 금액 필드가 아님
    if (countKeywords.any((keyword) => keyLower.contains(keyword))) {
      return false;
    }
    
    // 금액 관련 키워드가 포함되어 있으면 금액 필드
    return amountKeywords.any((keyword) => keyLower.contains(keyword));
  }

  static Widget buildTextWidget(String text, {bool isNumeric = false}) {
    return Text(
      text,
      textAlign: isNumeric ? TextAlign.right : TextAlign.left,
      style: const TextStyle(fontSize: 16),
    );
  }

  static Map<String, String> getStocksFieldNames(bool isResumida) {
    if (isResumida) {
      return {
        'tcode': 'Código',
        'tdesc': 'Descripción',
        'first_date': 'Primera Fecha',
        'last_date': 'Última Fecha',
        'pre1': 'Precio 1',
        'pre2': 'Precio 2',
        'pre3': 'Precio 3',
        'pre4': 'Precio 4',
        'pre5': 'Precio 5',
        'totaling3': 'Total Ingreso',
        'totalventa3': 'Total Venta',
        'todaying3': 'Ingreso Hoy',
        'todayvnt3': 'Venta Hoy',
        'totalreservado3': 'Total Reservado',
        'cntoffset3': 'Cnt Offset',
        'stockreal3': 'Stock Real',
        'porcentaje': 'Porcentaje',
        'sucursal': 'Sucursal',
        'ref_id_todocodigo': 'Ref ID',
      };
    } else {
      return {
        'codigo': 'Código',
        'descripcion': 'Descripción',
        'first_date': 'Primera Fecha',
        'last_date': 'Última Fecha',
        'pre1': 'Precio 1',
        'pre2': 'Precio 2',
        'pre3': 'Precio 3',
        'pre4': 'Precio 4',
        'pre5': 'Precio 5',
        'totaling': 'Total Ingreso',
        'totalventa': 'Total Venta',
        'todayingreso': 'Ingreso Hoy',
        'todayventa': 'Venta Hoy',
        'totalreservado': 'Total Reservado',
        'cntoffset': 'Cnt Offset',
        'stockreal': 'Stock Real',
        'porcentaje': 'Porcentaje',
        'sucursal': 'Sucursal',
        'id_codigo1': 'ID Código',
      };
    }
  }

  /// bcolorview 값이 활성화되었는지 확인
  /// bcolorview가 '1', true, 또는 1이면 true 반환 (todocodigos 테이블 데이터 사용)
  /// 그 외의 경우 false 반환 (vdetalle 테이블 데이터 사용)
  static bool isBcolorviewEnabled(dynamic bcolorview) {
    if (bcolorview == null) return false;
    if (bcolorview == true) return true;
    if (bcolorview == false) return false;
    if (bcolorview == 1) return true;
    if (bcolorview == 0) return false;
    if (bcolorview == '1') return true;
    if (bcolorview == '0') return false;
    if (bcolorview.toString().toLowerCase() == 'true') return true;
    if (bcolorview.toString().toLowerCase() == 'false') return false;
    return false;
  }
}

