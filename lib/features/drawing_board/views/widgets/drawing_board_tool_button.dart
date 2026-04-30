import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/core/theme/app_colors_dark.dart';
import 'package:flutter/material.dart';

class ToolButton extends StatelessWidget {
  const ToolButton({super.key, required this.icon, this.isActive = false});

  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color border = isDark ? AppColorsDark.border : AppColors.border;
    final Color activeBackground = isDark
        ? AppColorsDark.selectionLight
        : AppColors.selectionLight;
    final Color idleBackground = isDark
        ? AppColorsDark.surface
        : AppColors.surface;
    final Color iconColor = isActive
        ? (isDark ? AppColorsDark.iconActive : AppColors.icon)
        : (isDark ? AppColorsDark.icon : AppColors.iconInactive);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? activeBackground : idleBackground,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: iconColor),
    );
  }
}
