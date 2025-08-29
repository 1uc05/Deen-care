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
  int _currentSentenceIndex = 0;
  int _currentWordIndex = 0;
  List<String> _currentWords = [];
  bool _hasUnsavedChanges = false;
  bool _isLoading = true;
  
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _lastWordKey = GlobalKey();

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
      _currentSentenceIndex = progress.currentSentence;
    }
    
    _updateCurrentWords();
    
    setState(() {
      _isLoading = false;
    });
  }

  void _updateCurrentWords() {
    if (_currentSentenceIndex < widget.text.sentences.length) {
      final sentence = widget.text.sentences[_currentSentenceIndex];
      _currentWords = sentence.phoneticArabic.split(' ');
      
      // Si on arrive sur une nouvelle phrase, commencer au premier mot
      if (_currentWordIndex >= _currentWords.length) {
        _currentWordIndex = 0;
      }
    }
  }

  void _revealNextWord() {
    if (_currentSentenceIndex >= widget.text.sentences.length) return;

    setState(() {
      _hasUnsavedChanges = true;
      
      if (_currentWordIndex < _currentWords.length - 1) {
        // Révéler le mot suivant dans la phrase courante
        _currentWordIndex++;
      } else if (_currentSentenceIndex < widget.text.sentences.length - 1) {
        // Passer à la phrase suivante
        _goToNextSentence();
      } else {
        _currentSentenceIndex++;
      }
    });

    // Scroll automatique vers le dernier mot révélé
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastWord();
    });
  }

  void _goToNextSentence() {
    _currentSentenceIndex++;
    _currentWordIndex = 0;
    _updateCurrentWords();
  }

  void _scrollToLastWord() {
    if (_lastWordKey.currentContext != null) {
      Scrollable.ensureVisible(
        _lastWordKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    }
  }

  bool _isTextCompleted() {
    return _currentSentenceIndex >= widget.text.sentences.length;
  }

  Future<void> _saveProgress() async {
    final provider = context.read<TextsProvider>();
    
    try {
      // Ajouter le texte au suivi s'il ne l'est pas déjà
      if (!provider.isTextTracked(widget.text.id)) {
        final added = await provider.addTextToProgress(widget.text.id);
        if (!added) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Limite de 3 Sourate atteinte'),
                backgroundColor: AppColors.noStatus,
              ),
            );
          }
          return;
        }
      }
      
      // Sauvegarder la progression
      await provider.saveProgress(widget.text.id, _currentSentenceIndex);
      
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
    final confirmed = await _showResetConfirmation();
    if (!confirmed) return;

    final provider = context.read<TextsProvider>();
    
    try {
      await provider.resetProgress(widget.text.id);
      
      setState(() {
        _currentSentenceIndex = 0;
        _currentWordIndex = 0;
        _hasUnsavedChanges = false;
        _updateCurrentWords();
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
            backgroundColor: AppColors.backgroundLight,
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
        backgroundColor: AppColors.backgroundLight,
        content: const Text(
          'Vous avez des modifications non sauvegardées. Voulez-vous les sauvegarder ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textDark),
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
                    currentSentence: _currentSentenceIndex,
                    totalSentences: widget.text.sentences.length,
                  ),
                  
                  // Zone d'affichage du texte
                  Expanded(
                    child: _isTextCompleted()
                        ? _buildCompletionView()
                        : _buildTextView(),
                  ),
                ],
              ),
        // Bouton flottant pour révéler le mot suivant
        floatingActionButton: _isTextCompleted() 
            ? null 
            : FloatingActionButton(
                onPressed: _revealNextWord,
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.touch_app, size: 28),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildTextView() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Affichage des phrases déjà complètes
          ...List.generate(_currentSentenceIndex, (sentenceIndex) {
            return _buildCompleteSentence(sentenceIndex);
          }),
          
          // Phrase courante avec révélation progressive
          if (_currentSentenceIndex < widget.text.sentences.length)
            _buildCurrentSentence(),
          
          // Espace pour le FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCompleteSentence(int sentenceIndex) {
    final sentence = widget.text.sentences[sentenceIndex];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numéro de phrase
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
          
          // Texte complet de la phrase
          Text(
            sentence.phoneticArabic,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
              height: 1.6,
            ),
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

  Widget _buildCurrentSentence() {
    final sentence = widget.text.sentences[_currentSentenceIndex];
    final words = sentence.phoneticArabic.split(' ');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numéro de phrase courante
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(

              _currentSentenceIndex == 0 ? 'Basmala (en cours)' : 'Verset $_currentSentenceIndex  (en cours)',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Mots révélés progressivement
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: List.generate(words.length, (wordIndex) {
              final isRevealed = wordIndex <= _currentWordIndex;
              final isLastRevealed = wordIndex == _currentWordIndex;
              
              return Container(
                key: isLastRevealed ? _lastWordKey : null,
                child: Text(
                  isRevealed ? words[wordIndex] : '____',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isRevealed ? AppColors.textDark : AppColors.textGreyLight,
                    height: 1.6,
                    decoration: isLastRevealed ? TextDecoration.underline : null,
                    decorationColor: AppColors.secondary,
                    decorationThickness: 2,
                  ),
                ),
              );
            }),
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
