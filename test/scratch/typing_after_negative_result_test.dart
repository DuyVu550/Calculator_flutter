import 'package:flutter_test/flutter_test.dart';
import 'package:test_flutter/core/models/calculator_notifier.dart';

void main() {
  test('Gõ số sau khi kết quả là số âm', () {
    final notifier = CalculatorNotifier();
    notifier.addDigit('2');
    notifier.addOperator('-');
    notifier.addDigit('5');
    notifier.evaluate(); // 2 - 5 = -3
    
    print('Kết quả: ${notifier.state.display}');
    
    notifier.addDigit('9');
    print('Hiển thị sau khi gõ 9: ${notifier.state.display}');
  });
}
