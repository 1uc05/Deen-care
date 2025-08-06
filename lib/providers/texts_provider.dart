import 'package:flutter/material.dart';
import 'dart:async';
import '../core/services/firebase/texts_service.dart';
import '../core/services/firebase/users_service.dart';
import '../models/arabic_text.dart';
import '../models/text_progress.dart';

class TextsProvider extends ChangeNotifier {
  final UsersService _usersService = UsersService();
  final TextsService _textsService = TextsService();

  // États privés
  List<ArabicText> _allTexts = [];
  List<TextProgress> _userProgress = [];
  bool _isLoading = false;
  String? _error;

  // Getters (inchangés)
  List<ArabicText> get allTexts => List.unmodifiable(_allTexts);
  List<TextProgress> get userProgress => List.unmodifiable(_userProgress);
  bool get canAddMoreTexts => _userProgress.length < 3;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Textes avec progression (triés par dernière consultation)
  List<ArabicText> get trackedTexts {
    final trackedIds = _userProgress.map((p) => p.textId).toSet();
    final tracked = _allTexts.where((text) => trackedIds.contains(text.id)).toList();
    
    // Tri selon l'ordre de _userProgress (déjà trié par lastAccessedAt)
    // tracked.sort((a, b) {
    //   final indexA = _userProgress.indexWhere((p) => p.textId == a.id);
    //   final indexB = _userProgress.indexWhere((p) => p.textId == b.id);
    //   return indexA.compareTo(indexB);
    // });
    
    return tracked;
  }

  /// Textes sans progression (triés par number)
  List<ArabicText> get availableTexts {
    final trackedIds = _userProgress.map((p) => p.textId).toSet();
    final available = _allTexts.where((text) => !trackedIds.contains(text.id)).toList();
    
    // Tri par number (déjà fait dans le service mais on s'assure)
    // available.sort((a, b) => a.numberSentence.compareTo(b.numberSentence));
    
    return available;
  }

  /// Initialise les données - appelé par MainScreen
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        loadTexts(),
        loadUserProgress(),
      ]);
    } catch (e) {
      _setError('Erreur d\'initialisation: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Charge tous les textes disponibles
  Future<void> loadTexts() async {
    try {
      final texts = await _textsService.getTexts();
      _allTexts = texts;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des textes: $e');
    }
  }

  /// Charge la progression utilisateur
  Future<void> loadUserProgress() async {
    try {
      final progress = await _usersService.getUserProgress();
      _userProgress = progress;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement de la progression: $e');
    }
  }

  /// Force le rechargement des données
  Future<void> refresh() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        loadTexts(),
        loadUserProgress(),
      ]);
    } catch (e) {
      _setError('Erreur lors du rafraîchissement: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Ajoute un texte au suivi
  Future<bool> addTextToProgress(String textId) async {
    if (!canAddMoreTexts) {
      _setError('Vous ne pouvez suivre que 3 textes maximum');
      return false;
    }

    if (isTextTracked(textId)) {
      _setError('Ce texte est déjà dans votre suivi');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _usersService.addTextToProgress(textId);
      // Recharger la progression après ajout
      await loadUserProgress();
    } catch (e) {
      _setError('Erreur lors de l\'ajout: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }

    return true;
  }

  /// Retire un texte du suivi
  Future<void> removeTextFromProgress(String textId) async {
    _setLoading(true);
    _clearError();

    try {
      await _usersService.removeTextFromProgress(textId);
      // Recharger la progression après suppression
      await loadUserProgress();
    } catch (e) {
      _setError('Erreur lors de la suppression: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sauvegarde la progression d'un texte
  Future<void> saveProgress(String textId, int currentSentence) async {
    _setLoading(true);
    _clearError();

    try {
      await _usersService.saveProgress(textId, currentSentence);
      // Mise à jour locale pour éviter un rechargement complet
      final index = _userProgress.indexWhere((p) => p.textId == textId);
      if (index != -1) {
        _userProgress[index] = _userProgress[index].copyWith(
          currentSentence: currentSentence,
        );
        notifyListeners();
      }
    } catch (e) {
      _setError('Erreur lors de la sauvegarde: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Remet à zéro la progression d'un texte
  Future<void> resetProgress(String textId) async {
    _setLoading(true);
    _clearError();

    try {
      await _usersService.resetTextProgress(textId);
      // Recharger la progression après reset
      await loadUserProgress();
    } catch (e) {
      _setError('Erreur lors de la remise à zéro: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Vérifie si un texte est suivi
  TextProgress? getProgressForText(String textId) {
    try {
      return _userProgress.firstWhere((progress) => progress.textId == textId);
    } catch (e) {
      return null;
    }
  }

  bool isTextTracked(String textId) {
    return _userProgress.any((progress) => progress.textId == textId);
  }

  // Méthodes utilitaires privées
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  void _clearError() {
    _setError(null);
  }

  // Plus de StreamSubscriptions à disposer
  @override
  void dispose() {
    super.dispose();
  }
}
