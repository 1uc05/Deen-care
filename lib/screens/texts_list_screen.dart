import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/texts_provider.dart';
import '../widgets/texts/text_card.dart';
import '../core/constants/app_colors.dart';
import 'text_study_screen.dart';

class TextsListScreen extends StatefulWidget {
  const TextsListScreen({Key? key}) : super(key: key);

  @override
  State<TextsListScreen> createState() => _TextsListScreenState();
}

class _TextsListScreenState extends State<TextsListScreen> {
  @override
  void initState() {
    super.initState();
    // Chargement initial des données
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final provider = context.read<TextsProvider>();
    // TODO: Récupérer userId du AuthProvider ou UserProvider
    const userId = 'current_user_id'; // Placeholder
    
    await Future.wait([
      provider.loadAllTexts(),
      provider.loadUserProgress(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mémorisation'),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false, // Pas de bouton retour
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.background,
      body: Consumer<TextsProvider>(
        builder: (context, provider, child) {
          // Gestion état de chargement
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Gestion des erreurs
          if (provider.error != null) {
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
                    'Erreur de chargement',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadInitialData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // Cas aucun texte disponible
          if (provider.allTexts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 64,
                    color: AppColors.textGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun texte disponible',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les textes seront bientôt ajoutés',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Corps principal
          return RefreshIndicator(
            onRefresh: _loadInitialData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section textes suivis
                  if (provider.trackedTexts.isNotEmpty) ...[
                    _buildTrackedSection(context, provider),
                    const SizedBox(height: 32),
                  ],
                  
                  // Section autres textes
                  _buildAvailableSection(context, provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackedSection(BuildContext context, TextsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec compteur
        Row(
          children: [
            Text(
              'Textes suivis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                '${provider.trackedTextsCount}/3',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Liste des textes suivis
        ...provider.trackedTexts.map((text) {
          final progress = provider.getProgressForText(text.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextCard(
              text: text,
              progress: progress,
              onTap: () => _navigateToStudy(text.id),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAvailableSection(BuildContext context, TextsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Autres textes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Liste des textes disponibles
        if (provider.availableTexts.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Vous suivez tous les textes disponibles !',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[
          ...provider.availableTexts.map((text) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextCard(
                text: text,
                progress: null,
                onTap: () => _handleAddText(text.id, text.title),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  void _navigateToStudy(String textId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TextStudyScreen(textId: textId),
      ),
    );
  }

  Future<void> _handleAddText(String textId, String title) async {
    final provider = context.read<TextsProvider>();
    
    // Vérification limite
    if (provider.isLimitReached) {
      _showLimitReachedDialog();
      return;
    }

    // TODO: Récupérer userId du AuthProvider ou UserProvider
    const userId = 'current_user_id'; // Placeholder
    
    final success = await provider.addTextToTracked(userId, textId, title);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Texte "$title" ajouté au suivi'),
          backgroundColor: AppColors.secondary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLimitReachedDialog() {
    final provider = context.read<TextsProvider>();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Limite atteinte',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vous suivez déjà 3 textes. Pour en ajouter un nouveau, retirez d\'abord un texte existant.',
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 16),
              Text(
                'Textes actuellement suivis :',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...provider.trackedTexts.map((text) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          text.title,
                          style: TextStyle(color: AppColors.textGrey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Ferme le dialog
                          _handleRemoveText(text.id, text.title);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                        ),
                        child: const Text('Retirer'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleRemoveText(String textId, String title) async {
    // TODO: Récupérer userId du AuthProvider ou UserProvider
    const userId = 'current_user_id'; // Placeholder
    
    final provider = context.read<TextsProvider>();
    await provider.removeTextFromTracked(userId, textId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Texte "$title" retiré du suivi'),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
