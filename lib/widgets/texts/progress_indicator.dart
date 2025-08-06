import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TextProgressIndicator extends StatelessWidget {
  final int currentSegment;
  final int totalSegments;
  final bool showPercentage;

  const TextProgressIndicator({
    Key? key,
    required this.currentSegment,
    required this.totalSegments,
    this.showPercentage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = totalSegments > 0 ? currentSegment / totalSegments : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barre de progression
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.textGreyLight.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 6,
        ),
        
        const SizedBox(height: 8),
        
        // Texte de progression
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              showPercentage
                ? '${(progress * 100).round()}% complété'
                : '$currentSegment/$totalSegments segments',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!showPercentage)
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}