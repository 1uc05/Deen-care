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












Phase suivante :
Phase 2 : Calendrier et réservation
Logique :
- L’application récupère en temps réel les créneaux disponibles depuis Firestore.
- Lorsqu’un utilisateur réserve un créneau :
    Le slot est marqué comme réservé dans Firestore (champ reservedByUid rempli avec l’UID Firebase de l’utilisateur).
    La réservation doit se faire via une transaction Firestore afin d’éviter les double-réservations.
- Les créneaux déjà réservés ou passés ne doivent plus être proposés.

Modèle de données Firestore
- Collection principale : slots
    - Champs d’un document slot
        startTime: Timestamp (obligatoire) – début du créneau
        endTime: Timestamp (obligatoire) – fin du créneau
        reservedByUid: String (UID de l’utilisateur, ou null si dispo)
        createdAt: Timestamp
        updatedAt: Timestamp
        status: String (available, booked)

UI
- un calendrier du mois en cours est affiché
- des fleches permettent de passer au mois suivant/précédent
- les jours avec des créneaux disponibles sont affichés en bleu
- en sélectionnant un jour avec une disponibilité, une page s'ouvre avec la liste des disponibilités
- en sélectionnant une disponibilité un popup de confirmation s'ouvre

Étape 2.0 – Modèle du slot
Générer :
    models/slot.dart
    Classe Slot, sérialisable (constructeur, fromMap, toMap)

Classe Slot
    Champs :
        String id (optionnel, pour stocker l’ID Firestore si besoin)
        DateTime startTime
        DateTime endTime
        String status : “available” / “reserved” / “completed” / “cancelled”
        String? reservedBy (nullable)
        String createdBy
        DateTime createdAt
        DateTime updatedAt
    Méthodes :
        Slot.fromMap(Map<String, dynamic> data, String docId)
        Map<String, dynamic> toMap()


Étape 2.1 - Service firebase (SlotService)
Générer :
core/services/firebase/calendar_service.dart :
    Méthode getAvailableSlots() retourne la liste des créneaux disponibles (format 30 minues)
    Méthode bookSlot() sauvegarde dans firebase le créneau réservé (utiliser une transaction pour garantir l’exclusivité)
    Collection : bookings/{userId}/slots/{slotId}
    Champs : slotId, date, heure, timestamp

Étape 2.2 - Écran calendrier
Générer :
screens/calendar_screen.dart :
    Intégration du widget month_calendar dans la page (plein écran)

Étape 2.3 - Écran créneau
Générer :
screens/slots_screen.dart :
    Liste horaire des créneaux disponibles pour le jour sélecionné
    1 ligne = 1 créneau représenté par l'heure de début du créneau (ex: 1igne1: 12:30 / ligne2: 14:00 / ligne3: 14:30)
    Tap sur créneau : popup de confirmation réservation
    Après confirmation réservation, retour à la page home

Étape 2.4 - Widgets calendrier
Générer :
widgets/calendar/month_calendar.dart : 
    Widget calendrier mensuel
    Jours bleus si des créneaux dispos
    Flèches pour passer d’un mois à l’autre

widgets/calendar/booking_popup.dart :
    Popup confirmation réservation avec heure/date
    Boutons Annuler/Confirmer
    
core/utils/date_utils.dart : 
      Fonctions : formater dates, obtenir listes de dates du mois, etc.

Étape 2.5 - Mise à jour temps réel
Générer :
core/providers/calendar_provider.dart :
    Provider pour l’état calendrier
    Rafraîchissement auto via stream Firestore
    Synchronisation après action (réservation/refresh slots)
    Gestion états de chargement (loading/reserved/failed)

Dépendances à ajouter
dependencies:
  table_calendar: ^3.0.9

Résultat attendu : 
- Calendrier plein écran, créneaux 30 minutes affichés, réservations transactionnelles via Firestore.
- Navigation fluide, UI feedback clairs.
- Synchro en temps réel : créneaux disparaissent dès qu’ils sont réservés.


Fais une pose entre chaque étape