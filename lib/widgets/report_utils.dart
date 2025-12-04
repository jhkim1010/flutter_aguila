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

  static String formatValue(dynamic value) {
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
}

