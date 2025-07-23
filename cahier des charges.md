# App Caunvo: Cahier des Charges

## Spécifications fonctionnelles détaillées
### Objectif
Application mobile permettant aux utilisateurs de réserver des créneaux avec des coachs pour jouer ensemble à Clash Royale avec communication vocale.

### Architecture technique
• Framework : Flutter (iOS/Android)
• Backend : Firebase (Auth + Firestore)
• Communication : Agora SDK (Chat texte + Voice audio)
• Jeu externe : Clash Royale (lancement via intent/URL scheme)

### Modèle de données Firestore
users/
├── {userId}/
    ├── email, name, createdAt
    ├── currentSessionId (nullable)
    └── sessions/ (sous-collection)
        └── {sessionId}/
            ├── coachId, scheduledAt, status, createdAt
            ├── agoraChannelId
            └── messages/ (sous-collection)
                └── {messageId}/
                    └── text, senderId, timestamp, isFromCoach
slots/
  └── {slotId}/
      ├── startTime: Timestamp
      ├── endTime: Timestamp
      ├── reservedBy: String?     // userId du client qui a réservé (ou null si libre)
      ├── status: String          // 'available', 'reserved', 'cancelled'
      ├── createdAt: Timestamp
      └── reservedAt: Timestamp?

### États des sessions (status)
• scheduled : créneau réservé, chat disponible
• active : session en cours, chat + appel vocal disponibles
• completed : session terminée

### Ecrans requis
1. Accueil : Résumé session actuelle/prochaine
2. Réservation : Calendrier mois de visualisation des créneaux disponibles
3. Salon : Chat texte (dès réservation) + appel vocal (pendant session active)
4. Créneau : Liste les créneaux disponibles pour un jour donné

### Intégrations critiques
• Firebase : authentification et créneau
• Agora Voice : Persistance en arrière-plan pendant Clash Royale
• Clash Royale : clashroyale:// (iOS) / Intent Android

### Fonctionnalité Calendrier/réservation
Les utilisateurs consultent les créneaux disponibles via un calendrier. En sélectionnant
un créneau, ils peuvent le réserver, ce qui le rend indisponible pour les autres. La
réservation et l’état des créneaux sont gérés en temps réel via Firestore, assurant la
synchronisation et l’absence de conflit.

### Règles métier
• Inscription libre (Firebase Auth)
• 1 seul créneau réservé par utilisateur
• Chat disponible dès la réservation
• Appel vocal uniquement pendant session active
• Seul le coach peut terminer la session
• Ne pas utiliser Riverpod