import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/navigation_provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/calendar/month_calendar.dart';
import '../widgets/calendar/reservation_card.dart';
import '../widgets/calendar/gender_mentor_selector.dart';
import 'slots_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  MentorGender _selectedGender = MentorGender.none;

  @override
  void initState() {
    super.initState();
  }

  void _onDaySelected(DateTime selectedDay) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SlotsScreen(selectedDate: selectedDay),
      ),
    );
  }

  void _onGenderChanged(MentorGender gender) {
    setState(() {
      _selectedGender = gender;
    });
    // TODO: Intégrer avec la logique métier
  }

  Future<void> _cancelReservation() async {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réservation annulée avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      child: Column(
        children: [
          AppBar(
            title: const Text('Réservation'),
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            foregroundColor: AppColors.primary,
            centerTitle: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16), 
              child: Consumer<CalendarProvider>(
                builder: (context, calendarProvider, child) {
                  if (calendarProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (calendarProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            calendarProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => calendarProvider.loadAvailableSlots(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<SessionProvider>(
                          builder: (context, provider, child) {
                            if (provider.hasActiveSession()) {
                              return ReservationCard(
                                startTime: provider.currentSessionStartTime!,
                                endTime: provider.currentSessionEndTime!,
                                onCancel: () => _cancelReservation(),
                                onGoToRoom: () => context.read<NavigationProvider>().goToRoom(),
                                isLoading: provider.isLoading,
                              );
                            } else {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primaryMedium,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Sélectionnez une date pour voir les créneaux disponibles',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                        
                        // Selecteur de genre - Affiché seulement si pas de réservation active
                        Consumer<SessionProvider>(
                          builder: (context, sessionProvider, child) {
                            if (!sessionProvider.hasActiveSession()) {
                              return Column(
                                children: [
                                  const SizedBox(height: 20),
                                  GenderMentorSelector(
                                    selectedGender: _selectedGender,
                                    onGenderChanged: _onGenderChanged,
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        
                        const SizedBox(height: 20),

                        Column(
                          children: [
                            SizedBox(
                              height: 350,
                              child: MonthCalendar(
                                availableDays: calendarProvider.getAvailableDays(),
                                onDaySelected: _onDaySelected,
                              ),
                            ),

                            const SizedBox(height: 22),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.secondarySubtle,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildLegendItem(
                                    context,
                                    color: AppColors.primaryMedium,
                                    label: 'Disponible',
                                  ),
                                  _buildLegendItem(
                                    context,
                                    color: Colors.grey.shade300,
                                    label: 'Indisponible',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, {
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}