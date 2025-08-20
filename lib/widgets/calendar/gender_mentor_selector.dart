import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum MentorGender { none, female, male }

class GenderMentorSelector extends StatefulWidget {
  final MentorGender selectedGender;
  final ValueChanged<MentorGender> onGenderChanged;

  const GenderMentorSelector({
    required this.selectedGender,
    required this.onGenderChanged,
    super.key,
  });

  @override
  State<GenderMentorSelector> createState() => _GenderMentorSelectorState();
}

class _GenderMentorSelectorState extends State<GenderMentorSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryMedium,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Préférence de mentor',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGenderButton(
                  context: context,
                  gender: MentorGender.female,
                  icon: Icons.woman,
                  label: 'Femme',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderButton(
                  context: context,
                  gender: MentorGender.male,
                  icon: Icons.man,
                  label: 'Homme',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton({
    required BuildContext context,
    required MentorGender gender,
    required IconData icon,
    required String label,
  }) {
    final isSelected = widget.selectedGender == gender;
    
    return GestureDetector(
      onTap: () {
        // Si déjà sélectionné, on désélectionne (retour à "none")
        final newGender = isSelected ? MentorGender.none : gender;
        widget.onGenderChanged(newGender);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primaryMedium,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
