import 'package:flutter/material.dart';
import '../../models/text.dart';
import '../../models/user_progress.dart';
import '../../core/constants/app_colors.dart';

class TextCard extends StatelessWidget {
  final ArabicText text;
  final UserProgress? progress;
  final VoidCallback onTap;

  const TextCard({
    Key? key,
    required this.text,
    this.progress,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isTracked = progress != null;

return Card(
  elevation: isTracked ? 4 : 2,
  color: isTracked ? AppColors.backgroundLight : AppColors.background,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: isTracked 
      ? BorderSide(color: AppColors.primary, width: 1)
      : BorderSide.none,
  ),
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre et badge
          Row(
            children: [
              Expanded(
                child: Text(
                  text.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isTracked) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SUIVI',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Informations de progression ou invitation
          if (isTracked) ...[
            // Barre de progression
            LinearProgressIndicator(
              value: text.totalSegments > 0 
                ? progress!.currentSegment / text.totalSegments
                : 0.0,
              backgroundColor: AppColors.textGreyLight.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            
            const SizedBox(height: 8),
            
            // Texte de progression
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress!.currentSegment}/${text.totalSegments} segments',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
                Text(
                  text.totalSegments > 0
                    ? '${((progress!.currentSegment / text.totalSegments) * 100).round()}%'
                    : '0%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Invitation à suivre le texte
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: AppColors.textGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Appuyer pour suivre',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  ),
);

  }
}
