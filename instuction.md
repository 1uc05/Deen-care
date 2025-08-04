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
    core/constants/app_constants.dart : constantes pour routes (/home, /calendar, /room), URLs API, durées sessions
    core/constants/app_colors.dart : palette de couleurs cohérente

Étape 2.2 - Écran d'accueil

Générer :

    screens/home/home_screen.dart :
        AppBar avec nom utilisateur et déconnexion
        Card affichant prochaine session (si existe) avec date/heure
        Bouton principal "Lancer Clash Royale" (toujours visible)
        Bouton "Réserver un créneau" (si pas de session active)
        Navigation vers /calendar et /room

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

    screens/room/room_screen.dart :
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










# Phase 3 : Chat, communication et écran salon

## Objectif :
Ajouter la fonctionnalité de communication chat et vocal présente sur l'écran room_screen.
Si session.status = scheduled, alors il est possible  d'envoyer des messages.
Si session.status = inProgress, alors il est possible  d'envoyer des messages et d'appeler (un bouton appeler est affiché)
Les messages sont stockés uniquement dans Agora (pas Firebase)
L'ID de la room Agora est récupéré dès l'ouverture dde l'app si existant ou créé par SessionProvier dès la réservation d'un slot (fonction déja présente)

## Dépendance :
dependencies:
  agora_chat_sdk: ^1.3.3
  agora_rtc_engine: ^6.5.2
  permission_handler: ^12.0.1  # Package for managing runtime permissions

## Element existant :
class AppConstants {
    static const String agoraAppID 
    //...

class Message {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;
  final bool isFromCoach;

## Etapes :
Étape 3.1 - Service Agora
Générer :
    core/services/agora_service.dart :
        Configuration Agora Chat et Voice
        Chaque nouvelle session = nouveau channel Agora
        Méthodes requises :
            initializeSession(String roomId) : Initialise chat et voice pour la room
            sendMessage(String text) : Envoie message texte
            loadMessages() : Charge historique messages Agora
            Stream<List<Message>> getMessagesStream() : Stream des nouveaux messages
            joinVoiceCall() : Rejoint appel vocal (client)
            endVoiceCall() : Termine appel vocal
            dispose() : Nettoie les ressources
Permissions à gérer :
    - Permission.microphone (obligatoire pour voice)
    - Demande au premier lancement d'appel
    - Gestion des refus utilisateur

Étape 3.2 - Provider room
Générer :
    providers/room_provider.dart :
        Stream des messages Agora temps réel (pas Firebase)
        État géré :
            Liste des messages
            État de l'appel vocal : idle/calling/connected
            État de connexion chat
        Méthodes requises :
            updateCurrentSession(Session? newSession) : mise à jour automatique de la session en cours  via  proxy
            sendMessage(String text) : Délègue à AgoraService
            loadMessages() : Charge historique via AgoraService
            joinVoiceCall() : Rejoint appel (client)
            endVoiceCall() : Termine appel
        Récupération ID Room Agora :
            L'ID de la room Agora se trouve dans `session.agoraChannelId` de la session active.
            Pour l'obtenir :
            1. Via SessionProvider : `sessionProvider.currentSession?.agoraChannelId`
            2. Le RoomProvider doit être configuré en ProxyProvider<SessionProvider, RoomProvider>
            3. Quand SessionProvider.currentSession change → RoomProvider.updateCurrentSession() appelé automatiquement


Étape 3.3 - Écran salon principal
Générer :
    screens/room_screen.dart :
        Structure :
            AppBar : Infos session (nom coach, date/heure session)
            Zone messages : ListView.builder avec messages
            Champ saisie : Input message en bas d'écran
            Bouton appel : Visible uniquement si session.status = "inProgress"
        Comportement :
            L'appel vocal reste actif en arrière-plan
            Navigation possible vers autres écrans sans couper l'appel


Étape 3.4 - Widgets chat
Générer :
    widgets/room/message_bubble.dart :
        Bulle message avec alignement conditionnel :
            Coach : gauche, couleur A
            Client : droite, couleur B
        Affichage timestamp
        Propriété isFromCoach pour la logique d'affichage

    widgets/room/voice_call_button.dart :
        États visuels selon voiceCallState :
            idle : "Appeler" (disponible)
            calling : "En cours..." (en cours)
            connected : "Raccrocher" (connecté)
        Logique : coach peut démarrer, client peut rejoindre

    widgets/room/message_input.dart
        Champ de saisie avec validation (non-vide)
        Envoi sur appui Enter ou bouton Envoyer
        Integration avec room_provider.sendMessage()


Points techniques importants :
    L'ID de room est à récupérer dans _currentSession.agoraChannelId avec _currentSession mis à jour automatiquement
    Pas de sauvegarde Firebase pour les messages
    L'appel vocal doit persister en arrière-plan
    Seul le coach peut initier le changement de status session







à faire plus tard :
Étape 2.1 - Service firebase (MessagesService)
Générer :
    core/services/firebase/messages_service.dart :








----------------

Le code es fonctionnel mais il y a un probleme de logique et de responsabilié entre AgoraService et RoomProvier.
Voici ce que  nous allons faire :
1. Séparer AgoraService en 3 classes :
- AgoraService sera le point d'entrée de RoomProvider
- AgoraMessageService prendra en charge toute la partie message et chat (ChaSDK)
- AgoraVoiceService prendra en charge la partie communicaion vocale (RTCEngine)

La logique :
- AgoraService doit être une abstraction des fonctions Agora mais ne doit pas avoir de la logique métier
- Ses fonctions publiques sont :
createRoom(): retourne id de la room créé
deleteRoom(roomId) 
sendMessage(text, roomId)
loadMessages(roomId): retourne liste des messages
joinVoiceCall(roomId)
leaveVoiceCall(roomId)


- RoomProvier a la logique métier des rooms (changement)


note: les messages doivent être récupéré automatiquement













Tu vas être le chef de projet de mon application web. Ton but est de créer un cahier des charges et une architecture logicielle qui serviront aux autres développeurs.
Cette application web, appelé caunvo_dashboard, doit être simple afin d'être rapidement développé (2 jours max). Cette app sera utilisé par des professionnels (appelé coach) elle n'a pas besoin d'UX/UI recherché.
Cette app est une interface web pour des coachs afin d'ils puissent intéragir avec leurs clients. Les clients utilisent une applicaion mobile (appli déjà développé, ne fait pas partie de ce projet). 
Le fonctionnement :
Les coach proposent des créneaux de 30 minutes pour des sessions de coaching (via l'app web). Les clients peuvent réserver un créneaux (via l'app mobile). Dès qu'ils réservent, une session est créée (via l'app mobile) et les cliens peuvent envoyer des messages aux coachs. Dès l'heure du créneau, une discussion téléphonique est disponible entre le coach et le client.

Une base de données Firestore (déjà existante) fait la liaison entre l'applicaion web (coach) et l'applicaion mobile (client)

Les sessions:
Une session est associée à un créneau réservé. Ces sessions ont 3 phases :
• scheduled : le client a reservé la session, le créneau est réservé, le chat (communication texe) est disponible
• inProgress : session en cours, chat + appel vocal disponibles
• completed : session terminée, chet + appel vocal non disponibles

Fonctionnalité de caunvo_dashboard :
1. Afficher un calendrier/agenda d'une semaine (lundi - dimanche) afin d'afficher les créneaux disponible/réservé et créer des nouveaux créneaux. Ces créneaux sont ensuite réservable par les clients (depuis l'app mobile)
- permet de créer des créneaux (30 minutes) "disponible"
- permet de retirer des créneaux "disponible"
- permet de voir les créneaux "disponible" / "réservé"
- permet de faire défiler les semaines
- en cliquant sur un créneau libre (30 minutes), un popup s'ouvre pour confirmer la création (slot.satus = available)
- en cliquant sur un créneau "disponible", un popup s'ouvre pour proposer l'annulation
- en cliquant sur un créneau "reservé", un popup s'ouvre pour voir le nom de la personne
- les coach peuvent donc soit créer un créneau (slot.satus = available) soit le retirer. il ne peuvent pas reserver (ce sont les cliens)

2. Afficher une page de communication afin de communiquer (message texte et appel vocal) avec les clients qui ont réservés
- page semblable aux applications de message (ex Messenger, WhatsApp...)
- un volet sur la gauche liste toutes les discussions des clients qui ont une reservation d'un créneau
- sur le reste de la page, la discussion sélectionné avec zone pour envoyer des messages et un bouton appeler quand c'est l'heure du créneau

3. Auhentificaion Firebase
- une connexion par mot de passe et email est requise

Architecture technique
- Backend : Firebase (Auth + Firestore)
- Communication : Agora SDK (Chat texte + Voice audio)

Modèle de données Firestore
users/
└── {userId}/
    ├── email, name, createdAt
    ├── currentSessionId?: String
    ├── createdAt: Timestamp
    └── role: String                // 'client', 'coach', 'admin'
sessions/
└── {sessionId}/
    ├── userId, coachId, slotId
    ├── status: String          // 'scheduled', 'inProgress', 'completed'
    ├── startedAt: Timestamp
    ├── agoraChannelId: String
    └── messages/ (sous-collection)
        └── {messageId}/
            └── text, senderId, timestamp
slots/                              // Créneaux
└── {slotId}/
    ├── startTime: Timestamp
    ├── endTime: Timestamp
    ├── reservedBy?: String     // userId du client qui a réservé (ou null si libre)
    ├── createdBy: String
    ├── sessionId?: String
    ├── status: String          // 'available', 'reserved', 'cancelled'
    ├── createdAt: Timestamp
    └── reservedAt: Timestamp?

Avant de commencer le cahier des charges, as-tu des questions ou besoin de précision/reformulation ? En tant que chef de projet, il es important que tu ai une bonne compréhention du projet