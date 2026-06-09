import 'package:flutter_test/flutter_test.dart';
import 'package:test_flutter/core/models/calculator_notifier.dart';

void main() {
  test('Lặp dấu bằng với toán hạng âm', () {
    final notifier = CalculatorNotifier();
    notifier.addDigit('2');
    notifier.addOperator('*');
    notifier.addDigit('5');
    notifier.toggleSign();
    print('Trước khi tính toán lần 1: biểu thức = ${notifier.state.pendingExpression}');
    notifier.evaluate(); // 2 * -5 = -10
    
    print('Sau khi tính toán lần 1: kết quả = ${notifier.state.display}');
    print('Toán tử lặp: ${notifier.state.repeatOperator}, toán hạng: ${notifier.state.repeatOperand}');
    
    notifier.evaluate(); // should be -10 * -5 = 50
    print('Hiển thị sau khi lặp: ${notifier.state.display}');
    print('Toán tử lặp: ${notifier.state.repeatOperator}, toán hạng: ${notifier.state.repeatOperand}');
  });
}
