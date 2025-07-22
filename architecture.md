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
│   │   │   ├── auth_service.dart      # Authentification
│   │   │   ├── user_service.dart      # CRUD utilisateurs
│   │   │   └── booking_service.dart   # CRUD réservations
│   │   ├── firebase_service.dart      # Auth + Firestore
│   │   ├── calendly_service.dart      # API Calendly
│   │   ├── agora_service.dart         # Chat + Voice
│   │   └── navigation_service.dart    # Navigation globale
│   └── utils/
│       ├── date_utils.dart           # Formatage dates
│       └── app_launcher.dart         # Lancement Clash Royale
│
├── models/                           # Modèles de données
│   ├── user.dart
│   ├── session.dart
│   ├── message.dart
│   └── calendar_slot.dart
│
├── screens/                          # Écrans principaux
│   ├── home/
│   │   ├── home_screen.dart
│   ├── calendar/
│   │   ├── calendar_screen.dart
│   └── salon/
│       ├── salon_screen.dart
│
├── providers/                        # Gestion d'état (Provider)
│   ├── auth_provider.dart
│   ├── session_provider.dart
│   └── chat_provider.dart
│
└── widgets/                          # Widgets partagés
