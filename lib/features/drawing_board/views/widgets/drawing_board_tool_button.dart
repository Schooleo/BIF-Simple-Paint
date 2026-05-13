import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ToolButton extends StatelessWidget {
  const ToolButton({super.key, required this.icon, this.isActive = false});

  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color border = colors.borderSubtle;
    final Color activeBackground = colors.overlaySelection;
    final Color idleBackground = colors.surfacePrimary;
    final Color iconColor = isActive ? colors.iconActive : colors.iconMuted;

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
