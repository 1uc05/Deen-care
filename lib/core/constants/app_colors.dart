import 'package:flutter/material.dart';

class AppColors {
  // === COULEURS PRINCIPALES ===
  static const Color primary          = Color(0xFF2196F3);  // Bleu principal
  static const Color secondary        = Color(0xFF4CAF50);  // Vert (succès/disponible)  
  static const Color accent           = Color(0xFFFF9800);  // Orange (warning/en cours)

  // === TEXTE ===
  static const Color textDark         = Color(0xFF212121);  // Texte principal
  static const Color textGrey         = Color(0xFF757575);  // Texte secondaire
  static const Color textGreyLight    = Color(0xFFBDBDBD);  // Texte secondaire clair

  // === BACKGROUNDS ===
  static const Color background       = Colors.white;       // Fond principal
  static const Color backgroundLight  = Color(0xFFF5F5F5);  // Fond alternatif
  
  // === ÉTATS SYSTÈME ===
  static const Color error            = Colors.red;         // Erreurs, Supprimer, Annuler, Quitter
  static const Color success          = secondary;          // Réutilise le vert
  static const Color noStatus         = Colors.grey;          // Réutilise le vert
  
  // === OPACITÉS STANDARDISÉES ===
  static const double subtle = 0.05;      // États hover, effets très discrets
  static const double light = 0.1;        // Fonds de messages info, zones highlight
  static const double soft = 0.2;         // Séparateurs, bordures discrètes
  static const double medium = 0.3;       // Bordures visibles, états désactivés
  static const double strong = 0.5;       // Overlays, masques modals
  static const double bold = 0.7;         // États de focus importants, badges urgents
  
  // === COULEURS AVEC OPACITÉS ===
  static Color get primarySubtle    => primary.withOpacity(subtle);     // 0.05
  static Color get primaryLight     => primary.withOpacity(light);      // 0.1
  static Color get primarySoft      => primary.withOpacity(soft);       // 0.2
  static Color get primaryMedium    => primary.withOpacity(medium);     // 0.3
  static Color get primaryStrong    => primary.withOpacity(strong);     // 0.5
  static Color get primaryBold      => primary.withOpacity(bold);       // 0.7

  static Color get secondarySubtle    => secondary.withOpacity(subtle);     // 0.05
  static Color get secondaryLight     => secondary.withOpacity(light);      // 0.1
  static Color get secondarySoft      => secondary.withOpacity(soft);       // 0.2
  static Color get secondaryMedium    => secondary.withOpacity(medium);     // 0.3
  static Color get secondaryStrong    => secondary.withOpacity(strong);     // 0.5
  static Color get secondaryBold      => secondary.withOpacity(bold);       // 0.7


  static Color get warningLight     => accent.withOpacity(light); 
  static Color get errorLight       => error.withOpacity(light);        // 0.1
  static Color get boxShadow        => Colors.black.withOpacity(light); // 0.1
}