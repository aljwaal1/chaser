import 'package:flutter_test/flutter_test.dart';
import 'package:offline_barcode_cashier_camera_fix/utils/barcode_utils.dart';

void main() {
  group('normalizeBarcodeValue', () {
    test('trims scanner line endings', () {
      expect(normalizeBarcodeValue('  123456789\r\n'), '123456789');
    });

    test('converts Arabic and Persian digits', () {
      expect(normalizeBarcodeValue('٠١٢٣٤٥٦٧٨٩'), '0123456789');
      expect(normalizeBarcodeValue('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    });

    test('keeps alphanumeric Code 128 values', () {
      expect(normalizeBarcodeValue('ABC-123 xyz'), 'ABC-123 xyz');
    });
  });

  group('isUsableBarcodeValue', () {
    test('rejects empty values', () {
      expect(isUsableBarcodeValue('   '), isFalse);
    });

    test('accepts normal retail barcodes', () {
      expect(isUsableBarcodeValue('5901234123457'), isTrue);
    });
  });
}
