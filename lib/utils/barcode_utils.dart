String normalizeBarcodeValue(String? raw) {
  if (raw == null) return '';

  const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
  const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();

  for (final rune in raw.trim().runes) {
    final character = String.fromCharCode(rune);
    final arabicIndex = arabicDigits.indexOf(character);
    if (arabicIndex >= 0) {
      buffer.write(arabicIndex);
      continue;
    }

    final persianIndex = persianDigits.indexOf(character);
    if (persianIndex >= 0) {
      buffer.write(persianIndex);
      continue;
    }

    if (rune == 10 || rune == 13 || rune == 9) continue;
    buffer.write(character);
  }

  return buffer.toString().trim();
}

bool isUsableBarcodeValue(String value) {
  final normalized = normalizeBarcodeValue(value);
  return normalized.isNotEmpty && normalized.length <= 256;
}
