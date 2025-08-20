import 'package:flutter/material.dart';
import '../../core/utils/date_utils.dart';
import '../../core/constants/app_colors.dart';

class MonthCalendar extends StatefulWidget {
  final Function(DateTime) onDaySelected;
  final Set<DateTime> availableDays; // Jours avec créneaux disponibles

  const MonthCalendar({
    required this.onDaySelected,
    required this.availableDays,
    super.key,
  });

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildWeekdayHeaders(),
          const SizedBox(height: 10),
          _buildCalendarGrid(), // ✅ SUPPRESSION d'Expanded
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left, size: 28),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
        Text(
          AppDateUtils.formatMonthYear(_currentMonth),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right, size: 28),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    return Row(
      children: AppDateUtils.getWeekdayHeaders().map((weekday) {
        return Expanded(
          child: Center(
            child: Text(
              weekday,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final calendarDays = AppDateUtils.getCalendarDays(_currentMonth);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.1, // ✅ ASPECT RATIO légèrement plus large pour plus d'espace vertical
        mainAxisSpacing: 4,    // ✅ ESPACEMENT vertical entre les cellules
        crossAxisSpacing: 4,   // ✅ ESPACEMENT horizontal entre les cellules
      ),
      itemCount: calendarDays.length,
      itemBuilder: (context, index) {
        final day = calendarDays[index];
        return _buildDayCell(day);
      },
    );
  }

  Widget _buildDayCell(DateTime day) {
    final isCurrentMonth = day.month == _currentMonth.month;
    final isToday = AppDateUtils.isToday(day);
    final isPast = AppDateUtils.isPastDay(day);
    final hasSlots = _hasAvailableSlots(day);
    final isSelectable = isCurrentMonth && !isPast && hasSlots;

    return GestureDetector(
      onTap: isSelectable ? () => widget.onDaySelected(day) : null,
      child: Container(
        margin: const EdgeInsets.all(1), // ✅ MARGE réduite pour optimiser l'espace
        decoration: BoxDecoration(
          color: _getDayBackgroundColor(isToday, hasSlots, isCurrentMonth, isPast),
          borderRadius: BorderRadius.circular(8),
          border: isToday 
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        ),
        child: Center(
          child: Text(
            AppDateUtils.formatDay(day),
            style: TextStyle(
              color: _getDayTextColor(isCurrentMonth, isPast, hasSlots, isToday),
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Color _getDayBackgroundColor(bool isToday, bool hasSlots, bool isCurrentMonth, bool isPast) {
    if (!isCurrentMonth || isPast) return Colors.transparent;
    if (hasSlots) return AppColors.primaryLight;
    return Colors.transparent;
  }

  Color _getDayTextColor(bool isCurrentMonth, bool isPast, bool hasSlots, bool isToday) {
    if (!isCurrentMonth) return Colors.grey.shade300;
    if (isPast) return Colors.grey.shade400;
    if (hasSlots) return AppColors.primary;
    if (isToday) return AppColors.primary;
    return Colors.grey.shade600;
  }

  bool _hasAvailableSlots(DateTime day) {
    return widget.availableDays.any((availableDay) => 
      AppDateUtils.isSameDay(availableDay, day)
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      if (delta > 0) {
        _currentMonth = AppDateUtils.getNextMonth(_currentMonth);
      } else {
        _currentMonth = AppDateUtils.getPreviousMonth(_currentMonth);
      }
    });
  }
}
