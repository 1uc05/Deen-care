import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/arabic_text.dart';
import '../providers/texts_provider.dart';
import '../widgets/texts/progress_indicator.dart';
import '../core/constants/app_colors.dart';

class TextMemorizationScreen extends StatefulWidget {
  final ArabicText text;

  const TextMemorizationScreen({
    super.key,
    required this.text,
  });

  @override
  State<TextMemorizationScreen> createState() => _TextMemorizationScreenState();
}

class _TextMemorizationScreenState extends State<TextMemorizationScreen> {
  int _currentMaxSentence = 0; // Nombre de versets débloqués
  bool _hasUnsavedChanges = false;
  bool _isLoading = true;
  bool _isRevealingLetters = false; // État révélation temporaire

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialState() {
    final provider = context.read<TextsProvider>();
    final progress = provider.getProgressForText(widget.text.id);

    if (progress != null && progress.currentSentence > 0) {
      _currentMaxSentence = progress.currentSentence;
    } else {
      _currentMaxSentence = 0; // Commence par le premier verset seulement
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _revealNextSentence() {
    if (_currentMaxSentence < widget.text.sentences.length - 1) {
      setState(() {
        _currentMaxSentence++;
        _hasUnsavedChanges = true;
      });
      
      // Auto-scroll vers le nouveau verset
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  String _formatWordWithMask(String word) {
    if (word.isEmpty) return word;
    return word[0] + '_' * (word.length - 1);
  }

  bool _isTextCompleted() {
    return _currentMaxSentence >= widget.text.sentences.length - 1;
  }

  Future<void> _saveProgress() async {
    try {
      final provider = context.read<TextsProvider>();
      await provider.saveProgress(widget.text.id, _currentMaxSentence);
      
      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progression sauvegardée'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _resetProgress() async {
    final shouldReset = await _showResetConfirmation();
    if (!shouldReset) return;

    try {
      final provider = context.read<TextsProvider>();
      await provider.saveProgress(widget.text.id, 0);

      setState(() {
        _currentMaxSentence = 0;
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progression remise à zéro'),
            backgroundColor: AppColors.noStatus,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _showResetConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer la progression ?'),
        content: const Text(
          'Cette action remettra votre progression à zéro. Cette action est irréversible.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textDark),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Effacer'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _showSaveConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sauvegarder avant de quitter ?'),
        content: const Text(
          'Vous avez des modifications non sauvegardées. Voulez-vous les sauvegarder ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Quitter sans sauvegarder'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldSave = await _showSaveConfirmation();
    if (shouldSave) {
      await _saveProgress();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assistant de mémorisation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
            // Bouton Reset
            IconButton(
              onPressed: _resetProgress,
              icon: const Icon(Icons.restart_alt),
              tooltip: 'Recommencer',
            ),
            // Bouton Sauvegarder
            IconButton(
              onPressed: _hasUnsavedChanges ? _saveProgress : null,
              icon: Icon(
                Icons.save,
                color: _hasUnsavedChanges ? Colors.white : Colors.white54,
              ),
              tooltip: 'Sauvegarder',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Indicateur de progression
                  TextProgressIndicator(
                    currentSentence: _currentMaxSentence,
                    totalSentences: widget.text.sentences.length,
                  ),

                  // Zone d'affichage du texte
                  Expanded(
                    child: _isTextCompleted()
                        ? _buildCompletionView()
                        : _buildTextView(),
                  ),

                  // Boutons en bas
                  if (!_isTextCompleted()) _buildBottomButtons(),
                ],
              ),
      ),
    );
  }

  Widget _buildTextView() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Affichage des versets débloqués
          ...List.generate(_currentMaxSentence + 1, (sentenceIndex) {
            return _buildSentenceDisplay(sentenceIndex);
          }),
        ],
      ),
    );
  }

  Widget _buildSentenceDisplay(int sentenceIndex) {
    final sentence = widget.text.sentences[sentenceIndex];
    final words = sentence.phoneticArabic.split(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numéro de verset
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sentenceIndex == 0 ? 'Basmala' : 'Verset $sentenceIndex',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Mots avec masquage ou révélation
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: words.map((word) {
              return Text(
                _isRevealingLetters ? word : _formatWordWithMask(word),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                  height: 1.6,
                ),
              );
            }).toList(),
          ),

          // Séparateur
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

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton révéler lettres
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isRevealingLetters = true),
              onTapUp: (_) => setState(() => _isRevealingLetters = false),
              onTapCancel: () => setState(() => _isRevealingLetters = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isRevealingLetters ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 18,
                      color: _isRevealingLetters ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Révéler Versets',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _isRevealingLetters ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Bouton verset suivant
          Expanded(
            child: GestureDetector(
              onTap: _currentMaxSentence < widget.text.sentences.length - 1 
                  ? _revealNextSentence 
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _currentMaxSentence < widget.text.sentences.length - 1
                      ? AppColors.secondary
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      size: 18,
                      color: _currentMaxSentence < widget.text.sentences.length - 1
                          ? Colors.white
                          : AppColors.textGreyLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verset suivant',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _currentMaxSentence < widget.text.sentences.length - 1
                            ? Colors.white
                            : AppColors.textGreyLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 64,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 24),
            Text(
              'Félicitations !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Vous avez terminé la mémorisation de cette Sourate.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _resetProgress,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Recommencer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
