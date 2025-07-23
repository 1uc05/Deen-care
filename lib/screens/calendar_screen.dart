import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/calendar/month_calendar.dart';
import '../providers/calendar_provider.dart';
import '../core/constants/app_colors.dart';
import 'slots_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    // Initialiser le provider au premier chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarProvider>().loadAvailableSlots();
    });
  }

  void _onDaySelected(DateTime selectedDay) {
    // Navigation vers la liste des créneaux du jour sélectionné
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SlotsScreen(selectedDate: selectedDay),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Réservation'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.highLight,
          centerTitle: true,
        ),
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

              if (calendarProvider.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
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
                          backgroundColor: AppColors.highLight,
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
                    // Instructions pour l'utilisateur
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.highLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.highLight.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.highLight,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sélectionnez une date pour voir les créneaux disponibles',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.highLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Calendrier plein écran
                    Expanded(
                      child: MonthCalendar(
                        availableDays: calendarProvider.getAvailableDays(),
                        onDaySelected: _onDaySelected,
                      ),
                    ),
                    
                    // Légende en bas
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLegendItem(
                            context,
                            color: AppColors.highLight,
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
              );
            },
          ),
        ),
      ],
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
