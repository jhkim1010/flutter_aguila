import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ReportType {
  stocks,
  items,
  clientes,
  gastos,
  ventas,
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

  static String formatValue(dynamic value, {String? fieldName, bool isCurrency = false}) {
    if (value == null) return 'N/A';
    
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

