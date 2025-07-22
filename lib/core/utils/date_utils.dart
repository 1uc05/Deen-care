// import 'package:intl/intl.dart';

// class DateUtilsFr {
//   static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');
//   static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
//   static final DateFormat _hourMinuteFormat = DateFormat('HH:mm', 'fr_FR');

//   /// Formate une date en français, exemple : 16/06/2024 à 14:30
//   static String formatDateTimeFr(DateTime date) {
//     return _dateTimeFormat.format(date);
//   }

//   /// Formate seulement la date (sans heure) en français
//   static String formatDateFr(DateTime date) {
//     return _dateFormat.format(date);
//   }

//   /// Formate l'heure-minute, exemple : 14:30
//   static String formatHourMinute(DateTime date) {
//     return _hourMinuteFormat.format(date);
//   }

//   /// Retourne une durée lisible, ex: "1h 25min", "45min"
//   static String formatDuration(Duration duration) {
//     if (duration.inHours > 0) {
//       return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
//     }
//     return '${duration.inMinutes}min';
//   }

//   /// Retourne true si la date passée est aujourd'hui
//   static bool isToday(DateTime date) {
//     final now = DateTime.now();
//     return date.year == now.year && date.month == now.month && date.day == now.day;
//   }

//   /// Retourne true si la date est dans le futur
//   static bool isInFuture(DateTime date) {
//     return date.isAfter(DateTime.now());
//   }

//   /// Retourne true si la date passée est dans moins de [minutes]
//   static bool isWithinMinutes(DateTime date, int minutes) {
//     final now = DateTime.now();
//     return date.isBefore(now.add(Duration(minutes: minutes))) && date.isAfter(now);
//   }
// }
