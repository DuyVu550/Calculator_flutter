import 'package:flutter_test/flutter_test.dart';
import 'package:test_flutter/core/logic/expr_evaluator.dart';

void main() {
  late ExpressionEvaluator evaluator;

  setUp(() {
    evaluator = ExpressionEvaluator();
  });

  group('ExpressionEvaluator - Phép tính cơ bản', () {
    test('Cộng hai số dương', () {
      expect(evaluator.evaluate('2 + 3'), 5.0);
    });

    test('Trừ hai số dương', () {
      expect(evaluator.evaluate('5 - 2'), 3.0);
    });

    test('Nhân hai số dương', () {
      expect(evaluator.evaluate('4 * 5'), 20.0);
    });

    test('Chia hai số dương', () {
      expect(evaluator.evaluate('10 / 2'), 5.0);
    });

    test('Số thập phân', () {
      expect(evaluator.evaluate('2.5 + 1.5'), 4.0);
      expect(evaluator.evaluate('.5 * 4'), 2.0);
    });

    test('Phép tính chỉ có một số', () {
      expect(evaluator.evaluate('7'), 7.0);
      expect(evaluator.evaluate('3.14'), 3.14);
    });
  });

  group('ExpressionEvaluator - Độ ưu tiên toán tử (BODMAS)', () {
    test('Nhân chia ưu tiên hơn cộng trừ', () {
      expect(evaluator.evaluate('2 + 3 * 4'), 14.0); // Không phải 20
      expect(evaluator.evaluate('10 - 6 / 2'), 7.0);
    });

    test('Dấu ngoặc thay đổi thứ tự', () {
      expect(evaluator.evaluate('(2 + 3) * 4'), 20.0);
      expect(evaluator.evaluate('10 - (6 / 2)'), 7.0);
    });

    test('Nhiều ngoặc lồng nhau', () {
      expect(evaluator.evaluate('2 * (3 + (4 - 1))'), 12.0);
    });

    test('Biểu thức phức tạp từ tài liệu thiết kế', () {
      // Đây chính là ví dụ đã nêu trong yêu cầu ban đầu
      expect(evaluator.evaluate('2 + 3 * (5 - 1)'), 14.0);
    });

    test('Nhiều toán tử cùng ưu tiên (trái sang phải)', () {
      // 10 - 3 - 2 phải được tính là (10-3)-2 = 5, không phải 10-(3-2) = 9
      expect(evaluator.evaluate('10 - 3 - 2'), 5.0);
      expect(evaluator.evaluate('20 / 4 / 2'), 2.5); // (20/4)/2 = 5/2 = 2.5
    });
  });

  group('ExpressionEvaluator - Dấu âm (Unary minus)', () {
    test('Dấu âm ở đầu biểu thức', () {
      expect(evaluator.evaluate('-5 + 3'), -2.0);
      expect(evaluator.evaluate('-5 * 2'), -10.0);
    });

    test('Dấu âm sau toán tử', () {
      expect(evaluator.evaluate('2 * -4'), -8.0);
      expect(evaluator.evaluate('5 - -2'), 7.0); // 5 trừ (âm 2) = 7
      expect(evaluator.evaluate('10 + -3'), 7.0);
    });

    test('Dấu âm sau ngoặc mở', () {
      expect(evaluator.evaluate('10 / (-2)'), -5.0);
      expect(evaluator.evaluate('(-3) * (-4)'), 12.0); // âm * âm = dương
    });
  });

  group('ExpressionEvaluator - Ngoại lệ (Exceptions)', () {
    test('Chia cho 0 trả về infinity (không ném exception)', () {
      // Trong Dart, chia số nguyên/double cho 0 trả về infinity
      // Tầng Notifier sẽ kiểm tra isInfinite để báo lỗi
      expect(evaluator.evaluate('5 / 0'), double.infinity);
      expect(evaluator.evaluate('-5 / 0'), double.negativeInfinity);
    });

    test('Biểu thức rỗng', () {
      expect(() => evaluator.evaluate(''), throwsA(isA<FormatException>()));
      expect(() => evaluator.evaluate('   '), throwsA(isA<FormatException>()));
    });

    test('Thiếu ngoặc đóng', () {
      expect(
        () => evaluator.evaluate('2 * (3 + 1'),
        throwsA(isA<FormatException>()),
      );
    });

    test('Thiếu ngoặc mở', () {
      expect(
        () => evaluator.evaluate('2 * 3 + 1)'),
        throwsA(isA<FormatException>()),
      );
    });

    test('Toán tử dư thừa (cú pháp sai)', () {
      // '2 + * 3': sau khi tokenize có token ['2', '+', '*', '3']
      // '*' là toán tử đứng sau toán tử khác → stack RPN sẽ trả về kết quả
      // không hợp lệ do không có đủ số hạng → evalRPN ném exception
      expect(
        () => evaluator.evaluate('2 + * 3'),
        throwsA(isA<FormatException>()),
      );
    });

    test('Ký tự chữ cái không hợp lệ', () {
      // 'a', 'b'... bị ném ngay ở bước Tokenize
      expect(
        () => evaluator.evaluate('2 + abc'),
        throwsA(isA<FormatException>()),
      );
    });

    test('Token số định dạng sai (.5.) vào _toRPN', () {
      // '.5.' được gom vào buffer như một token số,
      // double.tryParse('.5.') == null nên bị throw trong _toRPN
      expect(
        () => evaluator.evaluate('2 + .5. * 3'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
