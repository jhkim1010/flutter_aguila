import 'package:flutter/material.dart';
import 'report_utils.dart';

/// 보고서 데이터 UI 빌더
class ReportDataBuilder {
  /// 데이터 카드 빌드
  static Widget buildDataCard(dynamic item) {
    if (item is Map<String, dynamic>) {
      return Container(
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: item.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      ReportUtils.formatValue(entry.value),
                      textAlign: ReportUtils.isNumeric(entry.value) ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        dense: true,
        title: Text(
          item.toString(),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  /// 데이터 맵 빌드
  static Widget buildDataMap(Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.zero,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: buildValueWidget(entry.value),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 값 위젯 빌드
  static Widget buildValueWidget(dynamic value) {
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (value as Map<String, dynamic>).entries.map((entry) {
          final formattedValue = ReportUtils.formatValue(entry.value);
          final isNumeric = ReportUtils.isNumeric(entry.value);
          return Padding(
            padding: EdgeInsets.zero,
            child: Text(
              '${entry.key}: $formattedValue',
              textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      );
    } else if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.asMap().entries.map((entry) {
          final formattedValue = ReportUtils.formatValue(entry.value);
          final isNumeric = ReportUtils.isNumeric(entry.value);
          return Padding(
            padding: EdgeInsets.zero,
            child: Text(
              '${entry.key + 1}. $formattedValue',
              textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      );
    }
    final formattedValue = ReportUtils.formatValue(value);
    final isNumeric = ReportUtils.isNumeric(value);
    return Text(
      formattedValue,
      textAlign: isNumeric ? TextAlign.right : TextAlign.left,
      style: const TextStyle(fontSize: 14),
    );
  }

}

