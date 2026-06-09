// lib/ui/theme/app_colors.dart

import 'package:flutter/material.dart';

// Toàn bộ màu sắc của app được định nghĩa tập trung ở đây.
// Không hard-code màu rải rác trong các widget.
class AppColors {
  // Màu nền chính (tối)
  static const Color background = Color(0xFF1C1C1E);

  // Màu nền các nút số
  static const Color btnNumber = Color(0xFF333335);
  static const Color btnNumberText = Colors.white;

  // Màu nền các nút chức năng: AC, +/-, %
  static const Color btnFunction = Color(0xFF636366);
  static const Color btnFunctionText = Colors.white;

  // Màu nền các nút toán tử: +, -, *, /
  static const Color btnOperator = Color(0xFFFF9F0A);
  static const Color btnOperatorText = Colors.white;

  // Khi nút toán tử đang được chọn thì đảo màu nền/chữ
  static const Color btnOperatorActive = Colors.white;
  static const Color btnOperatorActiveText = Color(0xFFFF9F0A);

  // Màu nút bằng (=)
  static const Color btnEqual = Color(0xFFFF9F0A);
  static const Color btnEqualText = Colors.white;

  // Màu nền nút khoa học (chế độ ngang): tối hơn nút số
  static const Color btnScientific = Color(0xFF1E1E20);
  static const Color btnScientificText = Color(0xFFE0E0E0);

  // Màu nền nút khoa học đang active (Rad/Deg)
  static const Color btnScientificActive = Color(0xFF636366);
  static const Color btnScientificActiveText = Colors.white;

  // Màu chữ trên màn hình hiển thị
  static const Color displayText = Colors.white;

  // Màu chữ cho biểu thức đang chờ (nhỏ hơn, xám hơn)
  static const Color pendingText = Color(0xFF8E8E93);

  // Màu chữ khi có lỗi
  static const Color errorText = Color(0xFFFF453A);

  // Màu chữ lịch sử tính toán
  static const Color historyText = Color(0xFF636366);

  // Màu đường kẻ phân cách lịch sử và bàn phím
  static const Color historyDivider = Color(0xFF38383A);
}
