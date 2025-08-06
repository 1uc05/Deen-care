import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TextProgressIndicator extends StatelessWidget {
  final int currentSentence;
  final int totalSentences;

  const TextProgressIndicator({
    super.key,
    required this.currentSentence,
    required this.totalSentences,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalSentences > 0 
        ? currentSentence / totalSentences 
        : 0.0;
    final int percentage = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.backgroundLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Barre de progression
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.backgroundLight,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            minHeight: 6,
          ),
          
          const SizedBox(height: 12),
          
          // Informations progression
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentSentence/$totalSentences Versets',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
