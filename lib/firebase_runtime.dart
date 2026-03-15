import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<FirebaseAppServices> initializeFirebaseServices() async {
  try {
    final app = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final firestore = FirebaseFirestore.instance;
    firestore.settings = const Settings(persistenceEnabled: true);
    final auth = FirebaseAuth.instance;

    FirebaseAnalytics? analytics;
    try {
      analytics = FirebaseAnalytics.instance;
    } catch (_) {
      analytics = null;
    }

    return FirebaseAppServices(app: app, firestore: firestore, auth: auth, analytics: analytics);
  } catch (error) {
    return FirebaseAppServices.disabled(initializationError: error);
  }
}

class FirebaseAppServices {
  const FirebaseAppServices({
    required this.app,
    required this.firestore,
    required this.auth,
    required this.analytics,
    this.initializationError,
  });

  const FirebaseAppServices.disabled({this.initializationError})
      : app = null,
        firestore = null,
        auth = null,
        analytics = null;

  final FirebaseApp? app;
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;
  final FirebaseAnalytics? analytics;
  final Object? initializationError;

  bool get isEnabled => firestore != null && auth != null;

  Future<Map<String, dynamic>?> fetchPreferences(String clientId) async {
    final reference = _preferencesRef(clientId);
    if (reference == null) {
      return null;
    }
    final snapshot = await reference.get();
    return snapshot.data();
  }

  Future<List<Map<String, dynamic>>> fetchCategories(String clientId) async {
    final collection = _categoriesRef(clientId);
    if (collection == null) {
      return [];
    }
    final snapshot = await collection.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> fetchTransactions(String clientId) async {
    final collection = _transactionsRef(clientId);
    if (collection == null) {
      return [];
    }
    final snapshot = await collection.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> savePreferences(String clientId, Map<String, dynamic> data) async {
    final reference = _preferencesRef(clientId);
    if (reference == null) {
      return;
    }
    await _userRef(clientId)?.set(
      {
        'updatedAt': FieldValue.serverTimestamp(),
        'clientId': clientId,
      },
      SetOptions(merge: true),
    );
    await reference.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> upsertCategory(String clientId, Map<String, dynamic> data) async {
    final collection = _categoriesRef(clientId);
    if (collection == null) {
      return;
    }
    final id = data['id'] as String;
    await collection.doc(id).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteCategory(String clientId, String categoryId) async {
    final collection = _categoriesRef(clientId);
    if (collection == null) {
      return;
    }
    await collection.doc(categoryId).delete();
  }

  Future<void> upsertTransaction(String clientId, Map<String, dynamic> data) async {
    final collection = _transactionsRef(clientId);
    if (collection == null) {
      return;
    }
    final id = data['id'] as String;
    await collection.doc(id).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteTransaction(String clientId, String transactionId) async {
    final collection = _transactionsRef(clientId);
    if (collection == null) {
      return;
    }
    await collection.doc(transactionId).delete();
  }

  Future<void> logEvent(String name, [Map<String, Object?> parameters = const {}]) async {
    final analytics = this.analytics;
    if (analytics == null) {
      return;
    }
    final payload = <String, Object>{};
    for (final entry in parameters.entries) {
      final value = entry.value;
      if (value is String || value is num || value is bool) {
        payload[entry.key] = value as Object;
      }
    }
    await analytics.logEvent(name: name, parameters: payload);
  }

  Future<void> logScreen(String screenName) async {
    final analytics = this.analytics;
    if (analytics == null) {
      return;
    }
    await analytics.logScreenView(screenName: screenName);
  }

  DocumentReference<Map<String, dynamic>>? _userRef(String clientId) {
    final firestore = this.firestore;
    if (firestore == null) {
      return null;
    }
    return firestore.collection('simple_currency_users').doc(clientId);
  }

  DocumentReference<Map<String, dynamic>>? _preferencesRef(String clientId) {
    return _userRef(clientId)?.collection('meta').doc('preferences');
  }

  CollectionReference<Map<String, dynamic>>? _categoriesRef(String clientId) {
    return _userRef(clientId)?.collection('wallet_categories');
  }

  CollectionReference<Map<String, dynamic>>? _transactionsRef(String clientId) {
    return _userRef(clientId)?.collection('wallet_transactions');
  }
}
