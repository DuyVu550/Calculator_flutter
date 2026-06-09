// lib/core/models/calculator_notifier.dart

import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'calculator_state.dart';
import '../logic/expr_evaluator.dart';

// Provider toàn cục - dùng trong UI bằng ref.watch(calculatorProvider)
final calculatorProvider =
    StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  return CalculatorNotifier();
});

// ---------------------------------------------------------------------------

// StateNotifier chứa toàn bộ logic xử lý sự kiện bàn phím.
// Mỗi hàm nhận một sự kiện từ UI, cập nhật state và Riverpod
// sẽ tự động thông báo cho UI rebuild.
class CalculatorNotifier extends StateNotifier<CalculatorState> {
  CalculatorNotifier() : super(const CalculatorState());

  final ExpressionEvaluator _evaluator = ExpressionEvaluator();

  // Giới hạn số chữ số người dùng có thể nhập
  static const int _maxDigits = 15;

  // Danh sách các ký tự là toán tử
  static const List<String> _operators = ['+', '-', '*', '/'];

  // =========================================================================
  // 1. NHẬP CHỮ SỐ
  // Được gọi khi người dùng nhấn các nút 0-9 và dấu '.'
  // =========================================================================
  void addDigit(String digit) {
    // Nếu đang có lỗi → xóa sạch và bắt đầu lại từ đầu
    if (state.error != null) {
      state = CalculatorState(isRadian: state.isRadian);
    }

    String currentNumber = _getCurrentNumber();

    // Ngăn chặn nhập nhiều số 0 vô nghĩa ở đầu (ví dụ: '00' hoặc '05')
    if (currentNumber == '0' || currentNumber == '-0') {
      if (digit == '0') {
        return;
      }
      if (digit != '.') {
        // Thay thế chữ số '0' ở cuối bằng chữ số mới
        String expr = state.pendingExpression;
        String newExpr = expr.substring(0, expr.length - 1) + digit;
        state = state.copyWith(
          pendingExpression: newExpr,
          display: _getCurrentNumberFrom(newExpr),
          clearError: true,
        );
        return;
      }
    }

    // Không cho nhập hai dấu chấm thập phân trong cùng một số
    if (digit == '.') {
      if (currentNumber.contains('.')) {
        return;
      }
      // Tự thêm '0' trước dấu chấm nếu chưa có số nào
      if (currentNumber.isEmpty) {
        _append('0.');
        state = state.copyWith(display: '0.', clearError: true);
        return;
      }
    }

    // Không cho nhập quá số lượng chữ số tối đa
    String digitsOnly = currentNumber.replaceAll('.', '');
    if (digitsOnly.length >= _maxDigits) {
      return;
    }

    // Nếu màn hình đang hiển thị kết quả của phép tính trước
    // và người dùng nhập số mới → bắt đầu lại từ đầu
    if (_isShowingResult()) {
      state = CalculatorState(isRadian: state.isRadian);
    }

    _append(digit);

    // Cập nhật display thành số vừa nhập
    state = state.copyWith(display: _getCurrentNumber(), clearError: true);
  }

  // =========================================================================
  // 2. NHẬP TOÁN TỬ
  // Được gọi khi người dùng nhấn +, -, *, /
  // =========================================================================
  void addOperator(String op) {
    // Nếu đang có lỗi → xóa sạch và bắt đầu lại từ đầu
    if (state.error != null) {
      state = CalculatorState(isRadian: state.isRadian);
    }

    String expr = state.pendingExpression;

    // Trường hợp expression đang rỗng
    // Chỉ cho phép dấu trừ để nhập số âm, bỏ qua các toán tử khác
    if (expr.isEmpty) {
      if (op == '-') {
        state = state.copyWith(
          pendingExpression: '-',
          display: '-',
          clearError: true,
        );
      }
      return;
    }

    String lastChar = expr[expr.length - 1];

    // Nếu ký tự cuối đã là toán tử → thay thế bằng toán tử mới
    // Ví dụ: người dùng nhấn "+" rồi nhấn "*" → dùng "*"
    if (_operators.contains(lastChar)) {
      String newExpr = expr.substring(0, expr.length - 1) + op;
      state = state.copyWith(
        pendingExpression: newExpr,
        display: op, // <-- Sửa lỗi: Cần cập nhật display thành toán tử mới
        clearError: true,
      );
      return;
    }

    // Ký tự cuối là ngoặc mở → chỉ cho phép dấu trừ đơn
    if (lastChar == '(') {
      if (op == '-') {
        _append(op);
        state = state.copyWith(display: op, clearError: true);
      }
      return;
    }

    // Trường hợp bình thường: thêm toán tử vào cuối expression
    _append(op);
    state = state.copyWith(display: op, clearError: true);
  }

  // =========================================================================
  // 3. TÍNH TOÁN
  // Được gọi khi người dùng nhấn "="
  //
  // Hành vi lặp phép tính (Repeat Equals):
  //   - Lần đầu bấm "=" trên biểu thức "1+1":
  //       → Phân tích toán tử cuối là "+", số hạng cuối là "1"
  //       → Tính ra 2, lưu repeatOperator="+", repeatOperand="1"
  //   - Bấm "=" lần 2 khi đang hiển thị kết quả "2":
  //       → Tính "2+1" = 3 (áp dụng lại repeatOperator và repeatOperand)
  //   - Bấm "=" lần 3: tính "3+1" = 4, cứ thế tiếp tục
  //   - Bấm phím số hoặc toán tử mới sẽ xóa repeatOperator/repeatOperand
  // =========================================================================
  void evaluate() {
    String expr = state.pendingExpression.trim();

    if (expr.isEmpty) {
      return;
    }

    // --- Trường hợp lặp phép tính (Repeat Equals) ---
    // Nếu màn hình đang hiển thị kết quả và còn lưu phép tính cũ,
    // thì ghép kết quả hiện tại + toán tử cũ + số hạng cũ để tính tiếp.
    if (_isShowingResult() &&
        state.repeatOperator != null &&
        state.repeatOperand != null) {
      String newExpr = expr + state.repeatOperator! + state.repeatOperand!;
      _doEvaluate(newExpr, state.repeatOperator!, state.repeatOperand!);
      return;
    }

    // --- Trường hợp tính lần đầu ---
    // Phân tích expression để tìm toán tử cuối và số hạng cuối.
    // Ví dụ: "1+1" → operator="+", operand="1"
    //        "10*5-2" → operator="-", operand="2"
    String? foundOperator;
    String? foundOperand;

    for (int i = expr.length - 1; i >= 0; i--) {
      String ch = expr[i];

      // Bỏ qua nếu là dấu trừ mang tính âm (unary minus)
      // Dấu trừ là unary nếu nó đứng ở đầu (i == 0) hoặc đứng ngay sau một toán tử/ngoặc mở
      bool isUnaryMinus = false;
      if (ch == '-') {
        if (i == 0) {
          isUnaryMinus = true;
        } else {
          String prevChar = expr[i - 1];
          if (_operators.contains(prevChar) || prevChar == '(') {
            isUnaryMinus = true;
          }
        }
      }

      if (!isUnaryMinus && _operators.contains(ch)) {
        foundOperator = ch;
        foundOperand = expr.substring(i + 1);
        break;
      }
    }

    _doEvaluate(expr, foundOperator, foundOperand);
  }

  // Thực thi tính toán: gọi evaluator, xử lý lỗi, cập nhật state.
  // Nhận vào expression cần tính và thông tin lặp phép tính để lưu lại.
  void _doEvaluate(String expr, String? repeatOp, String? repeatOperand) {
    try {
      double rawResult = _evaluator.evaluate(expr);

      // Kiểm tra trường hợp chia cho 0
      if (rawResult.isInfinite) {
        state = state.copyWith(error: 'Lỗi: Không thể chia cho 0');
        return;
      }

      // Kiểm tra kết quả không xác định
      if (rawResult.isNaN) {
        state = state.copyWith(error: 'Lỗi: Kết quả không xác định');
        return;
      }

      String resultStr = _formatResult(rawResult);

      // Lưu vào lịch sử
      CalculationRecord record = CalculationRecord(
        expression: expr,
        result: resultStr,
        timestamp: DateTime.now(),
      );

      // Cập nhật state: hiển thị kết quả và lưu lại thông tin để lặp phép tính
      state = state
          .addRecord(record)
          .copyWith(
            display: resultStr,
            pendingExpression: resultStr,
            repeatOperator: repeatOp,
            repeatOperand: repeatOperand,
            clearError: true,
          );
    } on FormatException catch (e) {
      state = state.copyWith(error: 'Lỗi: ${e.message}');
    } catch (e) {
      state = state.copyWith(error: 'Lỗi không xác định');
    }
  }

  // =========================================================================
  // 4. XÓA TOÀN BỘ (nút AC)
  // =========================================================================
  void clearAll() {
    state = CalculatorState(isRadian: state.isRadian);
  }

  // =========================================================================
  // 5. XÓA KÝ TỰ CUỐI (nút ⌫)
  // =========================================================================
  void deleteLast() {
    // Nếu đang có lỗi → xóa sạch và dừng lại
    if (state.error != null) {
      state = CalculatorState(isRadian: state.isRadian);
      return;
    }

    String expr = state.pendingExpression;

    if (expr.isEmpty) {
      return;
    }

    // Xóa ký tự cuối cùng
    String newExpr = expr.substring(0, expr.length - 1);

    // Nếu expression rỗng sau khi xóa → về màn hình "0"
    String newDisplay;
    if (newExpr.isEmpty) {
      newDisplay = '0';
    } else {
      newDisplay = _getLastToken(newExpr);
    }

    state = state.copyWith(
      pendingExpression: newExpr,
      display: newDisplay,
      clearError: true,
    );
  }

  // =========================================================================
  // 6. ĐỔI DẤU +/- (nút +/-)
  // =========================================================================
  void toggleSign() {
    // Nếu đang có lỗi → xóa sạch và bắt đầu lại từ đầu
    if (state.error != null) {
      state = CalculatorState(isRadian: state.isRadian);
    }

    String current = _getCurrentNumber();

    if (current.isEmpty || current == '0') {
      return;
    }

    String expr = state.pendingExpression;
    String newExpr;

    if (current.startsWith('-')) {
      // Đang âm → bỏ dấu trừ
      String withoutMinus = current.substring(1);
      String prefix = expr.substring(0, expr.length - current.length);
      newExpr = prefix + withoutMinus;
    } else {
      // Đang dương → thêm dấu trừ
      String prefix = expr.substring(0, expr.length - current.length);
      newExpr = '$prefix-$current';
    }

    state = state.copyWith(
      pendingExpression: newExpr,
      display: _getCurrentNumberFrom(newExpr),
      clearError: true,
    );
  }

  // =========================================================================
  // 7. PHẦN TRĂM (nút %)
  // Chuyển số hiện tại thành phần trăm bằng cách chia cho 100.
  // Ví dụ: "50" → "0.5"
  // =========================================================================
  void addPercent() {
    // Nếu đang có lỗi → xóa sạch và bắt đầu lại từ đầu
    if (state.error != null) {
      state = CalculatorState(isRadian: state.isRadian);
    }

    String current = _getCurrentNumber();

    if (current.isEmpty) {
      return;
    }

    double? value = double.tryParse(current);
    if (value == null) {
      return;
    }

    String percentStr = _formatResult(value / 100);
    String expr = state.pendingExpression;
    String prefix = expr.substring(0, expr.length - current.length);
    String newExpr = prefix + percentStr;

    state = state.copyWith(
      pendingExpression: newExpr,
      display: percentStr,
      clearError: true,
    );
  }

  // =========================================================================
  // 8. NGOẶC (nút ( và ) )
  // Tự động chèn ngoặc mở hoặc đóng tùy ngữ cảnh.
  // =========================================================================
  void addParenthesis(String paren) {
    if (state.error != null) {
      state = CalculatorState(isRadian: state.isRadian);
    }

    if (_isShowingResult() && paren == '(') {
      // Sau kết quả, bắt đầu biểu thức mới với ngoặc mở
      state = CalculatorState(isRadian: state.isRadian);
    }

    _append(paren);
    state = state.copyWith(display: paren, clearError: true);

    // Cập nhật display thành số nếu vừa đóng ngoặc
    if (paren == ')') {
      String num = _getCurrentNumberFrom(state.pendingExpression);
      if (num.isNotEmpty) {
        state = state.copyWith(display: num);
      }
    }
  }

  // =========================================================================
  // 9. CÁC HÀM KHOA HỌC - áp dụng ngay lên số hiện tại
  // =========================================================================

  // Hàm lũy thừa (xʸ): nhập số đáy xong, nhấn xʸ → thêm ^ vào expression
  // Vì ExpressionEvaluator không có ^, ta xử lý bằng cách evaluate tức thì
  // rồi cho nhập số mũ tiếp.
  // Tuy nhiên để đơn giản, ta áp dụng hàm 1 tham số lên số hiện tại.
  void applyScientificFunction(String funcName) {
    if (state.error != null) {
      state = CalculatorState(isRadian: state.isRadian);
    }

    String current = _getCurrentNumber();

    // Nếu đang hiển thị kết quả, lấy kết quả đó làm đầu vào
    if (_isShowingResult()) {
      current = state.display;
    }

    if (current.isEmpty) {
      return;
    }

    double? value = double.tryParse(current);
    if (value == null) {
      return;
    }

    double result;
    String expression;

    if (funcName == 'sin') {
      if (state.isRadian) {
        result = math.sin(value);
      } else {
        result = math.sin(value * math.pi / 180);
      }
      expression = 'sin($current)';
    } else if (funcName == 'cos') {
      if (state.isRadian) {
        result = math.cos(value);
      } else {
        result = math.cos(value * math.pi / 180);
      }
      expression = 'cos($current)';
    } else if (funcName == 'tan') {
      if (!state.isRadian && value % 180 == 90) {
        state = state.copyWith(error: 'Lỗi: Không xác định');
        return;
      }
      if (state.isRadian) {
        result = math.tan(value);
      } else {
        result = math.tan(value * math.pi / 180);
      }
      expression = 'tan($current)';
    } else if (funcName == 'sinh') {
      result = _sinh(value);
      expression = 'sinh($current)';
    } else if (funcName == 'cosh') {
      result = _cosh(value);
      expression = 'cosh($current)';
    } else if (funcName == 'tanh') {
      result = _tanh(value);
      expression = 'tanh($current)';
    } else if (funcName == 'ln') {
      if (value <= 0) {
        state = state.copyWith(error: 'Lỗi: ln không xác định');
        return;
      }
      result = math.log(value);
      expression = 'ln($current)';
    } else if (funcName == 'log10') {
      if (value <= 0) {
        state = state.copyWith(error: 'Lỗi: log không xác định');
        return;
      }
      result = math.log(value) / math.ln10;
      expression = 'log($current)';
    } else if (funcName == 'sqrt') {
      if (value < 0) {
        state = state.copyWith(error: 'Lỗi: Không căn số âm');
        return;
      }
      result = math.sqrt(value);
      expression = '√($current)';
    } else if (funcName == 'cbrt') {
      result = value < 0 ? -math.pow(-value, 1 / 3).toDouble() : math.pow(value, 1 / 3).toDouble();
      expression = '∛($current)';
    } else if (funcName == 'square') {
      result = value * value;
      expression = '($current)²';
    } else if (funcName == 'cube') {
      result = value * value * value;
      expression = '($current)³';
    } else if (funcName == 'reciprocal') {
      if (value == 0) {
        state = state.copyWith(error: 'Lỗi: Không thể chia cho 0');
        return;
      }
      result = 1 / value;
      expression = '1/($current)';
    } else if (funcName == 'exp') {
      result = math.exp(value);
      expression = 'eˣ($current)';
    } else if (funcName == 'pow10') {
      result = math.pow(10, value).toDouble();
      expression = '10ˣ($current)';
    } else if (funcName == 'factorial') {
      if (value < 0 || value != value.truncateToDouble()) {
        state = state.copyWith(error: 'Lỗi: Chỉ tính giai thừa số nguyên dương');
        return;
      }
      int n = value.toInt();
      if (n > 20) {
        state = state.copyWith(error: 'Lỗi: Số quá lớn để tính giai thừa');
        return;
      }
      result = _factorial(n).toDouble();
      expression = '$current!';
    } else {
      return;
    }

    if (result.isNaN) {
      state = state.copyWith(error: 'Lỗi: Kết quả không xác định');
      return;
    }
    if (result.isInfinite) {
      state = state.copyWith(error: 'Lỗi: Kết quả vô hạn');
      return;
    }

    String resultStr = _formatResult(result);

    String expr = state.pendingExpression;
    String prefix = '';
    if (!_isShowingResult()) {
      prefix = expr.substring(0, expr.length - current.length);
    }
    String newExpr = prefix + resultStr;

    CalculationRecord record = CalculationRecord(
      expression: expression,
      result: resultStr,
      timestamp: DateTime.now(),
    );

    state = state
        .addRecord(record)
        .copyWith(
          display: resultStr,
          pendingExpression: newExpr,
          clearError: true,
        );
  }

  // =========================================================================
  // 10. NHẬP HẰNG SỐ (π, e)
  // =========================================================================
  void insertConstant(String name) {
    if (state.error != null) {
      state = CalculatorState(isRadian: state.isRadian);
    }

    if (_isShowingResult()) {
      state = CalculatorState(isRadian: state.isRadian);
    }

    String value;
    if (name == 'pi') {
      value = _formatResult(math.pi);
    } else if (name == 'e') {
      value = _formatResult(math.e);
    } else {
      return;
    }

    // Nếu expression rỗng hoặc kết thúc bằng toán tử → thêm số trực tiếp
    String expr = state.pendingExpression;
    if (expr.isNotEmpty) {
      String lastChar = expr[expr.length - 1];
      if (!_operators.contains(lastChar) && lastChar != '(') {
        // Đang có số → thêm nhân ngầm định
        _append('*');
      }
    }

    _append(value);
    state = state.copyWith(display: value, clearError: true);
  }

  // =========================================================================
  // 11. SỐ NGẪU NHIÊN (Rand)
  // =========================================================================
  void insertRandom() {
    if (state.error != null) {
      state = CalculatorState(isRadian: state.isRadian);
    }

    double randomValue = math.Random().nextDouble();
    String valueStr = _formatResult(randomValue);

    if (_isShowingResult()) {
      state = CalculatorState(isRadian: state.isRadian);
    }

    String expr = state.pendingExpression;
    if (expr.isNotEmpty) {
      String lastChar = expr[expr.length - 1];
      if (!_operators.contains(lastChar) && lastChar != '(') {
        _append('*');
      }
    }

    _append(valueStr);
    state = state.copyWith(display: valueStr, clearError: true);
  }

  // =========================================================================
  // 12. ĐỔI ĐỘ / RADIAN
  // =========================================================================
  void toggleRadianDegree() {
    state = state.copyWith(isRadian: !state.isRadian);
  }

  // =========================================================================
  // HÀM HỖ TRỢ PRIVATE
  // =========================================================================

  // Thêm một chuỗi vào cuối pendingExpression
  void _append(String s) {
    state = state.copyWith(
      pendingExpression: state.pendingExpression + s,
      clearError: true,
    );
  }

  // Lấy số đang được nhập (phần token số ở cuối expression)
  String _getCurrentNumber() {
    return _getCurrentNumberFrom(state.pendingExpression);
  }

  // Lấy số ở cuối của một chuỗi expression bất kỳ
  String _getCurrentNumberFrom(String expr) {
    if (expr.isEmpty) {
      return '';
    }
    // Dùng Regex lấy số cuối cùng, có hỗ trợ bắt dấu trừ đơn (nếu có)
    RegExpMatch? match = RegExp(r'(?:^|(?<=[+\-*/(]))(-?[\d.]+)$').firstMatch(expr);
    if (match == null) {
      return '';
    }
    return match.group(1) ?? '';
  }

  // Lấy token cuối để cập nhật display sau khi xóa ký tự
  String _getLastToken(String expr) {
    if (expr.isEmpty) {
      return '0';
    }
    String lastChar = expr[expr.length - 1];
    if (_operators.contains(lastChar) || lastChar == '(' || lastChar == ')') {
      return lastChar;
    }
    return _getCurrentNumberFrom(expr);
  }

  // Kiểm tra xem màn hình có đang hiển thị kết quả của "=" không
  bool _isShowingResult() {
    if (state.history.isEmpty) {
      return false;
    }
    String lastResult = state.history[0].result;
    bool displayMatchesResult = state.display == lastResult;

    String exprToCheck = state.pendingExpression;
    if (exprToCheck.startsWith('-')) {
      exprToCheck = exprToCheck.substring(1);
    }
    bool expressionHasNoOperator = !exprToCheck.contains(
      RegExp(r'[+\-*/()]'),
    );

    return displayMatchesResult && expressionHasNoOperator;
  }

  // Định dạng kết quả: không hiển thị ".0" nếu là số nguyên
  // Đồng thời sửa lỗi sai số dấu phẩy động (ví dụ: 0.9999999999999999 -> 1.0)
  String _formatResult(double value) {
    if (value.isInfinite || value.isNaN) {
      return value.toString();
    }

    double rounded;
    // Tránh lỗi RangeError với toStringAsFixed cho số quá lớn
    if (value.abs() < 1e21) {
      rounded = double.parse(value.toStringAsFixed(10));
    } else {
      rounded = value;
    }

    // Làm tròn các số siêu nhỏ về 0 (ví dụ cos(90 độ) = 6.12e-17)
    if (rounded.abs() < 1e-10) {
      rounded = 0.0;
    }

    if (rounded == rounded.truncateToDouble()) {
      return rounded.toInt().toString();
    }
    
    return rounded.toString();
  }

  // Sinh học (hyperbolic)
  double _sinh(double x) {
    return (math.exp(x) - math.exp(-x)) / 2;
  }

  double _cosh(double x) {
    return (math.exp(x) + math.exp(-x)) / 2;
  }

  double _tanh(double x) {
    return _sinh(x) / _cosh(x);
  }

  // Tính giai thừa n!
  int _factorial(int n) {
    if (n == 0 || n == 1) {
      return 1;
    }
    int result = 1;
    for (int i = 2; i <= n; i++) {
      result = result * i;
    }
    return result;
  }
}
