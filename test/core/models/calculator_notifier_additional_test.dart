import 'package:flutter_test/flutter_test.dart';
import 'package:test_flutter/core/models/calculator_notifier.dart';
import 'dart:math' as math;

void main() {
  late CalculatorNotifier notifier;

  setUp(() {
    notifier = CalculatorNotifier();
  });

  group('CalculatorNotifier - Các trường hợp biên bổ sung', () {
    test('Nhập số ngẫu nhiên thêm một token số', () {
      notifier.insertRandom();
      final display = notifier.state.display;
      expect(double.tryParse(display), isNotNull);
    });

    test('Hàm khoa học - trường hợp hợp lệ và lỗi của tan', () {
      // tan hợp lệ ở chế độ độ (ví dụ: 45 độ)
      notifier.addDigit('4');
      notifier.addDigit('5');
      notifier.applyScientificFunction('tan');
      // Chuyển display thành double để so sánh
      final tanResult = double.parse(notifier.state.display);
      expect(tanResult, closeTo(math.tan(45 * math.pi / 180), 1e-7));

      // Trường hợp lỗi: tan(90) độ sẽ báo lỗi
      notifier.clearAll();
      notifier.addDigit('9');
      notifier.addDigit('0');
      notifier.applyScientificFunction('tan');
      expect(notifier.state.error, contains('Lỗi'));
    });

    test('Hàm khoa học - xử lý lỗi cho ln và log10', () {
      // ln của số dương
      notifier.addDigit('2');
      notifier.applyScientificFunction('ln');
      final lnResult = double.parse(notifier.state.display);
      expect(lnResult, closeTo(math.log(2), 1e-7));

      // ln của số 0 -> báo lỗi
      notifier.clearAll();
      notifier.addDigit('0');
      notifier.applyScientificFunction('ln');
      expect(notifier.state.error, contains('Lỗi'));

      // log10 của số dương
      notifier.clearAll();
      notifier.addDigit('1');
      notifier.addDigit('0');
      notifier.applyScientificFunction('log10');
      final logResult = double.parse(notifier.state.display);
      expect(logResult, closeTo(math.log(10) / math.ln10, 1e-7));

      // log10 của số âm -> báo lỗi
      notifier.clearAll();
      notifier.addDigit('-');
      notifier.addDigit('5');
      notifier.applyScientificFunction('log10');
      expect(notifier.state.error, contains('Lỗi'));
    });

    test('Hàm khoa học - sinh, cosh, tanh', () {
      notifier.addDigit('1');
      notifier.applyScientificFunction('sinh');
      final sinhResult = double.parse(notifier.state.display);
      expect(sinhResult, closeTo((math.exp(1) - math.exp(-1)) / 2, 1e-7));

      notifier.clearAll();
      notifier.addDigit('2');
      notifier.applyScientificFunction('cosh');
      final coshResult = double.parse(notifier.state.display);
      expect(coshResult, closeTo((math.exp(2) + math.exp(-2)) / 2, 1e-7));

      notifier.clearAll();
      notifier.addDigit('3');
      notifier.applyScientificFunction('tanh');
      final tanhResult = double.parse(notifier.state.display);
      expect(tanhResult, closeTo(((math.exp(3) - math.exp(-3)) / 2) / ((math.exp(3) + math.exp(-3)) / 2), 1e-7));
    });

    test('Hàm khoa học - cbrt, cube, nghịch đảo, exp, pow10', () {
      notifier.addDigit('2');
      notifier.applyScientificFunction('cbrt');
      final cbrtResult = double.parse(notifier.state.display);
      expect(cbrtResult, closeTo(math.pow(2, 1 / 3), 1e-7));

      notifier.clearAll();
      notifier.addDigit('3');
      notifier.applyScientificFunction('cube');
      expect(notifier.state.display, '27');

      notifier.clearAll();
      notifier.addDigit('4');
      notifier.applyScientificFunction('reciprocal');
      expect(notifier.state.display, '0.25');

      notifier.clearAll();
      notifier.addDigit('1');
      notifier.addDigit('0');
      notifier.applyScientificFunction('exp');
      final expResult = double.parse(notifier.state.display);
      expect(expResult, closeTo(math.exp(10), 1e-7));

      notifier.clearAll();
      notifier.addDigit('2');
      notifier.applyScientificFunction('pow10');
      expect(notifier.state.display, '100');
    });

    test('Trường hợp biên của giai thừa: số không nguyên và số quá lớn', () {
      notifier.addDigit('5');
      notifier.addDigit('.');
      notifier.addDigit('5');
      notifier.applyScientificFunction('factorial');
      expect(notifier.state.error, contains('Lỗi'));

      notifier.clearAll();
      notifier.addDigit('2');
      notifier.addDigit('1');
      notifier.applyScientificFunction('factorial');
      expect(notifier.state.error, contains('Lỗi'));
    });

    test('Xử lý dấu ngoặc và tính toán', () {
      notifier.addParenthesis('(');
      notifier.addDigit('2');
      notifier.addOperator('+');
      notifier.addDigit('3');
      notifier.addParenthesis(')');
      notifier.evaluate();
      expect(notifier.state.display, '5');
    });

    test('Xóa ký tự cuối sau khi có lỗi sẽ xóa sạch lỗi và reset', () {
      notifier.addDigit('5');
      notifier.addOperator('/');
      notifier.addDigit('0');
      notifier.evaluate();
      expect(notifier.state.error, isNotNull);
      notifier.deleteLast();
      expect(notifier.state.error, isNull);
      expect(notifier.state.display, '0');
      expect(notifier.state.pendingExpression, '');
    });
  });
}
