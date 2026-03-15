import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_runtime.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseServices = await initializeFirebaseServices();
  runApp(SimpleCurrencyApp(firebaseServices: firebaseServices));
}
