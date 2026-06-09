// lib/core/models/calculator_state.dart

// Lưu thông tin một phép tính đã hoàn thành.
class CalculationRecord {
  final String expression; // ví dụ: "2+3*4"
  final String result;     // ví dụ: "14"
  final DateTime timestamp;

  CalculationRecord({
    required this.expression,
    required this.result,
    required this.timestamp,
  });
}

// ---------------------------------------------------------------------------

// Toàn bộ trạng thái của máy tính tại một thời điểm.
// Class này là bất biến (immutable): mỗi khi thay đổi,
// ta tạo một bản sao mới thay vì sửa trực tiếp.
class CalculatorState {
  // Chuỗi đang hiển thị trên màn hình chính, mặc định là "0"
  final String display;

  // Biểu thức toán học đang được xây dựng, ví dụ: "12+3*"
  final String pendingExpression;

  // Danh sách các phép tính đã thực hiện
  final List<CalculationRecord> history;

  // Thông báo lỗi, null nếu không có lỗi
  final String? error;

  // Toán tử và số hạng của phép tính vừa thực hiện.
  // Dùng để lặp lại phép tính khi bấm "=" liên tiếp.
  // Ví dụ: 1+1=2 → lưu repeatOperator="+", repeatOperand="1"
  //        bấm "=" lần 2 → tính 2+1=3, lần 3 → 3+1=4, ...
  final String? repeatOperator;
  final String? repeatOperand;

  // Chế độ góc: true = Radian, false = Độ
  // Dùng cho các hàm lượng giác sin/cos/tan
  final bool isRadian;

  const CalculatorState({
    this.display = '0',
    this.pendingExpression = '',
    this.history = const [],
    this.error,
    this.repeatOperator,
    this.repeatOperand,
    this.isRadian = false,
  });

  // Tạo bản sao mới với một số trường được thay đổi.
  // Các trường không truyền vào sẽ giữ nguyên giá trị cũ.
  CalculatorState copyWith({
    String? display,
    String? pendingExpression,
    List<CalculationRecord>? history,
    String? error,
    bool clearError = false,       // dùng để xóa lỗi (đặt error = null)
    String? repeatOperator,
    String? repeatOperand,
    bool clearRepeat = false,      // dùng để xóa repeatOperator/repeatOperand
    bool? isRadian,
  }) {
    return CalculatorState(
      display: display ?? this.display,
      pendingExpression: pendingExpression ?? this.pendingExpression,
      history: history ?? this.history,
      error: clearError ? null : (error ?? this.error),
      repeatOperator: clearRepeat ? null : (repeatOperator ?? this.repeatOperator),
      repeatOperand: clearRepeat ? null : (repeatOperand ?? this.repeatOperand),
      isRadian: isRadian ?? this.isRadian,
    );
  }

  // Thêm một record mới vào đầu danh sách lịch sử.
  // Tự động xóa phần tử cũ nhất nếu vượt quá giới hạn.
  CalculatorState addRecord(CalculationRecord record) {
    const int maxHistory = 50;

    List<CalculationRecord> newHistory = [record, ...history];

    if (newHistory.length > maxHistory) {
      newHistory = newHistory.sublist(0, maxHistory);
    }

    return copyWith(history: newHistory);
  }
}
