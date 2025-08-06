import 'package:flutter/foundation.dart';
import '../core/services/firebase/texts_service.dart';
import '../models/text.dart';
import '../models/user_progress.dart';

class TextsProvider extends ChangeNotifier {
  final TextsService _textsService = TextsService.instance;
  
  // ÉTATS PRIVÉS
  List<ArabicText> _allTexts = [];
  List<UserProgress> _userProgress = [];
  ArabicText? _currentStudyText;
  int _currentSegmentIndex = 0;
  bool _showFrench = true;
  bool _isLoading = false;
  String? _error;
  bool _hasUnsavedChanges = false;
  String? _currentUserId;

  // GETTERS PUBLICS
  
  /// Tous les textes disponibles
  List<ArabicText> get allTexts => List.unmodifiable(_allTexts);
  
  /// Textes actuellement suivis par l'utilisateur
  List<ArabicText> get trackedTexts {
    if (_userProgress.isEmpty) return [];
    
    final trackedIds = _userProgress.map((p) => p.textId).toSet();
    return _allTexts.where((text) => trackedIds.contains(text.id)).toList();
  }
  
  /// Textes disponibles (non suivis)
  List<ArabicText> get availableTexts {
    if (_userProgress.isEmpty) return _allTexts;
    
    final trackedIds = _userProgress.map((p) => p.textId).toSet();
    return _allTexts.where((text) => !trackedIds.contains(text.id)).toList();
  }
  
  /// Texte actuellement étudié
  ArabicText? get currentStudyText => _currentStudyText;
  
  /// Mode d'affichage français activé/désactivé
  bool get showFrench => _showFrench;
  
  /// État de chargement
  bool get isLoading => _isLoading;
  
  /// Erreur courante
  String? get error => _error;
  
  /// Changements non sauvegardés présents
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  
  /// Pourcentage de progression du texte actuel
  double get currentProgressPercentage {
    if (_currentStudyText == null || _currentStudyText!.totalSegments == 0) {
      return 0.0;
    }
    return _currentSegmentIndex / _currentStudyText!.totalSegments;
  }
  
  /// Texte formaté selon le mode langue et la progression
  String get displayedText {
    if (_currentStudyText == null || _currentSegmentIndex == 0) {
      return '';
    }
    return _currentStudyText!.getDisplayText(_currentSegmentIndex, _showFrench);
  }
  
  /// Peut afficher le segment suivant
  bool get canShowNextSegment {
    if (_currentStudyText == null) return false;
    return _currentSegmentIndex < _currentStudyText!.totalSegments;
  }
  
  /// Index du segment actuel
  int get currentSegmentIndex => _currentSegmentIndex;
  
  /// Progression utilisateur actuelle
  List<UserProgress> get userProgress => List.unmodifiable(_userProgress);

  // MÉTHODES PUBLIQUES
  
  /// Charge tous les textes disponibles
  Future<void> loadAllTexts() async {
    _setLoading(true);
    _setError(null);
    
    try {
      _allTexts = await _textsService.getAllTexts();
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des textes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Charge la progression de l'utilisateur
  Future<void> loadUserProgress(String userId) async {
    _currentUserId = userId;
    _setLoading(true);
    _setError(null);
    
    try {
      _userProgress = await _textsService.getUserProgress(userId);
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement de la progression: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // GESTION SÉLECTION TEXTE
  
  /// Ajoute un texte au suivi (vérifie la limite de 3)
  Future<bool> addTextToTracked(String userId, String textId, String title) async {
    _setError(null);
    
    try {
      // Vérifier la limite de 3 textes
      final canAdd = await _textsService.canAddNewText(userId);
      if (!canAdd) {
        _setError('Vous pouvez suivre maximum 3 textes simultanément');
        return false;
      }
      
      // Ajouter le texte avec progression initiale
      await _textsService.saveProgress(userId, textId, 0, title);
      
      // Recharger la progression
      await loadUserProgress(userId);
      
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ajout du texte: ${e.toString()}');
      return false;
    }
  }
  
  /// Retire un texte du suivi
  Future<void> removeTextFromTracked(String userId, String textId) async {
    _setError(null);
    
    try {
      await _textsService.removeFromProgress(userId, textId);
      
      // Si c'est le texte actuellement étudié, le désélectionner
      if (_currentStudyText?.id == textId) {
        _currentStudyText = null;
        _currentSegmentIndex = 0;
        _hasUnsavedChanges = false;
      }
      
      // Recharger la progression
      await loadUserProgress(userId);
    } catch (e) {
      _setError('Erreur lors de la suppression: ${e.toString()}');
    }
  }
  
  /// Sélectionne un texte pour l'étude
  Future<void> selectTextForStudy(String textId) async {
    _setError(null);
    
    try {
      // Charger le texte complet
      final text = await _textsService.getTextById(textId);
      if (text == null) {
        _setError('Texte introuvable');
        return;
      }
      
      _currentStudyText = text;
      
      // Récupérer la progression sauvegardée
      final progress = _userProgress.firstWhere(
        (p) => p.textId == textId,
        orElse: () => UserProgress(
          textId: textId,
          title: text.title,
          currentSegment: 0,
          lastAccessedAt: DateTime.now(),
        ),
      );
      
      _currentSegmentIndex = progress.currentSegment;
      _hasUnsavedChanges = false;
      
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la sélection du texte: ${e.toString()}');
    }
  }

  // GESTION ÉTUDE
  
  /// Révèle le segment suivant
  void showNextSegment() {
    if (!canShowNextSegment) return;
    
    _currentSegmentIndex++;
    _hasUnsavedChanges = true;
    notifyListeners();
  }
  
  /// Bascule entre mode arabe seul et arabe + français
  void toggleLanguageMode() {
    _showFrench = !_showFrench;
    notifyListeners();
  }
  
  /// Sauvegarde la progression actuelle
  Future<void> saveCurrentProgress(String userId) async {
    if (_currentStudyText == null) return;
    
    _setError(null);
    
    try {
      await _textsService.saveProgress(
        userId,
        _currentStudyText!.id,
        _currentSegmentIndex,
        _currentStudyText!.title,
      );
      
      _hasUnsavedChanges = false;
      
      // Recharger la progression pour mettre à jour lastAccessedAt
      await loadUserProgress(userId);
    } catch (e) {
      _setError('Erreur lors de la sauvegarde: ${e.toString()}');
    }
  }
  
  /// Remet à zéro la progression d'un texte
  Future<void> resetTextProgress(String userId, String textId) async {
    _setError(null);
    
    try {
      await _textsService.resetProgress(userId, textId);
      
      // Si c'est le texte actuellement étudié, réinitialiser l'affichage
      if (_currentStudyText?.id == textId) {
        _currentSegmentIndex = 0;
        _hasUnsavedChanges = false;
      }
      
      // Recharger la progression
      await loadUserProgress(userId);
    } catch (e) {
      _setError('Erreur lors de la remise à zéro: ${e.toString()}');
    }
  }

  // UTILITAIRES
  
  /// Efface l'erreur courante
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
  
  /// Met à jour l'état de chargement
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  /// Met à jour l'erreur
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }
  
  /// Force la sauvegarde pour éviter la perte de données
  void markAsChanged() {
    if (!_hasUnsavedChanges) {
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }
  
  /// Récupère la progression d'un texte spécifique
  UserProgress? getProgressForText(String textId) {
    try {
      return _userProgress.firstWhere((p) => p.textId == textId);
    } catch (e) {
      return null;
    }
  }
  
  /// Vérifie si un texte est suivi
  bool isTextTracked(String textId) {
    return _userProgress.any((p) => p.textId == textId);
  }
  
  /// Obtient le nombre de textes suivis
  int get trackedTextsCount => _userProgress.length;
  
  /// Vérifie si la limite de 3 textes est atteinte
  bool get isLimitReached => trackedTextsCount >= 3;
}
