# App Caunvo: Cahier des Charges

## Spécifications fonctionnelles détaillées
### Objectif
Application mobile permettant aux utilisateurs de réserver des créneaux avec des coachs
pour jouer ensemble à Clash Royale avec communication vocale.

### Architecture technique
• Framework : Flutter (iOS/Android)
• Backend : Firebase (Auth + Firestore)
• Communication : Agora SDK (Chat texte + Voice audio)
• Jeu externe : Clash Royale (lancement via intent/URL scheme)

### Modèle de données Firestore
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
slots/
└── {slotId}/
    ├── startTime: Timestamp
    ├── endTime: Timestamp
    ├── reservedBy?: String     // userId du client qui a réservé (ou null si libre)
    ├── createdBy: String
    ├── sessionId?: String
    ├── status: String          // 'available', 'reserved', 'cancelled'
    ├── createdAt: Timestamp
    └── reservedAt: Timestamp?

### États des sessions (status)
• scheduled : créneau réservé, chat disponible
• inProgress : session en cours, chat + appel vocal disponibles
• completed : session terminée, chet + appel vocal non disponibles

### Ecrans requis
1. Accueil : Résumé session actuelle/prochaine
2. Réservation : Calendrier mois de visualisation des créneaux disponibles
3. Salon : Chat texte (dès réservation) + appel vocal (pendant session active)
4. Créneau : Liste les créneaux disponibles pour un jour donné

### Intégrations critiques
• Firebase : authentification et créneau
• Agora Voice : Persistance en arrière-plan pendant Clash Royale
• Clash Royale : clashroyale:// (iOS) / Intent Android

### Architecture et patterns adoptés
• **Gestion d'état** : Provider (ChangeNotifierProvider) - pas de Riverpod
• **Navigation** : Go Router avec routes déclaratives et redirections automatiques
• **Services** : Pattern singleton pour les services Firebase
• **Structure** : Services héritent de FirebaseService (classe mère commune)
• **Validation** : Validation systematic avec handleFirestoreException()
• **Navigation interne** : NavigationProvider pour la BottomNavigationBar

### Fonctionnalité Calendrier/réservation
Les utilisateurs consultent les créneaux disponibles via un calendrier. En sélectionnantf
un créneau, ils peuvent le réserver, ce qui le rend indisponible pour les autres. La
réservation et l’état des créneaux sont gérés en temps réel via Firestore, assurant la
synchronisation et l’absence de conflit.

### Fonctionnalité Salon/Communication
Les utilisateurs accèdent à un salon de communication dès la réservation d'un créneau.
Le chat textuel est disponible immédiatement (statut 'scheduled'), permettant les échanges
préparatoires entre client et coach. Lors du passage en session active ('active'), un appel
vocal s'ajoute au chat via la technologie Agora. L'appel vocal persiste en arrière-plan
pendant le jeu Clash Royale, assurant une communication continue. Les messages sont stockés
exclusivement sur les serveurs Agora pour optimiser les performances temps réel, tandis que
seuls les métadonnées de session restent dans Firestore.

### Règles métier
• Inscription libre (Firebase Auth)
• 1 seul créneau réservé par utilisateur
• Chat disponible dès la réservation
• Appel vocal uniquement pendant session active
• Seul le coach peut terminer la session
• Ne pas utiliser Riverpod