import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/resizable_data_table.dart';

void main() {
  group('TableColumnDef', () {
    test('기본값이 올바르게 설정된다', () {
      const col = TableColumnDef(
        key: 'test',
        label: 'Test',
        defaultWidth: 100,
      );
      expect(col.minWidth, 50.0);
      expect(col.maxWidth, 2000.0);
      expect(col.textAlign, TextAlign.left);
      expect(col.sortable, false);
    });

    test('커스텀 값이 올바르게 설정된다', () {
      const col = TableColumnDef(
        key: 'price',
        label: 'Precio',
        defaultWidth: 80,
        minWidth: 40,
        maxWidth: 300,
        textAlign: TextAlign.right,
        sortable: true,
      );
      expect(col.key, 'price');
      expect(col.textAlign, TextAlign.right);
      expect(col.sortable, true);
    });
  });
}
