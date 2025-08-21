import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/arabic_text.dart';
import '../../models/text_progress.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/texts_provider.dart';

class TextCard extends StatelessWidget {
  final ArabicText text;
  final bool isTracked;
  final TextProgress? progress;
  final VoidCallback onTap;

  const TextCard({
    super.key,
    required this.text,
    required this.isTracked,
    this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: isTracked 
          ? Border.all(color: AppColors.primary, width: 2)
          : null,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: isTracked 
              ? AppColors.primaryLight
              : AppColors.boxShadow,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec numéro discret et action favorite
                Row(
                  children: [
                    // Numéro discret
                    Text(
                      'Sourate ${text.id}',
                      style: TextStyle(
                        color: AppColors.textGreyLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Bouton étoile pour ajouter/retirer
                    _buildFavoriteButton(context),
                    
                    const SizedBox(width: 8),
                    
                    // Flèche navigation
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textGreyLight,
                      size: 20,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Titres avec meilleur espacement  
                Text(
                  text.titleArabic,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    height: 1.4,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 6),
                
                Text(
                  text.titleFrench,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                    height: 1.3,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Progression redesignée
                if (isTracked && progress != null) ...[
                  const SizedBox(height: 16),
                  _buildProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return Consumer<TextsProvider>(
      builder: (context, provider, child) {
        return InkWell(
          onTap: () => _handleFavoriteToggle(context, provider),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(
              isTracked ? Icons.star : Icons.star_border,
              color: isTracked ? AppColors.secondary : AppColors.textGreyLight,
              size: 22,
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleFavoriteToggle(BuildContext context, TextsProvider provider) async {    
    try {
      if (isTracked) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Retirer des favoris'),
            backgroundColor: AppColors.backgroundLight,
            content: const Text('Êtes-vous sûr de vouloir retirer ce Sourate de vos favoris ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Non', style: TextStyle(color: AppColors.textDark)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Oui', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        // Retirer des favoris
        await provider.removeTextFromProgress(text.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vous ne suivez plus ce Sourate'),
              backgroundColor: AppColors.textGrey,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Ajouter aux favoris 
        if(!provider.canAddMoreTexts) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum 3 Sourates suivis autorisés'),
              backgroundColor: AppColors.noStatus,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        final success = await provider.addTextToProgress(text.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success 
                ? 'Sourate ajouté aux sourates à maitriser'
                : 'Maximum 3 Sourates suivis autorisés'),
              backgroundColor: success ? AppColors.secondary : AppColors.noStatus,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildProgressIndicator() {
    if (progress == null) return const SizedBox.shrink();
    
    final progressPercent = progress!.currentSentence / text.totalSentences;
    final progressText = '${progress!.currentSentence}/${text.totalSentences} Versets';
    final isCompleted = progressPercent.round() >= 1;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.secondarySubtle : AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? AppColors.secondaryLight : AppColors.primaryLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 16,
                color: isCompleted ? AppColors.secondary : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progressText,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted ? AppColors.secondary : AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.secondary : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progressPercent * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPercent,
              backgroundColor: AppColors.backgroundLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.secondary : AppColors.primary
              ),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }
}
