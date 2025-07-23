import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_provider.dart';
import '../providers/auth_provider.dart';
import '../models/slot.dart';
import '../core/constants/app_colors.dart';
import '../widgets/calendar/booking_popup.dart';

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
    final dateFormatter = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
    
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
          Container(
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
                  dateFormatter.format(widget.selectedDate),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.highLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sélectionnez un créneau pour réserver',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
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

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: daySlots.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final slot = daySlots[index];
                    return _buildSlotItem(slot);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotItem(Slot slot) {
    final timeFormatter = DateFormat('HH:mm');
    final startTime = timeFormatter.format(slot.startTime);
    final endTime = timeFormatter.format(slot.endTime);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _isBooking ? null : () => _showBookingConfirmation(slot),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.highLight.withOpacity(0.2),
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
                  color: AppColors.highLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.access_time,
                  color: AppColors.highLight,
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
                        color: AppColors.highLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Durée: $startTime - $endTime (30 min)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Flèche ou loader
              if (_isBooking)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.highLight,
                  ),
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
      final authProvider = context.read<AuthProvider>();

      await calendarProvider.bookSlot(slot, authProvider.user!.id);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la réservation: $e'),
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
