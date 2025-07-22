import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1A237E);    // Indigo foncé
  static const accent = Color(0xFFFFC107);     // Jaune
  static const background = Color(0xFFF5F5F5); // Gris très clair
  static const error = Color(0xFFD32F2F);      // Rouge fort
  static const textBlack = Color(0xFF212121);       // Noir texte
  static const textWhite = Color(0xFFFFFFFF);       // Blanc texte
  static const textGrey = Color(0xFF999999);       // Gris texte
  static const highLight = Color(0xFF3A37BA); // Couleur des boutons
}


/*
Phase 2 : Calendrier et réservation
Étape 2.1 - Service Calendly
Générer :
    core/services/calendly_service.dart :
        Méthode getAvailableSlots() retournant la liste des créneaux disponibles (format 1h)
        Méthode bookSlot(slotId) pour réserver un créneau
        Gestion des erreurs API avec try/catch

Étape 2.2 - Service Firebase
Générer :
core/services/booking_service.dart :
    Méthode saveBooking() pour sauvegarder le créneau réservé dans Firestore
    Collection : bookings/{userId}/slots/{slotId}
    Champs : slotId, date, heure, statut, timestamp

Étape 2.3 - Écran calendrier hebdomadaire
Générer :
screens/calendar_screen.dart :
    Intégration des widgets calendrier dans la page (plein écran)
    Gestion des appels API (Calendly + Firebase)
    Gestion des états : loading, erreur réseau
    Tap sur créneau → popup de confirmation réservation

Étape 2.4 - Widget calendrier
Générer :
widgets/calendar/week_calendar.dart : 
    Widget calendrier semaine avec créneaux disponibles colorés (bleu) et réservés (vert)
    Gestion scroll horizontal entre semaines
widgets/calendar/booking_popup.dart : 
    Popup confirmation réservation avec date/heure
    Boutons "Annuler" et "Confirmer"
core/utils/date_utils.dart : 
    Fonctions formatage date/heure en français
    Calculs semaines précédente/suivante

Étape 2.5 - Mise à jour temps réel
Générer :
core/providers/calendar_provider.dart :
    Provider pour gestion état calendrier
    Auto-refresh créneaux disponibles
    Synchronisation après réservation
    Gestion loading states

Dépendances à ajouter
dependencies:
  table_calendar: ^3.0.9

Résultat attendu : Calendrier hebdomadaire plein écran avec créneaux 1h colorés, réservation par popup, sauvegarde Firestore, navigation cohérente, mise à jour temps réel.
*/