// lib/ui/screens/calculator_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/calculator_notifier.dart';
import '../../core/models/calculator_state.dart';
import '../theme/app_colors.dart';
import '../widgets/button_tile.dart';

// Màn hình chính của máy tính.
// Dùng OrientationBuilder để tự động chuyển layout khi xoay màn hình:
//   - Dọc  : bàn phím 4 cột chuẩn
//   - Ngang: thêm 6 cột bên trái với các nút khoa học
//
// Dùng ConsumerWidget để lắng nghe Riverpod provider.
class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    CalculatorState state = ref.watch(calculatorProvider);
    CalculatorNotifier notifier = ref.read(calculatorProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            // Chế độ ngang: hiển thị thêm bàn phím khoa học
            if (orientation == Orientation.landscape) {
              return LandscapeLayout(state: state, notifier: notifier);
            }
            // Chế độ dọc: layout chuẩn
            return PortraitLayout(state: state, notifier: notifier);
          },
        ),
      ),
    );
  }
}

// =============================================================================
// LAYOUT DỌC (Portrait)
// =============================================================================
class PortraitLayout extends StatelessWidget {
  final CalculatorState state;
  final CalculatorNotifier notifier;

  const PortraitLayout({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Nửa trên: phần hiển thị
        Expanded(
          flex: 5,
          child: DisplayPanel(state: state),
        ),

        // Đường kẻ phân cách
        const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.historyDivider,
          indent: 24,
          endIndent: 24,
        ),

        // Nửa dưới: bàn phím chuẩn
        Expanded(
          flex: 6,
          child: StandardKeyboard(state: state, notifier: notifier),
        ),
      ],
    );
  }
}

// =============================================================================
// LAYOUT NGANG (Landscape)
// Chia đôi màn hình theo chiều ngang:
//   - Bên trái: hiển thị + bàn phím khoa học
//   - Bên phải: bàn phím số chuẩn
// =============================================================================
class LandscapeLayout extends StatelessWidget {
  final CalculatorState state;
  final CalculatorNotifier notifier;

  const LandscapeLayout({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Cột trái: màn hình + bàn phím khoa học
        Expanded(
          flex: 6,
          child: Column(
            children: [
              // Phần hiển thị (thu nhỏ chiều cao)
              Expanded(
                flex: 3,
                child: DisplayPanel(state: state, compact: true),
              ),

              // Đường kẻ phân cách
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.historyDivider,
              ),

              // Bàn phím khoa học
              Expanded(
                flex: 5,
                child: ScientificKeyboard(state: state, notifier: notifier),
              ),
            ],
          ),
        ),

        // Đường kẻ dọc phân cách
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppColors.historyDivider,
        ),

        // Cột phải: bàn phím chuẩn
        Expanded(
          flex: 4,
          child: StandardKeyboard(state: state, notifier: notifier),
        ),
      ],
    );
  }
}

// =============================================================================
// PHẦN HIỂN THỊ (Display Panel)
// Gồm 3 phần xếp từ trên xuống dưới:
//   1. Danh sách lịch sử (cuộn được)
//   2. Biểu thức đang chờ (màu xám nhỏ)
//   3. Kết quả / số đang nhập (to, trắng)
// =============================================================================
class DisplayPanel extends StatelessWidget {
  final CalculatorState state;
  // compact: thu nhỏ font khi ở chế độ ngang
  final bool compact;

  const DisplayPanel({
    super.key,
    required this.state,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Danh sách lịch sử chiếm phần lớn phía trên
        Expanded(
          child: HistoryList(history: state.history),
        ),

        // Biểu thức đang xây dựng - chỉ hiện khi khác với display
        if (state.pendingExpression.isNotEmpty &&
            state.pendingExpression != state.display)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                state.pendingExpression,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.pendingText,
                  fontSize: compact ? 14 : 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),

        // Màn hình chính: hiển thị kết quả hoặc số đang nhập
        Padding(
          padding: EdgeInsets.fromLTRB(16, 2, 16, compact ? 8 : 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: AnimatedDisplay(
              text: state.error ?? state.display,
              isError: state.error != null,
              compact: compact,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// MÀN HÌNH CHÍNH CÓ ANIMATION
// Font size tự động thu nhỏ khi chuỗi dài.
// Đổi sang màu đỏ khi có lỗi.
// =============================================================================
class AnimatedDisplay extends StatelessWidget {
  final String text;
  final bool isError;
  final bool compact;

  const AnimatedDisplay({
    super.key,
    required this.text,
    required this.isError,
    this.compact = false,
  });

  double _getFontSize() {
    // Khi compact (chế độ ngang), font nhỏ hơn
    double scale = compact ? 0.65 : 1.0;
    int length = text.length;

    double fontSize;
    if (length <= 6) {
      fontSize = 72;
    } else if (length <= 9) {
      fontSize = 56;
    } else if (length <= 12) {
      fontSize = 44;
    } else {
      fontSize = 32;
    }

    return fontSize * scale;
  }

  @override
  Widget build(BuildContext context) {
    Color textColor;
    if (isError) {
      textColor = AppColors.errorText;
    } else {
      textColor = AppColors.displayText;
    }

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 150),
      style: TextStyle(
        color: textColor,
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w300,
        letterSpacing: -1,
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
      ),
    );
  }
}

// =============================================================================
// DANH SÁCH LỊCH SỬ
// Cuộn ngược: phép tính mới nhất xuất hiện ở dưới cùng.
// =============================================================================
class HistoryList extends StatelessWidget {
  final List<CalculationRecord> history;

  const HistoryList({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      itemCount: history.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 2);
      },
      itemBuilder: (context, index) {
        CalculationRecord record = history[index];

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                '${record.expression} = ${record.result}',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.historyText,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// BÀN PHÍM CHUẨN (Standard Keyboard)
// Layout 5 hàng, mỗi hàng 4 nút (riêng hàng cuối nút 0 rộng gấp đôi).
// =============================================================================
class StandardKeyboard extends StatelessWidget {
  final CalculatorState state;
  final CalculatorNotifier notifier;

  const StandardKeyboard({
    super.key,
    required this.state,
    required this.notifier,
  });

  // Kiểm tra xem một toán tử có đang được chọn không
  bool _isOperatorActive(String op) {
    String expr = state.pendingExpression;
    if (expr.isEmpty) {
      return false;
    }
    String lastChar = expr[expr.length - 1];
    return lastChar == op;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: [
          // Hàng 1: AC, +/-, %, ÷
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ButtonTile(
                  label: 'AC',
                  type: ButtonType.function,
                  onTap: () => notifier.clearAll(),
                ),
                ButtonTile(
                  label: '+/-',
                  type: ButtonType.function,
                  onTap: () => notifier.toggleSign(),
                ),
                ButtonTile(
                  label: '%',
                  type: ButtonType.function,
                  onTap: () => notifier.addPercent(),
                ),
                ButtonTile(
                  label: '÷',
                  type: ButtonType.operator,
                  onTap: () => notifier.addOperator('/'),
                  isActive: _isOperatorActive('/'),
                ),
              ],
            ),
          ),

          // Hàng 2: 7, 8, 9, ×
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ButtonTile(
                  label: '7',
                  type: ButtonType.number,
                  onTap: () => notifier.addDigit('7'),
                ),
                ButtonTile(
                  label: '8',
                  type: ButtonType.number,
                  onTap: () => notifier.addDigit('8'),
                ),
                ButtonTile(
                  label: '9',
                  type: ButtonType.number,
                  onTap: () => notifier.addDigit('9'),
                ),
                ButtonTile(
                  label: '×',
                  type: ButtonType.operator,
                  onTap: () => notifier.addOperator('*'),
                  isActive: _isOperatorActive('*'),
                ),
              ],
            ),
          ),

          // Hàng 3: 4, 5, 6, −
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ButtonTile(
                  label: '4',
                  type: ButtonType.number,
                  onTap: () => notifier.addDigit('4'),
                ),
                ButtonTile(
                  label: '5',
                  type: ButtonType.number,
                  onTap: () => notifier.addDigit('5'),
                ),
                ButtonTile(
                  label: '6',
                  type: ButtonType.number,
                  onTap: () => notifier.addDigit('6'),
                ),
                ButtonTile(
                  label: '−',
                  type: ButtonType.operator,
                  onTap: () => notifier.addOperator('-'),
                  isActive: _isOperatorActive('-'),
                ),
              ],
            ),
          ),

          // Hàng 4: 1, 2, 3, +
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ButtonTile(
                  label: '1',
                  type: ButtonType.number,
                  onTap: () => notifier.addDigit('1'),
                ),
                ButtonTile(
                  label: '2',
                  type: ButtonType.number,
                  onTap: () => notifier.addDigit('2'),
                ),
                ButtonTile(
                  label: '3',
                  type: ButtonType.number,
                  onTap: () => notifier.addDigit('3'),
                ),
                ButtonTile(
                  label: '+',
                  type: ButtonType.operator,
                  onTap: () => notifier.addOperator('+'),
                  isActive: _isOperatorActive('+'),
                ),
              ],
            ),
          ),

          // Hàng 5: 0 (rộng gấp đôi), ., =
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ButtonTile(
                  label: '0',
                  type: ButtonType.number,
                  onTap: () => notifier.addDigit('0'),
                  flex: 2, // chiếm 2 phần thay vì 1
                ),
                ButtonTile(
                  label: '.',
                  type: ButtonType.number,
                  onTap: () => notifier.addDigit('.'),
                ),
                ButtonTile(
                  label: '=',
                  type: ButtonType.equal,
                  onTap: () => notifier.evaluate(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BÀN PHÍM KHOA HỌC (Scientific Keyboard) - chỉ hiện ở chế độ ngang
// Layout 5 hàng × 6 nút, giống iOS Calculator landscape
// =============================================================================
class ScientificKeyboard extends StatelessWidget {
  final CalculatorState state;
  final CalculatorNotifier notifier;

  const ScientificKeyboard({
    super.key,
    required this.state,
    required this.notifier,
  });

  // Nút khoa học gọn
  Widget _sciBtn(String label, VoidCallback onTap, {bool isActive = false}) {
    return ButtonTile(
      label: label,
      type: ButtonType.scientific,
      onTap: onTap,
      isActive: isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isRad = state.isRadian;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 4),
      child: Column(
        children: [
          // Hàng 1: (, ), mc, m+, m−, mr
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sciBtn('(', () => notifier.addParenthesis('(')),
                _sciBtn(')', () => notifier.addParenthesis(')')),
                // Bộ nhớ chưa hỗ trợ → hiển thị mờ nhưng không crash
                _sciBtn('mc', () {}),
                _sciBtn('m+', () {}),
                _sciBtn('m−', () {}),
                _sciBtn('mr', () {}),
              ],
            ),
          ),

          // Hàng 2: 2ⁿᵈ, x², x³, xʸ, eˣ, 10ˣ
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2ⁿᵈ: chưa dùng, placeholder
                _sciBtn('2ⁿᵈ', () {}),
                _sciBtn('x²', () => notifier.applyScientificFunction('square')),
                _sciBtn('x³', () => notifier.applyScientificFunction('cube')),
                _sciBtn('xʸ', () {
                  // Chưa hỗ trợ lũy thừa tùy ý - sẽ bổ sung sau
                }),
                _sciBtn('eˣ', () => notifier.applyScientificFunction('exp')),
                _sciBtn('10ˣ', () => notifier.applyScientificFunction('pow10')),
              ],
            ),
          ),

          // Hàng 3: 1/x, ²√x, ³√x, ʸ√x, ln, log₁₀
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sciBtn('1/x', () => notifier.applyScientificFunction('reciprocal')),
                _sciBtn('²√x', () => notifier.applyScientificFunction('sqrt')),
                _sciBtn('³√x', () => notifier.applyScientificFunction('cbrt')),
                // ʸ√x: cần 2 tham số, đơn giản hóa = sqrt
                _sciBtn('ʸ√x', () => notifier.applyScientificFunction('sqrt')),
                _sciBtn('ln', () => notifier.applyScientificFunction('ln')),
                _sciBtn('log₁₀', () => notifier.applyScientificFunction('log10')),
              ],
            ),
          ),

          // Hàng 4: x!, sin, cos, tan, e, EE
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sciBtn('x!', () => notifier.applyScientificFunction('factorial')),
                _sciBtn('sin', () => notifier.applyScientificFunction('sin')),
                _sciBtn('cos', () => notifier.applyScientificFunction('cos')),
                _sciBtn('tan', () => notifier.applyScientificFunction('tan')),
                _sciBtn('e', () => notifier.insertConstant('e')),
                // EE (×10ˣ): đơn giản hóa
                _sciBtn('EE', () => notifier.applyScientificFunction('pow10')),
              ],
            ),
          ),

          // Hàng 5: Rad/Deg, sinh, cosh, tanh, π, Rand
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nút Rad/Deg: bấm để đổi chế độ, sáng hơn khi là Rad
                _sciBtn(
                  isRad ? 'Rad' : 'Deg',
                  () => notifier.toggleRadianDegree(),
                  isActive: isRad,
                ),
                _sciBtn('sinh', () => notifier.applyScientificFunction('sinh')),
                _sciBtn('cosh', () => notifier.applyScientificFunction('cosh')),
                _sciBtn('tanh', () => notifier.applyScientificFunction('tanh')),
                _sciBtn('π', () => notifier.insertConstant('pi')),
                _sciBtn('Rand', () => notifier.insertRandom()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
