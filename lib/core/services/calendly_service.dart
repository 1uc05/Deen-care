// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../models/calendar_slot.dart';

// // Service singleton Calendly
// class CalendlyService {
//   static final CalendlyService _instance = CalendlyService._internal();
//   factory CalendlyService() => _instance;
//   CalendlyService._internal();

//   // API Key privative, à stocker en sécurité !
//   static const String apiKey = 'TON_CALENDLY_API_KEY';
//   static const String baseUrl = 'https://api.calendly.com';

//   Map<String, String> get _headers => {
//     'Authorization': 'Bearer $apiKey',
//     'Content-Type': 'application/json',
//     'Accept': 'application/json',
//   };

//   /// Récupère les créneaux disponibles pour les 7 prochains jours
//   Future<List<CalendarSlot>> getAvailableSlots() async {
//     try {
//       final now = DateTime.now();
//       final in7days = now.add(const Duration(days: 7));
//       // Calendly API: à adapter selon tes endpoints réels de slots dispo
//       final url = Uri.parse('$baseUrl/scheduled_events?organization=ORG_ID&user=USER_ID'
//           '&min_start_time=${now.toUtc().toIso8601String()}'
//           '&max_start_time=${in7days.toUtc().toIso8601String()}');
//       final response = await http.get(url, headers: _headers);

//       if (response.statusCode == 200) {
//         final List<dynamic> events = json.decode(response.body)['collection'];
//         return events.map((e) => CalendarSlot.fromCalendlyJson(e)).toList();
//       } else {
//         final errorMsg = _extractErrorMessage(response.body) 
//             ?? 'Erreur Calendly ${response.statusCode}';
//         throw CalendlyServiceException(errorMsg);
//       }
//     } catch (e) {
//       throw CalendlyServiceException('Impossible de charger les créneaux : $e');
//     }
//   }

//   /// Réserve un créneau Calendly (RDV)
//   Future<void> bookSlot(String slotId) async {
//     try {
//       final url = Uri.parse('$baseUrl/scheduled_events/$slotId/invitees');
//       final response = await http.post(
//         url,
//         headers: _headers,
//         body: json.encode({
//           // Le body exact dépend de l’API Calendly, à adapter.
//           // Ex : 'invitee': {'email': ...}, etc.
//         }),
//       );

//       if (response.statusCode != 201) {
//         final errorMsg = _extractErrorMessage(response.body)
//             ?? 'Erreur réservation ${response.statusCode}';
//         throw CalendlyServiceException(errorMsg);
//       }
//     } catch (e) {
//       throw CalendlyServiceException('Erreur lors de la réservation : $e');
//     }
//   }

//   /// Extraction d’un message d’erreur explicite Calendly (si dispo)
//   String? _extractErrorMessage(String body) {
//     try {
//       final Map<String, dynamic> jsonBody = json.decode(body);
//       if (jsonBody.containsKey('message')) return jsonBody['message'];
//       if (jsonBody.containsKey('error')) return jsonBody['error'];
//     } catch (_) {}
//     return null;
//   }
// }

// // Exception métier claire pour le service Calendly
// class CalendlyServiceException implements Exception {
//   final String message;
//   CalendlyServiceException(this.message);

//   @override
//   String toString() => 'CalendlyServiceException: $message';
// }
