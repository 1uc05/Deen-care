import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudFunctionsService extends FirebaseService {
  static final CloudFunctionsService _instance = CloudFunctionsService._internal();
  factory CloudFunctionsService() => _instance;
  CloudFunctionsService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  /// Crée un nouvel utilisateur Agora Chat
  Future<void> createAgoraUser() async {
    try {
      final callable = _functions.httpsCallable('addUser');
      
      final result = await callable.call({});
      
      if (result.data['success'] == true) {
        debugPrint('CloudFunctions: Agora user created/verified');
      } else {
        throw Exception('Failed to create Agora user');
      }
      
    } on FirebaseFunctionsException catch (e) {
      debugPrint('CloudFunctions error creating Agora user: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('CloudFunctions error: $e');
      rethrow;
    }
  }

  /// Génère un token Agora Chat pour l'utilisateur courant
  Future<String> generateChatToken({int expireTimeInSeconds = 3600}) async {
    try {
      validateCurrentUser();

      // TODO: appel de testAuth  en attenant, impossible e faire fonctionner generateAgoraChatToken
      // final callable = _functions.httpsCallable('generateAgoraChatToken');
      final callable = _functions.httpsCallable('testAuth');
      
      final result = await callable.call({});

      // final expirationTime = result.data['expirationTime'] as int;
      // debugPrint('CloudFunctions: Chat token generated, expires at: ${DateTime.fromMillisecondsSinceEpoch(expirationTime * 1000)}');

      final token = result.data['token'] as String;
      return token;

    // } on FirebaseFunctionsException catch (e) {
    //   debugPrint('CloudFunctions error generating token: ${e.code} - ${e.message}');
    //   rethrow;
    } catch (e) {
      debugPrint('CloudFunctions error: $e');
      rethrow;
    }
  }

  Future<String> testCloudFunction() async {
    final testCallable = _functions.httpsCallable('testAuth');
    try {
      debugPrint('🔍 Testing auth with testAuth function...');
      final testResult = await testCallable.call({});
      debugPrint('🔍 testAuth SUCCESS: $testResult');
      final token = testResult.data['token'] as String;
      debugPrint('🔍 testAuth token: $token');
      return token;
    } catch (e) {
      debugPrint('🔍 testAuth ERROR: $e');
      return '';
    }
  }
}