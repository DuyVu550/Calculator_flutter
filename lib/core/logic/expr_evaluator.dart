// lib/core/logic/expr_evaluator.dart

// Bộ tính toán biểu thức toán học dạng chuỗi.
// Ví dụ: evaluate("2 + 3 * (5 - 1)") trả về 14.0
//
// Cách hoạt động gồm 3 bước:
//   Bước 1 - Tokenize : tách chuỗi thành danh sách token
//   Bước 2 - Shunting-Yard : chuyển infix sang RPN (hậu tố)
//   Bước 3 - Eval RPN : tính kết quả từ RPN

class ExpressionEvaluator {
  // Độ ưu tiên của từng toán tử
  // Nhân/chia ưu tiên hơn cộng/trừ
  int _getPrecedence(String op) {
    if (op == '+' || op == '-') {
      return 1;
    }
    if (op == '*' || op == '/') {
      return 2;
    }
    if (op == '@') {
      // '@' là ký hiệu nội bộ cho dấu trừ đơn (unary minus)
      // Ưu tiên cao nhất
      return 3;
    }
    return 0;
  }

  bool _isOperator(String token) {
    return token == '+' || token == '-' || token == '*' || token == '/';
  }

  // =========================================================================
  // HÀM CÔNG KHAI: evaluate
  // Nhận vào một chuỗi biểu thức, trả về kết quả dạng double.
  // Ném FormatException nếu biểu thức không hợp lệ.
  // =========================================================================
  double evaluate(String expr) {
    List<String> tokens = _tokenize(expr.trim());

    if (tokens.isEmpty) {
      throw const FormatException('Biểu thức rỗng');
    }

    List<String> rpn = _toRPN(tokens);
    return _evalRPN(rpn);
  }

  // =========================================================================
  // BƯỚC 1: TOKENIZE
  // Tách chuỗi thành danh sách token.
  // "12+3*(5-1)" → ["12", "+", "3", "*", "(", "5", "-", "1", ")"]
  //
  // Trường hợp đặc biệt: dấu trừ đơn (unary minus)
  //   Ví dụ: "-5 + 3" hay "2 * (-4)"
  //   Được nhận biết khi '-' xuất hiện ở đầu hoặc ngay sau toán tử/'('
  //   Được thay bằng ký hiệu '@' để phân biệt với phép trừ thông thường
  // =========================================================================
  List<String> _tokenize(String expr) {
    List<String> tokens = [];
    String buffer = ''; // dùng để gom các chữ số lại thành một số

    for (int i = 0; i < expr.length; i++) {
      String ch = expr[i];

      // Bỏ qua khoảng trắng
      if (ch == ' ') {
        continue;
      }

      // Nếu là chữ số hoặc dấu chấm thập phân → thêm vào buffer
      if (_isDigitOrDot(ch)) {
        buffer = buffer + ch;
        continue;
      }

      // Gặp ký tự khác → flush buffer (lưu số vừa gom được)
      if (buffer.isNotEmpty) {
        tokens.add(buffer);
        buffer = '';
      }

      if (ch == '(' || ch == ')') {
        tokens.add(ch);
        continue;
      }

      if (_isOperator(ch)) {
        // Phát hiện dấu trừ đơn (unary minus)
        bool isUnary = false;

        if (ch == '-') {
          if (tokens.isEmpty) {
            isUnary = true; // đứng đầu biểu thức
          } else {
            String prev = tokens[tokens.length - 1];
            if (_isOperator(prev) || prev == '(') {
              isUnary = true; // đứng sau toán tử hoặc ngoặc mở
            }
          }
        }

        if (isUnary) {
          tokens.add('@'); // '@' = unary minus
        } else {
          tokens.add(ch);
        }
        continue;
      }

      // Ký tự không hợp lệ
      throw FormatException('Ký tự không hợp lệ: "$ch"');
    }

    // Flush buffer lần cuối
    if (buffer.isNotEmpty) {
      tokens.add(buffer);
    }

    return tokens;
  }

  bool _isDigitOrDot(String ch) {
    int code = ch.codeUnitAt(0);
    bool isDigit = code >= 48 && code <= 57; // '0' đến '9'
    bool isDot = ch == '.';
    return isDigit || isDot;
  }

  // =========================================================================
  // BƯỚC 2: SHUNTING-YARD → chuyển infix thành RPN
  // Thuật toán của Dijkstra để xử lý độ ưu tiên và ngoặc đúng thứ tự.
  //
  // Ví dụ:  ["2", "+", "3", "*", "4"]  →  ["2", "3", "4", "*", "+"]
  // Kết quả: 2 + (3 * 4) = 14
  // =========================================================================
  List<String> _toRPN(List<String> tokens) {
    List<String> output = [];  // kết quả đầu ra (RPN)
    List<String> opStack = []; // ngăn xếp toán tử tạm thời

    for (int i = 0; i < tokens.length; i++) {
      String token = tokens[i];

      // Nếu là số → đưa thẳng vào output
      if (double.tryParse(token) != null) {
        output.add(token);
        continue;
      }

      // Unary minus '@' → đẩy vào stack (sẽ xử lý sau)
      if (token == '@') {
        opStack.add(token);
        continue;
      }

      // Nếu là toán tử nhị phân
      if (_isOperator(token)) {
        // Pop các toán tử trong stack có độ ưu tiên >= token hiện tại
        while (opStack.isNotEmpty &&
            opStack[opStack.length - 1] != '(' &&
            _getPrecedence(opStack[opStack.length - 1]) >= _getPrecedence(token)) {
          output.add(opStack.removeLast());
        }
        opStack.add(token);
        continue;
      }

      // Nếu là ngoặc mở → đẩy vào stack
      if (token == '(') {
        opStack.add(token);
        continue;
      }

      // Nếu là ngoặc đóng → pop cho đến khi gặp ngoặc mở
      if (token == ')') {
        bool foundOpen = false;

        while (opStack.isNotEmpty) {
          String top = opStack.removeLast();
          if (top == '(') {
            foundOpen = true;
            break;
          }
          output.add(top);
        }

        if (!foundOpen) {
          throw const FormatException('Dấu ngoặc không khớp');
        }

        // Nếu ngay sau ngoặc đóng là '@' (unary) thì pop luôn
        if (opStack.isNotEmpty && opStack[opStack.length - 1] == '@') {
          output.add(opStack.removeLast());
        }
        continue;
      }

      // Ký tự hợp lệ với Tokenizer nhưng không hợp lệ ở bước này (ví dụ '.5.')
      throw FormatException('Token không hợp lệ: "$token"');
    }

    // Pop toàn bộ phần còn lại trong stack vào output
    while (opStack.isNotEmpty) {
      String op = opStack.removeLast();
      if (op == '(') {
        throw const FormatException('Dấu ngoặc không khớp');
      }
      output.add(op);
    }

    return output;
  }

  // =========================================================================
  // BƯỚC 3: TÍNH KẾT QUẢ TỪ RPN
  // Duyệt danh sách RPN, dùng một stack để tính toán.
  //
  // Ví dụ RPN: ["2", "3", "4", "*", "+"]
  //   Đọc "2"  → stack: [2]
  //   Đọc "3"  → stack: [2, 3]
  //   Đọc "4"  → stack: [2, 3, 4]
  //   Đọc "*"  → pop 4 và 3, tính 3*4=12, push → stack: [2, 12]
  //   Đọc "+"  → pop 12 và 2, tính 2+12=14, push → stack: [14]
  //   Kết quả: 14
  // =========================================================================
  double _evalRPN(List<String> rpn) {
    List<double> stack = [];

    for (int i = 0; i < rpn.length; i++) {
      String token = rpn[i];

      // Unary minus: lấy 1 số trên stack, đổi dấu rồi push lại
      if (token == '@') {
        if (stack.isEmpty) {
          throw const FormatException('Biểu thức không hợp lệ');
        }
        double value = stack.removeLast();
        stack.add(-value);
        continue;
      }

      // Nếu là số → push vào stack
      double? number = double.tryParse(token);
      if (number != null) {
        stack.add(number);
        continue;
      }

      // Nếu là toán tử → lấy 2 số, tính rồi push kết quả
      if (_isOperator(token)) {
        if (stack.length < 2) {
          throw const FormatException('Biểu thức không hợp lệ');
        }

        double b = stack.removeLast(); // số bên phải
        double a = stack.removeLast(); // số bên trái
        double result = 0;

        if (token == '+') {
          result = a + b;
        } else if (token == '-') {
          result = a - b;
        } else if (token == '*') {
          result = a * b;
        } else if (token == '/') {
          result = a / b;
        }

        stack.add(result);
        continue;
      }

      throw FormatException('Token không hợp lệ: "$token"');
    }

    if (stack.length != 1) {
      throw const FormatException('Biểu thức không hợp lệ');
    }

    return stack[0];
  }
}
