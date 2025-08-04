import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/slot.dart';
import '../core/services/firebase/slots_service.dart';

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

  // Etat interne
  String? _currentUserId;
  List<Slot> _slots = [];
  String? _errorMessage;
  String? _bookingError;

  // Streams et subscriptions
  Stream<List<Slot>>? _slotsStream;
  StreamSubscription<List<Slot>>? _slotsSubscription;

  // États publics
  CalendarLoadingState _loadingState = CalendarLoadingState.initial;
  BookingState _bookingState = BookingState.idle;

  CalendarProvider({SlotsService? slotsService}) 
    : _slotsService = slotsService ?? SlotsService();

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
      _clearError();
      
    try {
      _currentUserId = userId;
    } catch (e) {
      _setError('CalendarProvider: Erreur initialisation: $e');
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
      // Nettoyer l'ancien stream avant d'en créer un nouveau
      await _slotsSubscription?.cancel();

      // Obtenir le stream des créneaux
      _slotsStream = _slotsService.getAvailableSlots();
      
      // Écouter les changements en temps réel
      _slotsSubscription = _slotsStream!.listen(
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

  // Méthodes privées de gestion d'état
  void _setLoadingState(CalendarLoadingState state) {
    if (_loadingState != state) {
      _loadingState = state;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    debugPrint(error);
    _setLoadingState(CalendarLoadingState.error);
  }


  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Reset complet du provider
  Future<void> reset() async {
    await _cleanup();
    _currentUserId = null;
    _slots.clear();
    _loadingState = CalendarLoadingState.initial;
    _bookingState = BookingState.idle;
    _clearError();
    _clearError();
    notifyListeners();
  }

  Future<void> _cleanup() async {
    await _slotsSubscription?.cancel();
    _slotsSubscription = null;
    _slotsStream = null;
  }

  @override
  Future<void> dispose() async {
    await _cleanup();
    super.dispose();
  }
}
