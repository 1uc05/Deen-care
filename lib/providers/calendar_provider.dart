import 'package:flutter/foundation.dart';
import '../models/slot.dart';
import '../core/services/firebase/calendar_service.dart';

enum CalendarLoadingState {
  initial,
  loading, 
  loaded,
  error,
}

enum BookingState {
  idle,
  booking,
  success,
  error,
}

class CalendarProvider with ChangeNotifier {
  final CalendarService _calendarService;

  // États publics
  CalendarLoadingState _loadingState = CalendarLoadingState.initial;
  BookingState _bookingState = BookingState.idle;
  
  List<Slot> _slots = [];
  String? _errorMessage;
  String? _bookingError;

  // Stream subscription pour les mises à jour temps réel
  Stream<List<Slot>>? _slotsStream;

  CalendarProvider({CalendarService? calendarService}) 
    : _calendarService = calendarService ?? CalendarService();

  // Getters
  CalendarLoadingState get loadingState => _loadingState;
  BookingState get bookingState => _bookingState;
  List<Slot> get slots => List.unmodifiable(_slots);
  String? get errorMessage => _errorMessage;
  String? get bookingError => _bookingError;
  
  // Getters de commodité
  bool get isLoading => _loadingState == CalendarLoadingState.loading;
  bool get hasError => _loadingState == CalendarLoadingState.error;
  bool get isBooking => _bookingState == BookingState.booking;
  bool get hasBookingError => _bookingState == BookingState.error;

  /// Obtient les créneaux disponibles d'un jour spécifique
  List<Slot> getSlotsForDay(DateTime day) {
    return _slots.where((slot) {
      return slot.startTime.year == day.year &&
             slot.startTime.month == day.month &&
             slot.startTime.day == day.day &&
             slot.status == SlotStatus.available;
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Obtient les jours ayant des créneaux disponibles
  Set<DateTime> getAvailableDays() {
    return _slots
        .where((slot) => slot.status == SlotStatus.available)
        .map((slot) => DateTime(
              slot.startTime.year,
              slot.startTime.month,
              slot.startTime.day,
            ))
        .toSet();
  }

  /// Charge les créneaux avec stream temps réel
  Future<void> loadAvailableSlots() async {
    if (_loadingState == CalendarLoadingState.loading) return;

    _setLoadingState(CalendarLoadingState.loading);
    _clearError();

    try {
      // Obtenir le stream des créneaux
      _slotsStream = _calendarService.getAvailableSlots();
      
      // Écouter les changements en temps réel
      _slotsStream!.listen(
        (slots) {
          _slots = slots;
          if (_loadingState != CalendarLoadingState.loaded) {
            _setLoadingState(CalendarLoadingState.loaded);
          }
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Erreur stream calendrier: $error');
          _setError('Erreur de synchronisation: $error');
        },
      );

    } catch (e) {
      debugPrint('Erreur chargement calendrier: $e');
      _setError('Impossible de charger les créneaux: $e');
    }
  }

  /// Force le rafraîchissement des données
  Future<void> refreshSlots() async {
    _clearError();
    
    try {
      // Re-déclencher le chargement
      await loadAvailableSlots();
    } catch (e) {
      debugPrint('Erreur refresh: $e');
      _setError('Erreur lors de l\'actualisation: $e');
    }
  }

  /// Réserve un créneau
  Future<void> bookSlot(Slot slot, String userId) async {
    if (_bookingState == BookingState.booking) return;

    _setBookingState(BookingState.booking);
    _clearBookingError();

    try {
      // Vérifications préalables
      if (slot.status != SlotStatus.available) {
        throw Exception('Ce créneau n\'est plus disponible');
      }

      if (hasExistingReservation(userId)) {
        throw Exception('Vous avez déjà une réservation en cours');
      }

      // Réserver le créneau
      if (slot.id == null) {
        throw Exception('Identifiant du créneau manquant');
      }
      await _calendarService.bookSlot(slot.id!);
      
      _setBookingState(BookingState.success);
      
      // Auto-reset du state après 3 secondes
      Future.delayed(const Duration(seconds: 3), () {
        if (_bookingState == BookingState.success) {
          _setBookingState(BookingState.idle);
        }
      });

    } catch (e) {
      debugPrint('Erreur réservation: $e');
      _setBookingError('Réservation échouée: $e');
    }
  }

  /// Annule une réservation
  Future<void> cancelReservation(String slotId) async {
    if (_bookingState == BookingState.booking) return;

    _setBookingState(BookingState.booking);
    _clearBookingError();

    try {
      await _calendarService.cancelBooking(slotId);
      _setBookingState(BookingState.success);
      
      // Auto-reset du state
      Future.delayed(const Duration(seconds: 3), () {
        if (_bookingState == BookingState.success) {
          _setBookingState(BookingState.idle);
        }
      });

    } catch (e) {
      debugPrint('Erreur annulation: $e');
      _setBookingError('Annulation échouée: $e');
    }
  }

  /// Vérifie si l'utilisateur a déjà une réservation
  bool hasExistingReservation(String userId) {
    return _slots.any((slot) => 
      slot.status == SlotStatus.reserved && slot.reservedBy == userId
    );
  }

  /// Obtient la réservation active de l'utilisateur
  Slot? getUserActiveReservation(String userId) {
    try {
      return _slots.firstWhere((slot) =>
        slot.status == SlotStatus.reserved && slot.reservedBy == userId
      );
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si un créneau est réservable
  bool canBookSlot(Slot slot, String userId) {
    return slot.status == SlotStatus.available && 
           !hasExistingReservation(userId) &&
           slot.startTime.isAfter(DateTime.now());
  }

  // Méthodes privées de gestion d'état
  void _setLoadingState(CalendarLoadingState state) {
    if (_loadingState != state) {
      _loadingState = state;
      notifyListeners();
    }
  }

  void _setBookingState(BookingState state) {
    if (_bookingState != state) {
      _bookingState = state;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    _setLoadingState(CalendarLoadingState.error);
  }

  void _setBookingError(String error) {
    _bookingError = error;
    _setBookingState(BookingState.error);
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _clearBookingError() {
    if (_bookingError != null) {
      _bookingError = null;
      notifyListeners();
    }
  }

  /// Reset complet du provider
  void reset() {
    _loadingState = CalendarLoadingState.initial;
    _bookingState = BookingState.idle;
    _slots.clear();
    _errorMessage = null;
    _bookingError = null;
    _slotsStream = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Le stream se ferme automatiquement
    super.dispose();
  }
}
