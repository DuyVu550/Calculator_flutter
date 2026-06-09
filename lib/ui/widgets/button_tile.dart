// lib/ui/widgets/button_tile.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Loại nút để xác định màu sắc tự động
enum ButtonType {
  number,     // nút số: 0-9, .
  function,   // nút chức năng: AC, +/-, %
  operator,   // nút toán tử: +, -, *, /
  equal,      // nút bằng: =
  scientific, // nút khoa học: sin, cos, tan, ln, ...
}

// Widget nút bấm tái sử dụng cho bàn phím máy tính.
//
// Tham số:
//   label    : chữ hiển thị trên nút
//   type     : loại nút → quyết định màu nền và màu chữ
//   onTap    : hàm gọi khi người dùng nhấn
//   flex     : độ rộng (1 = bình thường, 2 = nút 0 rộng gấp đôi)
//   isActive : true khi nút toán tử đang được chọn (đảo màu)
class ButtonTile extends StatelessWidget {
  final String label;
  final ButtonType type;
  final VoidCallback onTap;
  final int flex;
  final bool isActive;

  const ButtonTile({
    super.key,
    required this.label,
    required this.type,
    required this.onTap,
    this.flex = 1,
    this.isActive = false,
  });

  // Xác định màu nền dựa trên loại nút và trạng thái active
  Color _getBackgroundColor() {
    if (isActive && type == ButtonType.operator) {
      return AppColors.btnOperatorActive;
    }

    if (isActive && type == ButtonType.scientific) {
      return AppColors.btnScientificActive;
    }

    if (type == ButtonType.number) {
      return AppColors.btnNumber;
    }

    if (type == ButtonType.function) {
      return AppColors.btnFunction;
    }

    if (type == ButtonType.operator) {
      return AppColors.btnOperator;
    }

    if (type == ButtonType.equal) {
      return AppColors.btnEqual;
    }

    if (type == ButtonType.scientific) {
      return AppColors.btnScientific;
    }

    return AppColors.btnNumber;
  }

  // Xác định màu chữ dựa trên loại nút và trạng thái active
  Color _getTextColor() {
    if (isActive && type == ButtonType.operator) {
      return AppColors.btnOperatorActiveText;
    }

    if (isActive && type == ButtonType.scientific) {
      return AppColors.btnScientificActiveText;
    }

    if (type == ButtonType.number) {
      return AppColors.btnNumberText;
    }

    if (type == ButtonType.function) {
      return AppColors.btnFunctionText;
    }

    if (type == ButtonType.operator) {
      return AppColors.btnOperatorText;
    }

    if (type == ButtonType.equal) {
      return AppColors.btnEqualText;
    }

    if (type == ButtonType.scientific) {
      return AppColors.btnScientificText;
    }

    return AppColors.btnNumberText;
  }

  // Màu hiệu ứng gợn sóng khi nhấn
  Color _getSplashColor() {
    if (type == ButtonType.operator || type == ButtonType.equal) {
      return Colors.white.withValues(alpha: 0.25);
    }
    return Colors.white.withValues(alpha: 0.15);
  }

  // Cỡ chữ: nút 1 ký tự lớn hơn nút nhiều ký tự
  double _getFontSize() {
    if (label.length == 1) {
      return 32;
    }
    if (label.length == 2) {
      return 26;
    }
    if (label.length <= 4) {
      return 18;
    }
    return 14;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: AspectRatio(
          // Nút 0 (flex=2) dùng tỉ lệ ngang để không bị vuông méo
          aspectRatio: flex == 2 ? 2.18 : 1.0,
          child: Material(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(50), // bo tròn hình viên thuốc
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(50),
              splashColor: _getSplashColor(),
              highlightColor: Colors.transparent,
              child: Center(
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Nội dung bên trong nút: icon cho nút xóa, text cho các nút còn lại
  Widget _buildContent() {
    if (label == '⌫') {
      return Icon(
        Icons.backspace_outlined,
        color: _getTextColor(),
        size: 22,
      );
    }

    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _getTextColor(),
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w500,
        height: 1,
      ),
    );
  }
}
