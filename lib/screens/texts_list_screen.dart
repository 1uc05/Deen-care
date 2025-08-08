import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deen_care/core/constants/app_constants.dart';
import '../providers/texts_provider.dart';
import '../widgets/texts/text_card.dart';
import '../core/constants/app_colors.dart';
import '../models/arabic_text.dart';
import 'text_screen.dart';

class TextsListScreen extends StatefulWidget {
  const TextsListScreen({super.key});

  @override
  State<TextsListScreen> createState() => _TextsListScreenState();
}

class _TextsListScreenState extends State<TextsListScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TextsProvider>(context, listen: false);
      provider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mémorisation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: Consumer<TextsProvider>(
        builder: (context, provider, child) {
          // Gestion du loading
          if (provider.isLoading && provider.allTexts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
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
                    size: 48,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.error!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _handleRetry(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // Liste vide
          if (provider.allTexts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _handleRefresh(provider),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_books_outlined,
                          size: 48,
                          color: AppColors.textGreyLight,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucun Sourate disponible',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textGrey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tirez vers le bas pour actualiser',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textGreyLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final trackedTexts = provider.trackedTexts;
          final availableTexts = provider.availableTexts;

          return RefreshIndicator(
            onRefresh: () => _handleRefresh(provider),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Section textes suivis
                if (trackedTexts.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Sourates à mémoriser',
                    '${trackedTexts.length}/${AppConstants.maxTrackedTexts}',
                    AppColors.primary,
                  ),
                  ...trackedTexts.map((text) => TextCard(
                    text: text,
                    isTracked: true,
                    progress: provider.getProgressForText(text.id),
                    onTap: () => _navigateToText(context, text),
                  )),
                  const SizedBox(height: 16),
                ],

                // Section textes disponibles
                if (availableTexts.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Autres sourates',
                    '${availableTexts.length} Sourates',
                    AppColors.textGrey,
                  ),
                  ...availableTexts.map((text) => TextCard(
                    text: text,
                    isTracked: false,
                    progress: null,
                    onTap: () => _navigateToText(context, text),
                  )),
                ],

                // Espace en bas pour le scroll
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Gère le pull-to-refresh (NOUVEAU)
  Future<void> _handleRefresh(TextsProvider provider) async {
    try {
      await provider.refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'actualisation: $e'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    }
  }

  /// Gère la tentative de rechargement après erreur
  Future<void> _handleRetry(TextsProvider provider) async {
    await provider.initialize();
  }

  Widget _buildSectionHeader(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToText(BuildContext context, ArabicText text) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TextScreen(text: text),
      ),
    );
  }
}
