import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/arabic_text.dart';
import '../providers/texts_provider.dart';
import '../widgets/texts/sentence_display.dart';
import '../core/constants/app_colors.dart';
import 'text_memorization_screen.dart';

class TextScreen extends StatefulWidget {
  final ArabicText text;

  const TextScreen({
    super.key,
    required this.text,
  });

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  bool _showFrench = false;
  bool _showArabic = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text.titleArabic,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.text.titleFrench,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Numéro du texte
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Texte ${widget.text.id}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Boutons toggle
          Container(
            width: double.infinity,
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
            child: Row(
              children: [
                // Toggle Français
                Expanded(
                  child: _buildToggleButton(
                    'Français',
                    _showFrench,
                    () => setState(() => _showFrench = !_showFrench),
                  ),
                ),
                const SizedBox(width: 12),
                // Toggle العربية
                Expanded(
                  child: _buildToggleButton(
                    'العربية',
                    _showArabic,
                    () => setState(() => _showArabic = !_showArabic),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des phrases
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.text.sentences.length,
              itemBuilder: (context, index) {
                return SentenceDisplay(
                  sentence: widget.text.sentences[index],
                  showFrench: _showFrench,
                  showArabic: _showArabic,
                );
              },
            ),
          ),
        ],
      ),
      
      // FloatingActionButton pour mémorisation
      floatingActionButton: Consumer<TextsProvider>(
        builder: (context, provider, child) {
          final isTracked = provider.isTextTracked(widget.text.id);
          
          return FloatingActionButton.extended(
            onPressed: provider.isLoading 
                ? null 
                : () => _handleMemorizationTap(context, provider, isTracked),
            backgroundColor: isTracked ? AppColors.secondary : AppColors.primary,
            foregroundColor: Colors.white,
            icon: Icon(
              isTracked ? Icons.psychology : Icons.add_circle_outline,
            ),
            label: Text(
              isTracked 
                  ? 'Assistant de mémorisation'
                  : 'Ajouter aux Sourates à mémoriser',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildToggleButton(
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.backgroundLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gère le tap sur le FAB selon l'état du texte (NOUVEAU)
  Future<void> _handleMemorizationTap(
    BuildContext context,
    TextsProvider provider,
    bool isTracked,
  ) async {
    if (isTracked) {
      // Texte déjà suivi → Navigation vers mémorisation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TextMemorizationScreen(text: widget.text),
        ),
      );
    } else {
      // Texte non suivi → Vérifier si on peut l'ajouter
      if (provider.canAddMoreTexts) {
        // Ajouter le texte au suivi
        await provider.addTextToProgress(widget.text.id);
        
        if (mounted) {
          // Feedback de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Texte "${widget.text.titleFrench}" ajouté aux textes suivis',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.secondary,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        // Maximum atteint → Message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Maximum 3 textes suivis. Supprimez un texte pour en ajouter un nouveau.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.noStatus,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
