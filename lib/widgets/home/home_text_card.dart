import 'package:flutter/material.dart';
import '../../models/arabic_text.dart';
import '../../models/text_progress.dart';
import '../../core/constants/app_colors.dart';

class HomeTextCard extends StatelessWidget {
  final ArabicText text;
  final TextProgress? progress;
  final VoidCallback onTap;

  const HomeTextCard({
    super.key,
    required this.text,
    this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasProgress = progress != null;

    // Phrase 1 ignorée, commence à phrase 2
    final int adjustedTotal = text.totalSentences <= 1 ? 1 : text.totalSentences - 1;

    final progressValue = hasProgress 
        ? (progress!.currentSentence / adjustedTotal).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (progressValue * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasProgress ? AppColors.primaryMedium : AppColors.backgroundLight,
            width: hasProgress ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (hasProgress ? AppColors.primary : AppColors.backgroundLight).withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'N°${text.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (hasProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Titre français (tronqué)
              Text(
                text.titleFrench,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Titre arabe (tronqué)
              Text(
                text.titleArabic,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textGrey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
              ),
              
              const SizedBox(height: 8),
              
              // Progress section - toujours présente mais contenu variable
              if (hasProgress) ...[
                LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: AppColors.backgroundLight,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 3,
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress!.currentSentence}/$adjustedTotal versets',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textGrey,
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${text.sentences.length} versets',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
