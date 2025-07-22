// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import '../models/session.dart';
// import '../models/user.dart';
// import '../core/services/firebase_service.dart';

// // Cette classe sera utilisable avec Provider classique :
// // ChangeNotifierProvider(create: (_) => SessionProvider(userId: ...))

// class SessionProvider extends ChangeNotifier {
//   final String userId;

//   /// Session courante (ou null)
//   Session? _currentSession;
//   Session? get currentSession => _currentSession;

//   /// État de chargement des données
//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   String? _error;
//   String? get error => _error;

//   /// Firestore Subscription
//   StreamSubscription? _sessionSub;

//   SessionProvider({required this.userId}) {
//     loadCurrentSession();
//   }

//   /// Charge la session courante (écoute en temps réel)
//   Future<void> loadCurrentSession() async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     _sessionSub?.cancel();

//     try {
//       // On cherche la session où le statut n’est PAS "completed" (soit scheduled, soit active)
//       final query = FirebaseFirestore.instance
//         .collection('users').doc(userId)
//         .collection('sessions')
//         .where('status', whereIn: ['scheduled', 'active'])
//         .orderBy('scheduledAt')
//         .limit(1)
//         .snapshots();

//       _sessionSub = query.listen((snapshot) {
//         if (snapshot.docs.isEmpty) {
//           _currentSession = null;
//         } else {
//           _currentSession = Session.fromJson(snapshot.docs.first.data());
//         }
//         notifyListeners();
//       }, onError: (e) {
//         _error = "Erreur lors de la récupération de la session.";
//         notifyListeners();
//       });
//     } catch (e) {
//       _isLoading = false;
//       _error = "Chargement impossible : $e";
//       notifyListeners();
//     }

//     _isLoading = false;
//     notifyListeners();
//   }

//   /// Crée une nouvelle session
//   Future<void> createSession(Session session) async {
//     _isLoading = true;
//     notifyListeners();
//     try {
//       final docRef = FirebaseFirestore.instance
//         .collection('users').doc(userId)
//         .collection('sessions').doc(session.id);
//       await docRef.set(session.toJson());
//     } catch (e) {
//       _error = "Erreur lors de la création de la session : $e";
//       notifyListeners();
//     }
//     _isLoading = false;
//     notifyListeners();
//   }

//   /// Met à jour le statut d’une session (par ex : scheduled → active)
//   Future<void> updateSessionStatus(String sessionId, SessionStatus newStatus) async {
//     _isLoading = true;
//     notifyListeners();
//     try {
//       await FirebaseFirestore.instance
//         .collection('users').doc(userId)
//         .collection('sessions').doc(sessionId)
//         .update({'status': newStatus.name});
//     } catch (e) {
//       _error = "Erreur lors du changement de statut : $e";
//       notifyListeners();
//     }
//     _isLoading = false;
//     notifyListeners();
//   }


//   /// Permet d’exposer le flux en temps réel, si tu veux l’utiliser comme StreamBuilder côté UI
//   Stream<Session?> get sessionStream async* {
//     final ref = FirebaseFirestore.instance
//       .collection('users').doc(userId)
//       .collection('sessions')
//       .where('status', whereIn: ['scheduled', 'active'])
//       .orderBy('scheduledAt')
//       .limit(1);

//     await for (var snap in ref.snapshots()) {
//       if (snap.docs.isNotEmpty) {
//         yield Session.fromJson(snap.docs.first.data());
//       } else {
//         yield null;
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _sessionSub?.cancel();
//     super.dispose();
//   }
// }
