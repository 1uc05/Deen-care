import 'package:flutter/material.dart';
import '../../models/text_sentence.dart';
import '../../core/constants/app_colors.dart';

class SentenceDisplay extends StatelessWidget {
  final TextSentence sentence;
  final bool showFrench;
  final bool showArabic;

  const SentenceDisplay({
    super.key,
    required this.sentence,
    required this.showFrench,
    required this.showArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phonétique arabe (toujours affiché)
          Text(
            sentence.phoneticArabic,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
          
          // Français (conditionnel)
          if (showFrench) ...[
            const SizedBox(height: 8),
            Text(
              sentence.french,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          // Arabe (conditionnel)
          if (showArabic) ...[
            const SizedBox(height: 8),
            Text(
              sentence.arabic,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textDark,
                height: 1.8,
                fontWeight: FontWeight.w500,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ],
          
          // Séparateur horizontal
          const SizedBox(height: 16),
          Container(
            height: 1,
            width: double.infinity,
            color: AppColors.backgroundLight,
          ),
        ],
      ),
    );
  }
}
