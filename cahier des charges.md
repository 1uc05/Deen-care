# App Caunvo: Cahier des Charges

## Spécifications fonctionnelles détaillées
### Objectif
Application mobile permettant aux utilisateurs de réserver des créneaux avec des coachs pour jouer ensemble à Clash Royale avec communication vocale.

### Architecture technique
• Framework : Flutter (iOS/Android)
• Backend : Firebase (Auth + Firestore)
• Calendrier : Calendly API
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
                    ├── text, senderId, timestamp, isFromCoach

### États des sessions
• scheduled : créneau réservé, chat disponible
• active : session en cours, chat + appel vocal disponibles
• completed : session terminée

### Ecrans requis
1. Accueil : Résumé session actuelle/prochaine
2. Créneaux Calendly, réservation (1 seul à la fois)
3. Salon : Chat texte (dès réservation) + appel vocal (pendant session active)

### Intégrations critiques
• Calendly API : GET créneaux, POST réservation
• Agora Voice : Persistance en arrière-plan pendant Clash Royale
• Clash Royale : clashroyale:// (iOS) / Intent Android


### Règles métier
• Inscription libre (Firebase Auth)
• 1 seul créneau réservé par utilisateur
• Chat disponible dès la réservation
• Appel vocal uniquement pendant session active
• Seul le coach peut terminer la session
• Ne pas utiliser Riverpod