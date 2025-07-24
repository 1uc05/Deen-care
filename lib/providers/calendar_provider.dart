import 'package:flutter/foundation.dart';
import '../models/slot.dart';
import '../core/services/firebase/slots_service.dart';
import '../core/services/firebase/sessions_service.dart';

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
  final SlotsService _slotsService;
  final SessionsService _sessionsService;

  // Etat interne
  String? _currentUserId;
  List<Slot> _slots = [];
  String? _errorMessage;
  String? _bookingError;
  Stream<List<Slot>>? _slotsStream;
  Slot? _currentSlot;

  // États publics
  CalendarLoadingState _loadingState = CalendarLoadingState.initial;
  BookingState _bookingState = BookingState.idle;

  CalendarProvider({SlotsService? slotsService, SessionsService? sessionsService}) 
    : _slotsService = slotsService ?? SlotsService(),
      _sessionsService = sessionsService ?? SessionsService();

  // Getters
  CalendarLoadingState get loadingState => _loadingState;
  BookingState get bookingState => _bookingState;
  List<Slot> get slots => List.unmodifiable(_slots);
  String? get errorMessage => _errorMessage;
  String? get bookingError => _bookingError;
  Slot? get currentSlot => _currentSlot;
  bool get hasActiveSession => _currentSlot != null;

  // Getters de commodité
  bool get isLoading => _loadingState == CalendarLoadingState.loading;
  bool get hasError => _loadingState == CalendarLoadingState.error;
  bool get isBooking => _bookingState == BookingState.booking;
  bool get hasBookingError => _bookingState == BookingState.error;

  Slot? get userScheduledSlot {
    return _slots
        .where((slot) =>
            slot.reservedBy == _currentUserId &&
            slot.status == SlotStatus.reserved &&
            slot.sessionId != null &&
            slot.startTime.isAfter(DateTime.now()))
        .firstOrNull;
  }

  Future<void> initialize(String userId) async {
    try {
      _currentUserId = userId;

      final currentSlotId = await _sessionsService.getSessionSlotId(userId);
      debugPrint('Current slot ID: $currentSlotId');

      if (currentSlotId != null) {
        _currentSlot = await _slotsService.getSlotById(currentSlotId);
        debugPrint('Current slot: $_currentSlot');
      } else {
        _currentSlot = null;
      }
    } catch (e) {
      _setError('Erreur initialisation: $e');
    }
  }

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
      _slotsStream = _slotsService.getAvailableSlots();
      
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
          _setError('Erreur de synchronisation: $error');
        },
      );

    } catch (e) {
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
      _setError('Erreur lors de l\'actualisation: $e');
    }
  }

  /// Réserve un créneau
  Future<void> bookSlot(Slot slot) async {
    if (_bookingState == BookingState.booking) return;

    _setBookingState(BookingState.booking);
    _clearBookingError();

    try {
      // Vérifications préalables
      if (slot.status != SlotStatus.available) {
        throw Exception('Ce créneau n\'est plus disponible');
      }

      // Vérification ID non-null avec gestion d'erreur claire
      if (slot.id == null || slot.id!.isEmpty) {
        throw Exception('Identifiant du créneau invalide');
      }

      // Réserver le créneau (création session et update currentSessionId)
      await _slotsService.bookSlot(slot.id!);

      // Metre à jour currentSlot
      _currentSlot = slot;
      
      _setBookingState(BookingState.success);
      
      // Auto-reset du state après 3 secondes
      Future.delayed(const Duration(seconds: 3), () {
        if (_bookingState == BookingState.success) {
          _setBookingState(BookingState.idle);
        }
      });

    } catch (e) {
      _setBookingError('Réservation échouée: $e');
      rethrow;
    }
  }

  /// Annule une réservation
  Future<void> cancelReservation(String slotId) async {
    if (_bookingState == BookingState.booking) return;

    _setBookingState(BookingState.booking);
    _clearBookingError();

    try {
      await _slotsService.cancelBooking(slotId);
      _setBookingState(BookingState.success);
      _currentSlot = null;
      
      // Auto-reset du state
      Future.delayed(const Duration(seconds: 3), () {
        if (_bookingState == BookingState.success) {
          _setBookingState(BookingState.idle);
        }
      });

    } catch (e) {
      _setBookingError('Annulation échouée: $e');
    }
  }

  Slot? getUserReservation() {
    return _slots
        .where((slot) =>
            slot.reservedBy == _currentUserId &&
            slot.status == SlotStatus.reserved)
        .firstOrNull;
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
    debugPrint(error);
    _setLoadingState(CalendarLoadingState.error);
  }

  void _setBookingError(String error) {
    _bookingError = error;
    debugPrint(error);
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
    _currentSlot = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Le stream se ferme automatiquement
    super.dispose();
  }
}
