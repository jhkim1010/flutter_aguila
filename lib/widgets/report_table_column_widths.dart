// Column width constants and helpers shared between header and data row builders.

/// Single source of truth for fallback column widths.
/// Both buildHeaderRow and _buildDataRowFromMap must use this map.
const Map<String, double> kReportDefaultColumnWidths = {
  // Items
  'codigo1': 300, 'desc1': 200, 'ProductName': 400,
  'totalCantidad': 156, 'CategoryCode': 150, 'CompanyCode': 150,
  'tprendas': 100, 'timporte': 120,
  // Ingresos
  'codigo': 180, 'descripcion': 200, 'tevent': 100,
  'tcant': 120, 'tIngreso': 120, 'tingreso': 120,
  'cntEvent': 100, 'cntevent': 100,
  // Alertas — agreed values for header AND data rows
  'fecha': 60, 'hora': 50, 'evento': 1000,
  'progname': 75, 'alerta': 40, 'sucursal': 80,
  // Ventas
  'eventcount': 340, 'eventCount': 340,
  'tvents': 425, 'tVents': 425,
  'tventas': 425, 'tVentas': 425,
  'tcntropas': 340, 'tCntRopas': 340,
  'tefectivo': 306, 'tcredito': 306, 'tbanco': 306,
  'treservado': 306, 'tfavor': 255,
  'month': 204, 'year': 204, 'nencargado': 120,
};

/// Resolves a column width for [key] from [widths], with case-insensitive
/// fallback lookups. Returns [fallback] if nothing matches.
double resolveColumnWidth(
  String key,
  Map<String, double> widths, {
  double fallback = 150.0,
}) {
  final kl = key.toLowerCase();
  return widths[key] ??
      widths[kl] ??
      (kl == 'eventcount' ? widths['eventCount'] : null) ??
      (kl == 'tvents' ? widths['tVents'] : null) ??
      (kl == 'tventas' ? widths['tVentas'] : null) ??
      (kl == 'tcntropas' ? widths['tCntRopas'] : null) ??
      fallback;
}

/// Width for the SizedBox **inside a header Row cell**.
/// Headers are plain Row children (no DataCell padding), so ventas adds +32
/// to visually match a DataCell child that would get +16px on each side.
double headerCellWidth(
  double base, {
  required bool isAlertas,
  required bool isVentas,
  required bool useMeasuredWidths,
}) {
  if (useMeasuredWidths) return base;
  if (isAlertas) return base + 2.0;
  if (isVentas) return base + 32.0;
  return base;
}

/// Width for the SizedBox **inside a DataCell**.
/// DataCell adds 16px padding on each side automatically.
/// For measured widths on items/ingresos the measured value already includes
/// that padding, so we subtract it back out.
double dataCellWidth(
  double base, {
  required bool isAlertas,
  required bool isVentas,
  required bool isItemsOrIngresos,
  required bool useMeasuredWidths,
}) {
  if (useMeasuredWidths) {
    if (isItemsOrIngresos) return (base - 32.0).clamp(20.0, double.infinity);
    return base;
  }
  if (isAlertas) return base + 2.0;
  if (isVentas) return base; // DataCell's own 16+16 px accounts for the +32
  return base;
}
