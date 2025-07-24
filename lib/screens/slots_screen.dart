import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/session_provider.dart';
import '../models/slot.dart';
import '../core/constants/app_colors.dart';
import '../widgets/calendar/booking_popup.dart';
import '../core/utils/date_utils.dart';

class SlotsScreen extends StatefulWidget {
  final DateTime selectedDate;

  const SlotsScreen({
    required this.selectedDate,
    super.key,
  });

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  bool _isBooking = false;

  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Créneaux disponibles',
          style: TextStyle(color: AppColors.highLight),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.highLight,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec la date sélectionnée
          Consumer<CalendarProvider>(
            builder: (context, calendarProvider, child) {
              final hasActiveSession = calendarProvider.hasActiveSession;
              
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.highLight.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.highLight.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.formatFullDate(widget.selectedDate),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.highLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasActiveSession
                        ? 'Un créneau est déjà réservé'
                        : 'Sélectionnez un créneau pour réserver',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasActiveSession 
                          ? Colors.orange.shade700  // Couleur différente si bloqué
                          : AppColors.textGrey,
                      ),
                    ),
                    if (hasActiveSession) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Terminez votre session actuelle pour réserver',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // Liste des créneaux
          Expanded(
            child: Consumer<CalendarProvider>(
              builder: (context, calendarProvider, child) {
                if (calendarProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.highLight,
                    ),
                  );
                }

                // Filtrer les créneaux pour le jour sélectionné
                final daySlots = calendarProvider.getSlotsForDay(widget.selectedDate);

                if (daySlots.isEmpty) {
                  return _buildEmptyState();
                }

                final hasActiveSession = calendarProvider.hasActiveSession;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: daySlots.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final slot = daySlots[index];
                    return _buildSlotItem(slot, isBlocked: hasActiveSession); // ✅ Passer le statut
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotItem(Slot slot, {required bool isBlocked}) { // ✅ Paramètre ajouté
    final startTime = AppDateUtils.formatTime(slot.startTime);
    final endTime = AppDateUtils.formatTime(slot.endTime);

    return Card(
      elevation: isBlocked ? 1 : 2, // ✅ Élévation réduite si bloqué
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: (isBlocked || _isBooking) ? null : () => _showBookingConfirmation(slot), // ✅ Condition modifiée
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isBlocked 
                ? Colors.grey.shade300 // ✅ Bordure grise si bloqué
                : AppColors.highLight.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icône horaire
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isBlocked
                    ? Colors.grey.shade100 // ✅ Couleur terne si bloqué
                    : AppColors.highLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isBlocked ? Icons.lock_outline : Icons.access_time, // ✅ Icône différente
                  color: isBlocked
                    ? Colors.grey.shade400
                    : AppColors.highLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Informations du créneau
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startTime,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isBlocked
                          ? Colors.grey.shade500 // ✅ Texte gris si bloqué
                          : AppColors.highLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isBlocked 
                        ? 'Non disponible - Session en cours' // ✅ Texte différent
                        : 'Durée: $startTime - $endTime (30 min)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isBlocked
                          ? Colors.grey.shade400
                          : AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Flèche, loader ou icône bloquée
              if (_isBooking)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.highLight,
                  ),
                )
              else if (isBlocked)
                Icon(
                  Icons.block, // ✅ Icône de blocage
                  color: Colors.grey.shade400,
                  size: 20,
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.highLight,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Le reste des méthodes restent identiques...
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun créneau disponible',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez une autre date',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour au calendrier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.highLight,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBookingConfirmation(Slot slot) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BookingPopup(slot: slot),
    );

    if (result == true && mounted) {
      await _bookSlot(slot);
    }
  }

  Future<void> _bookSlot(Slot slot) async {
    if (_isBooking) return;

    setState(() => _isBooking = true);

    try {
      final calendarProvider = context.read<CalendarProvider>();

      await calendarProvider.bookSlot(slot);

      if (mounted) {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Créneau réservé avec succès !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Retour à la page home (index 0)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }
}
