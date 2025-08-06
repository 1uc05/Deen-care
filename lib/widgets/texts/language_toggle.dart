import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class LanguageToggle extends StatelessWidget {
  final bool showFrench;
  final ValueChanged onChanged;

  const LanguageToggle({
    Key? key,
    required this.showFrench,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textGreyLight),
      ),
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(8),
        selectedColor: Colors.white,
        fillColor: AppColors.primary,
        color: AppColors.textGrey,
        borderColor: Colors.transparent,
        selectedBorderColor: Colors.transparent,
        constraints: const BoxConstraints(
          minWidth: 100,
          minHeight: 40,
        ),
        isSelected: [showFrench, !showFrench],
        onPressed: (index) {
          onChanged(index == 0);
        },
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Bilingue',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Arabe seul',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
