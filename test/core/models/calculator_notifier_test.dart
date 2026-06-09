import 'package:flutter_test/flutter_test.dart';
import 'package:test_flutter/core/models/calculator_notifier.dart';

void main() {
  late CalculatorNotifier notifier;

  setUp(() {
    notifier = CalculatorNotifier();
  });

  group('CalculatorNotifier - Nhập số và toán tử', () {
    test('Nhập số bình thường', () {
      notifier.addDigit('5');
      notifier.addDigit('2');
      expect(notifier.state.display, '52');
      expect(notifier.state.pendingExpression, '52');
    });

    test('Chặn nhiều dấu chấm thập phân trong cùng một số', () {
      notifier.addDigit('5');
      notifier.addDigit('.');
      notifier.addDigit('2');
      notifier.addDigit('.'); // Bị bỏ qua
      notifier.addDigit('1');
      expect(notifier.state.display, '5.21');
    });

    test('Dấu chấm thập phân sau toán tử được phép (số mới)', () {
      // Sau dấu + là số mới, dấu chấm phải được chấp nhận
      notifier.addDigit('5');
      notifier.addOperator('+');
      notifier.addDigit('.'); // Tự thêm '0.' vì số mới rỗng
      expect(notifier.state.pendingExpression, '5+0.');
    });

    test('Thay thế toán tử nếu nhập liên tiếp cập nhật cả màn hình', () {
      notifier.addDigit('5');
      notifier.addOperator('+');
      notifier.addOperator('*'); // '*' sẽ ghi đè '+'
      expect(notifier.state.pendingExpression, '5*');
      expect(notifier.state.display, '*'); // Sửa lỗi ở đây
      
      notifier.addOperator('-');
      expect(notifier.state.pendingExpression, '5-');
      expect(notifier.state.display, '-');
      
      notifier.addOperator('+');
      expect(notifier.state.pendingExpression, '5+');
      expect(notifier.state.display, '+');
    });

    test('Giới hạn số chữ số (maxDigits = 15)', () {
      for (int i = 0; i < 16; i++) {
        notifier.addDigit('1');
      }
      // Dù nhập 16 số '1', độ dài display chỉ là 15 do bị chặn
      expect(notifier.state.display.length, 15);
      expect(notifier.state.pendingExpression.length, 15);
    });
  });

  group('CalculatorNotifier - Chức năng đặc biệt', () {
    test('Nút đổi dấu +/- lần 1: dương → âm', () {
      notifier.addDigit('5');
      notifier.toggleSign();
      expect(notifier.state.display, '-5');
      expect(notifier.state.pendingExpression, '-5');
    });

    test('Nút đổi dấu +/- lần 2: âm → dương', () {
      notifier.addDigit('5');
      notifier.toggleSign();
      notifier.toggleSign();
      expect(notifier.state.display, '5');
      expect(notifier.state.pendingExpression, '5');
    });

    test('Nút đổi dấu +/- nhiều lần liên tiếp (không bị cộng dồn --)', () {
      notifier.addDigit('5');
      notifier.toggleSign(); // -5
      notifier.toggleSign(); // 5
      notifier.toggleSign(); // -5
      // Expression phải là '-5', KHÔNG phải '---5'
      expect(notifier.state.pendingExpression, '-5');
      expect(notifier.state.display, '-5');
    });

    test('Đổi dấu sau toán tử', () {
      notifier.addDigit('2');
      notifier.addOperator('+');
      notifier.addDigit('5');
      notifier.toggleSign(); // 5 thành -5
      expect(notifier.state.display, '-5');
      expect(notifier.state.pendingExpression, '2+-5');
    });

    test('Đổi dấu sau toán tử rồi lại đổi ngược', () {
      notifier.addDigit('2');
      notifier.addOperator('+');
      notifier.addDigit('5');
      notifier.toggleSign(); // 2+-5
      notifier.toggleSign(); // 2+5 (không phải 2+--5)
      expect(notifier.state.display, '5');
      expect(notifier.state.pendingExpression, '2+5');
    });

    test('Nút phần trăm (%)', () {
      notifier.addDigit('5');
      notifier.addDigit('0');
      notifier.addPercent();
      expect(notifier.state.display, '0.5');
      expect(notifier.state.pendingExpression, '0.5');
    });

    test('Xóa ký tự cuối (deleteLast)', () {
      notifier.addDigit('1');
      notifier.addDigit('2');
      notifier.addDigit('3');
      notifier.deleteLast(); // xóa '3'
      expect(notifier.state.pendingExpression, '12');
      expect(notifier.state.display, '12');
    });

    test('Xóa ký tự cuối về rỗng → display về 0', () {
      notifier.addDigit('5');
      notifier.deleteLast();
      expect(notifier.state.pendingExpression, '');
      expect(notifier.state.display, '0');
    });

    test('Xóa tất cả (AC)', () {
      notifier.addDigit('5');
      notifier.addOperator('+');
      notifier.clearAll();
      expect(notifier.state.display, '0');
      expect(notifier.state.pendingExpression, '');
      expect(notifier.state.history, isEmpty);
      expect(notifier.state.error, isNull);
    });
  });

  group('CalculatorNotifier - Tính toán', () {
    test('Phép cộng thành công', () {
      notifier.addDigit('5');
      notifier.addOperator('+');
      notifier.addDigit('3');
      notifier.evaluate();

      expect(notifier.state.display, '8');
      expect(notifier.state.error, isNull);
      expect(notifier.state.history.length, 1);
      expect(notifier.state.history.first.expression, '5+3');
      expect(notifier.state.history.first.result, '8');
    });

    test('Kết quả được thêm vào lịch sử tích lũy', () {
      notifier.addDigit('2');
      notifier.addOperator('+');
      notifier.addDigit('3');
      notifier.evaluate(); // 2+3 = 5, history = [record1]

      notifier.addOperator('+');
      notifier.addDigit('1');
      notifier.evaluate(); // 5+1 = 6, history = [record2, record1]

      expect(notifier.state.history.length, 2);
      expect(notifier.state.history.first.expression, '5+1');
    });

    test('Tính toán số âm đơn', () {
      notifier.addOperator('-'); // Nhập số âm khi expression rỗng
      notifier.addDigit('5');
      notifier.addOperator('+');
      notifier.addDigit('3');
      notifier.evaluate();
      expect(notifier.state.display, '-2'); // -5 + 3 = -2
    });

    test('Chia cho không báo lỗi', () {
      notifier.addDigit('5');
      notifier.addOperator('/');
      notifier.addDigit('0');
      notifier.evaluate();

      expect(notifier.state.error, 'Lỗi: Không thể chia cho 0');
      expect(notifier.state.history, isEmpty); // Lỗi không được lưu vào lịch sử
    });

    test('Sau khi evaluate, nhập số mới thì bắt đầu lại', () {
      notifier.addDigit('5');
      notifier.addOperator('+');
      notifier.addDigit('3');
      notifier.evaluate(); // display = '8'

      notifier.addDigit('9'); // bắt đầu mới hoàn toàn
      expect(notifier.state.display, '9');
      expect(notifier.state.pendingExpression, '9');
    });

    test('Sau khi có lỗi, AC xóa sạch', () {
      notifier.addDigit('5');
      notifier.addOperator('/');
      notifier.addDigit('0');
      notifier.evaluate();

      notifier.clearAll();
      expect(notifier.state.error, isNull);
      expect(notifier.state.display, '0');
    });

    test('Tính toán biểu thức chưa hoàn chỉnh (vd: "2 + ") báo lỗi', () {
      notifier.addDigit('2');
      notifier.addOperator('+');
      notifier.evaluate();

      // Trong thư viện của chúng ta, "2+" sẽ bị ném lỗi FormatException 
      // ở ExpressionEvaluator ("Biểu thức không hợp lệ") do thiếu số.
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.error, contains('Lỗi:'));
    });

    test('Sau khi có lỗi, nhập số mới hoặc toán tử sẽ tự động xóa sạch và bắt đầu lại', () {
      notifier.addDigit('2');
      notifier.addOperator('/');
      notifier.addDigit('0');
      notifier.evaluate(); // Có lỗi chia cho 0
      expect(notifier.state.error, isNotNull);

      notifier.addDigit('5'); // tự reset và bắt đầu với '5'
      expect(notifier.state.error, isNull);
      expect(notifier.state.display, '5');
      expect(notifier.state.pendingExpression, '5');

      // Tương tự cho toán tử
      notifier.addOperator('/');
      notifier.addDigit('0');
      notifier.evaluate(); // Lại có lỗi
      expect(notifier.state.error, isNotNull);

      notifier.addOperator('-'); // tự reset và bắt đầu là dấu trừ âm
      expect(notifier.state.error, isNull);
      expect(notifier.state.display, '-');
      expect(notifier.state.pendingExpression, '-');
    });

    test('Ngăn chặn nhiều số 0 vô nghĩa ở đầu', () {
      notifier.addDigit('0');
      notifier.addDigit('0');
      notifier.addDigit('0');
      expect(notifier.state.display, '0');
      expect(notifier.state.pendingExpression, '0');

      notifier.addDigit('5'); // Thay thế 0 ở đầu thành 5
      expect(notifier.state.display, '5');
      expect(notifier.state.pendingExpression, '5');
    });

    test('Thay thế số 0 ở đầu sau toán tử hoặc dấu âm', () {
      // 2 + 0 -> 2 + 5
      notifier.addDigit('2');
      notifier.addOperator('+');
      notifier.addDigit('0');
      expect(notifier.state.pendingExpression, '2+0');
      notifier.addDigit('5');
      expect(notifier.state.pendingExpression, '2+5');
      expect(notifier.state.display, '5');

      // -0 -> -5
      notifier.clearAll();
      notifier.addOperator('-');
      notifier.addDigit('0');
      expect(notifier.state.pendingExpression, '-0');
      notifier.addDigit('5');
      expect(notifier.state.pendingExpression, '-5');
      expect(notifier.state.display, '-5');
    });

    test('Độ chính xác số thập phân (tránh sai số floating point 0.1 + 0.2)', () {
      notifier.addDigit('0');
      notifier.addDigit('.');
      notifier.addDigit('1');
      notifier.addOperator('+');
      notifier.addDigit('0');
      notifier.addDigit('.');
      notifier.addDigit('2');
      notifier.evaluate();
      // 0.1 + 0.2 trong Dart thông thường là 0.30000000000000004
      // Nhưng qua hàm format của chúng ta phải hiển thị là '0.3'
      expect(notifier.state.display, '0.3');
    });

    test('Tính phần trăm (%) cho số âm', () {
      notifier.addDigit('5');
      notifier.toggleSign(); // -5
      notifier.addPercent(); // -5% -> -0.05
      expect(notifier.state.display, '-0.05');
      expect(notifier.state.pendingExpression, '-0.05');
    });
  });

  // ===========================================================================
  // TÍNH NĂNG LẶP PHÉP TÍNH (REPEAT EQUALS)
  // Hành vi: nhấn "1+1=" ra 2, nhấn "=" tiếp ra 3, tiếp ra 4...
  // Cho đến khi bấm AC hoặc nhập số/toán tử mới.
  // ===========================================================================
  group('CalculatorNotifier - LẶp phép tính (Repeat Equals)', () {
    test('Bấm "=" liên tiếp lặp phép cộng: 1+1=2, =3, =4', () {
      notifier.addDigit('1');
      notifier.addOperator('+');
      notifier.addDigit('1');
      notifier.evaluate(); // 1+1 = 2
      expect(notifier.state.display, '2');

      notifier.evaluate(); // 2+1 = 3
      expect(notifier.state.display, '3');

      notifier.evaluate(); // 3+1 = 4
      expect(notifier.state.display, '4');
    });

    test('Bấm "=" liên tiếp lặp phép nhân: 2*3=6, =18, =54', () {
      notifier.addDigit('2');
      notifier.addOperator('*');
      notifier.addDigit('3');
      notifier.evaluate(); // 2*3 = 6
      expect(notifier.state.display, '6');

      notifier.evaluate(); // 6*3 = 18
      expect(notifier.state.display, '18');

      notifier.evaluate(); // 18*3 = 54
      expect(notifier.state.display, '54');
    });

    test('Bấm "=" liên tiếp lặp phép trừ: 10-3=7, =4, =1', () {
      notifier.addDigit('1');
      notifier.addDigit('0');
      notifier.addOperator('-');
      notifier.addDigit('3');
      notifier.evaluate(); // 10-3 = 7
      expect(notifier.state.display, '7');

      notifier.evaluate(); // 7-3 = 4
      expect(notifier.state.display, '4');

      notifier.evaluate(); // 4-3 = 1
      expect(notifier.state.display, '1');
    });

    test('Bấm "=" liên tiếp lặp phép chia: 8/2=4, =2, =1', () {
      notifier.addDigit('8');
      notifier.addOperator('/');
      notifier.addDigit('2');
      notifier.evaluate(); // 8/2 = 4
      expect(notifier.state.display, '4');

      notifier.evaluate(); // 4/2 = 2
      expect(notifier.state.display, '2');

      notifier.evaluate(); // 2/2 = 1
      expect(notifier.state.display, '1');
    });

    test('Biểu thức nhiều toán tử: chỉ lặp toán tử và số hạng CUỐI', () {
      // 1+2*3=7 → lưu operator="*", operand="3"
      // Bấm = tiếp → 7*3 = 21 (không phải 1+2*3 lần nữa)
      notifier.addDigit('1');
      notifier.addOperator('+');
      notifier.addDigit('2');
      notifier.addOperator('*');
      notifier.addDigit('3');
      notifier.evaluate(); // 1+2*3 = 7
      expect(notifier.state.display, '7');

      notifier.evaluate(); // 7*3 = 21
      expect(notifier.state.display, '21');
    });

    test('Sau khi lặp "=", nhập số mới thì phá vỡ chuỗi lặp', () {
      notifier.addDigit('5');
      notifier.addOperator('+');
      notifier.addDigit('1');
      notifier.evaluate(); // 5+1 = 6
      notifier.evaluate(); // 6+1 = 7
      expect(notifier.state.display, '7');

      // Nhập số mới → bắt đầu biểu thức mới hoàn toàn
      notifier.addDigit('9');
      expect(notifier.state.display, '9');
      expect(notifier.state.pendingExpression, '9');

      // Bấm = với biểu thức chỉ là số → không có gì để lặp, không thay đổi
      notifier.evaluate();
      expect(notifier.state.display, '9');
    });

    test('Lịch sử ghi đúng từng bước lặp', () {
      notifier.addDigit('1');
      notifier.addOperator('+');
      notifier.addDigit('1');
      notifier.evaluate(); // 1+1=2
      notifier.evaluate(); // 2+1=3

      // Phải có 2 bản ghi trong lịch sử
      expect(notifier.state.history.length, 2);
      // Bản ghi mới nhất là 2+1=3
      expect(notifier.state.history.first.expression, '2+1');
      expect(notifier.state.history.first.result, '3');
      // Bản ghi cũ hơn là 1+1=2
      expect(notifier.state.history[1].expression, '1+1');
      expect(notifier.state.history[1].result, '2');
    });

    test('Bấm "=" liên tiếp với toán hạng âm: 2*-5=-10, =50', () {
      notifier.addDigit('2');
      notifier.addOperator('*');
      notifier.addDigit('5');
      notifier.toggleSign(); // 2*-5
      notifier.evaluate(); // -10
      expect(notifier.state.display, '-10');

      // Lặp: -10 * -5 = 50
      notifier.evaluate();
      expect(notifier.state.display, '50');
      
      // Lặp tiếp: 50 * -5 = -250
      notifier.evaluate();
      expect(notifier.state.display, '-250');
    });

    test('Gõ phím số sau khi kết quả là số âm thì bắt đầu biểu thức mới', () {
      notifier.addDigit('2');
      notifier.addOperator('-');
      notifier.addDigit('5');
      notifier.evaluate(); // -3
      expect(notifier.state.display, '-3');

      // Gõ 9 -> màn hình thành 9, thay vì -39
      notifier.addDigit('9');
      expect(notifier.state.display, '9');
      expect(notifier.state.pendingExpression, '9');
    });
  });

  // ===========================================================================
  // TÍNH NĂNG MÁY TÍNH KHOA HỌC (SCIENTIFIC CALCULATOR)
  // ===========================================================================
  group('CalculatorNotifier - Máy tính khoa học', () {
    test('Đổi chế độ Radian / Độ', () {
      expect(notifier.state.isRadian, false); // Mặc định là Độ (Deg)
      notifier.toggleRadianDegree();
      expect(notifier.state.isRadian, true);
      notifier.toggleRadianDegree();
      expect(notifier.state.isRadian, false);
    });

    test('Tính sin(0) = 0', () {
      notifier.addDigit('0');
      notifier.applyScientificFunction('sin');
      expect(notifier.state.display, '0');
    });

    test('Tính cos(0) = 1', () {
      notifier.addDigit('0');
      notifier.applyScientificFunction('cos');
      expect(notifier.state.display, '1');
    });

    test('Bình phương số (square)', () {
      notifier.addDigit('5');
      notifier.applyScientificFunction('square');
      expect(notifier.state.display, '25');
    });

    test('Căn bậc 2 (sqrt)', () {
      notifier.addDigit('1');
      notifier.addDigit('6');
      notifier.applyScientificFunction('sqrt');
      expect(notifier.state.display, '4');
    });

    test('Căn bậc 2 số âm báo lỗi', () {
      notifier.addDigit('4');
      notifier.toggleSign(); // -4
      notifier.applyScientificFunction('sqrt');
      expect(notifier.state.error, contains('Không căn số âm'));
    });

    test('Tính giai thừa (factorial)', () {
      notifier.addDigit('5');
      notifier.applyScientificFunction('factorial'); // 5! = 120
      expect(notifier.state.display, '120');
    });

    test('Tính giai thừa số âm báo lỗi', () {
      notifier.addDigit('3');
      notifier.toggleSign(); // -3
      notifier.applyScientificFunction('factorial');
      expect(notifier.state.error, contains('số nguyên dương'));
    });

    test('Nhập hằng số pi', () {
      notifier.insertConstant('pi');
      expect(notifier.state.display, startsWith('3.14159'));
    });

    test('Hằng số pi tự thêm nhân ngầm định nếu trước đó là số', () {
      notifier.addDigit('2');
      notifier.insertConstant('pi');
      expect(notifier.state.pendingExpression, startsWith('2*3.14159'));
    });

    test('Hàm khoa học không ghi đè toàn bộ biểu thức (Fix Bug)', () {
      // Nhập 2 + 3
      notifier.addDigit('2');
      notifier.addOperator('+');
      notifier.addDigit('3');
      // Nhấn x² (square) trên số 3
      notifier.applyScientificFunction('square');
      // Màn hình hiển thị 9
      expect(notifier.state.display, '9');
      // Biểu thức đang chờ phải là 2+9, KHÔNG PHẢI chỉ là 9
      expect(notifier.state.pendingExpression, '2+9');
      
      // Tính toán 2+9 = 11
      notifier.evaluate();
      expect(notifier.state.display, '11');
    });

    test('Hàm khoa học tính tiếp trên kết quả vừa tính', () {
      notifier.addDigit('2');
      notifier.addOperator('+');
      notifier.addDigit('3');
      notifier.evaluate(); // 5
      
      notifier.applyScientificFunction('square'); // 5² = 25
      expect(notifier.state.display, '25');
      expect(notifier.state.pendingExpression, '25'); // Vì trước đó là kết quả nên prefix rỗng
    });
  });
}
