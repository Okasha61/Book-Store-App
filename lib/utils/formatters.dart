/// 1499 -> "Rs. 1,499"
String formatPrice(num value) => 'Rs. ${_group(value.round())}';

/// 12400 -> "12.4k", 950 -> "950"
String formatCount(int n) {
  if (n >= 1000000) return '${_trim(n / 1000000)}M';
  if (n >= 1000) return '${_trim(n / 1000)}k';
  return '$n';
}

String formatRating(double value) => value.toStringAsFixed(1);

String _trim(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String _group(int n) {
  final digits = n.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return n < 0 ? '-$buffer' : buffer.toString();
}
