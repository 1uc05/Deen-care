import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/texts_provider.dart';
import '../providers/session_provider.dart';
import '../providers/navigation_provider.dart';
import '../core/constants/app_colors.dart';
import '../widgets/calendar/reservation_card.dart';
import '../widgets/home/home_text_card.dart';
import '../screens/text_memorization_screen.dart';
import '../models/arabic_text.dart';
import '../core/utils/date_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      child: Column(
        children: [
          AppBar(
            title: const Text('Accueil'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _signOut(context),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header d'accueil
                  _buildWelcomeHeader(context),
                  
                  const SizedBox(height: 24),
                  
                  // Section Mémorisation
                  _buildMemorizationSection(context),
                  
                  const SizedBox(height: 24),
                  
                  // Section Session
                  _buildSessionSection(context),
                  
                  const SizedBox(height: 24),
                  
                  // Actions rapides
                  _buildQuickActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header personnalisé
  Widget _buildWelcomeHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return Column(
          children: [
            // Logo en haut, séparé
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 60,
                  width: 160,
                  child: Image.asset(
                    'lib/assets/images/Deen-care_no-background.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Card gradient pour le texte d'accueil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryMedium],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salaam ${user?.name ?? 'Utilisateur'} ! 👋',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Continuons votre mémorisation du Coran',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }



  // Section Mémorisation
  Widget _buildMemorizationSection(BuildContext context) {
    return Consumer<TextsProvider>(
      builder: (context, textsProvider, child) {
        final trackedTexts = textsProvider.trackedTexts;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📖 Mémorisation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (trackedTexts.isNotEmpty)
                  TextButton(
                    onPressed: () => context.read<NavigationProvider>().goToTextes(),
                    child: const Text(
                      'Voir tous',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            
            // const SizedBox(height: 12),
            
            // Contenu adaptatif
            if (trackedTexts.isEmpty)
              _buildEmptyMemorizationCard(context)
            else
              _buildTrackedTextsGrid(context, trackedTexts, textsProvider),
          ],
        );
      },
    );
  }

  // Card vide pour mémorisation
  Widget _buildEmptyMemorizationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.backgroundLight, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book,
              color: AppColors.secondary,
              size: 32,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Commencez à mémoriser',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'Choisissez vos premières Sourates à apprendre par coeur',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 20),
          
          ElevatedButton.icon(
            onPressed: () => context.read<NavigationProvider>().goToTextes(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Choisir une Sourate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Grille des textes suivis
  Widget _buildTrackedTextsGrid(BuildContext context, List<ArabicText> trackedTexts, TextsProvider textsProvider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: trackedTexts.length,
      itemBuilder: (context, index) {
        final text = trackedTexts[index];
        final progress = textsProvider.getProgressForText(text.id);
        
        return HomeTextCard(
          text: text,
          progress: progress,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TextMemorizationScreen(text: text),
            ),
          ),
        );
      },
    );
  }

  // Section Session
  Widget _buildSessionSection(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        final hasSession = sessionProvider.hasActiveSession();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📅 Votre mentorat Coranique',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            
            const SizedBox(height: 12),
            
            if (!hasSession)
              _buildEmptySessionCard(context)
            else
              _buildActiveSessionCard(context, sessionProvider),
          ],
        );
      },
    );
  }

  // Card vide pour session
  Widget _buildEmptySessionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.backgroundLight, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today,
              color: AppColors.secondary,
              size: 32,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Réservez une session',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'Planifiez un créneau avec un mentor pour élaborer un plan de mémorisation et de récitation',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 20),
          
          ElevatedButton.icon(
            onPressed: () => context.read<NavigationProvider>().goToCalendar(),
            icon: const Icon(Icons.event_available, size: 18),
            label: const Text('Voir le calendrier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card session active
  Widget _buildActiveSessionCard(BuildContext context, SessionProvider sessionProvider) {
    final startTime = sessionProvider.currentSessionStartTime!;
    final endTime = sessionProvider.currentSessionEndTime!;
    
    return ReservationCard(
      startTime: startTime,
      endTime: endTime,
      onCancel: () => _cancelReservation(context),
      onGoToRoom: () => context.read<NavigationProvider>().goToRoom(),
      isLoading: false,
    );
  }

  // Actions rapides
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 Actions rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        
        const SizedBox(height: 12),
        
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  icon: Icons.library_books,
                  title: 'Toutes les Sourates',
                  subtitle: 'Parcourir la bibliothèque',
                  color: AppColors.secondary,
                  onTap: () => context.read<NavigationProvider>().goToTextes(),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildLastSessionCard(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Card dernière session
  Widget _buildLastSessionCard(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        // final lastSession = sessionProvider.getLastCompletedSession();
        final lastSession = null;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.backgroundLight, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.history,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              
              const SizedBox(height: 12),
              
              const Text(
                'Dernière session',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                lastSession != null 
                  ? '${_formatSessionDate(lastSession.startedAt)} ✅'
                  : 'Aucune session terminée',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Card action rapide
  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.backgroundLight, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper pour formater la date
  String _formatSessionDate(DateTime? date) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Hier';
    } else if (difference < 7) {
      return 'Il y a $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Annulation réservation
  Future<void> _cancelReservation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: const Text('Êtes-vous sûr de vouloir annuler votre réservation ?'),
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

    if (confirmed == true) {
      try {
        await context.read<SessionProvider>().cancelSlot();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réservation annulée avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  // Déconnexion
  Future<void> _signOut(BuildContext context) async {
    try {
      debugPrint('Nettoyage des providers avant la déconnexion');
      await context.read<SessionProvider>().reset();
      await context.read<TextsProvider>().reset();
      await context.read<AuthProvider>().signOut();
    } catch (e) {
      debugPrint('Erreur déconnexion: $e');
    }
  }
}
