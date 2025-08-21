import 'package:intl/intl.dart';

class AppDateUtils {
  // Formatters statiques
  static final DateFormat _dayFormat = DateFormat('d');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'fr_FR');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('EEEE dd MMMM', 'fr_FR');
  static final DateFormat _fullDateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');

  /// Formate un jour (ex: "15")
  static String formatDay(DateTime date) => _dayFormat.format(date);

  /// Formate un mois et année (ex: "Janvier 2024")
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// Formate une heure (ex: "14:30")
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Formate une date (ex: "Lundi 15 janvier")
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Formate une date complète (ex: "Lundi 15 janvier 2024")
  static String formatFullDate(DateTime date) => _fullDateFormat.format(date);

  /// Vérifie si deux dates sont le même jour
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Vérifie si une date est aujourd'hui
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Vérifie si une date est dans le passé
  static bool isPastDay(DateTime date) {
    final today = DateTime.now();
    return date.isBefore(DateTime(today.year, today.month, today.day));
  }

  /// Obtient le premier jour du mois
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Obtient le dernier jour du mois
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Génère la liste des jours à afficher dans le calendrier mensuel
  /// Inclut les jours du mois précédent et suivant pour remplir la grille
  static List<DateTime> getCalendarDays(DateTime month) {
    final firstDay = getFirstDayOfMonth(month);
    final lastDay = getLastDayOfMonth(month);
    
    // Premier lundi de la grille (peut être du mois précédent)
    final startDate = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    
    // Dernier dimanche de la grille (peut être du mois suivant)
    final endDate = lastDay.add(Duration(days: 7 - lastDay.weekday));
    
    final days = <DateTime>[];
    var current = startDate;
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return days;
  }

  /// Obtient les jours du mois actuel uniquement
  static List<DateTime> getDaysInMonth(DateTime month) {
    final firstDay = getFirstDayOfMonth(month);
    final lastDay = getLastDayOfMonth(month);
    
    final days = <DateTime>[];
    var current = firstDay;
    
    while (current.isBefore(lastDay) || current.isAtSameMomentAs(lastDay)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return days;
  }

  /// Obtient le mois précédent
  static DateTime getPreviousMonth(DateTime date) {
    return DateTime(date.year, date.month - 1, 1);
  }

  /// Obtient le mois suivant
  static DateTime getNextMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 1);
  }

  /// Obtient les noms des jours de la semaine (L, M, M, J, V, S, D)
  static List<String> getWeekdayHeaders() {
    return ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  }
}
