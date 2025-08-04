lib/
├── main.dart
├── app.dart                           # MaterialApp + routing
│
├── core/                              # Fondations réutilisables
│   ├── constants/
│   │   ├── app_constants.dart         # URLs API, durées, etc.
│   │   └── app_colors.dart            # Thème couleurs
│   ├── services/
│   │   ├── firebase/
│   │   │   ├── users_service.dart     # Classe fille firebase, CRUD utilisateurs
│   │   │   ├── sessions_service.dart  # Classe fille firebase, CRUD sessions
│   │   │   └── slots_service.dart     # Classe fille firebase, Get / set reservaton
│   │   └── firebase_service.dart      # Classe mère firebase, instance Firebase partagées
│   │   └── agora_service.dart         # Chat + Voice
│   └── utils/
│       ├── date_utils.dart           # Formatage dates
│       └── app_launcher.dart         # Lancement Clash Royale
│
├── models/                           # Modèles de données
│   ├── user.dart
│   ├── session.dart
│   ├── message.dart
│   └── slot.dart
│
├── screens/                          # Écrans principaux
│   ├── main_screen.dart              # AppBar et menu
│   ├── home_screen.dart
│   ├── calendar_screen.dart          # Calendrier mois sur tout l'écran
│   ├── slots_screen.dart             # Liste des créneaux disponibles d'un jour
│   └── room_screen.dart             # Chat de discussion
│
├── providers/                        # Gestion d'état (Provider)
│   ├── navigation_provider.dart      # Gestion onglets de navigation (goToHome() / goToCalendar() / goToRoom())
│   ├── auth_provider.dart            # Authentification Firebase avec états (initial/loading/authenticated/unauthenticated/error)
│   ├── calendar_provider.dart        # Mise à jour temps réel des réservations
│   ├── session_provider.dart         # Gestion session active utilisateur
│   └── room_provider.dart            # Gestion messages et appel
│
└── widgets/                          # Widgets partagés
│   ├── calendar/
    │   ├── month_calendar.dart
    │   └── booking_popup.dart
    └── room/
        ├── message_bubble.dart
        ├── voice_call_button.dart
        └── message_input.dart
