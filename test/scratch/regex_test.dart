// Script kiểm tra hành vi Regex trong Dart
// Chạy bằng lệnh: dart run test/scratch/regex_test.dart

void main() {
  // Regex được dùng trong _getCurrentNumberFrom() sau khi sửa bug
  final regex = RegExp(r'(?:^|(?<=[+\-*/(]))(-?[\d.]+)$');

  final List<String> testExprs = [
    '5',        // → '5'        (số đơn dương)
    '-5',       // → '-5'       (âm đơn ở đầu)
    '2+-5',     // → '-5'       (âm sau toán tử +)
    '2*-5',     // → '-5'       (âm sau toán tử *)
    '12.5',     // → '12.5'     (số thập phân)
    '2+3',      // → '3'        (số sau toán tử)
    '2+',       // → null       (không có số cuối)
    '(5',       // → '5'        (sau ngoặc mở)
  ];

  for (final e in testExprs) {
    final m = regex.firstMatch(e);
    final g1 = m?.group(1);
    print('expr: "$e"  =>  group(1): $g1');
  }

  print('');
  print('--- Test toggleSign logic ---');

  // Mô phỏng toggleSign khi expr = '5'
  {
    final expr = '5';
    final current = regex.firstMatch(expr)?.group(1) ?? '';
    print('expr="$expr", current="$current", startsWith(-): ${current.startsWith('-')}');
  }

  // Mô phỏng toggleSign khi expr = '2+-5' (sau khi đã toggle thành âm)
  {
    final expr = '2+-5';
    final current = regex.firstMatch(expr)?.group(1) ?? '';
    print('expr="$expr", current="$current", startsWith(-): ${current.startsWith('-')}');
  }
}
