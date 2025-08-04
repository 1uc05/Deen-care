import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_utils.dart';

class ReservationCard extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final VoidCallback onCancel;
  final VoidCallback onGoToRoom;
  final bool isLoading;

  const ReservationCard({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onCancel,
    required this.onGoToRoom,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.highLight.withOpacity(0.1),
            AppColors.highLight.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.highLight.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.highLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_available,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votre réservation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.highLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Créneau confirmé',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Informations date et heure
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.highLight.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.highLight,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppDateUtils.formatFullDate(startTime),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: AppColors.highLight,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppDateUtils.formatTime(startTime)} - ${AppDateUtils.formatTime(endTime)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'action
          Row(
            children: [
              // Bouton Annuler
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onCancel,
                  icon: isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Annuler'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Bouton Aller au salon
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onGoToRoom,
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Aller au salon'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.highLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
