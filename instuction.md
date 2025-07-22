Instructions de Développement - App Caunvo MVP
Phase 1 : Configuration de base et authentification
Étape 1.1 - Configuration initiale

Générer :

    pubspec.yaml avec toutes les dépendances nécessaires
    main.dart avec initialisation Firebase
    app.dart avec MaterialApp, routes nommées vers 3 écrans principaux

Étape 1.2 - Modèles de données

Générer :

    models/user.dart : classe User avec id, email, name, createdAt, méthodes fromJson/toJson
    models/session.dart : classe Session avec id, coachId, userId, scheduledAt, status (enum: scheduled/active/completed), agoraChannelId, méthodes de sérialisation
    models/message.dart : classe Message avec id, text, senderId, timestamp, isFromCoach
    models/calendar_slot.dart : classe CalendarSlot pour données Calendly avec startTime, endTime, available

Étape 1.3 - Services Firebase et authentification

Générer :

    core/services/firebase_service.dart : singleton avec méthodes signInWithEmail, signUpWithEmail, signOut, getCurrentUser
    providers/auth_provider.dart : StateNotifier pour gérer l'état d'authentification avec isLoading, user, error
    Écran de login simple avec email/password, gestion des états loading/erreur

Phase 2 : Navigation et écran d'accueil
Étape 2.1 - Navigation et constantes

Générer :

    core/services/navigation_service.dart : service avec navigateTo, navigateAndReplace, goBack utilisant GlobalKey Navigator
    core/constants/app_constants.dart : constantes pour routes (/home, /calendar, /salon), URLs API, durées sessions
    core/constants/app_colors.dart : palette de couleurs cohérente

Étape 2.2 - Écran d'accueil

Générer :

    screens/home/home_screen.dart :
        AppBar avec nom utilisateur et déconnexion
        Card affichant prochaine session (si existe) avec date/heure
        Bouton principal "Lancer Clash Royale" (toujours visible)
        Bouton "Réserver un créneau" (si pas de session active)
        Navigation vers /calendar et /salon

Étape 2.3 - Utilitaires

Générer :

    core/utils/date_utils.dart : formatage dates françaises, calculs de durée, comparaisons
    core/utils/app_launcher.dart : méthode launchClashRoyale() avec url_launcher, gestion erreurs si app non installée

Phase 3 : Gestion des sessions
Étape 3.1 - Provider sessions

Générer :

    providers/session_provider.dart :
        StateNotifier gérant la session courante utilisateur
        Méthodes : loadCurrentSession, createSession, updateSessionStatus
        Écoute temps réel des changements de statut via Firestore
        Stream de la session courante

Étape 3.2 - Service Calendly (structure)

Générer :

    core/services/calendly_service.dart :
        Classe avec méthodes getAvailableSlots() et bookSlot(slotId)
        Gestion des headers API Calendly
        Transformation des réponses JSON en objets CalendarSlot
        Gestion des erreurs HTTP avec messages explicites

Phase 4 : Écran calendrier et réservation
Étape 4.1 - Écran calendrier

Générer :

    screens/calendar/calendar_screen.dart :
        AppBar avec titre "Réserver un créneau"
        ListView des créneaux disponibles sur 7 jours
        Widgets de slot avec date, heure, bouton "Réserver"
        Gestion états : loading, erreur, liste vide
        Confirmation avant réservation avec dialog

Étape 4.2 - Widgets calendrier

Générer :

    widgets/calendar/slot_card.dart : Card stylée pour chaque créneau avec date formatée, bouton réservation
    widgets/common/loading_widget.dart : CircularProgressIndicator centré avec texte
    widgets/common/error_widget.dart : Widget d'erreur avec icône et bouton retry

Phase 5 : Chat et communication
Étape 5.1 - Service Agora (structure)

Générer :

    core/services/agora_service.dart :
        Configuration Agora Chat et Voice
        Méthodes : initializeChat, sendMessage, startVoiceCall, endVoiceCall
        Gestion des channels par sessionId
        Callbacks pour réception messages et état appel

Étape 5.2 - Provider chat

Générer :

    providers/chat_provider.dart :
        StateNotifier pour messages d'une session
        Stream des messages Firestore temps réel
        Méthodes : sendMessage, loadMessages
        État de l'appel vocal (idle/calling/connected)

Phase 6 : Écran salon de communication
Étape 6.1 - Écran salon principal

Générer :

    screens/salon/salon_screen.dart :
        AppBar avec infos session (coach, date/heure)
        Zone messages avec ListView builder
        Champ de saisie message en bas
        Bouton appel vocal (visible seulement si session active)
        FloatingActionButton "Jouer à Clash Royale"

Étape 6.2 - Widgets chat

Générer :

    widgets/chat/message_bubble.dart : Bulle message alignée différemment selon isFromCoach, avec timestamp
    widgets/chat/voice_call_button.dart : Bouton avec états visuels (disponible/en appel/indisponible)
    Input de message avec validation non-vide et envoi sur Enter

Phase 7 : Intégration et finalisation
Étape 7.1 - Gestion d'état globale

Générer :

    Provider global dans app.dart wrappant tous les StateNotifiers
    Gestion de la persistance de session (l'utilisateur revient dans le bon contexte)
    Navigation automatique vers salon si session active au démarrage

Étape 7.2 - Gestion des erreurs et UX

Générer :

    Intercepteur d'erreurs global avec SnackBar
    États de chargement cohérents sur tous les écrans
    Gestion déconnexion réseau avec retry automatique
    Validation des formulaires avec messages d'erreur

Contraintes techniques à respecter :

    Utiliser Provider pour le state management
    Services en singleton avec pattern Dependency Injection
    Gestion d'erreurs avec try/catch et états loading
    Navigation par routes nommées uniquement
    Firestore en temps réel pour chat et sessions
    Code commenté en français pour les parties métier complexes

Chaque étape doit être générée complètement, il faut attendre une instruction avant de passer à la suivante.
