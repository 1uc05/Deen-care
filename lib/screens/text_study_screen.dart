import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/texts_provider.dart';
import '../widgets/texts/segment_display.dart';
import '../widgets/texts/language_toggle.dart';
import '../widgets/texts/progress_indicator.dart';
import '../core/constants/app_colors.dart';

class TextStudyScreen extends StatefulWidget {
  final String textId;
  
  const TextStudyScreen({
    Key? key,
    required this.textId,
  }) : super(key: key);

  @override
  State<TextStudyScreen> createState() => _TextStudyScreenState();
}

class _TextStudyScreenState extends State<TextStudyScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeStudy();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeStudy() async {
    final provider = context.read<TextsProvider>();
    
    try {
      await provider.selectTextForStudy(widget.textId);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TextsProvider>(
      builder: (context, provider, child) {
        return WillPopScope(
          onWillPop: () => _handleBackPress(provider),
          child: Scaffold(
            appBar: _buildAppBar(context, provider),
            backgroundColor: AppColors.background,
            body: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, provider),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, TextsProvider provider) {
    final currentText = provider.currentStudyText;
    
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.textDark),
        onPressed: () => _handleBackPress(provider),
      ),
      title: Text(
        currentText?.title ?? 'Étude en cours...',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        // Toggle langue
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: LanguageToggle(
            showFrench: provider.showFrench,
            onChanged: (value) => provider.toggleLanguageMode(),
          ),
        ),
        
        // Bouton reset
        IconButton(
          icon: Icon(Icons.refresh, color: AppColors.textGrey),
          onPressed: () => _showResetConfirmation(provider),
          tooltip: 'Recommencer',
        ),
        
        // Bouton sauvegarde
        IconButton(
          icon: Icon(
            Icons.save,
            color: provider.hasUnsavedChanges 
              ? AppColors.accent
              : AppColors.textGrey,
          ),
          onPressed: provider.hasUnsavedChanges 
            ? () => _saveProgress(provider)
            : null,
          tooltip: 'Sauvegarder',
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, TextsProvider provider) {
    final currentText = provider.currentStudyText;
    
    if (currentText == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger le texte',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeStudy,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header avec progression
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            border: Border(
              bottom: BorderSide(
                color: AppColors.textGreyLight.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: TextProgressIndicator(
            currentSegment: provider.currentSegmentIndex,
            totalSegments: currentText.totalSegments,
            showPercentage: false,
          ),
        ),
        
        // Zone d'affichage du texte
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SegmentDisplay(
                  displayText: provider.displayedText,
                ),
                
                // Espace pour éviter que le bouton masque le texte
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(TextsProvider provider) {
    if (!provider.canShowNextSegment) {
      return Container(); // Pas de bouton si fini
    }

    return FloatingActionButton.extended(
      onPressed: () {
        provider.showNextSegment();
        // Scroll automatique vers le bas après révélation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      },
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      label: const Text(
        'Segment suivant',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      icon: const Icon(Icons.arrow_forward),
    );
  }

  Future<bool> _handleBackPress(TextsProvider provider) async {
    if (provider.hasUnsavedChanges) {
      final shouldSave = await _showSaveConfirmation();
      if (shouldSave == true) {
        await _saveProgress(provider);
      } else if (shouldSave == null) {
        return false; // Annuler la sortie
      }
    }
    return true; // Autoriser la sortie
  }

  Future<void> _saveProgress(TextsProvider provider) async {
    try {
      // TODO: Récupérer userId du AuthProvider ou UserProvider
      const userId = 'current_user_id'; // Placeholder
      
      await provider.saveCurrentProgress(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Progression sauvegardée'),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<bool?> _showSaveConfirmation() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Sauvegarder la progression ?',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Vous avez des changements non sauvegardés. Voulez-vous les sauvegarder avant de quitter ?',
            style: TextStyle(color: AppColors.textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Quitter sans sauvegarder',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(
                'Annuler',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Sauvegarder'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showResetConfirmation(TextsProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Recommencer le texte ?',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Cette action effacera définitivement votre progression actuelle. Êtes-vous sûr de vouloir recommencer ?',
            style: TextStyle(color: AppColors.textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Annuler',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: const Text('Recommencer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // TODO: Récupérer userId du AuthProvider ou UserProvider
      const userId = 'current_user_id'; // Placeholder
      
      try {
        await provider.resetTextProgress(userId, widget.textId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Progression remise à zéro'),
              backgroundColor: AppColors.accent,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Scroll vers le haut après reset
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la remise à zéro: $e'),
              backgroundColor: AppColors.accent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
